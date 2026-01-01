from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.repositories.user import UserRepo
from src.models.user import UserCreate, UserUpdate, UserLogin
from src.utils.password import hash_password, generate_salt, verify_password


class UserService:
    @staticmethod
    async def register_user(user_data: UserCreate, session: AsyncSession):
        import logging
        logger = logging.getLogger("user_service")
        
        try:
            logger.info(f"🔵 Starting registration for email: {user_data.email}")
            
            # Check if email already exists
            try:
                existing_user = await UserRepo.get_by_email(session, user_data.email)
                if existing_user:
                    logger.warning(f"⚠️ Email already exists: {user_data.email}")
                    raise UserRepo.EmailExist()
            except UserRepo.UserNotFound:
                # Email doesn't exist, which is what we want
                pass
            except UserRepo.EmailExist:
                raise
            except Exception as e:
                logger.error(f"❌ Error checking email existence: {e}")
                raise
            
            salt = generate_salt()
            hashed_password = hash_password(user_data.password + salt)

            user_dict = user_data.model_dump()
            user_dict["password"] = hashed_password
            user_dict["salt"] = salt
            
            # Ensure phone and address have default values if None (database requires non-null)
            if not user_dict.get("phone"):
                user_dict["phone"] = ""
            if not user_dict.get("address"):
                user_dict["address"] = ""

            logger.debug(f"Creating user with data keys: {list(user_dict.keys())}")
            user = await UserRepo.create(session, user_dict, commit=True)
            logger.info(f"✅ User created successfully: user_id={user.user_id}, email={user.email}")
            return user
        except UserRepo.EmailExist:
            logger.warning(f"⚠️ Registration failed - email already exists: {user_data.email}")
            raise
        except Exception as e:
            logger.error(f"❌ Registration failed for email: {user_data.email} | Error: {str(e)}", exc_info=True)
            raise

    @staticmethod
    async def login_user(user_data: UserLogin, session: AsyncSession):
        user = await UserRepo.get_by_email(session, user_data.email)
        if user.account_status == False:
            raise UserRepo.Suspended()
        input_with_salt = user_data.password + user.salt

        if verify_password(input_with_salt, user.password):
            return user

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )

    @staticmethod
    async def search_user(user_id: int, session: AsyncSession):
        return await UserRepo.get_by_id(session, user_id)

    @staticmethod
    async def update_user(user_id: int, user_data: UserUpdate, session: AsyncSession):
        update_data = user_data.model_dump(exclude_unset=True)
        return await UserRepo.update(session, user_id, commit=True, **update_data)

    @staticmethod
    async def list_all(session: AsyncSession):
        return await UserRepo.get_all(session)

    @staticmethod
    async def delete_user(session: AsyncSession, user_id: int):
        deleted = await UserRepo.soft_delete(session, user_id, commit=True)
        if not deleted:
            raise UserRepo.UserNotFound()
        return True

    @staticmethod
    async def suspend_user(session: AsyncSession, user_id: int, reason: str):
        return await UserRepo.suspend(session, user_id, reason)

    @staticmethod
    async def unsuspend_user(session: AsyncSession, user_id: int):
        return await UserRepo.unsuspend(session, user_id)

    @staticmethod
    async def change_password(
        user_id: int,
        current_password: str,
        new_password: str,
        session: AsyncSession,
    ):
        """Change user password"""
        user = await UserRepo.get_by_id(session, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        # Verify current password
        input_with_salt = current_password + user.salt
        if not verify_password(input_with_salt, user.password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Current password is incorrect",
            )

        # Hash new password
        salt = generate_salt()
        hashed_password = hash_password(new_password + salt)

        # Update password
        updated_user = await UserRepo.update(
            session, user_id, password=hashed_password, salt=salt, commit=True
        )
        return updated_user
