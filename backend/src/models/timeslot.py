from pydantic import BaseModel, Field, ConfigDict, field_validator
from typing import Optional
from datetime import datetime
from ..database.db import TimeSlotStatus


class TimeSlotBase(BaseModel):
    start_at: datetime
    end_at: datetime
    status: TimeSlotStatus

    @field_validator("end_at")
    @classmethod
    def validate_end_after_start(cls, v, info):
        if "start_at" in info.data and v <= info.data["start_at"]:
            raise ValueError("end_at must be after start_at")
        return v


class TimeSlotCreate(TimeSlotBase):
    zone_id: int = Field(..., gt=0)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "zone_id": 1,
                "start_at": "2024-01-15T09:00:00",
                "end_at": "2024-01-15T12:00:00",
                "status": "active",
            }
        }
    )


class TimeSlotUpdate(BaseModel):
    zone_id: Optional[int] = Field(None, gt=0)
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    status: Optional[TimeSlotStatus] = None

    @field_validator("end_at")
    @classmethod
    def validate_end_after_start(cls, v, info):
        if (
            v is not None
            and "start_at" in info.data
            and info.data["start_at"] is not None
        ):
            if v <= info.data["start_at"]:
                raise ValueError("end_at must be after start_at")
        return v

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "start_at": "2024-01-15T10:00:00",
                "end_at": "2024-01-15T13:00:00",
                "status": "not_active",
            }
        }
    )


class TimeSlotResponse(TimeSlotBase):
    time_id: int
    zone_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
