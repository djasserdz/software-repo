from fastapi import APIRouter, status, Depends, HTTPException
from src.config.database import ConManager
from src.config.security import get_current_user
from src.models.warehouse import WarehouseCreate, WarehouseUpdate
from src.models.user import UserRole
from src.services.warehouse import WarehouseService
from src.repositories.user import User
from sqlalchemy.ext.asyncio import AsyncSession


router = APIRouter()


@router.get("/", description="get all warehouses")
async def list_all(
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    warehouses = await WarehouseService.list_all(session, current_user)
    return warehouses


@router.post("/", description="create a warehouse")
async def create(
    data: WarehouseCreate,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admin can create warehouses",
        )
    warehouse = await WarehouseService.create_warehouse(data, session)
    return warehouse


@router.get("/{warehouse_id}", description="get a warehouse")
async def get_warehouse(
    warehouse_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    warehouse = await WarehouseService.get_warehouse(
        warehouse_id, session, current_user
    )
    return warehouse


@router.patch("/{warehouse_id}", description="update a warehouse")
async def update_warehouse(
    data: WarehouseUpdate,
    warehouse_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admin can update warehouses",
        )
    warehouse = await WarehouseService.update(data, warehouse_id, session)
    return warehouse
