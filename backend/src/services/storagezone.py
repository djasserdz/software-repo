from sqlalchemy.ext.asyncio import AsyncSession
from src.models.storagezone import StorageZoneCreate, StorageZoneUpdate, ZoneStatus
from src.repositories.storagezone import StorageZoneRepo
from src.repositories.warehouse import WarehouseRepo
from src.repositories.grain import GrainRepo
from typing import Optional
import logging


class StorageService:
    @staticmethod
    async def create_zone(
        session: AsyncSession, data: StorageZoneCreate, warehouse_id: int
    ):
        try:
            warehouse = await WarehouseRepo.get_by_id(session, warehouse_id)
            grain = await GrainRepo.get_by_id(session, data.grain_type_id)
            # Add warehouse_id to the zone data
            zone_dict = data.model_dump()
            zone_dict['warehouse_id'] = warehouse_id
            zone = await StorageZoneRepo.create(session, zone_dict)
            return zone
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error happened: {e}")
            raise

    @staticmethod
    async def get_all(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 100,
        warehouse_id: Optional[int] = None,
        grain_type_id: Optional[int] = None,
        status: Optional[ZoneStatus] = None,
    ):
        try:
            return await StorageZoneRepo.get_all(
                session=session,
                skip=skip,
                limit=limit,
                warehouse_id=warehouse_id,
                grain_type_id=grain_type_id,
                status=status,
            )
        except StorageZoneRepo.GetAllError:
            raise

    @staticmethod
    async def get_zone(session: AsyncSession, zone_id: int):
        zone = await StorageZoneRepo.get_by_id(session, zone_id)
        return zone

    @staticmethod
    async def update_zone(session: AsyncSession, data: StorageZoneUpdate, zone_id: int):
        updated_data = data.model_dump(exclude_unset=True)
        zone = await StorageZoneRepo.update(session, zone_id, **updated_data)
        return zone
