from fastapi import Depends, APIRouter, Query, status, HTTPException, Body
from src.config.database import ConManager
from sqlalchemy.ext.asyncio import AsyncSession
from src.services.appointment import AppointementService
from src.models.appointment import AppointmentCreate, AppointmentCreateFromFrontend
from src.models.user import UserRole
from src.config.security import get_current_user
from src.database.db import AppointmentStatus, User
from src.repositories.warehouse import WarehouseRepo
from typing import Optional
import logging


router = APIRouter()


@router.get("/", description="Get all appointments")
async def get_all(
    zone_id: Optional[int] = Query(None, description="Zone ID to filter"),
    farmer_id: Optional[int] = Query(None, description="Farmer ID to filter"),
    status: Optional[str] = Query(None, description="Status to filter"),
    skip: int = Query(0, description="Number of items to skip"),
    limit: int = Query(100, description="Max number of items to return"),
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    from src.database.db import AppointmentStatus
    
    status_enum = None
    if status:
        try:
            status_enum = AppointmentStatus(status.lower())
        except ValueError:
            pass
    
    appointments = await AppointementService.get_appointments(
        session, zone_id=zone_id, farmer_id=farmer_id, status=status_enum, current_user=current_user
    )
    return appointments


@router.get("/my-appointments", description="Get my appointments (for farmers)")
async def get_my_appointments(
    status: Optional[str] = Query(None, description="Status to filter"),
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    
    try:
        status_enum = None
        if status:
            try:
                status_enum = AppointmentStatus(status.lower())
            except ValueError:
                pass
        
        appointments = await AppointementService.get_my_appointments(
            session=session, farmer_id=current_user.user_id, status=status_enum
        )
        return {"appointments": appointments}
    except HTTPException:
        raise
    except Exception as e:
        logging.exception(f"Error in get_my_appointments route: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to get appointments: {str(e)}"
        )


@router.get("/{appointment_id}", description="get a single appointment")
async def get_appointment(
    appointment_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    appointment = await AppointementService.get_appointment(
        session, appointment_id, current_user
    )
    return appointment


@router.post("/", description="create an appointment")
async def create(
    data: AppointmentCreateFromFrontend,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Create appointment - frontend format"""
    appointment = await AppointementService.create_appointment_from_frontend(
        data, session, current_user.user_id
    )
    return appointment


@router.put("/{appointment_id}/cancel", description="Cancel an appointment")
async def cancel_appointment(
    appointment_id: int,
    data: dict = Body(None),
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Cancel an appointment"""
    from src.database.db import AppointmentStatus
    
    try:
        appointment = await AppointementService.get_appointment(
            session, appointment_id, current_user
        )
        if not appointment:
            raise HTTPException(status_code=404, detail="Appointment not found")
        
        # Only the farmer who owns the appointment can cancel it
        if appointment.farmer_id != current_user.user_id:
            raise HTTPException(status_code=403, detail="You can only cancel your own appointments")
        
        # Update appointment status to cancelled
        updated = await AppointementService.update_appointment(
            session, appointment_id, status=AppointmentStatus.CANCELLED
        )
        return {"message": "Appointment cancelled successfully", "appointment": updated}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to cancel appointment: {str(e)}")


@router.put("/{appointment_id}/accept", description="Accept an appointment")
async def accept_appointment(
    appointment_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Accept a pending appointment (warehouse admin only)"""
    from src.database.db import AppointmentStatus
    
    try:
        appointment = await AppointementService.get_appointment(
            session, appointment_id, current_user
        )
        if not appointment:
            raise HTTPException(status_code=404, detail="Appointment not found")
        
        # Only warehouse admins can accept appointments
        if current_user.role.value != "warehouse_admin":
            raise HTTPException(status_code=403, detail="Only warehouse admins can accept appointments")
        
        if appointment.status != AppointmentStatus.PENDING:
            raise HTTPException(status_code=400, detail="Only pending appointments can be accepted")
        
        # Update appointment status to accepted
        updated = await AppointementService.update_appointment(
            session, appointment_id, status=AppointmentStatus.ACCEPTED
        )
        return {"message": "Appointment accepted successfully", "appointment": updated}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to accept appointment: {str(e)}")


@router.put("/{appointment_id}/refuse", description="Refuse an appointment")
async def refuse_appointment(
    appointment_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Refuse a pending appointment (warehouse admin only)"""
    from src.database.db import AppointmentStatus
    
    try:
        appointment = await AppointementService.get_appointment(
            session, appointment_id, current_user
        )
        if not appointment:
            raise HTTPException(status_code=404, detail="Appointment not found")
        
        # Only warehouse admins can refuse appointments
        if current_user.role.value != "warehouse_admin":
            raise HTTPException(status_code=403, detail="Only warehouse admins can refuse appointments")
        
        if appointment.status != AppointmentStatus.PENDING:
            raise HTTPException(status_code=400, detail="Only pending appointments can be refused")
        
        # Update appointment status to refused
        updated = await AppointementService.update_appointment(
            session, appointment_id, status=AppointmentStatus.REFUSED
        )
        return {"message": "Appointment refused successfully", "appointment": updated}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to refuse appointment: {str(e)}")


@router.put("/{appointment_id}/confirm-attendance", description="Confirm appointment attendance")
async def confirm_attendance(
    appointment_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Confirm that a farmer attended their appointment"""
    from src.database.db import AppointmentStatus
    
    try:
        appointment = await AppointementService.get_appointment(
            session, appointment_id, current_user
        )
        if not appointment:
            raise HTTPException(status_code=404, detail="Appointment not found")
        
        # Only warehouse admins can confirm attendance
        if current_user.role.value != "warehouse_admin":
            raise HTTPException(status_code=403, detail="Only warehouse admins can confirm attendance")
        
        # Update appointment status to completed
        updated = await AppointementService.update_appointment(
            session, appointment_id, status=AppointmentStatus.COMPLETED
        )
        await session.commit()
        await session.refresh(updated)
        return {"message": "Attendance confirmed successfully", "appointment": updated}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to confirm attendance: {str(e)}")


@router.get("/history", description="Get appointment history")
async def get_history(
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Get appointment history for the current user"""
    from src.database.db import AppointmentStatus
    
    # Get completed and cancelled appointments
    completed = await AppointementService.get_my_appointments(
        session=session, farmer_id=current_user.user_id, status=AppointmentStatus.COMPLETED
    )
    cancelled = await AppointementService.get_my_appointments(
        session=session, farmer_id=current_user.user_id, status=AppointmentStatus.CANCELLED
    )
    
    history = completed + cancelled
    return {"appointments": history}
