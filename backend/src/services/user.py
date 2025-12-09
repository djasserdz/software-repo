from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.repositories.user import UserRepo
from src.models.user import UserCreate, UserUpdate, UserLogin
from src.utils.password import hash_password, generate_salt, verify_password


class UserService:
    @staticmethod
    async def register_user(user_data: UserCreate, session: AsyncSession):
        salt = generate_salt()
        hashed_password = hash_password(user_data.password + salt)

        user_dict = user_data.model_dump()
        user_dict["password"] = hashed_password
        user_dict["salt"] = salt

        user = await UserRepo.create(session, user_dict,commit=True)
        return user

    @staticmethod
    async def login_user(user_data: UserLogin, session: AsyncSession):
     user = await UserRepo.get_by_email(session, user_data.email)
     if user.account_status == False:
        raise UserRepo.Suspended()  
     input_with_salt = user_data.password + user.salt
 
     if verify_password(input_with_salt, user.password):
         return user
 
     raise HTTPException(
         status_code=status.HTTP_401_UNAUTHORIZED,
         detail="Invalid credentials"
     )

    @staticmethod
    async def search_user(user_id: int, session: AsyncSession):
        return await UserRepo.get_by_id(session, user_id)

    @staticmethod
    async def update_user(user_id: int, user_data: UserUpdate, session: AsyncSession):
        update_data = user_data.model_dump(exclude_unset=True)
        return await UserRepo.update(session, user_id, **update_data)

    @staticmethod
    async def list_all(session: AsyncSession):
        return await UserRepo.get_all(session)

    @staticmethod
    async def delete_user(session: AsyncSession, user_id: int):
        deleted = await UserRepo.soft_delete(session, user_id,commit=True)
        if not deleted:
            raise UserRepo.UserNotFound()
        return True

    @staticmethod
    async def suspend_user(session: AsyncSession, user_id: int, reason: str):
        return await UserRepo.suspend(session, user_id, reason)

    @staticmethod
    async def unsuspend_user(session: AsyncSession, user_id: int):
        return await UserRepo.unsuspend(session, user_id)
