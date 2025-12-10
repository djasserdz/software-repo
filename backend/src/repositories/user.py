from typing import Optional, List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from sqlalchemy.exc import IntegrityError
from fastapi import status
import logging

from src.database.db import User
from src.models.user import UserCreate, UserRole
from src.HTTPBaseException import HTTPBaseException

logger = logging.getLogger(__name__)


class UserRepo:
    class UserNotFound(HTTPBaseException):
        code = status.HTTP_404_NOT_FOUND
        message = "User not found"

    class Suspended(HTTPBaseException):
        code = status.HTTP_401_UNAUTHORIZED
        message = "Your Account Has been Suspended"

    class EmailExist(HTTPBaseException):
        code = status.HTTP_409_CONFLICT
        message = "Email already in use"

    class CreateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to create user"

    class GetError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get user"

    class GetAllError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to get all users"

    class UpdateError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to update user"

    class SoftDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to soft delete user"

    class HardDeleteError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to hard delete user"

    class SuspendError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to suspend user"

    class UnsuspendError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to unsuspend user"

    class VerifyEmailError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to verify user email"

    class CountError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to count users"

    class ExistsError(HTTPBaseException):
        code = status.HTTP_500_INTERNAL_SERVER_ERROR
        message = "Failed to check user existence"

    @staticmethod
    async def create(session: AsyncSession, user_data: dict, commit: bool) -> User:
        try:
            user_data["account_status"] = True

            orm_user = User(**user_data)
            session.add(orm_user)
            if commit:
                await session.commit()
            else:
                await session.flush()
            await session.refresh(orm_user)
            return orm_user
        except IntegrityError as e:
            await session.rollback()

            error_msg = str(e).lower()

            if "email" in error_msg:
                raise UserRepo.EmailExist()

            logger.exception(f"❌ Integrity error : {error_msg}")
            raise UserRepo.CreateError()
        except Exception as e:
            await session.rollback()
            logger.exception(f"❌ Failed to create user Error : {e}")
            raise UserRepo.CreateError()

    @staticmethod
    async def get_by_id(session: AsyncSession, user_id: int) -> Optional[User]:
        try:
            stmt = select(User).where(
                User.user_id == user_id, User.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            user = result.scalar_one_or_none()
            if user is None:
                raise UserRepo.UserNotFound()
            return user
        except UserRepo.UserNotFound:
            raise
        except Exception as e:
            logger.exception(f"❌ Failed to get user Error : {e}")
            raise UserRepo.GetError()

    @staticmethod
    async def get_by_email(session: AsyncSession, email: str) -> Optional[User]:
        try:
            stmt = select(User).where(User.email == email, User.deleted_at.is_(None))
            result = await session.execute(stmt)
            user = result.scalar_one_or_none()
            if user is None:
                raise UserRepo.UserNotFound()
            return user
        except UserRepo.UserNotFound:
            raise
        except Exception as e:
            logger.exception(f"❌ Failed to get user Error : {e}")
            raise UserRepo.GetError()

    @staticmethod
    async def get_all(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 100,
        role: Optional[UserRole] = None,
        account_status: bool = None,
    ) -> List[User]:
        try:
            stmt = select(User).where(User.deleted_at.is_(None))

            if role:
                stmt = stmt.where(User.role == role)

            if account_status:
                stmt = stmt.where(User.account_status == account_status)

            stmt = stmt.offset(skip).limit(limit).order_by(User.created_at.desc())

            result = await session.execute(stmt)
            return list(result.scalars().all())
        except Exception as e:
            logger.exception(f"❌ Failed to get users Error : {e}")
            raise UserRepo.GetAllError()

    @staticmethod
    async def update(
        session: AsyncSession, user_id: int, commit: bool, **kwargs
    ) -> Optional[User]:
        try:
            kwargs["updated_at"] = datetime.utcnow()

            stmt = (
                update(User)
                .where(User.user_id == user_id, User.deleted_at.is_(None))
                .values(**kwargs)
                .returning(User)
            )

            result = await session.execute(stmt)
            if commit:
                await session.commit()
            else:
                await session.flush()

            updated = result.scalar_one_or_none()
            if updated is None:
                raise UserRepo.UserNotFound()
            return updated
        except IntegrityError:
            await session.rollback()
            raise UserRepo.EmailExist()
        except UserRepo.UserNotFound:
            raise
        except Exception as e:
            await session.rollback()
            logger.exception(f"❌ Failed to update user Error : {e}")
            raise UserRepo.UpdateError()

    @staticmethod
    async def soft_delete(session: AsyncSession, user_id: int, commit: bool) -> bool:
        try:
            stmt = (
                update(User)
                .where(User.user_id == user_id, User.deleted_at.is_(None))
                .values(deleted_at=datetime.utcnow())
            )

            result = await session.execute(stmt)
            if commit:
                await session.commit()
            else:
                await session.flush()

            return result.rowcount > 0
        except Exception as e:
            await session.rollback()
            logger.exception(f"❌ Failed to delete user Error : {e}")
            raise UserRepo.SoftDeleteError()

    @staticmethod
    async def hard_delete(session: AsyncSession, user_id: int, commit: bool) -> bool:
        try:
            stmt = delete(User).where(User.user_id == user_id)

            result = await session.execute(stmt)
            if commit:
                await session.commit()
            else:
                await session.flush()

            return result.rowcount > 0
        except Exception:
            await session.rollback()
            raise UserRepo.HardDeleteError()

    @staticmethod
    async def suspend(
        session: AsyncSession, user_id: int, reason: str
    ) -> Optional[User]:
        try:
            return await UserRepo.update(
                session,
                user_id,
                commit=True,
                account_status=False,
                suspended_at=datetime.utcnow(),
                suspended_reason=reason,
            )
        except UserRepo.UserNotFound:
            raise
        except Exception as e:
            logger.exception(f"❌ Failed to suspend user Error : {e}")
            raise UserRepo.SuspendError()

    @staticmethod
    async def unsuspend(session: AsyncSession, user_id: int) -> Optional[User]:
        try:
            return await UserRepo.update(
                session,
                user_id,
                commit=True,
                account_status=True,
                suspended_at=None,
                suspended_reason=None,
            )
        except UserRepo.UserNotFound:
            raise
        except Exception as e:
            logger.exception(f"❌ Failed to unsuspend user Error : {e}")
            raise UserRepo.UnsuspendError()

    @staticmethod
    async def verify_email(session: AsyncSession, user_id: int) -> Optional[User]:
        try:
            return await UserRepo.update(
                session, user_id, email_verified_at=datetime.utcnow()
            )
        except UserRepo.UserNotFound:
            raise
        except Exception:
            raise UserRepo.VerifyEmailError()

    @staticmethod
    async def count(
        session: AsyncSession,
        role: Optional[UserRole] = None,
        account_status: bool = None,
    ) -> int:
        try:
            stmt = select(func.count(User.user_id)).where(User.deleted_at.is_(None))

            if role:
                stmt = stmt.where(User.role == role)

            if account_status:
                stmt = stmt.where(User.account_status == account_status)

            result = await session.execute(stmt)
            return result.scalar_one()
        except Exception:
            raise UserRepo.CountError()

    @staticmethod
    async def exists(session: AsyncSession, user_id: int) -> bool:
        """Check if user exists"""
        try:
            stmt = select(User.user_id).where(
                User.user_id == user_id, User.deleted_at.is_(None)
            )
            result = await session.execute(stmt)
            return result.scalar_one_or_none() is not None
        except Exception:
            raise UserRepo.ExistsError()
