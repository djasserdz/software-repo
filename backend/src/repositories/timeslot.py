from typing import Optional, List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.exc import IntegrityError
from fastapi import status

from src.database.db import TimeSlot, TimeSlotStatus
from src.models.timeslot import TimeSlotCreate
from src.HTTPBaseException import HTTPBaseException


class TimeSlotRepo:
    """Repository class for TimeSlot operations with static methods and proper error handling"""

    class TimeSlotNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Time slot not found"

    class InvalidTimeRange(HTTPBaseException):
        code = status.HTTP_400_BAD_REQUEST
        message = "End time must be after start time"

    class CreateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to create time slot"

    class GetError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get time slot"

    class GetAllError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get all time slots"

    class UpdateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to update time slot"

    class SoftDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to soft delete time slot"

    class HardDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to hard delete time slot"

    class CountError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to count time slots"

    class ExistsError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to check time slot existence"

    @staticmethod
    async def create(session: AsyncSession, timeslot_data: TimeSlotCreate) -> TimeSlot:
        """Create a new time slot"""
        try:
            timeslot_dict = timeslot_data.model_dump()

            # Validate time range
            if timeslot_dict.get("end_at") <= timeslot_dict.get("start_at"):
                raise TimeSlotRepo.InvalidTimeRange()

            orm_timeslot = TimeSlot(**timeslot_dict)
            session.add(orm_timeslot)
            await session.commit()
            await session.refresh(orm_timeslot)
            return orm_timeslot
        except IntegrityError:
            await session.rollback()
            raise TimeSlotRepo.CreateError()
        except TimeSlotRepo.InvalidTimeRange:
            await session.rollback()
            raise
        except Exception:
            await session.rollback()
            raise TimeSlotRepo.CreateError()

    @staticmethod
    async def get_by_id(session: AsyncSession, time_id: int) -> Optional[TimeSlot]:
        """Get time slot by ID"""
        try:
            stmt = select(TimeSlot).where(
                TimeSlot.time_id == time_id, TimeSlot.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            timeslot = result.scalar_one_or_none()
            if timeslot is None:
                raise TimeSlotRepo.TimeSlotNotFound()
            return timeslot
        except TimeSlotRepo.TimeSlotNotFound:
            raise
        except Exception:
            raise TimeSlotRepo.GetError()

    @staticmethod
    async def get_all(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 100,
        zone_id: Optional[int] = None,
        status: Optional[TimeSlotStatus] = None,
    ) -> List[TimeSlot]:
        """Get all time slots with optional filters"""
        try:
            stmt = select(TimeSlot).where(TimeSlot.deleted_at.is_(None))

            if zone_id:
                stmt = stmt.where(TimeSlot.zone_id == zone_id)

            if status:
                stmt = stmt.where(TimeSlot.status == status)

            stmt = stmt.offset(skip).limit(limit).order_by(TimeSlot.start_at.asc())

            result = await session.execute(stmt)
            return list(result.scalars().all())
        except Exception:
            raise TimeSlotRepo.GetAllError()

    @staticmethod
    async def update(
        session: AsyncSession, time_id: int, **kwargs
    ) -> Optional[TimeSlot]:
        """Update time slot by ID"""
        try:
            # Validate time range if both times are being updated
            if "start_at" in kwargs and "end_at" in kwargs:
                if kwargs["end_at"] <= kwargs["start_at"]:
                    raise TimeSlotRepo.InvalidTimeRange()

            kwargs["updated_at"] = datetime.utcnow()

            stmt = (
                update(TimeSlot)
                .where(TimeSlot.time_id == time_id, TimeSlot.deleted_at.is_(None))
                .values(**kwargs)
                .returning(TimeSlot)
            )

            result = await session.execute(stmt)
            await session.commit()

            updated = result.scalar_one_or_none()
            if updated is None:
                raise TimeSlotRepo.TimeSlotNotFound()
            return updated
        except TimeSlotRepo.TimeSlotNotFound:
            raise
        except TimeSlotRepo.InvalidTimeRange:
            await session.rollback()
            raise
        except Exception:
            await session.rollback()
            raise TimeSlotRepo.UpdateError()

    @staticmethod
    async def soft_delete(session: AsyncSession, time_id: int) -> bool:
        """Soft delete time slot by setting deleted_at timestamp"""
        try:
            stmt = (
                update(TimeSlot)
                .where(TimeSlot.time_id == time_id, TimeSlot.deleted_at.is_(None))
                .values(deleted_at=datetime.utcnow())
            )

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise TimeSlotRepo.SoftDeleteError()

    @staticmethod
    async def hard_delete(session: AsyncSession, time_id: int) -> bool:
        """Hard delete time slot from database"""
        try:
            stmt = delete(TimeSlot).where(TimeSlot.time_id == time_id)

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise TimeSlotRepo.HardDeleteError()

    @staticmethod
    async def count(
        session: AsyncSession,
        zone_id: Optional[int] = None,
        status: Optional[TimeSlotStatus] = None,
    ) -> int:
        """Count time slots with optional filters"""
        try:
            stmt = select(func.count(TimeSlot.time_id)).where(
                TimeSlot.deleted_at.is_(None)
            )

            if zone_id:
                stmt = stmt.where(TimeSlot.zone_id == zone_id)

            if status:
                stmt = stmt.where(TimeSlot.status == status)

            result = await session.execute(stmt)
            return result.scalar_one()
        except Exception:
            raise TimeSlotRepo.CountError()

    @staticmethod
    async def exists(session: AsyncSession, time_id: int) -> bool:
        """Check if time slot exists"""
        try:
            stmt = select(TimeSlot.time_id).where(
                TimeSlot.time_id == time_id, TimeSlot.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            return result.scalar_one_or_none() is not None
        except Exception:
            raise TimeSlotRepo.ExistsError()
