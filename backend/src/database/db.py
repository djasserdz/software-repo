from typing import Optional
from datetime import datetime,time
from decimal import Decimal
from enum import Enum
from sqlmodel import Field, SQLModel, Relationship, Index


class UserRole(str, Enum):
    FARMER = "farmer"
    WAREHOUSE_ADMIN = "warehouse_admin"
    ADMIN = "admin"


class AccountStatus(str, Enum):
    ACTIVE = "active"
    NOT_ACTIVE = "not_active"


class ZoneStatus(str, Enum):
    ACTIVE = "active"
    NOT_ACTIVE = "not_active"


class AppointmentStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    CANCELLED = "cancelled"
    REFUSED = "refused"


class TimeSlotStatus(str, Enum):
    ACTIVE = "active"
    NOT_ACTIVE = "not_active"


class User(SQLModel, table=True):
    __tablename__ = "users"

    user_id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(nullable=False)
    email: str = Field(nullable=False, unique=True)
    password: str = Field(nullable=False)
    salt: str = Field(nullable=False)
    phone: str = Field(default="", nullable=False)
    address: str = Field(default="", nullable=False)
    role: UserRole = Field(nullable=False)
    email_verified_at: Optional[datetime] = None
    account_status: bool = Field(nullable=False)
    suspended_at: Optional[datetime] = None
    suspended_reason: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None

    warehouses: list["Warehouse"] = Relationship(back_populates="manager")
    appointments: list["Appointment"] = Relationship(back_populates="farmer")

    __table_args__ = (
        Index("idx_user_email", "email"),
        Index("idx_user_role", "role"),
        Index("idx_user_account_status", "account_status"),
    )


class Warehouse(SQLModel, table=True):
    __tablename__ = "warehouse"

    warehouse_id: Optional[int] = Field(default=None, primary_key=True)
    manager_id: int = Field(foreign_key="users.user_id", nullable=False)
    name: str = Field(nullable=False)
    location: str = Field(nullable=False)
    x_float: float = Field(nullable=False)
    y_float: float = Field(nullable=False)
    status: ZoneStatus = Field(nullable=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None

    manager: Optional[User] = Relationship(back_populates="warehouses")
    storage_zones: list["StorageZone"] = Relationship(back_populates="warehouse")

    __table_args__ = (
        Index("idx_warehouse_manager_id", "manager_id"),
        Index("idx_warehouse_status", "status"),
    )


class StorageZone(SQLModel, table=True):
    __tablename__ = "storagezones"

    zone_id: Optional[int] = Field(default=None, primary_key=True)
    warehouse_id: int = Field(foreign_key="warehouse.warehouse_id", nullable=False)
    grain_type_id: int = Field(nullable=False)
    name: str = Field(nullable=False)
    total_capacity: int = Field(nullable=False)
    available_capacity: int = Field(nullable=False)
    status: ZoneStatus = Field(nullable=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None

    warehouse: Optional[Warehouse] = Relationship(back_populates="storage_zones")
    appointments: list["Appointment"] = Relationship(back_populates="zone")
    time_slots: list["TimeSlot"] = Relationship(back_populates="zone")
    time_slot_templates: list["TimeSlotTemplate"] = Relationship(back_populates="zone")

    __table_args__ = (
        Index("idx_storagezone_warehouse_id", "warehouse_id"),
        Index("idx_storagezone_grain_type_id", "grain_type_id"),
        Index("idx_storagezone_status", "status"),
    )


class Grain(SQLModel, table=True):
    __tablename__ = "grains"

    grain_id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(nullable=False)
    price: Decimal = Field(nullable=False, decimal_places=2)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    __table_args__ = (Index("idx_grain_created_at", "created_at"),)

class TimeSlotTemplate(SQLModel, table=True):
    __tablename__ = "timeslot_templates"

    template_id: Optional[int] = Field(default=None, primary_key=True)
    zone_id: int = Field(foreign_key="storagezones.zone_id", nullable=False)
    day_of_week: int = Field(nullable=False)  # 0=Monday, 6=Sunday
    start_time: time = Field(nullable=False)
    end_time: time = Field(nullable=False)
    max_appointments: int = Field(default=1)  # 1 per timeslot
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    zone: Optional["StorageZone"] = Relationship(back_populates="time_slot_templates")

class TimeSlot(SQLModel, table=True):
    __tablename__ = "timeslots"

    time_id: Optional[int] = Field(default=None, primary_key=True)
    zone_id: int = Field(foreign_key="storagezones.zone_id", nullable=False)
    start_at: datetime = Field(nullable=False)
    end_at: datetime = Field(nullable=False)
    status: TimeSlotStatus = Field(nullable=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None

    zone: Optional[StorageZone] = Relationship(back_populates="time_slots")
    appointments: list["Appointment"] = Relationship(back_populates="time_slot")

    __table_args__ = (
        Index("idx_timeslot_zone_id", "zone_id"),
        Index("idx_timeslot_start_at", "start_at"),
        Index("idx_timeslot_status", "status"),
        Index("idx_timeslot_zone_start", "zone_id", "start_at"),
    )


class Appointment(SQLModel, table=True):
    __tablename__ = "appointments"

    appointment_id: Optional[int] = Field(default=None, primary_key=True)
    farmer_id: int = Field(foreign_key="users.user_id", nullable=False)
    zone_id: int = Field(foreign_key="storagezones.zone_id", nullable=False)
    grain_type_id: int = Field(foreign_key="grains.grain_id", nullable=False)
    timeslot_id: int = Field(foreign_key="timeslots.time_id", nullable=False)
    requested_quantity: int = Field(nullable=False)
    status: AppointmentStatus = Field(nullable=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None

    farmer: Optional[User] = Relationship(back_populates="appointments")
    zone: Optional[StorageZone] = Relationship(back_populates="appointments")
    grain_type: Optional[Grain] = Relationship()
    time_slot: Optional[TimeSlot] = Relationship(back_populates="appointments")
    delivery: Optional["Delivery"] = Relationship(back_populates="appointment")

    __table_args__ = (
        Index("idx_appointment_farmer_id", "farmer_id"),
        Index("idx_appointment_zone_id", "zone_id"),
        Index("idx_appointment_timeslot_id", "timeslot_id"),
        Index("idx_appointment_status", "status"),
        Index("idx_appointment_created_at", "created_at"),
    )


class Delivery(SQLModel, table=True):
    __tablename__ = "deliveries"

    delivery_id: Optional[int] = Field(default=None, primary_key=True)
    appointment_id: int = Field(
        foreign_key="appointments.appointment_id", nullable=False
    )
    receipt_code: str = Field(nullable=False)
    total_price: Decimal = Field(nullable=False, decimal_places=2)
    deleted_at: Optional[datetime] = None
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    appointment: Optional[Appointment] = Relationship(back_populates="delivery")

    __table_args__ = (
        Index("idx_delivery_appointment_id", "appointment_id"),
        Index("idx_delivery_receipt_code", "receipt_code"),
        Index("idx_delivery_created_at", "created_at"),
    )
