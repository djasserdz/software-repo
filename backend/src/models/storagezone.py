from pydantic import BaseModel, Field, ConfigDict, model_validator
from typing import Optional
from datetime import datetime
from src.database.db import ZoneStatus


class StorageZoneBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    grain_type_id: int = Field(..., gt=0)
    total_capacity: int = Field(..., gt=0, description="Total capacity in kg (kilograms)")
    available_capacity: int = Field(..., ge=0, description="Available capacity in kg (kilograms)")
    status: ZoneStatus

    @model_validator(mode="after")
    def validate_capacity(self):
        if self.available_capacity > self.total_capacity:
            raise ValueError("available_capacity cannot exceed total_capacity")
        return self


class StorageZoneCreate(StorageZoneBase):
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "name": "Zone A - Wheat Storage",
                "grain_type_id": 1,
                "total_capacity": 10000,  # in kg
                "available_capacity": 5000,  # in kg
                "status": "active",
            }
        }
    )


class StorageZoneUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    grain_type_id: Optional[int] = Field(None, gt=0)
    total_capacity: Optional[int] = Field(None, gt=0, description="Total capacity in kg (kilograms)")
    available_capacity: Optional[int] = Field(None, ge=0, description="Available capacity in kg (kilograms)")
    status: Optional[ZoneStatus] = None
    warehouse_id: Optional[int] = Field(None, gt=0)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "name": "Updated Zone Name",
                "available_capacity": 3000,  # in kg
                "status": "not_active",
            }
        }
    )


class StorageZoneResponse(StorageZoneBase):
    zone_id: int
    warehouse_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
