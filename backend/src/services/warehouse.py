from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.models.warehouse import WarehouseCreate, WarehouseUpdate
from src.repositories.warehouse import WarehouseRepo
from src.repositories.user import UserRepo, User
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
    async def get_warehouse(
        warehouse_id: int, session: AsyncSession, current_user: Optional[User] = None
    ):
        warehouse = await WarehouseRepo.get_by_id(session, warehouse_id)

        # Check if warehouse admin is trying to access their own warehouse
        if current_user and current_user.role == UserRole.WAREHOUSE_ADMIN:
            if warehouse.manager_id != current_user.user_id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You can only access your own warehouse",
                )

        return warehouse

    @staticmethod
    async def list_all(session: AsyncSession, current_user: Optional[User] = None):
        # If user is a warehouse admin, only return their warehouse
        if current_user and current_user.role == UserRole.WAREHOUSE_ADMIN:
            warehouses = await WarehouseRepo.get_all(session, manager_id=current_user.user_id)
            return warehouses

        # Admins and farmers can see all warehouses
        warehouses = await WarehouseRepo.get_all(session)
        return warehouses

    @staticmethod
    async def update(data: WarehouseUpdate, warehouse_id: int, session: AsyncSession):
        try:
            if data.manager_id:
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
