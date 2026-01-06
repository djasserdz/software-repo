from fastapi import APIRouter, Depends, Query, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from src.config.database import ConManager
from src.services.timeslot import TimeSlotService
from src.models.timeslot import TimeSlotCreate, TimeSlotUpdate
from typing import Optional
import logging


router = APIRouter()


@router.get("/", description="get all times")
async def list_all(
    zone_id: int = Query(..., description="Zone ID"),
    skip: int = Query(0, description="Number of items to skip"),
    limit: int = Query(100, description="Max number of items to return"),
    session: AsyncSession = Depends(ConManager.get_session),
):
    times = await TimeSlotService.get_all(session, zone_id, skip=skip, limit=limit)
    return {"data": times}


@router.get("/available", description="Get available time slots for a zone")
async def get_available(
    request: Request,
    session: AsyncSession = Depends(ConManager.get_session),
):
    """Get available time slots for a zone"""
    try:
        # Parse query parameters manually to avoid FastAPI validation issues
        query_params = dict(request.query_params)
        zone_id_str = query_params.get('zone_id')
        grain_type_id_str = query_params.get('grain_type_id')
        
        # Validate and convert zone_id
        if not zone_id_str:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="zone_id is required"
            )
        
        try:
            zone_id_int = int(zone_id_str)
        except (ValueError, TypeError):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"zone_id must be an integer, got: {zone_id_str}"
            )
        
        if zone_id_int <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="zone_id must be a positive integer"
            )
        
        # Convert grain_type_id to int if provided, otherwise None
        grain_type_id_int = None
        if grain_type_id_str:
            try:
                grain_type_id_int = int(grain_type_id_str)
            except (ValueError, TypeError):
                # If conversion fails, just use None (optional parameter)
                grain_type_id_int = None
        
        logging.info(f"get_available: zone_id={zone_id_int}, grain_type_id={grain_type_id_int}")
        slots = await TimeSlotService.get_available(session, zone_id_int, grain_type_id_int)
        return {"data": slots}
    except HTTPException:
        raise
    except Exception as e:
        logging.exception(f"Error in get_available endpoint: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get available time slots: {str(e)}"
        )


@router.get("/{time_id}", description="get time")
async def get_time(
    time_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    time = await TimeSlotService.get_time(session, time_id)
    return time


@router.post("/", description="create a time")
async def create(
    data: TimeSlotCreate, session: AsyncSession = Depends(ConManager.get_session)
):
    time = await TimeSlotService.create_time(session, data)
    return time


@router.patch("/{time_id}", description="update a time")
async def update(
    data: TimeSlotUpdate,
    time_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
):
    time = await TimeSlotService.updated_time(session, data, time_id)
    return time


@router.delete("/{time_id}", description="delete a time")
async def delete(time_id: int, session: AsyncSession = Depends(ConManager.get_session)):
    deleted = await TimeSlotService.delete_time(session, time_id)
    if deleted:
        return {"message": "Time slot deleted successfully"}
    else:
        return {"message": "Time slot not found or already deleted"}


@router.post("/generate", description="Generate time slots for next day")
async def generate(session: AsyncSession = Depends(ConManager.get_session)):
    """Generate time slots for the next day based on templates"""
    try:
        slots = await TimeSlotService.generate_timeslots_for_next_day(session)
        if len(slots) == 0:
            return {
                "message": "No time slots generated. Make sure you have templates for tomorrow's weekday.",
                "slots": [],
                "count": 0
            }
        return {
            "message": f"Generated {len(slots)} time slots for tomorrow",
            "slots": slots,
            "count": len(slots)
        }
    except Exception as e:
        import logging
        logging.exception(f"Error in generate endpoint: {e}")
        raise


@router.post("/generate-week", description="Generate time slots for the next week")
async def generate_week(session: AsyncSession = Depends(ConManager.get_session)):
    """Generate time slots for the next 7 days based on templates"""
    try:
        slots = await TimeSlotService.generate_timeslots_for_next_week(session)
        if len(slots) == 0:
            return {
                "message": "No time slots generated. Make sure you have templates for the upcoming weekdays.",
                "slots": [],
                "count": 0
            }
        return {
            "message": f"Generated {len(slots)} time slots for the next week",
            "slots": slots,
            "count": len(slots)
        }
    except Exception as e:
        import logging
        logging.exception(f"Error in generate-week endpoint: {e}")
        raise
