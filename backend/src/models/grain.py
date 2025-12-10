from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import datetime
from decimal import Decimal


class GrainBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    price: Decimal = Field(..., ge=0, decimal_places=2)


class GrainCreate(GrainBase):
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "name": "Premium Wheat",
                "price": "150.50",
            }
        }
    )


class GrainUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    price: Optional[Decimal] = Field(None, ge=0, decimal_places=2)

    model_config = ConfigDict(
        json_schema_extra={"example": {"name": "Updated Grain Name", "price": "175.00"}}
    )


class GrainResponse(GrainBase):
    grain_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
