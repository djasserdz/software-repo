from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional
from datetime import datetime
from enum import Enum


# --------------------------
# Enums
# --------------------------
class UserRole(str, Enum):
    FARMER = "farmer"
    WAREHOUSE_ADMIN = "warehouse_admin"
    ADMIN = "admin"


class AccountStatus(str, Enum):
    ACTIVE = "active"
    NOT_ACTIVE = "not_active"


# --------------------------
# Base user model
# --------------------------
class UserBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    role: UserRole
    phone: Optional[str] = None          # now optional
    address: Optional[str] = None        # now optional


# --------------------------
# User creation
# --------------------------
class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=100)
    salt: Optional[str] = None
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "name": "John Doe",
                "email": "john@example.com",
                "role": "farmer",
                "password": "SecurePass123",
                "phone": "1234567890",
                "address": "123 Main Street",
            }
        }
    )


# --------------------------
# User update
# --------------------------
class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=8, max_length=100)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {"name": "John Updated", "email": "newemail@example.com"}
        }
    )


# --------------------------
# User response
# --------------------------
class UserResponse(UserBase):
    user_id: int
    account_status: AccountStatus
    suspension_reason: Optional[str] = None
    suspended_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --------------------------
# User login
# --------------------------
class UserLogin(BaseModel):
    email: EmailStr
    password: str


# --------------------------
# Suspend / Reactivate
# --------------------------
class UserSuspend(BaseModel):
    suspension_reason: str = Field(..., min_length=5, max_length=500)
    model_config = ConfigDict(
        json_schema_extra={
            "example": {"suspension_reason": "Missed 3 appointments without notice"}
        }
    )


class UserReactivate(BaseModel):
    reactivation_note: Optional[str] = Field(None, max_length=500)


# --------------------------
# Admin update
# --------------------------
class UserAdminUpdate(BaseModel):
    account_status: Optional[AccountStatus] = None
    suspension_reason: Optional[str] = Field(None, min_length=5, max_length=500)
    suspended_at: Optional[datetime] = None

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "account_status": "not_active",
                    "suspension_reason": "Missed 3 appointments without notice",
                },
                {
                    "account_status": "active",
                    "suspension_reason": None,
                    "suspended_at": None,
                },
            ]
        }
    )
