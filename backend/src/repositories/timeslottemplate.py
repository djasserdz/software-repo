from typing import List
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from src.database.db import TimeSlotTemplate

class TimeSlotTemplateRepo:
    
    class NotFound(Exception):
        pass

    @staticmethod
    async def get_by_id(session: AsyncSession, template_id: int) -> TimeSlotTemplate:
        result = await session.execute(
            select(TimeSlotTemplate).where(TimeSlotTemplate.template_id == template_id)
        )
        template = result.scalar_one_or_none()
        if not template:
            raise TimeSlotTemplateRepo.NotFound()
        return template

    @staticmethod
    async def get_by_day(session: AsyncSession, day_of_week: int) -> List[TimeSlotTemplate]:
        result = await session.execute(
            select(TimeSlotTemplate).where(TimeSlotTemplate.day_of_week == day_of_week)
        )
        return list(result.scalars().all())

    @staticmethod
    async def create(session: AsyncSession, data: dict) -> TimeSlotTemplate:
        template = TimeSlotTemplate(**data)
        session.add(template)
        await session.commit()
        await session.refresh(template)
        return template

    @staticmethod
    async def update(session: AsyncSession, template_id: int, **kwargs) -> TimeSlotTemplate:
        stmt = (
            update(TimeSlotTemplate)
            .where(TimeSlotTemplate.template_id == template_id)
            .values(**kwargs)
            .returning(TimeSlotTemplate)
        )
        result = await session.execute(stmt)
        await session.commit()
        updated = result.scalar_one_or_none()
        if not updated:
            raise TimeSlotTemplateRepo.NotFound()
        return updated

    @staticmethod
    async def delete(session: AsyncSession, template_id: int):
        stmt = (
            update(TimeSlotTemplate)
            .where(TimeSlotTemplate.template_id == template_id)
            .values(deleted_at=datetime.utcnow())
        )
        await session.execute(stmt)
        await session.commit()
