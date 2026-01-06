from sqlalchemy.ext.asyncio import AsyncSession
from src.models.timeslottemplate import TimeSlotTemplateCreate, TimeSlotTemplateUpdate
from src.repositories.timeslottemplate import TimeSlotTemplateRepo
from src.repositories.storagezone import StorageZoneRepo
from typing import Optional
import logging


class TimeSlotTemplateService:
    @staticmethod
    async def create_template(session: AsyncSession, data: TimeSlotTemplateCreate):
        try:
            # Verify zone exists
            zone = await StorageZoneRepo.get_by_id(session, data.zone_id)
            
            # Convert Pydantic model to dict
            template_dict = data.model_dump()
            
            template = await TimeSlotTemplateRepo.create(session, template_dict)
            return template
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error while creating time slot template: {e}")
            raise

    @staticmethod
    async def get_all(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 100,
        zone_id: Optional[int] = None,
        day_of_week: Optional[int] = None,
    ):
        try:
            templates = await TimeSlotTemplateRepo.get_all(
                session, skip=skip, limit=limit, zone_id=zone_id, day_of_week=day_of_week
            )
            return templates
        except Exception as e:
            logging.exception(f"Error while getting all time slot templates: {e}")
            raise

    @staticmethod
    async def get_template(session: AsyncSession, template_id: int):
        template = await TimeSlotTemplateRepo.get_by_id(session, template_id)
        return template

    @staticmethod
    async def get_by_zone(session: AsyncSession, zone_id: int):
        templates = await TimeSlotTemplateRepo.get_by_zone(session, zone_id)
        return templates

    @staticmethod
    async def update_template(
        session: AsyncSession, data: TimeSlotTemplateUpdate, template_id: int
    ):
        updated_data = data.model_dump(exclude_unset=True)
        template = await TimeSlotTemplateRepo.update(session, template_id, **updated_data)
        return template

    @staticmethod
    async def delete_template(session: AsyncSession, template_id: int):
        deleted = await TimeSlotTemplateRepo.soft_delete(session, template_id)
        return deleted

