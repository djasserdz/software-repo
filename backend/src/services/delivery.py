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
        session: AsyncSession, data: DeliveryCreate, current_user=None
    ):
        """Create a new delivery"""
        from src.models.user import UserRole
        from src.repositories.warehouse import WarehouseRepo
        from src.repositories.storagezone import StorageZoneRepo
        
        try:
            # Verify appointment exists
            appointment = await AppointmentRepo.get_by_id(
                session, data.appointment_id
            )
            
            # Check warehouse admin access
            if current_user and current_user.role == UserRole.WAREHOUSE_ADMIN:
                zone = await StorageZoneRepo.get_by_id(session, appointment.zone_id)
                warehouse = await WarehouseRepo.get_by_id(session, zone.warehouse_id)
                
                if warehouse.manager_id != current_user.user_id:
                    raise HTTPException(
                        status_code=403,
                        detail="You can only create deliveries for appointments in your own warehouse"
                    )
            
            delivery = await DeliveryRepo.create(session, data)
            return delivery
        except HTTPException:
            raise
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
        current_user=None,
    ):
        """Get all deliveries with optional filters"""
        from src.models.user import UserRole
        
        try:
            # If warehouse admin, we need to filter by their warehouse
            # This requires getting all appointments in their zones
            if current_user and current_user.role == UserRole.WAREHOUSE_ADMIN:
                from src.repositories.warehouse import WarehouseRepo
                from src.repositories.storagezone import StorageZoneRepo
                from src.repositories.appointment import AppointmentRepo
                
                # Get all zones for this warehouse admin
                warehouses = await WarehouseRepo.get_all(
                    session, manager_id=current_user.user_id
                )
                if not warehouses:
                    return []
                
                warehouse_id = warehouses[0].warehouse_id
                zones = await StorageZoneRepo.get_all(session, warehouse_id=warehouse_id)
                zone_ids = [z.zone_id for z in zones]
                
                if not zone_ids:
                    return []
                
                # Get all appointments in these zones
                all_deliveries = []
                for z_id in zone_ids:
                    appointments = await AppointmentRepo.get_all(session, zone_id=z_id)
                    for apt in appointments:
                        # Get deliveries for this appointment
                        deliveries = await DeliveryRepo.get_all(
                            session=session,
                            appointment_id=apt.appointment_id,
                            skip=0,
                            limit=1000,
                        )
                        all_deliveries.extend(deliveries)
                
                return all_deliveries[skip:skip+limit]
            
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
    async def get_by_id(session: AsyncSession, delivery_id: int, current_user=None):
        """Get delivery by ID"""
        from src.models.user import UserRole
        from src.repositories.warehouse import WarehouseRepo
        from src.repositories.storagezone import StorageZoneRepo
        
        try:
            delivery = await DeliveryRepo.get_by_id(session, delivery_id)
            
            # Check warehouse admin access
            if current_user and current_user.role == UserRole.WAREHOUSE_ADMIN:
                # Get appointment for this delivery
                appointment = await AppointmentRepo.get_by_id(
                    session, delivery.appointment_id
                )
                # Get zone for this appointment
                zone = await StorageZoneRepo.get_by_id(session, appointment.zone_id)
                # Get warehouse for this zone
                warehouse = await WarehouseRepo.get_by_id(session, zone.warehouse_id)
                
                if warehouse.manager_id != current_user.user_id:
                    raise HTTPException(
                        status_code=403,
                        detail="You can only view deliveries from your own warehouse"
                    )
            
            return delivery
        except HTTPException:
            raise
        except Exception as e:
            logging.exception(f"Error getting delivery: {e}")
            raise

