from sqlalchemy.ext.asyncio import AsyncSession
from src.repositories.delivery import DeliveryRepo
from src.repositories.appointment import AppointmentRepo
from src.repositories.grain import GrainRepo
from src.models.delivery import DeliveryCreate
from src.HTTPBaseException import HTTPBaseException
from fastapi import HTTPException
from typing import Optional, List
import logging


class DeliveryService:
    @staticmethod
    async def create_delivery(
        session: AsyncSession, data: DeliveryCreate
    ):
        """Create a new delivery"""
        try:
            # Verify appointment exists
            appointment = await AppointmentRepo.get_by_id(
                session, data.appointment_id
            )
            delivery = await DeliveryRepo.create(session, data)
            return delivery
        except Exception as e:
            await session.rollback()
            logging.exception(f"Error creating delivery: {e}")
            raise

    @staticmethod
    async def get_all(
        session: AsyncSession,
        appointment_id: Optional[int] = None,
        farmer_id: Optional[int] = None,
        skip: int = 0,
        limit: int = 100,
    ):
        """Get all deliveries with optional filters"""
        try:
            deliveries = await DeliveryRepo.get_all(
                session=session,
                appointment_id=appointment_id,
                farmer_id=farmer_id,
                skip=skip,
                limit=limit,
            )
            return deliveries
        except Exception as e:
            logging.exception(f"Error getting deliveries: {e}")
            raise

    @staticmethod
    async def get_my_deliveries(
        session: AsyncSession, farmer_id: int
    ):
        """Get deliveries for a specific farmer with related data formatted for frontend"""
        try:
            deliveries = await DeliveryRepo.get_all(
                session=session, farmer_id=farmer_id
            )

            # Format deliveries with related data
            formatted_deliveries = []
            for delivery in deliveries:
                # Get appointment and related data with error handling
                try:
                    appointment = await AppointmentRepo.get_by_id(
                        session, delivery.appointment_id
                    )
                    if not appointment:
                        logging.warning(f"Appointment {delivery.appointment_id} not found for delivery {delivery.delivery_id}")
                        continue
                except (HTTPBaseException, HTTPException, Exception) as e:
                    logging.warning(f"Error getting appointment {delivery.appointment_id} for delivery {delivery.delivery_id}: {e}")
                    continue

                grain = None
                try:
                    grain = await GrainRepo.get_by_id(
                        session, appointment.grain_type_id
                    )
                except (HTTPBaseException, HTTPException, Exception) as e:
                    logging.warning(f"Grain {appointment.grain_type_id} not found for appointment {appointment.appointment_id}: {e}")
                    grain = None

                formatted_deliveries.append(
                    {
                        "id": delivery.delivery_id,
                        "delivery_id": delivery.delivery_id,
                        "appointment_id": delivery.appointment_id,
                        "receipt_code": delivery.receipt_code if hasattr(delivery, 'receipt_code') else "",
                        "total_price": str(delivery.total_price) if hasattr(delivery, 'total_price') and delivery.total_price else "0.00",
                        "grainType": grain.name if grain and hasattr(grain, 'name') else f"Grain {appointment.grain_type_id if appointment else 'Unknown'}",
                        "quantity": float(appointment.requested_quantity) if appointment and hasattr(appointment, 'requested_quantity') and appointment.requested_quantity else 0.0,
                        "deliveryDate": delivery.created_at.isoformat()
                        if delivery and hasattr(delivery, 'created_at') and delivery.created_at
                        else None,
                        "created_at": delivery.created_at.isoformat()
                        if delivery and hasattr(delivery, 'created_at') and delivery.created_at
                        else None,
                    }
                )

            return formatted_deliveries
        except HTTPException:
            raise
        except Exception as e:
            logging.exception(f"Error getting farmer deliveries: {e}")
            raise HTTPException(
                status_code=500, detail=f"Failed to get farmer deliveries: {str(e)}"
            )

    @staticmethod
    async def get_by_id(session: AsyncSession, delivery_id: int):
        """Get delivery by ID"""
        try:
            delivery = await DeliveryRepo.get_by_id(session, delivery_id)
            return delivery
        except Exception as e:
            logging.exception(f"Error getting delivery: {e}")
            raise

