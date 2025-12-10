from fastapi import Depends, APIRouter, Query, status
from src.config.database import ConManager
from sqlalchemy.ext.asyncio import AsyncSession
from src.services.appointment import AppointementService
from src.models.appointment import AppointmentCreate
from typing import Optional


router = APIRouter()


@router.get("/", description="Get all appointments")
async def get_all(
    zone_id: Optional[int] = Query(None, description="Zone ID to filter"),
    farmer_id: Optional[int] = Query(None, description="Farmer ID to filter"),
    skip: int = Query(0, description="Number of items to skip"),
    limit: int = Query(100, description="Max number of items to return"),
    
    session: AsyncSession = Depends(ConManager.get_session),
):
    appointments = await AppointementService.get_appointments(
        session, zone_id=zone_id, farmer_id=farmer_id
    )
    return appointments


@router.get("/{appointment_id}", description="get a single appointment")
async def get_appointment(
    appointment_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    appointment = await AppointementService.get_appointment(session, appointment_id)
    return appointment


@router.post("/", description="create an appointment")
async def create(
    data: AppointmentCreate, session: AsyncSession = Depends(ConManager.get_session)
):
    appointment = await AppointementService.create_appointment(data, session)
    return appointment
