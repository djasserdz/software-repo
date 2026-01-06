from typing import Optional, List, Union
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.exc import IntegrityError
from fastapi import status
import logging

from src.database.db import TimeSlot, TimeSlotStatus
from src.models.timeslot import TimeSlotCreate
from src.HTTPBaseException import HTTPBaseException


class TimeSlotRepo:
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
    async def create(session: AsyncSession, timeslot_data: Union[TimeSlotCreate, dict]) -> TimeSlot:
        """Create a new time slot. Accepts either TimeSlotCreate model or dict"""
        try:
            # Handle both Pydantic model and dict inputs
            if isinstance(timeslot_data, dict):
                timeslot_dict = timeslot_data.copy()
            else:
                timeslot_dict = timeslot_data.model_dump()
            
            # Convert status string to enum if needed
            if 'status' in timeslot_dict and isinstance(timeslot_dict['status'], str):
                try:
                    timeslot_dict['status'] = TimeSlotStatus(timeslot_dict['status'])
                except ValueError:
                    # If invalid status, default to ACTIVE
                    timeslot_dict['status'] = TimeSlotStatus.ACTIVE
            
            # Ensure datetime fields are datetime objects, not strings
            if 'start_at' in timeslot_dict and isinstance(timeslot_dict['start_at'], str):
                timeslot_dict['start_at'] = datetime.fromisoformat(timeslot_dict['start_at'].replace('Z', '+00:00'))
            if 'end_at' in timeslot_dict and isinstance(timeslot_dict['end_at'], str):
                timeslot_dict['end_at'] = datetime.fromisoformat(timeslot_dict['end_at'].replace('Z', '+00:00'))

            # Validate that end_at is after start_at
            if timeslot_dict.get('end_at') <= timeslot_dict.get('start_at'):
                raise TimeSlotRepo.InvalidTimeRange()

            # Log the data being created
            logging.info(f"📝 Creating TimeSlot: zone_id={timeslot_dict.get('zone_id')}, "
                         f"start_at={timeslot_dict.get('start_at')}, end_at={timeslot_dict.get('end_at')}")

            orm_timeslot = TimeSlot(**timeslot_dict)
            session.add(orm_timeslot)
            await session.flush()  # Flush to get the ID
            await session.commit()
            await session.refresh(orm_timeslot)
            logging.info(f"✅ TimeSlot created successfully: ID={orm_timeslot.time_id}, zone={orm_timeslot.zone_id}, start={orm_timeslot.start_at}")
            return orm_timeslot
        except TimeSlotRepo.InvalidTimeRange:
            await session.rollback()
            raise
        except IntegrityError:
            await session.rollback()
            raise TimeSlotRepo.CreateError()
        except Exception:
            await session.rollback()
            raise TimeSlotRepo.CreateError()

    @staticmethod
    async def get_by_id(session: AsyncSession, time_id: int) -> Optional[TimeSlot]:
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
        try:
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
        except Exception:
            await session.rollback()
            raise TimeSlotRepo.UpdateError()

    @staticmethod
    async def soft_delete(session: AsyncSession, time_id: int) -> bool:
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
        try:
            stmt = select(TimeSlot.time_id).where(
                TimeSlot.time_id == time_id, TimeSlot.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            return result.scalar_one_or_none() is not None
        except Exception:
            raise TimeSlotRepo.ExistsError()

    @staticmethod
    async def get_by_zone_and_start(
        session: AsyncSession, zone_id: int, start_at: datetime
    ) -> Optional[TimeSlot]:
        """Get time slot by zone ID and start time (exact match)"""
        try:
            # Use exact datetime match for duplicate detection
            stmt = select(TimeSlot).where(
                TimeSlot.zone_id == zone_id,
                TimeSlot.start_at == start_at,
                TimeSlot.deleted_at.is_(None),
            )
            result = await session.execute(stmt)
            slot = result.scalar_one_or_none()
            if slot:
                logging.debug(f"Found existing slot: ID={slot.time_id}, zone={zone_id}, start={start_at}")
            return slot
        except Exception as e:
            logging.error(f"Error checking for existing slot: {e}")
            raise TimeSlotRepo.GetError()
