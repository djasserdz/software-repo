from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from src.config.database import ConManager
from src.services.timeslot import TimeSlotService
from src.models.timeslot import TimeSlotCreate, TimeSlotUpdate
from typing import Optional


router = APIRouter()


@router.get("/", description="get all times")
async def list_all(
    zone_id: int,
    skip: int = Query(0, description="Number of items to skip"),
    limit: int = Query(100, description="Max number of items to return"),
    session: AsyncSession = Depends(ConManager.get_session),
):
    times = await TimeSlotService.get_all(session, zone_id, skip=skip, limit=limit)
    return times


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
    time = await TimeSlotService.delete_time(session, time_id)
    if time:
        return "Time deleted"


@router.get("/available", description="Get available time slots for a zone")
async def get_available(
    zone_id: int = Query(..., description="Zone ID"),
    grain_type_id: Optional[int] = Query(None, description="Grain type ID (optional)"),
    session: AsyncSession = Depends(ConManager.get_session),
):
    """Get available time slots for a zone"""
    slots = await TimeSlotService.get_available(session, zone_id, grain_type_id)
    return {"data": slots}


@router.post("/generate", description="Generate time slots for next day")
async def generate(session: AsyncSession = Depends(ConManager.get_session)):
    """Generate time slots for the next day based on templates"""
    slots = await TimeSlotService.generate_timeslots_for_next_day(session)
    return {"message": f"Generated {len(slots)} time slots for tomorrow", "slots": slots}


@router.post("/generate-week", description="Generate time slots for the next week")
async def generate_week(session: AsyncSession = Depends(ConManager.get_session)):
    """Generate time slots for the next 7 days based on templates"""
    slots = await TimeSlotService.generate_timeslots_for_next_week(session)
    return {"message": f"Generated {len(slots)} time slots for the next week", "slots": slots}
