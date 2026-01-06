from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from src.config.database import ConManager

router = APIRouter()

@router.get("/statistics", description="Get system statistics")
async def get_statistics(session: AsyncSession = Depends(ConManager.get_session)):
    # Mock data for now; replace with actual database queries
    return {
        "data": {
            "total_users": 42,
            "total_warehouses": 5,
            "total_appointments": 120,
            "total_deliveries": 75
        }
    }