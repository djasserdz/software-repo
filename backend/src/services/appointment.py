from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from src.repositories.appointment import AppointmentRepo
from src.repositories.user import UserRepo
from src.repositories.timeslot import TimeSlotRepo
from src.repositories.grain import GrainRepo
from src.repositories.storagezone import StorageZoneRepo
from src.models.appointment import AppointmentCreate, AppointmentUpdate
from src.database.db import TimeSlotStatus
from typing import Optional
import logging


class AppointementService:
    @staticmethod
    async def create_appointment(data: AppointmentCreate, session: AsyncSession):
        try:
            farmer = await UserRepo.get_by_id(session, data.farmer_id)
            zone = await StorageZoneRepo.get_by_id(session, data.zone_id)
            time = await TimeSlotRepo.get_by_id(session, data.timeslot_id)
            grain = await GrainRepo.get_by_id(session, data.grain_type_id)
    
            if time.status != TimeSlotStatus.ACTIVE:
                raise HTTPException(status_code=403, detail="Cannot use this time")
    
            if zone.available_capacity < data.requested_quantity:
                raise HTTPException(status_code=403, detail="Storage not enough")
    
            existing_appointment = await AppointmentRepo.get_by_timeslot(session, time.time_id)
            if existing_appointment:
                raise HTTPException(status_code=403, detail="Time slot already booked")
    
            await TimeSlotRepo.update(session, time.time_id, status=TimeSlotStatus.NOT_ACTIVE)
    
            appointment = await AppointmentRepo.create(session, data)
    
            return appointment
    
        except HTTPException:
            raise  
    
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error happened: {e}")
            raise HTTPException(status_code=500, detail="Failed to create appointment")


    @staticmethod
    async def get_appointments(
        session: AsyncSession,
        zone_id: Optional[int] = None,
        farmer_id: Optional[int] = None,
    ):
        appointments = await AppointmentRepo.get_all(session, zone_id, farmer_id)
        return appointments

    @staticmethod
    async def get_appointment(session: AsyncSession, id: int):
        appointment = await AppointmentRepo.get_by_id(session, id)
        return appointment
