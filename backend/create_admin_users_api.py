"""
Script to create admin users via API
Make sure the backend server is running before executing this script.
Run: python create_admin_users_api.py
"""
import requests
import sys

API_BASE_URL = "http://localhost:8000/api"  # Adjust if your API is on a different URL

def create_user(user_data):
    """Create a user via the API"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/user/register",
            json=user_data
        )
        
        if response.status_code == 200 or response.status_code == 201:
            return response.json()
        elif response.status_code == 409:
            print(f"⚠️  User already exists: {user_data['email']}")
            return None
        else:
            print(f"❌ Error creating user {user_data['email']}: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to the API. Make sure the backend server is running.")
        print(f"   Attempted URL: {API_BASE_URL}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        return None


def main():
    print("Creating admin users via API...")
    print("="*50)
    
    # Warehouse Admin User
    warehouse_admin_data = {
        "name": "Warehouse Admin",
        "email": "warehouse_admin@mahsoul.com",
        "password": "WarehouseAdmin123!",
        "role": "warehouse_admin",
        "phone": "1234567890",
        "address": "Warehouse Admin Address"
    }
    
    print("\nCreating Warehouse Admin...")
    warehouse_result = create_user(warehouse_admin_data)
    if warehouse_result:
        user = warehouse_result.get('user', {})
        print(f"✅ Warehouse Admin created successfully!")
        print(f"   Email: {user.get('email', warehouse_admin_data['email'])}")
        print(f"   User ID: {user.get('user_id', 'N/A')}")
        print(f"   Role: {user.get('role', warehouse_admin_data['role'])}")
    
    # System Admin User
    system_admin_data = {
        "name": "System Admin",
        "email": "admin@mahsoul.com",
        "password": "Admin123!",
        "role": "admin",
        "phone": "0987654321",
        "address": "System Admin Address"
    }
    
    print("\nCreating System Admin...")
    system_result = create_user(system_admin_data)
    if system_result:
        user = system_result.get('user', {})
        print(f"✅ System Admin created successfully!")
        print(f"   Email: {user.get('email', system_admin_data['email'])}")
        print(f"   User ID: {user.get('user_id', 'N/A')}")
        print(f"   Role: {user.get('role', system_admin_data['role'])}")
    
    print("\n" + "="*50)
    print("Summary:")
    print("="*50)
    print("\nWarehouse Admin Credentials:")
    print(f"  Email: {warehouse_admin_data['email']}")
    print(f"  Password: {warehouse_admin_data['password']}")
    print("\nSystem Admin Credentials:")
    print(f"  Email: {system_admin_data['email']}")
    print(f"  Password: {system_admin_data['password']}")
    print("\n" + "="*50)


if __name__ == "__main__":
    main()

