from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import datetime


class DeliveryBase(BaseModel):
    receipt_code: str = Field(..., min_length=1, max_length=100)
    total_price: str = Field(..., min_length=1, description="Total price in DZD (Algerian Dinar)")


class DeliveryCreate(DeliveryBase):
    appointment_id: int = Field(..., gt=0)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "appointment_id": 1,
                "receipt_code": "REC-2024-001",
                "total_price": "75000.00",  # in DZD
            }
        }
    )


class DeliveryUpdate(BaseModel):
    appointment_id: Optional[int] = Field(None, gt=0)
    receipt_code: Optional[str] = Field(None, min_length=1, max_length=100)
    total_price: Optional[str] = Field(None, min_length=1, description="Total price in DZD (Algerian Dinar)")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "receipt_code": "REC-2024-001-UPDATED",
                "total_price": "80000.00",  # in DZD
            }
        }
    )


class DeliveryResponse(DeliveryBase):
    delivery_id: int
    appointment_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
