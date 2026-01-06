from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from src.repositories.appointment import AppointmentRepo
from src.repositories.user import UserRepo
from src.repositories.timeslot import TimeSlotRepo
from src.repositories.grain import GrainRepo
from src.repositories.storagezone import StorageZoneRepo
from src.HTTPBaseException import HTTPBaseException
from src.models.appointment import (
    AppointmentCreate,
    AppointmentCreateFromFrontend,
    AppointmentUpdate,
)
from src.database.db import TimeSlotStatus, AppointmentStatus
from typing import Optional
import logging


class AppointementService:
    @staticmethod
    async def create_appointment(
        data: AppointmentCreate, session: AsyncSession, farmer_id: Optional[int] = None
    ):
        """Create appointment - can accept either AppointmentCreate or farmer_id separately"""
        try:
            # Use farmer_id from parameter if provided, otherwise from data
            farmer_id = farmer_id or data.farmer_id
            farmer = await UserRepo.get_by_id(session, farmer_id)
            zone = await StorageZoneRepo.get_by_id(session, data.zone_id)
            time = await TimeSlotRepo.get_by_id(session, data.timeslot_id)
            grain = await GrainRepo.get_by_id(session, data.grain_type_id)

            if time.status != TimeSlotStatus.ACTIVE:
                raise HTTPException(status_code=403, detail="Cannot use this time")

            if zone.available_capacity < data.requested_quantity:
                raise HTTPException(
                    status_code=403, detail="Storage capacity not sufficient"
                )

            existing_appointment = await AppointmentRepo.get_by_timeslot(
                session, time.time_id
            )
            if existing_appointment:
                raise HTTPException(status_code=403, detail="Time slot already booked")

            await TimeSlotRepo.update(
                session, time.time_id, status=TimeSlotStatus.NOT_ACTIVE
            )

            # Create appointment with farmer_id
            appointment_data = AppointmentCreate(
                farmer_id=farmer_id,
                zone_id=data.zone_id,
                grain_type_id=data.grain_type_id,
                timeslot_id=data.timeslot_id,
                requested_quantity=int(data.requested_quantity),
                status=AppointmentStatus.PENDING,
            )

            appointment = await AppointmentRepo.create(session, appointment_data)

            return appointment

        except HTTPException:
            raise

        except Exception as e:
            await session.rollback()
            logging.exception(f"Error happened: {e}")
            raise HTTPException(status_code=500, detail="Failed to create appointment")

    @staticmethod
    async def create_appointment_from_frontend(
        data: AppointmentCreateFromFrontend,
        session: AsyncSession,
        farmer_id: int,
    ):
        """Create appointment from frontend format"""
        try:
            # Convert frontend format to backend format
            appointment_data = AppointmentCreate(
                farmer_id=farmer_id,
                zone_id=data.warehouseZoneId,
                grain_type_id=int(data.grainTypeId),
                timeslot_id=data.timeSlotId,
                requested_quantity=int(data.requestedQuantity),
                status=AppointmentStatus.PENDING,
            )

            return await AppointementService.create_appointment(
                appointment_data, session, farmer_id
            )

        except HTTPException:
            raise
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error creating appointment from frontend: {e}")
            raise HTTPException(status_code=500, detail="Failed to create appointment")


    @staticmethod
    async def get_appointments(
        session: AsyncSession,
        zone_id: Optional[int] = None,
        farmer_id: Optional[int] = None,
        status: Optional[AppointmentStatus] = None,
        current_user=None,
    ):
        from src.models.user import UserRole
        
        # If warehouse admin, only return appointments for their warehouse zones
        if current_user and current_user.role == UserRole.WAREHOUSE_ADMIN:
            from src.repositories.warehouse import WarehouseRepo
            from src.repositories.storagezone import StorageZoneRepo
            
            # Get all zones for this warehouse admin
            warehouses = await WarehouseRepo.get_all(
                session, manager_id=current_user.user_id
            )
            if not warehouses:
                return []
            
            warehouse_id = warehouses[0].warehouse_id
            zones = await StorageZoneRepo.get_all(session, warehouse_id=warehouse_id)
            zone_ids = [z.zone_id for z in zones]
            
            # Get appointments for these zones
            appointments = []
            for z_id in zone_ids:
                zones_apps = await AppointmentRepo.get_all(
                    session, zone_id=z_id, farmer_id=farmer_id, status=status
                )
                appointments.extend(zones_apps)
            return appointments
        
        appointments = await AppointmentRepo.get_all(
            session, zone_id=zone_id, farmer_id=farmer_id, status=status
        )
        return appointments

    @staticmethod
    async def get_my_appointments(
        session: AsyncSession,
        farmer_id: int,
        status: Optional[AppointmentStatus] = None,
    ):
        try:
            appointments = await AppointmentRepo.get_all(
                session, farmer_id=farmer_id, status=status
            )

            formatted_appointments = []
            for apt in appointments:
                grain = None
                time_slot = None
                zone = None
                warehouse = None
                
                try:
                    grain = await GrainRepo.get_by_id(session, apt.grain_type_id)
                except (HTTPBaseException, HTTPException, Exception) as e:
                    logging.warning(f"Grain {apt.grain_type_id} not found for appointment {apt.appointment_id}: {e}")
                    grain = None
                
                try:
                    time_slot = await TimeSlotRepo.get_by_id(session, apt.timeslot_id)
                except (HTTPBaseException, HTTPException, Exception) as e:
                    logging.warning(f"Time slot {apt.timeslot_id} not found for appointment {apt.appointment_id}: {e}")
                    time_slot = None
                
                try:
                    zone = await StorageZoneRepo.get_by_id(session, apt.zone_id)
                except (HTTPBaseException, HTTPException, Exception) as e:
                    logging.warning(f"Zone {apt.zone_id} not found for appointment {apt.appointment_id}: {e}")
                    zone = None
                
                if zone:
                    from src.repositories.warehouse import WarehouseRepo
                    try:
                        warehouse = await WarehouseRepo.get_by_id(
                            session, zone.warehouse_id
                        )
                    except (HTTPBaseException, HTTPException, Exception) as e:
                        logging.warning(f"Warehouse {zone.warehouse_id} not found for zone {zone.zone_id}: {e}")
                        warehouse = None

                status_str = "UNKNOWN"
                if apt.status:
                    try:
                        if isinstance(apt.status, AppointmentStatus):
                            status_str = apt.status.value.upper()
                        elif isinstance(apt.status, str):
                            status_str = apt.status.upper()
                        else:
                            status_str = str(apt.status).upper()
                    except Exception as e:
                        logging.warning(f"Error formatting status for appointment {apt.appointment_id}: {e}")
                        status_str = "UNKNOWN"
                
                formatted_appointments.append(
                    {
                        "id": apt.appointment_id,
                        "appointment_id": apt.appointment_id,
                        "farmer_id": apt.farmer_id,
                        "zone_id": apt.zone_id,
                        "grain_type_id": apt.grain_type_id,
                        "grainType": grain.name if grain and hasattr(grain, 'name') else f"Grain {apt.grain_type_id}",
                        "requestedQuantity": float(apt.requested_quantity) if apt.requested_quantity else 0.0,
                        "status": status_str,
                        "scheduledDate": time_slot.start_at.isoformat()
                        if time_slot and hasattr(time_slot, 'start_at') and time_slot.start_at
                        else None,
                        "timeSlot": {
                            "id": time_slot.time_id if time_slot and hasattr(time_slot, 'time_id') else None,
                            "start_at": time_slot.start_at.isoformat()
                            if time_slot and hasattr(time_slot, 'start_at') and time_slot.start_at
                            else None,
                            "end_at": time_slot.end_at.isoformat()
                            if time_slot and hasattr(time_slot, 'end_at') and time_slot.end_at
                            else None,
                        }
                        if time_slot
                        else None,
                        "warehouseZone": {
                            "id": zone.zone_id if zone and hasattr(zone, 'zone_id') else None,
                            "name": zone.name if zone and hasattr(zone, 'name') else None,
                            "warehouse": {
                                "id": warehouse.warehouse_id if warehouse and hasattr(warehouse, 'warehouse_id') else None,
                                "name": warehouse.name if warehouse and hasattr(warehouse, 'name') else None,
                                "location": warehouse.location if warehouse and hasattr(warehouse, 'location') else None,
                            }
                            if warehouse
                            else None,
                        }
                        if zone
                        else None,
                        "created_at": apt.created_at.isoformat() if apt.created_at else None,
                        "updated_at": apt.updated_at.isoformat() if apt.updated_at else None,
                    }
                )

            return formatted_appointments
        except HTTPException:
            raise
        except Exception as e:
            logging.exception(f"Error getting farmer appointments: {e}")
            raise HTTPException(
                status_code=500, detail=f"Failed to get farmer appointments: {str(e)}"
            )

    @staticmethod
    async def get_appointment(session: AsyncSession, id: int, current_user=None):
        from src.models.user import UserRole
        from src.repositories.warehouse import WarehouseRepo
        
        appointment = await AppointmentRepo.get_by_id(session, id)
        
        # Check warehouse admin access
        if current_user and current_user.role == UserRole.WAREHOUSE_ADMIN:
            zone = await StorageZoneRepo.get_by_id(session, appointment.zone_id)
            warehouse = await WarehouseRepo.get_by_id(session, zone.warehouse_id)
            
            if warehouse.manager_id != current_user.user_id:
                raise HTTPException(
                    status_code=403,
                    detail="You can only view appointments in your own warehouse"
                )
        
        return appointment

    @staticmethod
    async def update_appointment(
        session: AsyncSession, appointment_id: int, **kwargs
    ):
        """Update an appointment"""
        try:
            updated = await AppointmentRepo.update(session, appointment_id, **kwargs)
            return updated
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error updating appointment: {e}")
            raise HTTPException(status_code=500, detail="Failed to update appointment")
