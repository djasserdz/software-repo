from fastapi import APIRouter,status
from src.models.warehouse import WarehouseCreate
from src.services.warehouse import WarehouseService


router = APIRouter()

@router.get('/',description="get all warehouses")
async def list_all():
    pass