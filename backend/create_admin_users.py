"""
Script to create admin users (warehouse admin and system admin)
Run this script from the backend directory: python create_admin_users.py
"""
import asyncio
import sys
from pathlib import Path

# Add the src directory to the path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from src.config.database import ConManager, Database
from src.models.user import UserCreate, UserRole
from src.services.user import UserService
from src.repositories.user import UserRepo


async def create_admin_users():
    """Create warehouse admin and system admin users"""
    
    # Initialize database connection
    await Database.create_db()
    await Database.init_db()
    
    # Get session from context manager
    async for session in ConManager.get_session():
        try:
            # Warehouse Admin User
            warehouse_admin_data = UserCreate(
                name="Warehouse Admin",
                email="warehouse_admin@mahsoul.com",
                password="WarehouseAdmin123!",
                role=UserRole.WAREHOUSE_ADMIN,
                phone="1234567890",
                address="Warehouse Admin Address"
            )
            
            try:
                warehouse_admin = await UserService.register_user(warehouse_admin_data, session)
                print(f"✅ Warehouse Admin created successfully!")
                print(f"   Email: {warehouse_admin.email}")
                print(f"   User ID: {warehouse_admin.user_id}")
                print(f"   Role: {warehouse_admin.role}")
            except UserRepo.EmailExist:
                print(f"⚠️  Warehouse Admin user already exists (email: {warehouse_admin_data.email})")
            except Exception as e:
                print(f"❌ Error creating Warehouse Admin: {e}")
                raise
            
            # System Admin User
            system_admin_data = UserCreate(
                name="System Admin",
                email="admin@mahsoul.com",
                password="Admin123!",
                role=UserRole.ADMIN,
                phone="0987654321",
                address="System Admin Address"
            )
            
            try:
                system_admin = await UserService.register_user(system_admin_data, session)
                print(f"\n✅ System Admin created successfully!")
                print(f"   Email: {system_admin.email}")
                print(f"   User ID: {system_admin.user_id}")
                print(f"   Role: {system_admin.role}")
            except UserRepo.EmailExist:
                print(f"⚠️  System Admin user already exists (email: {system_admin_data.email})")
            except Exception as e:
                print(f"❌ Error creating System Admin: {e}")
                raise
            
            print("\n" + "="*50)
            print("Summary:")
            print("="*50)
            print("\nWarehouse Admin Credentials:")
            print(f"  Email: {warehouse_admin_data.email}")
            print(f"  Password: {warehouse_admin_data.password}")
            print("\nSystem Admin Credentials:")
            print(f"  Email: {system_admin_data.email}")
            print(f"  Password: {system_admin_data.password}")
            print("\n" + "="*50)
            
        except Exception as e:
            print(f"❌ Fatal error: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)


if __name__ == "__main__":
    print("Creating admin users...")
    print("="*50)
    asyncio.run(create_admin_users())

