from fastapi import HTTPException,status
from sqlalchemy.ext.asyncio import AsyncSession
from src.models.warehouse import WarehouseCreate,WarehouseUpdate
from src.repositories.warehouse import WarehouseRepo
from src.repositories.user import UserRepo
from src.models.user import UserRole
from typing import Optional
import logging



class WarehouseService:
    @staticmethod
    async def create_warehouse(warehouse_data : WarehouseCreate,session : AsyncSession):
        try:
            user = await UserRepo.get_by_id(session,warehouse_data.manager_id)
            if user.role != UserRole.WAREHOUSE_ADMIN:
                raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail="User Manager is Required")
            warehouse = await WarehouseRepo.create(session,warehouse_data)
            return warehouse
            
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error happend : {e}")


    @staticmethod
    async def get_warehouse(warehouse_id : int , session : AsyncSession):
        warehouse = await WarehouseRepo.get_by_id(session,warehouse_id)
        return warehouse
    @staticmethod
    async def list_all(session : AsyncSession, manager_id : Optional[int]):
        warehouses= await WarehouseRepo.get_all(session)
        return warehouses