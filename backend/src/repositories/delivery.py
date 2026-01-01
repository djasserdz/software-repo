from typing import Optional, List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.exc import IntegrityError
from fastapi import status

from src.database.db import Delivery
from src.models.delivery import DeliveryCreate
from src.HTTPBaseException import HTTPBaseException


class DeliveryRepo:
    """Repository class for Delivery operations with static methods and proper error handling"""

    class DeliveryNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Delivery not found"

    class AppointmentNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "Appointment not found"

    class ReceiptCodeExists(HTTPBaseException):
        code = status.HTTP_409_CONFLICT
        message = "Receipt code already exists"

    class CreateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to create delivery"

    class GetError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get delivery"

    class GetAllError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get all deliveries"

    class UpdateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to update delivery"

    class SoftDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to soft delete delivery"

    class HardDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to hard delete delivery"

    class CountError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to count deliveries"

    class ExistsError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to check delivery existence"

    @staticmethod
    async def create(session: AsyncSession, delivery_data: DeliveryCreate) -> Delivery:
        """Create a new delivery"""
        try:
            delivery_dict = delivery_data.model_dump()
            orm_delivery = Delivery(**delivery_dict)
            session.add(orm_delivery)
            await session.commit()
            await session.refresh(orm_delivery)
            return orm_delivery
        except IntegrityError:
            await session.rollback()
            raise DeliveryRepo.ReceiptCodeExists()
        except Exception:
            await session.rollback()
            raise DeliveryRepo.CreateError()

    @staticmethod
    async def get_by_id(session: AsyncSession, delivery_id: int) -> Optional[Delivery]:
        """Get delivery by ID"""
        try:
            stmt = select(Delivery).where(
                Delivery.delivery_id == delivery_id, Delivery.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            delivery = result.scalar_one_or_none()
            if delivery is None:
                raise DeliveryRepo.DeliveryNotFound()
            return delivery
        except DeliveryRepo.DeliveryNotFound:
            raise
        except Exception:
            raise DeliveryRepo.GetError()

    @staticmethod
    async def get_by_receipt_code(
        session: AsyncSession, receipt_code: str
    ) -> Optional[Delivery]:
        """Get delivery by receipt code"""
        try:
            stmt = select(Delivery).where(
                Delivery.receipt_code == receipt_code, Delivery.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            delivery = result.scalar_one_or_none()
            if delivery is None:
                raise DeliveryRepo.DeliveryNotFound()
            return delivery
        except DeliveryRepo.DeliveryNotFound:
            raise
        except Exception:
            raise DeliveryRepo.GetError()

    @staticmethod
    async def get_all(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 100,
        appointment_id: Optional[int] = None,
        farmer_id: Optional[int] = None,
    ) -> List[Delivery]:
        """Get all deliveries with optional filters"""
        try:
            from src.database.db import Appointment
            
            stmt = select(Delivery).where(Delivery.deleted_at.is_(None))

            if appointment_id:
                stmt = stmt.where(Delivery.appointment_id == appointment_id)
            
            if farmer_id:
                # Join with appointments to filter by farmer_id
                stmt = stmt.join(Appointment, Delivery.appointment_id == Appointment.appointment_id)
                stmt = stmt.where(Appointment.farmer_id == farmer_id)
                stmt = stmt.where(Appointment.deleted_at.is_(None))

            stmt = stmt.offset(skip).limit(limit).order_by(Delivery.created_at.desc())

            result = await session.execute(stmt)
            return list(result.scalars().all())
        except Exception:
            raise DeliveryRepo.GetAllError()

    @staticmethod
    async def update(
        session: AsyncSession, delivery_id: int, **kwargs
    ) -> Optional[Delivery]:
        """Update delivery by ID"""
        try:
            kwargs["updated_at"] = datetime.utcnow()

            stmt = (
                update(Delivery)
                .where(
                    Delivery.delivery_id == delivery_id, Delivery.deleted_at.is_(None)
                )
                .values(**kwargs)
                .returning(Delivery)
            )

            result = await session.execute(stmt)
            await session.commit()

            updated = result.scalar_one_or_none()
            if updated is None:
                raise DeliveryRepo.DeliveryNotFound()
            return updated
        except IntegrityError:
            await session.rollback()
            raise DeliveryRepo.ReceiptCodeExists()
        except DeliveryRepo.DeliveryNotFound:
            raise
        except Exception:
            await session.rollback()
            raise DeliveryRepo.UpdateError()

    @staticmethod
    async def soft_delete(session: AsyncSession, delivery_id: int) -> bool:
        """Soft delete delivery by setting deleted_at timestamp"""
        try:
            stmt = (
                update(Delivery)
                .where(
                    Delivery.delivery_id == delivery_id, Delivery.deleted_at.is_(None)
                )
                .values(deleted_at=datetime.utcnow())
            )

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise DeliveryRepo.SoftDeleteError()

    @staticmethod
    async def hard_delete(session: AsyncSession, delivery_id: int) -> bool:
        """Hard delete delivery from database"""
        try:
            stmt = delete(Delivery).where(Delivery.delivery_id == delivery_id)

            result = await session.execute(stmt)
            await session.commit()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise DeliveryRepo.HardDeleteError()

    @staticmethod
    async def count(session: AsyncSession, appointment_id: Optional[int] = None) -> int:
        """Count deliveries with optional filters"""
        try:
            stmt = select(func.count(Delivery.delivery_id)).where(
                Delivery.deleted_at.is_(None)
            )

            if appointment_id:
                stmt = stmt.where(Delivery.appointment_id == appointment_id)

            result = await session.execute(stmt)
            return result.scalar_one()
        except Exception:
            raise DeliveryRepo.CountError()

    @staticmethod
    async def exists(session: AsyncSession, delivery_id: int) -> bool:
        """Check if delivery exists"""
        try:
            stmt = select(Delivery.delivery_id).where(
                Delivery.delivery_id == delivery_id, Delivery.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            return result.scalar_one_or_none() is not None
        except Exception:
            raise DeliveryRepo.ExistsError()
