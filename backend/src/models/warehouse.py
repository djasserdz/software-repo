from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import datetime
from ..database.db import ZoneStatus


class WarehouseBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    location: str = Field(..., min_length=1, max_length=500)
    x_float: float = Field(..., ge=-180.0, le=180.0)
    y_float: float = Field(..., ge=-90.0, le=90.0)
    status: ZoneStatus


class WarehouseCreate(WarehouseBase):
    manager_id: int = Field(..., gt=0)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "manager_id": 1,
                "name": "Main Warehouse",
                "location": "123 Storage St, City",
                "x_float": 40.7128,
                "y_float": -74.0060,
                "status": "active",
            }
        }
    )


class WarehouseUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    location: Optional[str] = Field(None, min_length=1, max_length=500)
    x_float: Optional[float] = Field(None, ge=-180.0, le=180.0)
    y_float: Optional[float] = Field(None, ge=-90.0, le=90.0)
    status: Optional[ZoneStatus] = None
    manager_id: Optional[int] = Field(None, gt=0)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {"name": "Updated Warehouse Name", "status": "not_active"}
        }
    )


class WarehouseResponse(WarehouseBase):
    warehouse_id: int
    manager_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
