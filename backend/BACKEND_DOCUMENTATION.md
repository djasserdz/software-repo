# Backend API Documentation

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Technology Stack](#technology-stack)
3. [Project Structure](#project-structure)
4. [Database Models](#database-models)
5. [Authentication & Security](#authentication--security)
6. [API Endpoints](#api-endpoints)
7. [Services & Business Logic](#services--business-logic)
8. [Background Tasks](#background-tasks)

---

## Architecture Overview

The backend is built using **FastAPI**, a modern Python web framework. It follows a layered architecture pattern:

- **Routes Layer**: Handles HTTP requests and responses
- **Services Layer**: Contains business logic
- **Repositories Layer**: Handles database operations
- **Models Layer**: Pydantic models for request/response validation
- **Database Layer**: SQLModel ORM models and database configuration

The application uses:
- **PostgreSQL** as the database
- **JWT** tokens for authentication
- **Argon2** for password hashing
- **APScheduler** for background tasks (time slot generation)
- **CORS** middleware for cross-origin requests

---

## Technology Stack

- **Framework**: FastAPI 0.121.3
- **Database**: PostgreSQL with asyncpg
- **ORM**: SQLModel 0.0.27
- **Authentication**: JWT (python-jose)
- **Password Hashing**: Argon2 (argon2-cffi)
- **Scheduler**: APScheduler 3.10.4
- **Validation**: Pydantic 2.12.4

---

## Project Structure

```
backend/src/
├── main.py                 # Application entry point
├── config/
│   ├── database.py        # Database connection management
│   ├── security.py        # JWT and password hashing
│   └── settings.py        # Environment configuration
├── database/
│   └── db.py              # SQLModel database models
├── models/                # Pydantic request/response models
│   ├── user.py
│   ├── warehouse.py
│   ├── grain.py
│   ├── storagezone.py
│   ├── timeslot.py
│   ├── appointment.py
│   ├── delivery.py
│   └── geolocation.py
├── routes/                # API route handlers
│   ├── user.py
│   ├── warehouse.py
│   ├── grain.py
│   ├── storagezone.py
│   ├── timeslot.py
│   ├── appointment.py
│   ├── delivery.py
│   ├── location.py
│   └── geolocation.py
├── services/              # Business logic
│   ├── user.py
│   ├── warehouse.py
│   ├── grain.py
│   ├── storagezone.py
│   ├── timeslot.py
│   ├── appointment.py
│   ├── delivery.py
│   ├── location.py
│   ├── geolocation.py
│   └── scheduler.py
└── repositories/          # Database access layer
    ├── user.py
    ├── warehouse.py
    ├── grain.py
    ├── storagezone.py
    ├── timeslot.py
    ├── appointment.py
    └── delivery.py
```

---

## Database Models

### User
- **user_id** (int, PK)
- **name** (str)
- **email** (str, unique)
- **password** (str, hashed)
- **salt** (str)
- **phone** (str)
- **address** (str)
- **role** (enum: farmer, warehouse_admin, admin)
- **account_status** (bool)
- **suspended_at** (datetime, nullable)
- **suspended_reason** (str, nullable)
- **created_at** (datetime)
- **updated_at** (datetime)

### Warehouse
- **warehouse_id** (int, PK)
- **manager_id** (int, FK → users.user_id)
- **name** (str)
- **location** (str)
- **x_float** (float) - Longitude
- **y_float** (float) - Latitude
- **status** (enum: active, not_active)
- **created_at** (datetime)
- **updated_at** (datetime)

### Grain
- **grain_id** (int, PK)
- **name** (str)
- **price** (Decimal)
- **created_at** (datetime)
- **updated_at** (datetime)

### StorageZone
- **zone_id** (int, PK)
- **warehouse_id** (int, FK → warehouse.warehouse_id)
- **grain_type_id** (int, FK → grains.grain_id)
- **name** (str)
- **total_capacity** (int)
- **available_capacity** (int)
- **status** (enum: active, not_active)
- **created_at** (datetime)
- **updated_at** (datetime)

### TimeSlotTemplate
- **template_id** (int, PK)
- **zone_id** (int, FK → storagezones.zone_id)
- **day_of_week** (int) - 0=Monday, 6=Sunday
- **start_time** (time)
- **end_time** (time)
- **max_appointments** (int, default=1)
- **created_at** (datetime)
- **updated_at** (datetime)

### TimeSlot
- **time_id** (int, PK)
- **zone_id** (int, FK → storagezones.zone_id)
- **start_at** (datetime)
- **end_at** (datetime)
- **status** (enum: active, not_active)
- **created_at** (datetime)
- **updated_at** (datetime)

### Appointment
- **appointment_id** (int, PK)
- **farmer_id** (int, FK → users.user_id)
- **zone_id** (int, FK → storagezones.zone_id)
- **grain_type_id** (int, FK → grains.grain_id)
- **timeslot_id** (int, FK → timeslots.time_id)
- **requested_quantity** (int)
- **status** (enum: pending, accepted, cancelled, refused)
- **created_at** (datetime)
- **updated_at** (datetime)

### Delivery
- **delivery_id** (int, PK)
- **appointment_id** (int, FK → appointments.appointment_id)
- **receipt_code** (str)
- **total_price** (Decimal)
- **created_at** (datetime)
- **updated_at** (datetime)

---

## Authentication & Security

### Authentication Flow
1. User registers/logs in with email and password
2. Password is hashed using Argon2
3. JWT token is generated containing `user_id`
4. Token is returned to client
5. Client includes token in `Authorization: Bearer <token>` header for protected routes

### Security Features
- **Password Hashing**: Argon2 with bcrypt fallback
- **JWT Tokens**: Signed with secret key, configurable expiration
- **CORS**: Configured to allow all origins (configurable)
- **Token Validation**: Middleware validates tokens on protected routes

### Protected Routes
Routes that require authentication use `Depends(get_current_user)` which:
- Extracts token from `Authorization` header
- Validates token signature and expiration
- Retrieves user from database
- Returns user object or raises 401 error

---

## API Endpoints

### Base URL
All endpoints are prefixed with their respective router prefix. The API is available at `http://localhost:8000` by default.

### User Endpoints (`/user` and `/auth`)

#### GET `/user/`
**Description**: Get all users

**Authentication**: Not required

**Query Parameters**: None

**Response**: 
```json
[
  {
    "user_id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "farmer",
    "phone": "1234567890",
    "address": "123 Main St",
    "account_status": true,
    "suspended_reason": null,
    "suspended_at": null,
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

---

#### POST `/user/register`
**Description**: Register a new user

**Authentication**: Not required

**Request Body**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123",
  "role": "farmer",
  "phone": "1234567890",
  "address": "123 Main Street"
}
```

**Response**:
```json
{
  "user": {
    "user_id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "farmer",
    "phone": "1234567890",
    "address": "123 Main Street",
    "account_status": true,
    "suspended_reason": null,
    "suspended_at": null,
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

#### POST `/user/login` or `/auth/login`
**Description**: Login user

**Authentication**: Not required

**Request Body**:
```json
{
  "email": "john@example.com",
  "password": "SecurePass123"
}
```

**Response**:
```json
{
  "user": {
    "user_id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "farmer",
    "phone": "1234567890",
    "address": "123 Main Street",
    "account_status": true,
    "suspended_reason": null,
    "suspended_at": null,
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

#### GET `/user/me` or `/auth/me`
**Description**: Get current authenticated user

**Authentication**: Required

**Response**: Same as user object in register/login

---

#### GET `/user/{user_id}`
**Description**: Get user by ID

**Authentication**: Not required

**Path Parameters**:
- `user_id` (int): User ID

**Response**: User object

---

#### POST `/user/suspend/{user_id}`
**Description**: Suspend a user

**Authentication**: Not required (should be protected in production)

**Path Parameters**:
- `user_id` (int): User ID

**Query Parameters**:
- `reason` (str): Suspension reason

**Response**: User object with updated suspension status

---

#### POST `/user/unsuspend`
**Description**: Unsuspend a user

**Authentication**: Not required (should be protected in production)

**Query Parameters**:
- `user_id` (int): User ID

**Response**: User object

---

#### GET `/user/profile`
**Description**: Get current user profile

**Authentication**: Required

**Response**: User object

---

#### PUT `/user/profile`
**Description**: Update current user profile

**Authentication**: Required

**Request Body**:
```json
{
  "name": "John Updated",
  "email": "newemail@example.com",
  "phone": "1234567890",
  "address": "123 Main Street"
}
```

**Response**: Updated user object

---

#### PUT `/user/change-password`
**Description**: Change user password

**Authentication**: Required

**Request Body**:
```json
{
  "currentPassword": "OldPassword123",
  "newPassword": "NewPassword123"
}
```

**Response**:
```json
{
  "message": "Password changed successfully"
}
```

---

### Warehouse Endpoints (`/warehouse`)

#### GET `/warehouse/`
**Description**: Get all warehouses

**Authentication**: Not required

**Response**:
```json
[
  {
    "warehouse_id": 1,
    "manager_id": 1,
    "name": "Main Warehouse",
    "location": "123 Storage St, City",
    "x_float": 40.7128,
    "y_float": -74.0060,
    "status": "active",
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

---

#### POST `/warehouse/`
**Description**: Create a warehouse

**Authentication**: Not required (should be protected in production)

**Request Body**:
```json
{
  "manager_id": 1,
  "name": "Main Warehouse",
  "location": "123 Storage St, City",
  "x_float": 40.7128,
  "y_float": -74.0060,
  "status": "active"
}
```

**Response**: Created warehouse object

---

#### GET `/warehouse/{warehouse_id}`
**Description**: Get a warehouse by ID

**Authentication**: Not required

**Path Parameters**:
- `warehouse_id` (int): Warehouse ID

**Response**: Warehouse object

---

#### PATCH `/warehouse/{warehouse_id}`
**Description**: Update a warehouse

**Authentication**: Not required (should be protected in production)

**Path Parameters**:
- `warehouse_id` (int): Warehouse ID

**Request Body** (all fields optional):
```json
{
  "name": "Updated Warehouse Name",
  "location": "New Location",
  "x_float": 84.55,
  "y_float": -1.25,
  "status": "not_active",
  "manager_id": 1
}
```

**Response**: Updated warehouse object

---

### Grain Endpoints (`/grain`)

#### GET `/grain/`
**Description**: Get all grains

**Authentication**: Not required

**Response**:
```json
[
  {
    "grain_id": 1,
    "name": "Premium Wheat",
    "price": "150.50",
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

---

#### POST `/grain/`
**Description**: Create a grain

**Authentication**: Not required (should be protected in production)

**Request Body**:
```json
{
  "name": "Premium Wheat",
  "price": "150.50"
}
```

**Response**: Created grain object

---

#### GET `/grain/{grain_id}`
**Description**: Get grain by ID

**Authentication**: Not required

**Path Parameters**:
- `grain_id` (int): Grain ID

**Response**: Grain object

---

#### PATCH `/grain/{grain_id}`
**Description**: Update a grain

**Authentication**: Not required (should be protected in production)

**Path Parameters**:
- `grain_id` (int): Grain ID

**Request Body** (all fields optional):
```json
{
  "name": "Updated Grain Name",
  "price": "175.00"
}
```

**Response**: Updated grain object

---

#### DELETE `/grain/{grain_id}`
**Description**: Delete a grain

**Authentication**: Not required (should be protected in production)

**Path Parameters**:
- `grain_id` (int): Grain ID

**Response**: `"grain Deleted!"`

---

### Storage Zone Endpoints (`/zone` and `/warehouse-zones`)

#### GET `/zone/`
**Description**: List all zones with optional filters

**Authentication**: Not required

**Query Parameters**:
- `skip` (int, default=0, min=0): Number of items to skip
- `limit` (int, default=100, max=1000): Maximum number of items to return
- `warehouse_id` (int, optional): Filter by warehouse ID
- `grain_type_id` (int, optional): Filter by grain type ID
- `status` (enum: active, not_active, optional): Filter by status

**Response**:
```json
[
  {
    "zone_id": 1,
    "warehouse_id": 1,
    "grain_type_id": 1,
    "name": "Zone A - Wheat Storage",
    "total_capacity": 10000,
    "available_capacity": 5000,
    "status": "active",
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

---

#### GET `/zone/{zone_id}`
**Description**: Get a zone by ID

**Authentication**: Not required

**Path Parameters**:
- `zone_id` (int): Zone ID

**Response**: Zone object

---

#### POST `/zone/`
**Description**: Create a zone

**Authentication**: Not required (should be protected in production)

**Query Parameters**:
- `warehouser_id` (int): Warehouse ID (note: typo in parameter name)

**Request Body**:
```json
{
  "name": "Zone A - Wheat Storage",
  "grain_type_id": 1,
  "total_capacity": 10000,
  "available_capacity": 5000,
  "status": "active"
}
```

**Response**: Created zone object

---

#### PATCH `/zone/{zone_id}`
**Description**: Update a zone

**Authentication**: Not required (should be protected in production)

**Path Parameters**:
- `zone_id` (int): Zone ID

**Request Body** (all fields optional):
```json
{
  "name": "Updated Zone Name",
  "grain_type_id": 1,
  "total_capacity": 10000,
  "available_capacity": 3000,
  "status": "not_active",
  "warehouse_id": 1
}
```

**Response**: Updated zone object

---

### Time Slot Endpoints (`/time` and `/time-slots`)

#### GET `/time/`
**Description**: Get all time slots for a zone

**Authentication**: Not required

**Query Parameters**:
- `zone_id` (int, required): Zone ID
- `skip` (int, default=0): Number of items to skip
- `limit` (int, default=100): Maximum number of items to return

**Response**:
```json
[
  {
    "time_id": 1,
    "zone_id": 1,
    "start_at": "2024-01-15T09:00:00",
    "end_at": "2024-01-15T12:00:00",
    "status": "active",
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

---

#### GET `/time/{time_id}`
**Description**: Get time slot by ID

**Authentication**: Not required

**Path Parameters**:
- `time_id` (int): Time slot ID

**Response**: Time slot object

---

#### POST `/time/`
**Description**: Create a time slot

**Authentication**: Not required (should be protected in production)

**Request Body**:
```json
{
  "zone_id": 1,
  "start_at": "2024-01-15T09:00:00",
  "end_at": "2024-01-15T12:00:00",
  "status": "active"
}
```

**Response**: Created time slot object

---

#### PATCH `/time/{time_id}`
**Description**: Update a time slot

**Authentication**: Not required (should be protected in production)

**Path Parameters**:
- `time_id` (int): Time slot ID

**Request Body** (all fields optional):
```json
{
  "zone_id": 1,
  "start_at": "2024-01-15T10:00:00",
  "end_at": "2024-01-15T13:00:00",
  "status": "not_active"
}
```

**Response**: Updated time slot object

---

#### DELETE `/time/{time_id}`
**Description**: Delete a time slot

**Authentication**: Not required (should be protected in production)

**Path Parameters**:
- `time_id` (int): Time slot ID

**Response**: `"Time deleted"`

---

#### GET `/time/available`
**Description**: Get available time slots for a zone

**Authentication**: Not required

**Query Parameters**:
- `zone_id` (int, required): Zone ID
- `grain_type_id` (int, optional): Grain type ID filter

**Response**:
```json
{
  "data": [
    {
      "time_id": 1,
      "zone_id": 1,
      "start_at": "2024-01-15T09:00:00",
      "end_at": "2024-01-15T12:00:00",
      "status": "active",
      "created_at": "2024-01-01T00:00:00",
      "updated_at": "2024-01-01T00:00:00"
    }
  ]
}
```

---

#### POST `/time/generate`
**Description**: Generate time slots for next day

**Authentication**: Not required (should be protected in production)

**Response**:
```json
{
  "message": "Generated 24 time slots for tomorrow",
  "slots": [...]
}
```

---

#### POST `/time/generate-week`
**Description**: Generate time slots for the next week

**Authentication**: Not required (should be protected in production)

**Response**:
```json
{
  "message": "Generated 168 time slots for the next week",
  "slots": [...]
}
```

---

### Appointment Endpoints (`/appointment` and `/appointments`)

#### GET `/appointment/`
**Description**: Get all appointments with optional filters

**Authentication**: Not required

**Query Parameters**:
- `zone_id` (int, optional): Filter by zone ID
- `farmer_id` (int, optional): Filter by farmer ID
- `status` (str, optional): Filter by status (pending, accepted, cancelled, refused)
- `skip` (int, default=0): Number of items to skip
- `limit` (int, default=100): Maximum number of items to return

**Response**:
```json
[
  {
    "appointment_id": 1,
    "farmer_id": 1,
    "zone_id": 1,
    "grain_type_id": 1,
    "timeslot_id": 1,
    "requested_quantity": 5000,
    "status": "pending",
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

---

#### GET `/appointment/my-appointments`
**Description**: Get current user's appointments

**Authentication**: Required

**Query Parameters**:
- `status` (str, optional): Filter by status

**Response**:
```json
{
  "appointments": [
    {
      "appointment_id": 1,
      "farmer_id": 1,
      "zone_id": 1,
      "grain_type_id": 1,
      "timeslot_id": 1,
      "requested_quantity": 5000,
      "status": "pending",
      "created_at": "2024-01-01T00:00:00",
      "updated_at": "2024-01-01T00:00:00"
    }
  ]
}
```

---

#### GET `/appointment/{appointment_id}`
**Description**: Get a single appointment

**Authentication**: Not required

**Path Parameters**:
- `appointment_id` (int): Appointment ID

**Response**: Appointment object

---

#### POST `/appointment/`
**Description**: Create an appointment (frontend format)

**Authentication**: Required

**Request Body**:
```json
{
  "grainTypeId": 1,
  "requestedQuantity": 5000,
  "warehouseZoneId": 1,
  "timeSlotId": 1
}
```

**Response**: Created appointment object

---

#### PUT `/appointment/{appointment_id}/cancel`
**Description**: Cancel an appointment

**Authentication**: Required (only the appointment owner can cancel)

**Path Parameters**:
- `appointment_id` (int): Appointment ID

**Request Body**: Optional (can be empty `{}`)

**Response**:
```json
{
  "message": "Appointment cancelled successfully",
  "appointment": {
    "appointment_id": 1,
    "status": "cancelled",
    ...
  }
}
```

---

#### PUT `/appointment/{appointment_id}/confirm-attendance`
**Description**: Confirm appointment attendance (warehouse admin only)

**Authentication**: Required (warehouse_admin role)

**Path Parameters**:
- `appointment_id` (int): Appointment ID

**Response**:
```json
{
  "message": "Attendance confirmed successfully",
  "appointment": {
    "appointment_id": 1,
    "status": "completed",
    ...
  }
}
```

---

#### GET `/appointment/history`
**Description**: Get appointment history for current user

**Authentication**: Required

**Response**:
```json
{
  "appointments": [
    {
      "appointment_id": 1,
      "status": "completed",
      ...
    },
    {
      "appointment_id": 2,
      "status": "cancelled",
      ...
    }
  ]
}
```

---

### Delivery Endpoints (`/delivery` and `/deliveries`)

#### GET `/delivery/`
**Description**: Get all deliveries with optional filters

**Authentication**: Not required

**Query Parameters**:
- `appointment_id` (int, optional): Filter by appointment ID
- `skip` (int, default=0): Number of items to skip
- `limit` (int, default=100): Maximum number of items to return

**Response**:
```json
[
  {
    "delivery_id": 1,
    "appointment_id": 1,
    "receipt_code": "REC-2024-001",
    "total_price": "75000.00",
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

---

#### GET `/delivery/my-deliveries`
**Description**: Get current user's deliveries

**Authentication**: Required

**Response**:
```json
{
  "deliveries": [
    {
      "delivery_id": 1,
      "appointment_id": 1,
      "receipt_code": "REC-2024-001",
      "total_price": "75000.00",
      "created_at": "2024-01-01T00:00:00",
      "updated_at": "2024-01-01T00:00:00"
    }
  ]
}
```

---

#### GET `/delivery/{delivery_id}`
**Description**: Get a single delivery

**Authentication**: Not required

**Path Parameters**:
- `delivery_id` (int): Delivery ID

**Response**: Delivery object

---

#### POST `/delivery/`
**Description**: Create a delivery

**Authentication**: Not required (should be protected in production)

**Request Body**:
```json
{
  "appointment_id": 1,
  "receipt_code": "REC-2024-001",
  "total_price": "75000.00"
}
```

**Response**: Created delivery object

---

### Location Endpoints (`/location`)

#### GET `/location/location/name/{location_name}`
**Description**: Get location data by location name

**Authentication**: Not required

**Path Parameters**:
- `location_name` (str): Location name

**Response**: Location data from external API

---

#### GET `/location/location/coordinates/`
**Description**: Get location data by coordinates

**Authentication**: Not required

**Query Parameters**:
- `latitude` (float): Latitude
- `longitude` (float): Longitude

**Response**: Location data from external API

---

### Geolocation Endpoints (`/geolocation`)

#### GET `/geolocation/nearest`
**Description**: Get nearest warehouses with zones for grain type

**Authentication**: Not required

**Query Parameters**:
- `lat` (float, required): Latitude
- `lng` (float, required): Longitude
- `grainType` (int, optional): Grain type ID
- `limit` (int, default=10, min=1, max=50): Maximum number of results

**Response**:
```json
{
  "data": {
    "allWarehouses": [
      {
        "warehouse_id": 1,
        "name": "Main Warehouse",
        "location": "123 Storage St",
        "x_float": 40.7128,
        "y_float": -74.0060,
        "distance": 5.2,
        "zones": [...]
      }
    ]
  }
}
```

---

#### PUT `/geolocation/warehouse/{warehouse_id}/location`
**Description**: Update warehouse location coordinates

**Authentication**: Required

**Path Parameters**:
- `warehouse_id` (int): Warehouse ID

**Query Parameters**:
- `latitude` (float, required): Latitude
- `longitude` (float, required): Longitude

**Response**:
```json
{
  "message": "Warehouse location updated successfully"
}
```

---

#### POST `/geolocation/update-location`
**Description**: Update farmer's current location

**Authentication**: Required

**Request Body**:
```json
{
  "latitude": 28.0339,
  "longitude": 1.6596
}
```

**Response**:
```json
{
  "message": "Location updated successfully"
}
```

---

## Services & Business Logic

### User Service
- **register_user**: Creates new user, hashes password, validates email uniqueness
- **login_user**: Validates credentials, returns user if valid
- **search_user**: Retrieves user by ID
- **list_all**: Retrieves all users
- **update_user**: Updates user profile information
- **change_password**: Validates current password and updates to new password
- **suspend_user**: Suspends user account with reason
- **unsuspend_user**: Reactivates suspended user account

### Warehouse Service
- **create_warehouse**: Creates new warehouse with manager assignment
- **get_warehouse**: Retrieves warehouse by ID
- **list_all**: Retrieves all warehouses
- **update**: Updates warehouse information

### Grain Service
- **create_grain**: Creates new grain type with price
- **get_grain**: Retrieves grain by ID
- **get_grains**: Retrieves all grains
- **update_grain**: Updates grain information
- **delete_grain**: Soft deletes grain (sets deleted_at)

### Storage Zone Service
- **create_zone**: Creates new storage zone in warehouse
- **get_zone**: Retrieves zone by ID
- **get_all**: Retrieves zones with filtering and pagination
- **update_zone**: Updates zone information and capacity

### Time Slot Service
- **create_time**: Creates new time slot for a zone
- **get_time**: Retrieves time slot by ID
- **get_all**: Retrieves time slots for a zone with pagination
- **get_available**: Retrieves available (not booked) time slots
- **updated_time**: Updates time slot
- **delete_time**: Soft deletes time slot
- **generate_timeslots_for_next_day**: Generates time slots for tomorrow based on templates
- **generate_timeslots_for_next_week**: Generates time slots for next 7 days based on templates

### Appointment Service
- **create_appointment**: Creates new appointment
- **create_appointment_from_frontend**: Creates appointment using frontend format (warehouseZoneId)
- **get_appointment**: Retrieves appointment by ID
- **get_appointments**: Retrieves appointments with filters
- **get_my_appointments**: Retrieves appointments for specific farmer
- **update_appointment**: Updates appointment status and details

### Delivery Service
- **create_delivery**: Creates delivery record for appointment
- **get_by_id**: Retrieves delivery by ID
- **get_all**: Retrieves deliveries with filters and pagination
- **get_my_deliveries**: Retrieves deliveries for specific farmer

### Geolocation Service
- **get_nearest_warehouses**: Calculates distances and returns nearest warehouses with zones
- **update_warehouse_location**: Updates warehouse coordinates
- **update_farmer_location**: Updates farmer's current location

### Location Service
- **fetch_by_location_name**: Fetches location data from external API by name
- **fetch_by_coordinates**: Fetches location data from external API by coordinates

---

## Background Tasks

### Time Slot Scheduler
The application includes a background scheduler that automatically generates time slots:

- **Frequency**: Runs every 3 days
- **Task**: Generates time slots for the next week based on time slot templates
- **Initial Run**: Executes immediately on application startup
- **Implementation**: Uses APScheduler (AsyncIOScheduler)

The scheduler:
1. Retrieves all active storage zones
2. For each zone, finds time slot templates
3. Generates time slots for the next 7 days based on templates
4. Creates time slots with appropriate start/end times
5. Logs generation results

This ensures that farmers always have available time slots to book appointments.

---

## Error Handling

The application uses FastAPI's HTTPException for error handling:

- **400 Bad Request**: Invalid input data
- **401 Unauthorized**: Missing or invalid authentication token
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **500 Internal Server Error**: Server-side errors

All errors are logged to `app.log` with rotation (5MB max, 5 backups).

---

## Configuration

Configuration is managed through environment variables loaded via Pydantic Settings:

- **Database**: PostgreSQL connection settings
- **JWT**: Secret key, algorithm, expiration time
- **Redis**: Host, port, password (if used)
- **Project**: Name, domain, team limits

Settings are loaded from `.env` file in the project root.

---

## Database Connection

The application uses async database connections:

- **Connection Pool**: Managed by SQLAlchemy async engine
- **Session Management**: Dependency injection via `ConManager.get_session()`
- **Database Creation**: Automatically creates database if it doesn't exist on startup
- **Schema Migration**: SQLModel automatically creates tables on startup

---

## Notes

1. **Authentication**: Many endpoints are marked as "not required" but should be protected in production based on user roles
2. **Parameter Typo**: The storage zone creation endpoint has a typo: `warehouser_id` instead of `warehouse_id`
3. **CORS**: Currently allows all origins (`*`) - should be restricted in production
4. **Soft Deletes**: Most entities use soft deletes (deleted_at field) rather than hard deletes
5. **Validation**: All input is validated using Pydantic models with appropriate constraints
6. **Logging**: Application logs to both file (`app.log`) and console with INFO level



