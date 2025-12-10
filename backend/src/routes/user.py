from fastapi import APIRouter, Depends, HTTPException, status
from src.config.database import ConManager
from src.database.db import User
from sqlalchemy.ext.asyncio import AsyncSession
from src.models.user import (
    UserCreate,
    UserResponse,
    UserUpdate,
    UserLogin,
    LoginResponse,
)
from src.repositories.user import UserRepo
from src.services.user import UserService
from src.config.security import create_access_token, get_current_user
from typing import Optional

router = APIRouter()


@router.get("/", response_model=list[UserResponse], description="get all users")
async def get_all_users(session: AsyncSession = Depends(ConManager.get_session)):
    users = await UserService.list_all(session)
    return users


@router.post("/register", description="Register a user")
async def register(
    user_data: UserCreate, session: AsyncSession = Depends(ConManager.get_session)
):
    user = await UserService.register_user(user_data, session)
    token_data = {"user_id": user.user_id}
    token = create_access_token(token_data)
    return {"user": user, "token": token}


@router.get(
    "/me", description="get current authenticated user", response_model=UserResponse
)
async def current_user(current_user: User = Depends(get_current_user)):
    return current_user


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    user = await UserService.search_user(user_id, session)
    return user


@router.post("/login", description="login user", response_model=LoginResponse)
async def login(
    data: UserLogin, session: AsyncSession = Depends(ConManager.get_session)
):
    user = await UserService.login_user(data, session)
    if user:
        token_data = {"user_id": user.user_id}
        token = create_access_token(token_data)
        return {"user": user, "token": token}


@router.post(
    "/suspend/{user_id}", description="suspend a user", response_model=UserResponse
)
async def suspend_user(
    user_id: int, reason: str, session: AsyncSession = Depends(ConManager.get_session)
):
    user = await UserService.suspend_user(session, user_id, reason=reason)
    return user


@router.post("/unsuspend", description="unsuspend a user", response_model=UserResponse)
async def unsuspend_user(
    user_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    user = await UserService.unsuspend_user(session, user_id)
    return user
