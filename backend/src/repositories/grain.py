from typing import Optional, List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.exc import IntegrityError
from fastapi import status

from src.database.db import Grain
from src.models.grain import GrainCreate
from src.HTTPBaseException import HTTPBaseException


class GrainRepo:
    """Repository class for Grain operations with static methods and proper error handling"""

    class GrainNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Grain not found"

    class CreateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to create grain"

    class GetError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get grain"

    class GetAllError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get all grains"

    class UpdateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to update grain"

    class SoftDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to soft delete grain"

    class HardDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to hard delete grain"

    class CountError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to count grains"

    class ExistsError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to check grain existence"

    @staticmethod
    async def create(session: AsyncSession, grain_data: GrainCreate) -> Grain:
        """Create a new grain"""
        try:
            grain_dict = grain_data.model_dump()
            orm_grain = Grain(**grain_dict)
            session.add(orm_grain)
            await session.commit()
            await session.refresh(orm_grain)
            return orm_grain
        except IntegrityError:
            await session.rollback()
            raise GrainRepo.CreateError()
        except Exception:
            await session.rollback()
            raise GrainRepo.CreateError()

    @staticmethod
    async def get_by_id(session: AsyncSession, grain_id: int) -> Optional[Grain]:
        """Get grain by ID"""
        try:
            stmt = select(Grain).where(
                Grain.grain_id == grain_id, Grain.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            grain = result.scalar_one_or_none()
            if grain is None:
                raise GrainRepo.GrainNotFound()
            return grain
        except GrainRepo.GrainNotFound:
            raise
        except Exception:
            raise GrainRepo.GetError()

    @staticmethod
    async def get_all(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 100,
    ) -> List[Grain]:
        try:
            stmt = select(Grain).where(Grain.deleted_at.is_(None))

            stmt = stmt.offset(skip).limit(limit).order_by(Grain.created_at.desc())

            result = await session.execute(stmt)
            return list(result.scalars().all())
        except Exception:
            raise GrainRepo.GetAllError()

    @staticmethod
    async def update(session: AsyncSession, grain_id: int, **kwargs) -> Optional[Grain]:
        try:
            kwargs["updated_at"] = datetime.utcnow()

            stmt = (
                update(Grain)
                .where(Grain.grain_id == grain_id, Grain.deleted_at.is_(None))
                .values(**kwargs)
                .returning(Grain)
            )

            result = await session.execute(stmt)
            await session.commit()

            updated = result.scalar_one_or_none()
            if updated is None:
                raise GrainRepo.GrainNotFound()
            return updated
        except GrainRepo.GrainNotFound:
            raise
        except Exception:
            await session.rollback()
            raise GrainRepo.UpdateError()

    @staticmethod
    async def soft_delete(session: AsyncSession, grain_id: int) -> bool:
        try:
            stmt = (
                update(Grain)
                .where(Grain.grain_id == grain_id, Grain.deleted_at.is_(None))
                .values(deleted_at=datetime.utcnow())
            )

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise GrainRepo.SoftDeleteError()

    @staticmethod
    async def hard_delete(session: AsyncSession, grain_id: int) -> bool:
        try:
            stmt = delete(Grain).where(Grain.grain_id == grain_id)

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise GrainRepo.HardDeleteError()

    @staticmethod
    async def count(
        session: AsyncSession,
    ) -> int:
        try:
            stmt = select(func.count(Grain.grain_id)).where(Grain.deleted_at.is_(None))
            result = await session.execute(stmt)
            return result.scalar_one()
        except Exception:
            raise GrainRepo.CountError()

    @staticmethod
    async def exists(session: AsyncSession, grain_id: int) -> bool:
        try:
            stmt = select(Grain.grain_id).where(
                Grain.grain_id == grain_id, Grain.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            return result.scalar_one_or_none() is not None
        except Exception:
            raise GrainRepo.ExistsError()
