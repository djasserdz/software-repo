# Mahsoul - Application Features

**Mahsoul** is a comprehensive grain warehouse management system designed to streamline the process of storing, managing, and delivering grain products. The application enables farmers, warehouse administrators, and system administrators to collaborate efficiently in grain storage and distribution operations.

---

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Core Features](#core-features)
3. [User Roles & Permissions](#user-roles--permissions)
4. [Farmer Features](#farmer-features)
5. [Warehouse Administrator Features](#warehouse-administrator-features)
6. [System Administrator Features](#system-administrator-features)
7. [Technical Architecture](#technical-architecture)
8. [Technology Stack](#technology-stack)

---

## 🎯 System Overview

Mahsoul is a multi-platform application built with:
- **Backend API**: FastAPI (Python)
- **Web Frontend**: Vue.js 3 with Vite
- **Mobile Application**: Flutter

The system manages the complete lifecycle of grain storage from booking appointments through delivery, with real-time tracking and role-based access control.

---

## 🌟 Core Features

### 1. **User Management**
- User registration and login with email/password
- Role-based account creation (Farmer, Warehouse Admin, System Admin)
- Secure password hashing using Argon2
- JWT-based authentication and token management
- User profile management and updates
- Account suspension/reactivation capabilities
- Role-specific dashboard redirection

### 2. **Warehouse Management**
- Browse all available warehouses
- View warehouse details including:
  - Manager information
  - Location (with geolocation coordinates)
  - Operational status (active/inactive)
  - Available storage zones
  - Grain types offered
- Geolocation-based warehouse search
- Warehouse creation and management (admin only)

### 3. **Storage Zone Management**
- Multiple storage zones per warehouse
- Zone capacity tracking (total and available capacity)
- Grain type association per zone
- Zone status management (active/inactive)
- Real-time capacity updates based on appointments and deliveries

### 4. **Grain Type Management**
- Manage grain types available in the system
- Price information for each grain type
- Grain type assignment to storage zones
- Create, update, and delete grain types (admin only)

### 5. **Time Slot & Appointment System**
- Flexible time slot templates based on day of week
- Automatic time slot generation based on templates
- Time slot scheduling with capacity limits
- Appointment booking by farmers
- Appointment status tracking (pending, accepted, cancelled, refused)
- Quantity reservation for grain storage
- Appointment history and management

### 6. **Delivery & Receipt Management**
- Receipt-based delivery tracking
- Delivery confirmation and completion
- Total price calculation per delivery
- Delivery history and status tracking
- Integration with appointments and grain data

### 7. **Geolocation Services**
- Location-based warehouse discovery
- GPS coordinate storage (longitude/latitude)
- Distance-based searching capabilities
- Location tracking for warehouse operations

### 8. **Authentication & Security**
- Secure JWT-based authentication
- Configurable token expiration
- Password encryption with Argon2
- CORS protection
- Role-based authorization
- Protected API endpoints
- Secure token storage in mobile app

---

## 👥 User Roles & Permissions

### Role Hierarchy
1. **Farmer** - Individual grain producers
2. **Warehouse Admin** - Warehouse managers and staff
3. **System Admin** - System operators and managers

---

## 🚜 Farmer Features

### Dashboard
- Quick access to key information
- Recent appointments overview
- Pending deliveries
- Warehouse statistics

### Warehouse Browsing
- Browse all active warehouses
- Filter by location (geolocation)
- View warehouse capacity
- Search by grain type
- View zone details and available time slots

### Appointment Management
- **Book Appointments**
  - Select warehouse and storage zone
  - Choose grain type and quantity
  - Select preferred time slot
  - Submit appointment request
  
- **View Appointments**
  - List all personal appointments
  - Filter by status (pending, accepted, cancelled, refused)
  - View appointment details
  - Cancel pending appointments

### Delivery Tracking
- View delivery history
- Track delivery status
- View receipt codes
- Check pricing information
- Download or print receipts

### Profile Management
- Update personal information (name, phone, address)
- View account details
- Manage contact information
- View account creation date

---

## 🏢 Warehouse Administrator Features

### Dashboard
- Warehouse overview and statistics
- Pending appointments count
- Current capacity utilization
- Quick action buttons

### Warehouse Management
- View assigned warehouses
- Monitor warehouse status
- Track operational metrics
- Manage warehouse information

### Storage Zone Management
- **Create & Edit Zones**
  - Specify grain type
  - Set capacity limits
  - Configure zone status
  - Manage zone details

- **View Zones**
  - List all zones with capacity info
  - Monitor available capacity
  - Track zone status
  - View associated time slots

### Time Slot Management
- **Create Time Slots**
  - Manually create specific time slots
  - Set time ranges
  - Configure capacity (max appointments)
  - Set status (active/inactive)

- **Generate Time Slots**
  - Automatic generation from templates
  - Based on recurring weekly schedules
  - Create multiple slots at once
  - Maintain consistency

- **Manage Time Slots**
  - Edit existing time slots
  - Delete time slots
  - View appointment counts per slot
  - Monitor time slot utilization

### Appointment Management
- **View All Appointments**
  - Filter by status (pending, accepted, etc.)
  - Sort by date and time
  - Search by farmer information

- **Accept/Refuse Appointments**
  - Review appointment requests
  - Accept qualified requests
  - Refuse with optional reasons
  - Update farmer notifications

- **Confirm Attendance**
  - Mark farmers as checked-in
  - Validate appointments on delivery date
  - Track completion

---

## 👨‍💼 System Administrator Features

### Admin Dashboard
- System overview and statistics
- Quick metrics (total users, warehouses, appointments)
- Quick action buttons
- System health status

### User Management
- **View All Users**
  - List users by role (farmer, warehouse admin, admin)
  - Filter by status (active, suspended)
  - Search by name or email

- **User Actions**
  - Suspend user accounts
  - Reactivate suspended accounts
  - View user details
  - Track suspension reasons and dates
  - View user creation/update timestamps

### Warehouse Management
- **Create Warehouses**
  - Assign manager (warehouse admin)
  - Set location information
  - Input GPS coordinates (latitude/longitude)
  - Configure status (active/inactive)

- **Edit Warehouses**
  - Update warehouse information
  - Change assigned manager
  - Modify location details
  - Toggle status

- **View Warehouses**
  - List all warehouses
  - Filter by status
  - View manager assignments
  - Monitor warehouse creation dates

### Grain Type Management
- **Create Grain Types**
  - Define grain name
  - Set pricing
  - Activate immediately

- **Edit Grain Types**
  - Update grain information
  - Modify pricing
  - Change status

- **Delete Grain Types**
  - Remove unused grain types
  - Manage grain catalog

### Appointment Oversight
- **View All System Appointments**
  - Monitor all appointments across warehouses
  - Filter by status
  - Search by farmer, warehouse, or zone
  - View comprehensive details
  - Track appointment metrics

- **Analytics**
  - Total appointments by status
  - Farmer appointment activity
  - Warehouse utilization rates
  - Peak booking times

---

## 🏗️ Technical Architecture

### Layered Architecture

```
┌─────────────────────────────────────┐
│      User Interface Layer           │
│  (Web Frontend, Mobile App)         │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│       API Routes Layer              │
│    (HTTP Endpoints, Validation)     │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│      Services Layer                 │
│   (Business Logic, Validation)      │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│    Repositories Layer               │
│   (Database Access, Queries)        │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│      Database Layer                 │
│    (PostgreSQL, SQLModel ORM)       │
└─────────────────────────────────────┘
```

### Key Components

#### Backend Components
- **Routes**: HTTP endpoint handlers with request/response validation
- **Services**: Business logic implementation and data validation
- **Repositories**: Database operations and queries
- **Models**: SQLModel ORM models and Pydantic validation schemas
- **Database**: PostgreSQL connection and configuration
- **Security**: JWT authentication and password hashing
- **Scheduler**: Background task scheduling for time slot generation

#### Database Models
- **User**: Authentication and profile information
- **Warehouse**: Grain storage facilities
- **Grain**: Grain type definitions and pricing
- **StorageZone**: Specific storage areas within warehouses
- **TimeSlotTemplate**: Recurring weekly schedules
- **TimeSlot**: Specific time slots for appointments
- **Appointment**: Farmer requests for grain storage
- **Delivery**: Completed transactions and receipt information

---

## 💻 Technology Stack

### Backend
- **Framework**: FastAPI 0.121.3 (Python)
- **Database**: PostgreSQL 16
- **ORM**: SQLModel 0.0.27
- **Authentication**: JWT with python-jose
- **Password Hashing**: Argon2 (argon2-cffi)
- **Scheduler**: APScheduler 3.10.4
- **Async**: asyncpg for async database operations
- **Validation**: Pydantic 2.12.4

### Frontend (Web)
- **Framework**: Vue 3
- **Build Tool**: Vite
- **Routing**: Vue Router
- **State Management**: Pinia
- **HTTP Client**: Axios
- **Styling**: Tailwind CSS
- **Icons**: Heroicons
- **Node.js**: 16+

### Mobile (Flutter)
- **SDK**: Flutter 3.0.0+
- **Language**: Dart
- **State Management**: Provider
- **HTTP Client**: Dio
- **Navigation**: Go Router
- **Local Storage**: SharedPreferences
- **Location Services**: Geolocator
- **Maps**: Google Maps Flutter

### Infrastructure
- **Container Orchestration**: Docker Compose
- **Web Server**: Nginx (reverse proxy)
- **Cache**: Redis (optional)

---

## 🔄 Key Workflows

### Farmer's Appointment Booking Workflow
1. Browse available warehouses
2. View storage zones and available time slots
3. Select grain type and quantity
4. Choose preferred appointment time
5. Submit appointment request
6. Wait for warehouse admin approval
7. Receive confirmation/rejection
8. Proceed with delivery on scheduled time

### Warehouse Admin's Daily Workflow
1. Check pending appointments
2. Generate time slots from templates
3. Manage storage zone capacities
4. Review and accept/refuse appointments
5. Confirm farmer attendance on delivery dates
6. Update zone capacity after deliveries

### System Admin's Management Workflow
1. Monitor system statistics
2. Manage user accounts (suspend/reactivate)
3. Create and configure warehouses
4. Manage grain types and pricing
5. Oversee appointment fulfillment
6. Handle system-wide operations

---

## 🔒 Security Features

- **Password Security**: Argon2 hashing with configurable iterations
- **Authentication**: JWT tokens with configurable expiration
- **Authorization**: Role-based access control on all endpoints
- **Data Validation**: Pydantic schemas for request validation
- **Error Handling**: Comprehensive error messages with appropriate HTTP status codes
- **CORS Protection**: Configurable cross-origin resource sharing
- **SQL Injection Prevention**: Parameterized queries via ORM
- **Secure Storage**: Sensitive data encrypted at rest in database

---

## 📊 Database Relationships

```
User (1) ──── (N) Warehouse (as manager)
User (1) ──── (N) Appointment (as farmer)

Warehouse (1) ──── (N) StorageZone
Warehouse (1) ──── (N) TimeSlotTemplate

StorageZone (1) ──── (N) Appointment
StorageZone (1) ──── (N) TimeSlot
StorageZone (N) ──── (1) Grain

TimeSlot (1) ──── (N) Appointment

Appointment (1) ──── (N) Delivery

Appointment (N) ──── (1) Grain
```

---

## 🚀 Deployment Architecture

The application is containerized using Docker Compose with the following services:
- **Backend API**: FastAPI application
- **Database**: PostgreSQL
- **Reverse Proxy**: Nginx
- **Cache**: Redis (optional)

All services communicate over internal Docker networks:
- `public_net`: External-facing services
- `private_net`: Internal service communication

---

## 📝 Notes

- The system operates with a PostgreSQL database for data persistence
- All timestamps are stored in UTC and converted to local timezone on the client side
- Geolocation features require GPS coordinate data (latitude/longitude)
- Automatic time slot generation runs as a background task
- The application supports concurrent user access with proper transaction handling

---

*Last Updated: January 6, 2026*
