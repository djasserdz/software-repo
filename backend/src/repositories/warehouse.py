from typing import Optional, List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.exc import IntegrityError
from fastapi import status

from src.database.db import Warehouse, ZoneStatus
from src.models.warehouse import WarehouseCreate
from src.HTTPBaseException import HTTPBaseException


class WarehouseRepo:
    """Repository class for Warehouse operations with static methods and proper error handling"""

    class WarehouseNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Warehouse not found"

    class ManagerNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Manager not found"

    class CreateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to create warehouse"

    class GetError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get warehouse"

    class GetAllError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get all warehouses"

    class UpdateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to update warehouse"

    class SoftDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to soft delete warehouse"

    class HardDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to hard delete warehouse"

    class CountError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to count warehouses"

    class ExistsError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to check warehouse existence"

    @staticmethod
    async def create(
        session: AsyncSession, warehouse_data: WarehouseCreate
    ) -> Warehouse:
        """Create a new warehouse"""
        try:
            warehouse_dict = warehouse_data.model_dump()
            orm_warehouse = Warehouse(**warehouse_dict)
            session.add(orm_warehouse)
            await session.commit()
            await session.refresh(orm_warehouse)
            return orm_warehouse
        except IntegrityError:
            await session.rollback()
            raise WarehouseRepo.CreateError()
        except Exception:
            await session.rollback()
            raise WarehouseRepo.CreateError()

    @staticmethod
    async def get_by_id(
        session: AsyncSession, warehouse_id: int
    ) -> Optional[Warehouse]:
        """Get warehouse by ID"""
        try:
            stmt = select(Warehouse).where(
                Warehouse.warehouse_id == warehouse_id, Warehouse.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            warehouse = result.scalar_one_or_none()
            if warehouse is None:
                raise WarehouseRepo.WarehouseNotFound()
            return warehouse
        except WarehouseRepo.WarehouseNotFound:
            raise
        except Exception:
            raise WarehouseRepo.GetError()

    @staticmethod
    async def get_all(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 100,
        manager_id: Optional[int] = None,
        status: Optional[ZoneStatus] = None,
    ) -> List[Warehouse]:
        """Get all warehouses with optional filters"""
        try:
            stmt = select(Warehouse).where(Warehouse.deleted_at.is_(None))

            if manager_id:
                stmt = stmt.where(Warehouse.manager_id == manager_id)

            if status:
                stmt = stmt.where(Warehouse.status == status)

            stmt = stmt.offset(skip).limit(limit).order_by(Warehouse.created_at.desc())

            result = await session.execute(stmt)
            return list(result.scalars().all())
        except Exception:
            raise WarehouseRepo.GetAllError()

    @staticmethod
    async def update(
        session: AsyncSession, warehouse_id: int, **kwargs
    ) -> Optional[Warehouse]:
        """Update warehouse by ID"""
        try:
            kwargs["updated_at"] = datetime.utcnow()

            stmt = (
                update(Warehouse)
                .where(
                    Warehouse.warehouse_id == warehouse_id,
                    Warehouse.deleted_at.is_(None),
                )
                .values(**kwargs)
                .returning(Warehouse)
            )

            result = await session.execute(stmt)
            await session.commit()

            updated = result.scalar_one_or_none()
            if updated is None:
                raise WarehouseRepo.WarehouseNotFound()
            return updated
        except WarehouseRepo.WarehouseNotFound:
            raise
        except Exception:
            await session.rollback()
            raise WarehouseRepo.UpdateError()

    @staticmethod
    async def soft_delete(session: AsyncSession, warehouse_id: int) -> bool:
        """Soft delete warehouse by setting deleted_at timestamp"""
        try:
            stmt = (
                update(Warehouse)
                .where(
                    Warehouse.warehouse_id == warehouse_id,
                    Warehouse.deleted_at.is_(None),
                )
                .values(deleted_at=datetime.utcnow())
            )

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise WarehouseRepo.SoftDeleteError()

    @staticmethod
    async def hard_delete(session: AsyncSession, warehouse_id: int) -> bool:
        """Hard delete warehouse from database"""
        try:
            stmt = delete(Warehouse).where(Warehouse.warehouse_id == warehouse_id)

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise WarehouseRepo.HardDeleteError()

    @staticmethod
    async def count(
        session: AsyncSession,
        manager_id: Optional[int] = None,
        status: Optional[ZoneStatus] = None,
    ) -> int:
        """Count warehouses with optional filters"""
        try:
            stmt = select(func.count(Warehouse.warehouse_id)).where(
                Warehouse.deleted_at.is_(None)
            )

            if manager_id:
                stmt = stmt.where(Warehouse.manager_id == manager_id)

            if status:
                stmt = stmt.where(Warehouse.status == status)

            result = await session.execute(stmt)
            return result.scalar_one()
        except Exception:
            raise WarehouseRepo.CountError()

    @staticmethod
    async def exists(session: AsyncSession, warehouse_id: int) -> bool:
        """Check if warehouse exists"""
        try:
            stmt = select(Warehouse.warehouse_id).where(
                Warehouse.warehouse_id == warehouse_id, Warehouse.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            return result.scalar_one_or_none() is not None
        except Exception:
            raise WarehouseRepo.ExistsError()
