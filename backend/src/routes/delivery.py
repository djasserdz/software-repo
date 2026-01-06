from fastapi import APIRouter, Depends, Query, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from src.config.database import ConManager
from src.services.delivery import DeliveryService
from src.models.delivery import DeliveryCreate
from src.models.user import UserRole
from src.config.security import get_current_user
from src.database.db import User
from typing import Optional
import logging


router = APIRouter()


@router.get("/", description="Get all deliveries")
async def get_all(
    appointment_id: Optional[int] = Query(None, description="Appointment ID to filter"),
    skip: int = Query(0, description="Number of items to skip"),
    limit: int = Query(100, description="Max number of items to return"),
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Get all deliveries with optional filters"""
    deliveries = await DeliveryService.get_all(
        session=session,
        appointment_id=appointment_id,
        skip=skip,
        limit=limit,
        current_user=current_user,
    )
    return deliveries


@router.get("/my-deliveries", description="Get my deliveries (for farmers)")
async def get_my_deliveries(
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Get deliveries for the current farmer"""
    try:
        deliveries = await DeliveryService.get_my_deliveries(
            session=session, farmer_id=current_user.user_id
        )
        return {"deliveries": deliveries}
    except HTTPException:
        raise
    except Exception as e:
        logging.exception(f"Error in get_my_deliveries route: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to get deliveries: {str(e)}"
        )


@router.get("/{delivery_id}", description="Get a single delivery")
async def get_delivery(
    delivery_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Get delivery by ID"""
    delivery = await DeliveryService.get_by_id(session, delivery_id, current_user)
    return delivery


@router.post("/", description="Create a delivery")
async def create(
    data: DeliveryCreate,
    session: AsyncSession = Depends(ConManager.get_session),
    current_user: User = Depends(get_current_user),
):
    """Create a new delivery"""
    delivery = await DeliveryService.create_delivery(session, data, current_user)
    return delivery

