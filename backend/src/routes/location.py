from fastapi import APIRouter, HTTPException
from src.services.location import LocationAPI   

router = APIRouter()

@router.get("/location/name/{location_name}")
async def get_location_by_name(location_name: str):
    location_data = LocationAPI.fetch_by_location_name(location_name)
    if not location_data:
        raise HTTPException(status_code=404, detail="Location not found")
    return location_data
@router.get("/location/coordinates/")
async def get_location_by_coordinates(latitude: float, longitude: float):
    location_data = LocationAPI.fetch_by_coordinates(latitude, longitude)
    if not location_data:
        raise HTTPException(status_code=404, detail="Location not found")
    return location_data
