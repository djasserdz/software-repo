from fastapi import APIRouter, Depends, Query, HTTPException, status
from src.config.database import ConManager
from src.config.security import get_current_user
from src.models.storagezone import StorageZoneCreate, StorageZoneUpdate, ZoneStatus
from src.models.user import UserRole
from src.services.storagezone import StorageService
from src.repositories.warehouse import WarehouseRepo
from src.repositories.user import User
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

router = APIRouter()


async def check_warehouse_access(
    warehouse_id: Optional[int],
    session: AsyncSession,
    current_user: User,
) -> None:
    """Check if user has access to the warehouse"""
    if warehouse_id and current_user.role == UserRole.WAREHOUSE_ADMIN:
        warehouse = await WarehouseRepo.get_by_id(session, warehouse_id)
        if warehouse.manager_id != current_user.user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only access your own warehouse",
            )


@router.get("/", description="List all zones")
async def get_all(
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, le=1000),
    warehouse_id: Optional[int] = None,
    grain_type_id: Optional[int] = None,
    status: Optional[ZoneStatus] = None,
):
    # Check warehouse access for warehouse admins
    if current_user.role == UserRole.WAREHOUSE_ADMIN:
        if warehouse_id:
            await check_warehouse_access(warehouse_id, session, current_user)
        else:
            # Warehouse admins can only see zones from their warehouse
            warehouse_id = current_user.user_id
            # Get the warehouse for this admin
            warehouses = await WarehouseRepo.get_all(
                session, manager_id=current_user.user_id
            )
            if warehouses:
                warehouse_id = warehouses[0].warehouse_id
            else:
                return []

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
    zone_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    zone = await StorageService.get_zone(session, zone_id)

    # Check if warehouse admin is accessing their zone
    if current_user.role == UserRole.WAREHOUSE_ADMIN:
        warehouse = await WarehouseRepo.get_by_id(session, zone.warehouse_id)
        if warehouse.manager_id != current_user.user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only access zones in your own warehouse",
            )

    return zone


@router.post("/", description="create a zone")
async def create_zone(
    data: StorageZoneCreate,
    warehouse_id: int = Query(..., description="Warehouse ID"),
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    # Check warehouse access for warehouse admins
    if current_user.role == UserRole.WAREHOUSE_ADMIN:
        await check_warehouse_access(warehouse_id, session, current_user)

    zone = await StorageService.create_zone(session, data, warehouse_id)
    return zone


@router.patch("/{zone_id}", description="update a zone")
async def updated_zone(
    zone_id: int,
    data: StorageZoneUpdate,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    zone = await StorageService.get_zone(session, zone_id)

    # Check if warehouse admin is updating their zone
    if current_user.role == UserRole.WAREHOUSE_ADMIN:
        warehouse = await WarehouseRepo.get_by_id(session, zone.warehouse_id)
        if warehouse.manager_id != current_user.user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only update zones in your own warehouse",
            )

    zone = await StorageService.update_zone(session, data, zone_id)
    return zone
