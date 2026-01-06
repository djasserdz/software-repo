# Creating Admin Users

This document explains how to create warehouse admin and system admin users.

## Method 1: Using the Bash Script (Recommended)

Make sure your backend server is running, then execute:

```bash
cd backend
bash create_admin_users.sh
```

Or if your API is on a different URL:

```bash
API_BASE_URL=http://your-api-url/api bash create_admin_users.sh
```

## Method 2: Using Python Script with API

If you have `requests` installed:

```bash
cd backend
pip install requests  # if not already installed
python create_admin_users_api.py
```

## Method 3: Using Python Script Directly (Requires Backend Dependencies)

If you want to create users directly using the backend code:

```bash
cd backend
# Make sure you have all dependencies installed
pip install -r requirements.txt
python create_admin_users.py
```

## Method 4: Using curl Manually

### Create Warehouse Admin:
```bash
curl -X POST "http://localhost:8000/api/user/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Warehouse Admin",
    "email": "warehouse_admin@mahsoul.com",
    "password": "WarehouseAdmin123!",
    "role": "warehouse_admin",
    "phone": "1234567890",
    "address": "Warehouse Admin Address"
  }'
```

### Create System Admin:
```bash
curl -X POST "http://localhost:8000/api/user/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "System Admin",
    "email": "admin@mahsoul.com",
    "password": "Admin123!",
    "role": "admin",
    "phone": "0987654321",
    "address": "System Admin Address"
  }'
```

## Created Users

After running any of the above methods, you'll have:

### Warehouse Admin
- **Email**: `warehouse_admin@mahsoul.com`
- **Password**: `WarehouseAdmin123!`
- **Role**: `warehouse_admin`

### System Admin
- **Email**: `admin@mahsoul.com`
- **Password**: `Admin123!`
- **Role**: `admin`

## Login

You can now log in to the frontend using these credentials. The system will automatically redirect you to the appropriate dashboard based on your role:

- Warehouse Admin → `/warehouse-admin`
- System Admin → `/admin`
- Farmer → `/dashboard`

