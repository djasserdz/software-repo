from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import datetime
from decimal import Decimal


class GrainBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    price: Decimal = Field(..., ge=0, decimal_places=2)


class GrainCreate(GrainBase):
    zone_id: int = Field(..., gt=0)
    appointment_id: int = Field(..., gt=0)
    delivery_id: int = Field(..., gt=0)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "zone_id": 1,
                "appointment_id": 1,
                "delivery_id": 1,
                "name": "Premium Wheat",
                "price": "150.50",
            }
        }
    )


class GrainUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    price: Optional[Decimal] = Field(None, ge=0, decimal_places=2)
    zone_id: Optional[int] = Field(None, gt=0)
    appointment_id: Optional[int] = Field(None, gt=0)
    delivery_id: Optional[int] = Field(None, gt=0)

    model_config = ConfigDict(
        json_schema_extra={"example": {"name": "Updated Grain Name", "price": "175.00"}}
    )


class GrainResponse(GrainBase):
    grain_id: int
    zone_id: int
    appointment_id: int
    delivery_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
