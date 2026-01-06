from typing import Optional, List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.exc import IntegrityError
from fastapi import status

from src.database.db import TimeSlotTemplate
from src.HTTPBaseException import HTTPBaseException
import logging


class TimeSlotTemplateRepo:
    class TemplateNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Time slot template not found"

    class InvalidTimeRange(HTTPBaseException):
        code = status.HTTP_400_BAD_REQUEST
        message = "End time must be after start time"

    class CreateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to create time slot template"

    class GetError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get time slot template"

    class GetAllError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get all time slot templates"

    class UpdateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to update time slot template"

    class SoftDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to soft delete time slot template"

    class HardDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to hard delete time slot template"

    class CountError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to count time slot templates"

    class ExistsError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to check time slot template existence"

    @staticmethod
    async def create(session: AsyncSession, data: dict) -> TimeSlotTemplate:
        """Create a new time slot template"""
        try:
            from datetime import time as time_type
            
            # Ensure time objects are properly handled
            start_time = data.get('start_time')
            end_time = data.get('end_time')
            
            if isinstance(start_time, str):
                # Try different time formats
                try:
                    if len(start_time.split(':')) == 2:
                        # Format: HH:MM
                        data['start_time'] = datetime.strptime(start_time, '%H:%M').time()
                    else:
                        # Format: HH:MM:SS
                        data['start_time'] = datetime.strptime(start_time, '%H:%M:%S').time()
                except ValueError as e:
                    logging.error(f"Invalid start_time format: {start_time}, error: {e}")
                    raise TimeSlotTemplateRepo.InvalidTimeRange()
            
            if isinstance(end_time, str):
                # Try different time formats
                try:
                    if len(end_time.split(':')) == 2:
                        # Format: HH:MM
                        data['end_time'] = datetime.strptime(end_time, '%H:%M').time()
                    else:
                        # Format: HH:MM:SS
                        data['end_time'] = datetime.strptime(end_time, '%H:%M:%S').time()
                except ValueError as e:
                    logging.error(f"Invalid end_time format: {end_time}, error: {e}")
                    raise TimeSlotTemplateRepo.InvalidTimeRange()
            
            # Ensure we have time objects for validation
            start_time_obj = data.get('start_time')
            end_time_obj = data.get('end_time')
            
            if not isinstance(start_time_obj, time_type) or not isinstance(end_time_obj, time_type):
                raise TimeSlotTemplateRepo.InvalidTimeRange()
            
            # Validate that end_time is after start_time
            if end_time_obj <= start_time_obj:
                raise TimeSlotTemplateRepo.InvalidTimeRange()
            
            template = TimeSlotTemplate(**data)
            session.add(template)
            await session.commit()
            await session.refresh(template)
            return template
        except TimeSlotTemplateRepo.InvalidTimeRange:
            await session.rollback()
            raise
        except IntegrityError:
            await session.rollback()
            raise TimeSlotTemplateRepo.CreateError()
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error creating time slot template: {e}")
            raise TimeSlotTemplateRepo.CreateError()

    @staticmethod
    async def get_by_id(
        session: AsyncSession, template_id: int
    ) -> Optional[TimeSlotTemplate]:
        """Get time slot template by ID"""
        try:
            stmt = select(TimeSlotTemplate).where(
                TimeSlotTemplate.template_id == template_id
            )
            result = await session.execute(stmt)
            template = result.scalar_one_or_none()
            if template is None:
                raise TimeSlotTemplateRepo.TemplateNotFound()
            return template
        except TimeSlotTemplateRepo.TemplateNotFound:
            raise
        except Exception as e:
            logging.exception(f"Error getting time slot template: {e}")
            raise TimeSlotTemplateRepo.GetError()

    @staticmethod
    async def get_by_day(
        session: AsyncSession, day_of_week: int
    ) -> List[TimeSlotTemplate]:
        """Get time slot templates by day of week"""
        try:
            stmt = select(TimeSlotTemplate).where(
                TimeSlotTemplate.day_of_week == day_of_week
            )
            result = await session.execute(stmt)
            return list(result.scalars().all())
        except Exception as e:
            logging.exception(f"Error getting time slot templates by day: {e}")
            raise TimeSlotTemplateRepo.GetAllError()

    @staticmethod
    async def get_by_zone(
        session: AsyncSession, zone_id: int
    ) -> List[TimeSlotTemplate]:
        """Get time slot templates by zone ID"""
        try:
            stmt = select(TimeSlotTemplate).where(
                TimeSlotTemplate.zone_id == zone_id
            )
            result = await session.execute(stmt)
            return list(result.scalars().all())
        except Exception as e:
            logging.exception(f"Error getting time slot templates by zone: {e}")
            raise TimeSlotTemplateRepo.GetAllError()

    @staticmethod
    async def get_all(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 100,
        zone_id: Optional[int] = None,
        day_of_week: Optional[int] = None,
    ) -> List[TimeSlotTemplate]:
        """Get all time slot templates with optional filters"""
        try:
            stmt = select(TimeSlotTemplate)

            if zone_id is not None:
                stmt = stmt.where(TimeSlotTemplate.zone_id == zone_id)

            if day_of_week is not None:
                stmt = stmt.where(TimeSlotTemplate.day_of_week == day_of_week)

            stmt = (
                stmt.offset(skip)
                .limit(limit)
                .order_by(TimeSlotTemplate.zone_id, TimeSlotTemplate.day_of_week)
            )

            result = await session.execute(stmt)
            return list(result.scalars().all())
        except Exception as e:
            logging.exception(f"Error getting all time slot templates: {e}")
            raise TimeSlotTemplateRepo.GetAllError()

    @staticmethod
    async def update(
        session: AsyncSession, template_id: int, **kwargs
    ) -> Optional[TimeSlotTemplate]:
        """Update time slot template by ID"""
        try:
            kwargs["updated_at"] = datetime.utcnow()

            stmt = (
                update(TimeSlotTemplate)
                .where(TimeSlotTemplate.template_id == template_id)
                .values(**kwargs)
                .returning(TimeSlotTemplate)
            )

            result = await session.execute(stmt)
            await session.commit()

            updated = result.scalar_one_or_none()
            if updated is None:
                raise TimeSlotTemplateRepo.TemplateNotFound()
            return updated
        except TimeSlotTemplateRepo.TemplateNotFound:
            raise
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error updating time slot template: {e}")
            raise TimeSlotTemplateRepo.UpdateError()

    @staticmethod
    async def soft_delete(session: AsyncSession, template_id: int) -> bool:
        """Soft delete time slot template by setting deleted_at timestamp"""
        try:
            stmt = (
                update(TimeSlotTemplate)
                .where(TimeSlotTemplate.template_id == template_id)
                .values(deleted_at=datetime.utcnow())
            )

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error soft deleting time slot template: {e}")
            raise TimeSlotTemplateRepo.SoftDeleteError()

    @staticmethod
    async def hard_delete(session: AsyncSession, template_id: int) -> bool:
        """Hard delete time slot template from database"""
        try:
            stmt = delete(TimeSlotTemplate).where(
                TimeSlotTemplate.template_id == template_id
            )

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error hard deleting time slot template: {e}")
            raise TimeSlotTemplateRepo.HardDeleteError()

    @staticmethod
    async def count(
        session: AsyncSession,
        zone_id: Optional[int] = None,
        day_of_week: Optional[int] = None,
    ) -> int:
        """Count time slot templates with optional filters"""
        try:
            stmt = select(func.count(TimeSlotTemplate.template_id))

            if zone_id is not None:
                stmt = stmt.where(TimeSlotTemplate.zone_id == zone_id)

            if day_of_week is not None:
                stmt = stmt.where(TimeSlotTemplate.day_of_week == day_of_week)

            result = await session.execute(stmt)
            return result.scalar_one()
        except Exception as e:
            logging.exception(f"Error counting time slot templates: {e}")
            raise TimeSlotTemplateRepo.CountError()

    @staticmethod
    async def exists(session: AsyncSession, template_id: int) -> bool:
        """Check if time slot template exists"""
        try:
            stmt = select(TimeSlotTemplate.template_id).where(
                TimeSlotTemplate.template_id == template_id
            )
            result = await session.execute(stmt)
            return result.scalar_one_or_none() is not None
        except Exception as e:
            logging.exception(f"Error checking time slot template existence: {e}")
            raise TimeSlotTemplateRepo.ExistsError()
