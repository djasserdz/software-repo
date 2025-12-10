from fastapi import APIRouter, status, Depends
from src.config.database import ConManager
from src.models.warehouse import WarehouseCreate, WarehouseUpdate
from src.services.warehouse import WarehouseService
from sqlalchemy.ext.asyncio import AsyncSession


router = APIRouter()


@router.get("/", description="get all warehouses")
async def list_all(session: AsyncSession = Depends(ConManager.get_session)):
    warehouses = await WarehouseService.list_all(session)
    return warehouses


@router.post("/", description="create a warehouse")
async def create(
    data: WarehouseCreate, session: AsyncSession = Depends(ConManager.get_session)
):
    warehouse = await WarehouseService.create_warehouse(data, session)
    return warehouse


@router.get("/{warehouse_id}", description="get a warehouse")
async def get_warehouse(
    warehouser_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    warehouse = await WarehouseService.get_warehouse(warehouser_id, session)
    return warehouse


@router.patch("/{warehouse_id}", description="update a warehouse")
async def update_warehouse(
    data: WarehouseUpdate,
    warehouse_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
):
    warehouse = await WarehouseService.update(data, warehouse_id, session)
    return warehouse
