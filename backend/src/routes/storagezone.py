from fastapi import APIRouter, Depends, Query
from src.config.database import ConManager
from src.models.storagezone import StorageZoneCreate, StorageZoneUpdate, ZoneStatus
from src.services.storagezone import StorageService
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

router = APIRouter()


@router.get("/", description="List all zones")
async def get_all(
    session: AsyncSession = Depends(ConManager.get_session),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, le=1000),
    warehouse_id: Optional[int] = None,
    grain_type_id: Optional[int] = None,
    status: Optional[ZoneStatus] = None,
):
    zones = await StorageService.get_all(
        session=session,
        skip=skip,
        limit=limit,
        warehouse_id=warehouse_id,
        grain_type_id=grain_type_id,
        status=status,
    )
    return zones


@router.get("/{zone_id}", description="get a zone")
async def get_zone(
    zone_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    zone = await StorageService.get_zone(session, zone_id)
    return zone


@router.post("/", description="create a zone")
async def create_zone(
    data: StorageZoneCreate,
    warehouser_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
):
    zone = await StorageService.create_zone(session, data, warehouser_id)
    return zone


@router.patch("/{zone_id}", description="update a zone")
async def updated_zone(
    zone_id: int,
    data: StorageZoneUpdate,
    session: AsyncSession = Depends(ConManager.get_session),
):
    zone = await StorageService.update_zone(session, data, zone_id)
    return zone
