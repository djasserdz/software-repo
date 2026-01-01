from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import datetime
from ..database.db import AppointmentStatus


class AppointmentBase(BaseModel):
    grain_type_id: int = Field(..., gt=0)
    requested_quantity: int = Field(..., gt=0)
    status: AppointmentStatus


class AppointmentCreate(AppointmentBase):
    farmer_id: int = Field(..., gt=0)
    zone_id: int = Field(..., gt=0)
    timeslot_id: int = Field(..., gt=0)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "farmer_id": 1,
                "zone_id": 1,
                "grain_type_id": 1,
                "timeslot_id": 1,
                "requested_quantity": 5000,
                "status": "pending",
            }
        }
    )


class AppointmentCreateFromFrontend(BaseModel):
    """Model for appointment creation from frontend (uses warehouseZoneId)"""
    grainTypeId: int = Field(..., gt=0, alias="grainTypeId")
    requestedQuantity: float = Field(..., gt=0, alias="requestedQuantity")
    warehouseZoneId: int = Field(..., gt=0, alias="warehouseZoneId")
    timeSlotId: int = Field(..., gt=0, alias="timeSlotId")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "grainTypeId": 1,
                "requestedQuantity": 5000,
                "warehouseZoneId": 1,
                "timeSlotId": 1,
            }
        },
        populate_by_name=True,
    )


class AppointmentUpdate(BaseModel):
    farmer_id: Optional[int] = Field(None, gt=0)
    zone_id: Optional[int] = Field(None, gt=0)
    grain_type_id: Optional[int] = Field(None, gt=0)
    timeslot_id: Optional[int] = Field(None, gt=0)
    requested_quantity: Optional[int] = Field(None, gt=0)
    status: Optional[AppointmentStatus] = None

    model_config = ConfigDict(
        json_schema_extra={
            "example": {"requested_quantity": 6000, "status": "accepted"}
        }
    )


class AppointmentResponse(AppointmentBase):
    appointment_id: int
    farmer_id: int
    zone_id: int
    timeslot_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
