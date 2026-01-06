#!/bin/bash

# Script to create admin users via API
# Make sure the backend server is running before executing this script
# Run: bash create_admin_users.sh

API_BASE_URL="${API_BASE_URL:-http://localhost:8000/api}"

echo "Creating admin users via API..."
echo "=================================================="

# Warehouse Admin User
echo ""
echo "Creating Warehouse Admin..."
WAREHOUSE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/user/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Warehouse Admin",
    "email": "warehouse_admin@mahsoul.com",
    "password": "WarehouseAdmin123!",
    "role": "warehouse_admin",
    "phone": "1234567890",
    "address": "Warehouse Admin Address"
  }')

HTTP_CODE=$(echo "$WAREHOUSE_RESPONSE" | tail -n1)
BODY=$(echo "$WAREHOUSE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Warehouse Admin created successfully!"
    echo "$BODY" | grep -o '"email":"[^"]*"' | cut -d'"' -f4 | xargs -I {} echo "   Email: {}"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠️  Warehouse Admin user already exists"
else
    echo "❌ Error creating Warehouse Admin (HTTP $HTTP_CODE)"
    echo "$BODY"
fi

# System Admin User
echo ""
echo "Creating System Admin..."
SYSTEM_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/user/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "System Admin",
    "email": "admin@mahsoul.com",
    "password": "Admin123!",
    "role": "admin",
    "phone": "0987654321",
    "address": "System Admin Address"
  }')

HTTP_CODE=$(echo "$SYSTEM_RESPONSE" | tail -n1)
BODY=$(echo "$SYSTEM_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ System Admin created successfully!"
    echo "$BODY" | grep -o '"email":"[^"]*"' | cut -d'"' -f4 | xargs -I {} echo "   Email: {}"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠️  System Admin user already exists"
else
    echo "❌ Error creating System Admin (HTTP $HTTP_CODE)"
    echo "$BODY"
fi

echo ""
echo "=================================================="
echo "Summary:"
echo "=================================================="
echo ""
echo "Warehouse Admin Credentials:"
echo "  Email: warehouse_admin@mahsoul.com"
echo "  Password: WarehouseAdmin123!"
echo ""
echo "System Admin Credentials:"
echo "  Email: admin@mahsoul.com"
echo "  Password: Admin123!"
echo ""
echo "=================================================="

