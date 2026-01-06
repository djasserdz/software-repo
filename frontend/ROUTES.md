# Application Routes

This document lists all available routes in the application, organized by user role and functionality.

## Public Routes

| Path | Name | Component | Description |
|------|------|-----------|-------------|
| `/login` | Login | Login.vue | User login page |
| `/register` | Register | Register.vue | User registration page |

## Common Routes (All Authenticated Users)

| Path | Name | Component | Description |
|------|------|-----------|-------------|
| `/` | - | - | Redirects to `/dashboard` |
| `/dashboard` | Dashboard | Dashboard.vue | Farmer dashboard (redirects for other roles) |
| `/warehouses` | Warehouses | Warehouses.vue | Browse all warehouses |
| `/warehouses/:id` | WarehouseDetail | WarehouseDetail.vue | View warehouse details |
| `/appointments` | Appointments | Appointments.vue | View appointments |
| `/appointments/book` | BookAppointment | BookAppointment.vue | Book a new appointment (Farmers only) |
| `/deliveries` | Deliveries | Deliveries.vue | View deliveries |
| `/profile` | Profile | Profile.vue | User profile management |

## System Admin Routes (`requiresAdmin: true`)

| Path | Name | Component | Description |
|------|------|-----------|-------------|
| `/admin` | AdminDashboard | AdminDashboard.vue | System admin dashboard |
| `/admin/users` | AdminUsers | AdminUsers.vue | Manage all users (suspend/unsuspend) |
| `/admin/warehouses` | AdminWarehouses | AdminWarehouses.vue | Manage all warehouses (create/edit) |
| `/admin/grains` | AdminGrains | AdminGrains.vue | Manage grain types (create/edit/delete) |
| `/admin/appointments` | AdminAppointments | AdminAppointments.vue | View all appointments in the system |

## Warehouse Admin Routes (`requiresWarehouseAdmin: true`)

| Path | Name | Component | Description |
|------|------|-----------|-------------|
| `/warehouse-admin` | WarehouseAdminDashboard | WarehouseAdminDashboard.vue | Warehouse admin dashboard |
| `/warehouse-admin/warehouses` | WarehouseAdminWarehouses | WarehouseAdminWarehouses.vue | View assigned warehouses |
| `/warehouse-admin/zones` | WarehouseAdminZones | WarehouseAdminZones.vue | Manage storage zones (create/edit) |
| `/warehouse-admin/timeslots` | WarehouseAdminTimeSlots | WarehouseAdminTimeSlots.vue | Manage time slots (create/edit/delete/generate) |
| `/warehouse-admin/appointments` | WarehouseAdminAppointments | WarehouseAdminAppointments.vue | Manage appointments (confirm attendance) |

## Route Protection

Routes are protected using route meta properties:

- **`requiresAuth: true`** - Requires user to be authenticated
- **`requiresGuest: true`** - Requires user to NOT be authenticated (redirects if logged in)
- **`requiresAdmin: true`** - Requires user role to be `admin`
- **`requiresWarehouseAdmin: true`** - Requires user role to be `warehouse_admin`

## Navigation Flow

### On Login:
- **Admin** → Redirects to `/admin`
- **Warehouse Admin** → Redirects to `/warehouse-admin`
- **Farmer** → Redirects to `/dashboard`

### Access Control:
- Users without the required role are redirected to their dashboard
- Unauthenticated users are redirected to `/login` with a redirect query parameter

## Quick Reference

### Admin Navigation:
- Dashboard: `/admin`
- Users: `/admin/users`
- Warehouses: `/admin/warehouses`
- Grains: `/admin/grains`
- Appointments: `/admin/appointments`

### Warehouse Admin Navigation:
- Dashboard: `/warehouse-admin`
- Warehouses: `/warehouse-admin/warehouses`
- Zones: `/warehouse-admin/zones`
- Time Slots: `/warehouse-admin/timeslots`
- Appointments: `/warehouse-admin/appointments`

### Farmer Navigation:
- Dashboard: `/dashboard`
- Warehouses: `/warehouses`
- Book Appointment: `/appointments/book`
- My Appointments: `/appointments`
- Deliveries: `/deliveries`

