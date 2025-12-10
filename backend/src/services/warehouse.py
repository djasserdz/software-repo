from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.models.warehouse import WarehouseCreate, WarehouseUpdate
from src.repositories.warehouse import WarehouseRepo
from src.repositories.user import UserRepo
from src.models.user import UserRole
from typing import Optional
import logging


class WarehouseService:
    @staticmethod
    async def create_warehouse(warehouse_data: WarehouseCreate, session: AsyncSession):
        try:
            user = await UserRepo.get_by_id(session, warehouse_data.manager_id)
            if user.role != UserRole.WAREHOUSE_ADMIN:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="User must be a warehouse admin",
                )
            warehouse = await WarehouseRepo.create(session, warehouse_data)
            return warehouse
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error happend : {e}")
            raise

    @staticmethod
    async def get_warehouse(warehouse_id: int, session: AsyncSession):
        warehouse = await WarehouseRepo.get_by_id(session, warehouse_id)
        return warehouse

    @staticmethod
    async def list_all(session: AsyncSession):
        warehouses = await WarehouseRepo.get_all(session)
        return warehouses

    @staticmethod
    async def update(data: WarehouseUpdate, warehouse_id: int, session: AsyncSession):
        try:
            user = await UserRepo.get_by_id(session, data.manager_id)
            if user.role != UserRole.WAREHOUSE_ADMIN:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="User must be a warehouse admin",
                )
            update_data = data.model_dump(exclude_unset=True)
            warehouse = await WarehouseRepo.update(session, warehouse_id, **update_data)
            return warehouse
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error updating warehouse : {e}")
            raise
