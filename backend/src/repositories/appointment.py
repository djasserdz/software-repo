from typing import Optional, List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.exc import IntegrityError
from fastapi import status

from src.database.db import Appointment, AppointmentStatus
from src.models.appointment import AppointmentCreate
from src.HTTPBaseException import HTTPBaseException


class AppointmentRepo:
    """Repository class for Appointment operations with static methods and proper error handling"""

    class AppointmentNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Appointment not found"

    class FarmerNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Farmer not found"

    class ZoneNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Storage zone not found"

    class TimeSlotNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Time slot not found"

    class CreateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to create appointment"

    class GetError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get appointment"

    class GetAllError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get all appointments"

    class UpdateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to update appointment"

    class SoftDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to soft delete appointment"

    class HardDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to hard delete appointment"

    class CountError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to count appointments"

    class ExistsError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to check appointment existence"

    @staticmethod
    async def create(
        session: AsyncSession, appointment_data: AppointmentCreate
    ) -> Appointment:
        """Create a new appointment"""
        try:
            appointment_dict = appointment_data.model_dump()
            orm_appointment = Appointment(**appointment_dict)
            session.add(orm_appointment)
            await session.commit()
            await session.refresh(orm_appointment)
            return orm_appointment
        except IntegrityError:
            await session.rollback()
            raise AppointmentRepo.CreateError()
        except Exception:
            await session.rollback()
            raise AppointmentRepo.CreateError()

    @staticmethod
    async def get_by_id(
        session: AsyncSession, appointment_id: int
    ) -> Optional[Appointment]:
        """Get appointment by ID"""
        try:
            stmt = select(Appointment).where(
                Appointment.appointment_id == appointment_id,
                Appointment.deleted_at.is_(None),
            )
            result = await session.execute(stmt)
            appointment = result.scalar_one_or_none()
            if appointment is None:
                raise AppointmentRepo.AppointmentNotFound()
            return appointment
        except AppointmentRepo.AppointmentNotFound:
            raise
        except Exception:
            raise AppointmentRepo.GetError()

    @staticmethod
    async def get_all(
        session: AsyncSession,
        zone_id: Optional[int] = None,
        farmer_id: Optional[int] = None,
        skip: int = 0,
        limit: int = 100,
        status: Optional[AppointmentStatus] = None,
    ) -> List[Appointment]:
        """Get all appointments with optional filters"""
        try:
            stmt = select(Appointment).where(Appointment.deleted_at.is_(None))

            if farmer_id:
                stmt = stmt.where(Appointment.farmer_id == farmer_id)

            if zone_id:
                stmt = stmt.where(Appointment.zone_id == zone_id)

            if status:
                stmt = stmt.where(Appointment.status == status)

            stmt = (
                stmt.offset(skip).limit(limit).order_by(Appointment.created_at.desc())
            )

            result = await session.execute(stmt)
            return list(result.scalars().all())
        except Exception:
            raise AppointmentRepo.GetAllError()

    @staticmethod
    async def get_by_timeslot(
        session: AsyncSession, timeslot_id: int
    ) -> Optional[Appointment]:
        """Get appointment by timeslot ID"""
        try:
            stmt = select(Appointment).where(
                Appointment.timeslot_id == timeslot_id,
                Appointment.deleted_at.is_(None),
            )
            result = await session.execute(stmt)
            return result.scalar_one_or_none()
        except Exception:
            raise AppointmentRepo.GetError()

    @staticmethod
    async def update(
        session: AsyncSession, appointment_id: int, **kwargs
    ) -> Optional[Appointment]:
        """Update appointment by ID"""
        try:
            kwargs["updated_at"] = datetime.utcnow()

            stmt = (
                update(Appointment)
                .where(
                    Appointment.appointment_id == appointment_id,
                    Appointment.deleted_at.is_(None),
                )
                .values(**kwargs)
                .returning(Appointment)
            )

            result = await session.execute(stmt)
            await session.commit()

            updated = result.scalar_one_or_none()
            if updated is None:
                raise AppointmentRepo.AppointmentNotFound()
            return updated
        except AppointmentRepo.AppointmentNotFound:
            raise
        except Exception:
            await session.rollback()
            raise AppointmentRepo.UpdateError()

    @staticmethod
    async def soft_delete(session: AsyncSession, appointment_id: int) -> bool:
        """Soft delete appointment by setting deleted_at timestamp"""
        try:
            stmt = (
                update(Appointment)
                .where(
                    Appointment.appointment_id == appointment_id,
                    Appointment.deleted_at.is_(None),
                )
                .values(deleted_at=datetime.utcnow())
            )

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise AppointmentRepo.SoftDeleteError()

    @staticmethod
    async def hard_delete(session: AsyncSession, appointment_id: int) -> bool:
        """Hard delete appointment from database"""
        try:
            stmt = delete(Appointment).where(
                Appointment.appointment_id == appointment_id
            )

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise AppointmentRepo.HardDeleteError()

    @staticmethod
    async def count(
        session: AsyncSession,
        farmer_id: Optional[int] = None,
        zone_id: Optional[int] = None,
        status: Optional[AppointmentStatus] = None,
    ) -> int:
        """Count appointments with optional filters"""
        try:
            stmt = select(func.count(Appointment.appointment_id)).where(
                Appointment.deleted_at.is_(None)
            )

            if farmer_id:
                stmt = stmt.where(Appointment.farmer_id == farmer_id)

            if zone_id:
                stmt = stmt.where(Appointment.zone_id == zone_id)

            if status:
                stmt = stmt.where(Appointment.status == status)

            result = await session.execute(stmt)
            return result.scalar_one()
        except Exception:
            raise AppointmentRepo.CountError()

    @staticmethod
    async def exists(session: AsyncSession, appointment_id: int) -> bool:
        """Check if appointment exists"""
        try:
            stmt = select(Appointment.appointment_id).where(
                Appointment.appointment_id == appointment_id,
                Appointment.deleted_at.is_(None),
            )
            result = await session.execute(stmt)
            return result.scalar_one_or_none() is not None
        except Exception:
            raise AppointmentRepo.ExistsError()
