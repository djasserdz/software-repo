from pydantic import BaseModel, Field, ConfigDict, field_validator
from typing import Optional
from datetime import time
from datetime import datetime


class TimeSlotTemplateBase(BaseModel):
    zone_id: int = Field(..., gt=0)
    day_of_week: int = Field(..., ge=0, le=6)  # 0=Monday, 6=Sunday
    start_time: time
    end_time: time
    max_appointments: int = Field(default=1, ge=1)

    @field_validator("end_time")
    @classmethod
    def validate_end_after_start(cls, v, info):
        if "start_time" in info.data and v <= info.data["start_time"]:
            raise ValueError("end_time must be after start_time")
        return v


class TimeSlotTemplateCreate(TimeSlotTemplateBase):
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "zone_id": 1,
                "day_of_week": 0,
                "start_time": "09:00:00",
                "end_time": "12:00:00",
                "max_appointments": 1,
            }
        }
    )


class TimeSlotTemplateUpdate(BaseModel):
    zone_id: Optional[int] = Field(None, gt=0)
    day_of_week: Optional[int] = Field(None, ge=0, le=6)
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    max_appointments: Optional[int] = Field(None, ge=1)

    @field_validator("end_time")
    @classmethod
    def validate_end_after_start(cls, v, info):
        if (
            v is not None
            and "start_time" in info.data
            and info.data["start_time"] is not None
        ):
            if v <= info.data["start_time"]:
                raise ValueError("end_time must be after start_time")
        return v

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "start_time": "10:00:00",
                "end_time": "13:00:00",
                "max_appointments": 2,
            }
        }
    )


class TimeSlotTemplateResponse(TimeSlotTemplateBase):
    template_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

