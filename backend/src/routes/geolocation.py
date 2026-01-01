from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.config.database import ConManager
from src.services.geolocation import GeolocationService
from src.config.security import get_current_user
from src.database.db import User
from src.models.geolocation import LocationUpdate
from typing import Optional

router = APIRouter()


@router.get("/nearest", description="Get nearest warehouses with zones for grain type")
async def get_nearest_warehouses(
    lat: float = Query(..., description="Latitude"),
    lng: float = Query(..., description="Longitude"),
    grainType: Optional[int] = Query(None, description="Grain type ID"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of results"),
    session: AsyncSession = Depends(ConManager.get_session),
):
    """Get nearest warehouses that have zones for the specified grain type"""
    try:
        warehouses = await GeolocationService.get_nearest_warehouses(
            session=session,
            latitude=lat,
            longitude=lng,
            grain_type_id=grainType,
            limit=limit,
        )
        return {"data": {"allWarehouses": warehouses}}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get nearest warehouses: {str(e)}",
        )


@router.put("/warehouse/{warehouse_id}/location", description="Update warehouse location")
async def update_warehouse_location(
    warehouse_id: int,
    latitude: float = Query(..., description="Latitude"),
    longitude: float = Query(..., description="Longitude"),
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Update warehouse location coordinates"""
    try:
        await GeolocationService.update_warehouse_location(
            session=session,
            warehouse_id=warehouse_id,
            latitude=latitude,
            longitude=longitude,
        )
        return {"message": "Warehouse location updated successfully"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update warehouse location: {str(e)}",
        )


@router.post("/update-location", description="Update farmer location")
async def update_farmer_location(
    data: LocationUpdate,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Update farmer's current location - accepts POST body with latitude and longitude"""
    try:
        await GeolocationService.update_farmer_location(
            session=session,
            user_id=current_user.user_id,
            latitude=data.latitude,
            longitude=data.longitude,
        )
        return {"message": "Location updated successfully"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update location: {str(e)}",
        )

