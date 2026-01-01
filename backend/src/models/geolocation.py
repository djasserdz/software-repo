from pydantic import BaseModel, Field


class LocationUpdate(BaseModel):
    latitude: float = Field(..., ge=-90, le=90, description="Latitude")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude")

    class Config:
        json_schema_extra = {
            "example": {
                "latitude": 28.0339,
                "longitude": 1.6596,
            }
        }

