from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from src.config.database import ConManager
from src.services.timeslottemplate import TimeSlotTemplateService
from src.models.timeslottemplate import TimeSlotTemplateCreate, TimeSlotTemplateUpdate, TimeSlotTemplateResponse
from typing import Optional, List

router = APIRouter()


@router.get("/", description="List all time slot templates", response_model=List[TimeSlotTemplateResponse])
async def get_all(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, le=1000),
    zone_id: Optional[int] = Query(None, description="Filter by zone ID"),
    day_of_week: Optional[int] = Query(None, ge=0, le=6, description="Filter by day of week (0=Monday, 6=Sunday)"),
    session: AsyncSession = Depends(ConManager.get_session),
):
    templates = await TimeSlotTemplateService.get_all(
        session=session,
        skip=skip,
        limit=limit,
        zone_id=zone_id,
        day_of_week=day_of_week,
    )
    return templates


@router.get("/{template_id}", description="Get a time slot template")
async def get_template(
    template_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    template = await TimeSlotTemplateService.get_template(session, template_id)
    return template


@router.get("/zone/{zone_id}", description="Get time slot templates by zone")
async def get_by_zone(
    zone_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    templates = await TimeSlotTemplateService.get_by_zone(session, zone_id)
    return templates


@router.post("/", description="Create a time slot template")
async def create_template(
    data: TimeSlotTemplateCreate, session: AsyncSession = Depends(ConManager.get_session)
):
    template = await TimeSlotTemplateService.create_template(session, data)
    return template


@router.patch("/{template_id}", description="Update a time slot template")
async def update_template(
    template_id: int,
    data: TimeSlotTemplateUpdate,
    session: AsyncSession = Depends(ConManager.get_session),
):
    template = await TimeSlotTemplateService.update_template(session, data, template_id)
    return template


@router.delete("/{template_id}", description="Delete a time slot template")
async def delete_template(
    template_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    deleted = await TimeSlotTemplateService.delete_template(session, template_id)
    if deleted:
        return {"message": "Time slot template deleted successfully"}
    else:
        return {"message": "Time slot template not found or already deleted"}

