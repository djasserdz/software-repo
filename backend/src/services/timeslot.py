from sqlalchemy.ext.asyncio import AsyncSession
from src.models.timeslot import TimeSlotCreate, TimeSlotUpdate,TimeSlotStatus
from src.repositories.timeslot import TimeSlotRepo
from src.repositories.timeslottemplate import TimeSlotTemplateRepo
from src.repositories.storagezone import StorageZoneRepo
from typing import Optional
from datetime import datetime,time,timedelta
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
            logging.exception(f"Error whiel creating time slot : {e}")
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
            logging.exception(f"Erro while getting all times : {e}")
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
        tomorrow = datetime.utcnow().date() + timedelta(days=1)
        weekday = tomorrow.weekday()  # 0 = Monday
        templates = await TimeSlotTemplateRepo.get_by_day(session, weekday)

        created_slots = []
        for tpl in templates:
            start_at = datetime.combine(tomorrow, tpl.start_time)
            end_at = datetime.combine(tomorrow, tpl.end_time)
            
            # Check if slot already exists to avoid duplicates
            existing = await TimeSlotRepo.get_by_zone_and_start(session, tpl.zone_id, start_at)
            if existing:
                continue

            slot_data = {
                "zone_id": tpl.zone_id,
                "start_at": start_at,
                "end_at": end_at,
                "status": TimeSlotStatus.ACTIVE,
            }
            slot = await TimeSlotRepo.create(session, slot_data)
            created_slots.append(slot)
        
        return created_slots

