from typing import Optional, List, Union
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.exc import IntegrityError
from fastapi import status

from src.database.db import StorageZone, ZoneStatus
from src.models.storagezone import StorageZoneCreate
from src.HTTPBaseException import HTTPBaseException


class StorageZoneRepo:
    class StorageZoneNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Storage zone not found"

    class WarehouseNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Warehouse not found"

    class CapacityError(HTTPBaseException):
        code = status.HTTP_400_BAD_REQUEST
        message = "Available capacity cannot exceed total capacity"

    class CreateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to create storage zone"

    class GetError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get storage zone"

    class GetAllError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get all storage zones"

    class UpdateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to update storage zone"

    class SoftDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to soft delete storage zone"

    class HardDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to hard delete storage zone"

    class CountError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to count storage zones"

    class ExistsError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to check storage zone existence"

    @staticmethod
    async def create(
        session: AsyncSession, zone_data: Union[StorageZoneCreate, dict]
    ) -> StorageZone:
        try:
            # Handle both dict and Pydantic model
            if isinstance(zone_data, dict):
                zone_dict = zone_data
            else:
                zone_dict = zone_data.model_dump()
            orm_zone = StorageZone(**zone_dict)
            session.add(orm_zone)
            await session.commit()
            await session.refresh(orm_zone)
            return orm_zone
        except IntegrityError:
            await session.rollback()
            raise StorageZoneRepo.CreateError()
        except Exception:
            await session.rollback()
            raise StorageZoneRepo.CreateError()

    @staticmethod
    async def get_by_id(session: AsyncSession, zone_id: int):
        try:
            stmt = select(StorageZone).where(
                StorageZone.zone_id == zone_id, StorageZone.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            zone = result.scalar_one_or_none()
            if zone is None:
                raise StorageZoneRepo.StorageZoneNotFound()
            return zone
        except StorageZoneRepo.StorageZoneNotFound:
            raise
        except Exception:
            raise StorageZoneRepo.GetError()

    @staticmethod
    async def get_all(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 100,
        warehouse_id: Optional[int] = None,
        grain_type_id: Optional[int] = None,
        status: Optional[ZoneStatus] = None,
    ) -> List[StorageZone]:
        try:
            stmt = select(StorageZone).where(StorageZone.deleted_at.is_(None))

            if warehouse_id is not None:
                stmt = stmt.where(StorageZone.warehouse_id == warehouse_id)

            if grain_type_id is not None:
                stmt = stmt.where(StorageZone.grain_type_id == grain_type_id)

            if status is not None:
                stmt = stmt.where(StorageZone.status == status)

            stmt = (
                stmt.offset(skip).limit(limit).order_by(StorageZone.created_at.desc())
            )

            result = await session.execute(stmt)
            return list(result.scalars().all())
        except Exception:
            raise StorageZoneRepo.GetAllError()

    @staticmethod
    async def update(
        session: AsyncSession, zone_id: int, **kwargs
    ) -> Optional[StorageZone]:
        try:
            kwargs["updated_at"] = datetime.utcnow()

            stmt = (
                update(StorageZone)
                .where(StorageZone.zone_id == zone_id, StorageZone.deleted_at.is_(None))
                .values(**kwargs)
                .returning(StorageZone)
            )

            result = await session.execute(stmt)
            await session.commit()

            updated = result.scalar_one_or_none()
            if updated is None:
                raise StorageZoneRepo.StorageZoneNotFound()
            return updated
        except StorageZoneRepo.StorageZoneNotFound:
            raise
        except Exception:
            await session.rollback()
            raise StorageZoneRepo.UpdateError()

    @staticmethod
    async def soft_delete(session: AsyncSession, zone_id: int) -> bool:
        try:
            stmt = (
                update(StorageZone)
                .where(StorageZone.zone_id == zone_id, StorageZone.deleted_at.is_(None))
                .values(deleted_at=datetime.utcnow())
            )

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise StorageZoneRepo.SoftDeleteError()

    @staticmethod
    async def hard_delete(session: AsyncSession, zone_id: int) -> bool:
        try:
            stmt = delete(StorageZone).where(StorageZone.zone_id == zone_id)

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise StorageZoneRepo.HardDeleteError()

    @staticmethod
    async def count(
        session: AsyncSession,
        warehouse_id: Optional[int] = None,
        grain_type_id: Optional[int] = None,
        status: Optional[ZoneStatus] = None,
    ) -> int:
        try:
            stmt = select(func.count(StorageZone.zone_id)).where(
                StorageZone.deleted_at.is_(None)
            )

            if warehouse_id:
                stmt = stmt.where(StorageZone.warehouse_id == warehouse_id)

            if grain_type_id:
                stmt = stmt.where(StorageZone.grain_type_id == grain_type_id)

            if status:
                stmt = stmt.where(StorageZone.status == status)

            result = await session.execute(stmt)
            return result.scalar_one()
        except Exception:
            raise StorageZoneRepo.CountError()

    @staticmethod
    async def exists(session: AsyncSession, zone_id: int) -> bool:
        try:
            stmt = select(StorageZone.zone_id).where(
                StorageZone.zone_id == zone_id, StorageZone.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            return result.scalar_one_or_none() is not None
        except Exception:
            raise StorageZoneRepo.ExistsError()
