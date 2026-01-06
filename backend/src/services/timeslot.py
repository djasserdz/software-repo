from sqlalchemy.ext.asyncio import AsyncSession
from src.models.timeslot import TimeSlotCreate, TimeSlotUpdate, TimeSlotStatus
from src.repositories.timeslot import TimeSlotRepo
from src.repositories.timeslottemplate import TimeSlotTemplateRepo
from src.repositories.storagezone import StorageZoneRepo
from src.repositories.appointment import AppointmentRepo
from src.database.db import ZoneStatus, AppointmentStatus
from typing import Optional
from datetime import datetime, time, timedelta
import logging


class TimeSlotService:
    @staticmethod
    async def create_time(session: AsyncSession, data: TimeSlotCreate):
        try:
            zone = await StorageZoneRepo.get_by_id(session, data.zone_id)
            timeslot = await TimeSlotRepo.create(session, data)
            return timeslot
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error while creating time slot: {e}")
            raise

    @staticmethod
    async def get_all(
        session: AsyncSession,
        zone_id: int,
        skip: int = 0,
        limit: int = 100,
    ):
        try:
            zone = await StorageZoneRepo.get_by_id(session, zone_id)
            times = await TimeSlotRepo.get_all(
                session, skip=skip, limit=limit, zone_id=zone_id
            )
            return times
        except Exception as e:
            logging.exception(f"Error while getting all times: {e}")
            raise

    @staticmethod
    async def get_available(
        session: AsyncSession,
        zone_id: int,
        grain_type_id: Optional[int] = None,
    ):
        """Get available time slots for a zone, optionally filtered by grain type"""
        try:
            zone = await StorageZoneRepo.get_by_id(session, zone_id)
            
            # If grain_type_id is provided, verify the zone supports this grain type
            if grain_type_id and zone.grain_type_id != grain_type_id:
                return []
            
            # Get all active time slots for this zone
            times = await TimeSlotRepo.get_all(
                session, skip=0, limit=1000, zone_id=zone_id, status=TimeSlotStatus.ACTIVE
            )
            
            # Filter out time slots that are already booked or in the past
            # Only consider appointments with PENDING or ACCEPTED status as "booked"
            now = datetime.utcnow()
            available_slots = []
            for time_slot in times:
                # Skip time slots that have already passed
                if time_slot.start_at < now:
                    continue
                
                # Check if this time slot has an active appointment (pending or accepted)
                appointment = await AppointmentRepo.get_by_timeslot(session, time_slot.time_id)
                if appointment and appointment.status in [AppointmentStatus.PENDING, AppointmentStatus.ACCEPTED]:
                    # Skip timeslots with active appointments
                    continue
                
                # Format the time slot for frontend
                available_slots.append({
                    "time_id": time_slot.time_id,
                    "zone_id": time_slot.zone_id,
                    "start_at": time_slot.start_at.isoformat(),
                    "end_at": time_slot.end_at.isoformat(),
                    "date": time_slot.start_at.strftime("%Y-%m-%d"),
                    "startTime": time_slot.start_at.strftime("%H:%M"),
                    "endTime": time_slot.end_at.strftime("%H:%M"),
                    "status": time_slot.status.value,
                    "available": True,
                })
            
            # Sort by start_at (earliest first)
            available_slots.sort(key=lambda x: x["start_at"])
            
            return available_slots
        except Exception as e:
            logging.exception(f"Error getting available time slots: {e}")
            raise

    @staticmethod
    async def get_time(session: AsyncSession, time_id: int):
        time = await TimeSlotRepo.get_by_id(session, time_id)
        return time

    @staticmethod
    async def updated_time(session: AsyncSession, data: TimeSlotUpdate, time_id: int):
        updated_time = data.model_dump(exclude_unset=True)
        time = await TimeSlotRepo.update(session, time_id, **updated_time)
        return time

    @staticmethod
    async def delete_time(session: AsyncSession, time_id: int):
        time = await TimeSlotRepo.soft_delete(session, time_id)
        return time
    @staticmethod
    async def generate_timeslots_for_next_day(session: AsyncSession):
        """Generate time slots for tomorrow based on templates"""
        try:
            tomorrow = datetime.utcnow().date() + timedelta(days=1)
            weekday = tomorrow.weekday()  # 0 = Monday, 6 = Sunday
            logging.info(f"Generating time slots for {tomorrow} (weekday: {weekday})")
            
            templates = await TimeSlotTemplateRepo.get_by_day(session, weekday)
            logging.info(f"Found {len(templates)} templates for weekday {weekday}")

            if not templates:
                logging.warning(f"No templates found for weekday {weekday}")
                return []

            created_slots = []
            for tpl in templates:
                try:
                    logging.info(f"📋 Processing template ID={tpl.template_id}: zone={tpl.zone_id}, day={tpl.day_of_week}, time={tpl.start_time}-{tpl.end_time}")
                    
                    # Verify zone exists and is active
                    zone = await StorageZoneRepo.get_by_id(session, tpl.zone_id)
                    if zone.status != ZoneStatus.ACTIVE:
                        logging.info(
                            f"⏭️  Skipping zone {tpl.zone_id} - zone is not active (status: {zone.status})"
                        )
                        continue

                    # Combine date with time, ensuring timezone-aware datetime
                    start_at = datetime.combine(tomorrow, tpl.start_time)
                    end_at = datetime.combine(tomorrow, tpl.end_time)
                    
                    # Make timezone-aware (UTC)
                    start_at = start_at.replace(tzinfo=None)
                    end_at = end_at.replace(tzinfo=None)
                    
                    logging.info(f"🔍 Checking for existing slot: zone={tpl.zone_id}, start_at={start_at}")

                    # Check if slot already exists to avoid duplicates
                    existing = await TimeSlotRepo.get_by_zone_and_start(
                        session, tpl.zone_id, start_at
                    )
                    if existing:
                        logging.info(f"⏭️  Skipping: Time slot already exists for zone {tpl.zone_id} at {start_at} (existing slot ID: {existing.time_id}, existing start: {existing.start_at})")
                        continue
                    
                    logging.info(f"✅ No existing slot found. Creating new time slot for zone {tpl.zone_id}: {start_at} to {end_at}")

                    # Use TimeSlotCreate model
                    slot_data = TimeSlotCreate(
                        zone_id=tpl.zone_id,
                        start_at=start_at,
                        end_at=end_at,
                        status=TimeSlotStatus.ACTIVE,
                    )
                    slot = await TimeSlotRepo.create(session, slot_data)
                    created_slots.append(slot)
                    logging.info(f"✅ Successfully created time slot ID={slot.time_id} for zone {tpl.zone_id}")
                except StorageZoneRepo.StorageZoneNotFound:
                    logging.warning(f"Zone {tpl.zone_id} not found, skipping template {tpl.template_id}")
                    continue
                except Exception as e:
                    logging.exception(
                        f"Error creating time slot for template {tpl.template_id}: {e}"
                    )
                    continue

            logging.info(
                f"Generated {len(created_slots)} time slots for {tomorrow}"
            )
            return created_slots
        except Exception as e:
            logging.exception(f"Error in generate_timeslots_for_next_day: {e}")
            raise

    @staticmethod
    async def generate_timeslots_for_next_week(session: AsyncSession):
        """
        Generate time slots for the next 7 days based on templates.
        Only generates for active zones and skips existing slots.
        """
        try:
            today = datetime.utcnow().date()
            created_slots = []
            logging.info(f"Generating time slots for the next 7 days starting from {today}")

            # Generate slots for each day in the next week (7 days)
            for day_offset in range(1, 8):  # Days 1-7
                target_date = today + timedelta(days=day_offset)
                weekday = target_date.weekday()  # 0 = Monday, 6 = Sunday
                logging.info(f"Processing day {day_offset}: {target_date} (weekday: {weekday})")

                # Get all templates for this day of week
                templates = await TimeSlotTemplateRepo.get_by_day(session, weekday)
                logging.info(f"Found {len(templates)} templates for weekday {weekday}")

                for tpl in templates:
                    try:
                        logging.info(f"📋 Processing template ID={tpl.template_id}: zone={tpl.zone_id}, day={tpl.day_of_week}, time={tpl.start_time}-{tpl.end_time} for {target_date}")
                        
                        # Verify zone exists and is active
                        zone = await StorageZoneRepo.get_by_id(session, tpl.zone_id)
                        if zone.status != ZoneStatus.ACTIVE:
                            logging.info(
                                f"⏭️  Skipping zone {tpl.zone_id} on {target_date} - zone is not active (status: {zone.status})"
                            )
                            continue

                        start_at = datetime.combine(target_date, tpl.start_time)
                        end_at = datetime.combine(target_date, tpl.end_time)
                        
                        # Make timezone-aware (UTC)
                        start_at = start_at.replace(tzinfo=None)
                        end_at = end_at.replace(tzinfo=None)
                        
                        logging.info(f"🔍 Checking for existing slot: zone={tpl.zone_id}, start_at={start_at} on {target_date}")

                        # Check if slot already exists to avoid duplicates
                        existing = await TimeSlotRepo.get_by_zone_and_start(
                            session, tpl.zone_id, start_at
                        )
                        if existing:
                            logging.info(f"⏭️  Skipping: Time slot already exists for zone {tpl.zone_id} at {start_at} on {target_date} (existing slot ID: {existing.time_id}, existing start: {existing.start_at})")
                            continue
                        
                        logging.info(f"✅ No existing slot found. Creating new time slot for zone {tpl.zone_id} on {target_date}: {start_at} to {end_at}")

                        # Use TimeSlotCreate model (proper pattern)
                        slot_data = TimeSlotCreate(
                            zone_id=tpl.zone_id,
                            start_at=start_at,
                            end_at=end_at,
                            status=TimeSlotStatus.ACTIVE,
                        )
                        slot = await TimeSlotRepo.create(session, slot_data)
                        created_slots.append(slot)
                        logging.info(f"✅ Successfully created time slot ID={slot.time_id} for zone {tpl.zone_id} on {target_date}")
                    except StorageZoneRepo.StorageZoneNotFound:
                        logging.warning(
                            f"Zone {tpl.zone_id} not found, skipping template {tpl.template_id}"
                        )
                        continue
                    except Exception as e:
                        logging.exception(
                            f"Error creating time slot for zone {tpl.zone_id} on {target_date}: {e}"
                        )
                        continue

            logging.info(
                f"Generated {len(created_slots)} time slots for the next week (days 1-7)"
            )
            return created_slots
        except Exception as e:
            logging.exception(f"Error in generate_timeslots_for_next_week: {e}")
            raise

