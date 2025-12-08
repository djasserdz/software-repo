import asyncpg
from sqlmodel import SQLModel
from src.config.settings import settings

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

RED = "\033[31m"
GREEN = "\033[32m"
BLUE = "\033[34m"
YELLOW = "\033[33m"
RESET = "\033[0m"


class Database:
    BASE_URL = f"postgresql://{settings.POSTGRES_USER}:{settings.POSTGRES_PASSWORD.get_secret_value()}@{settings.POSTGRES_HOST}:{settings.POSTGRES_PORT}"
    SQLALCHEMY_URL = f"postgresql+asyncpg://{settings.POSTGRES_USER}:{settings.POSTGRES_PASSWORD.get_secret_value()}@{settings.POSTGRES_HOST}:{settings.POSTGRES_PORT}"

    @staticmethod
    async def create_db(db_name: str = settings.POSTGRES_DB) -> None:
        conn = await asyncpg.connect(f"{Database.BASE_URL}/postgres")
        dbs = await conn.fetch("SELECT 1 FROM pg_database WHERE datname=$1", db_name)
        if not dbs:
            print(
                f"{YELLOW}[WARNING]{RESET} M: Database {db_name} does not exist. Creating it..."
            )
            await conn.execute(f'CREATE DATABASE "{db_name}";')
        else:
            print(f"{GREEN}[SUCCESS]{RESET} M: Database {db_name} already exists.")

        await conn.close()

        return

    @staticmethod
    async def init_db():
        engine = create_async_engine(
            f"{Database.SQLALCHEMY_URL}/{settings.POSTGRES_DB}"
        )
        async with engine.begin() as conn:
            await conn.run_sync(SQLModel.metadata.create_all)
        await engine.dispose()


class ConManager:
    _engine = None

    @staticmethod
    async def get_engine(db_name: str = settings.POSTGRES_DB):
        if ConManager._engine is None:
            if ConManager._engine is None:
                DATABASE_URL = (
                    f"postgresql+asyncpg://{settings.POSTGRES_USER}:{settings.POSTGRES_PASSWORD.get_secret_value()}"
                    f"@{settings.POSTGRES_HOST}:{settings.POSTGRES_PORT}/{db_name}"
                )
                print(
                    f"{BLUE}[INFO]{RESET} Initializing SQLModel engine for DB: {db_name} ..."
                )
                ConManager._engine = create_async_engine(DATABASE_URL, echo=True)
        return ConManager._engine

    @staticmethod
    async def get_session() -> AsyncSession:
        engine = await ConManager.get_engine(settings.POSTGRES_DB)
        print(
            f"{BLUE}[INFO]{RESET} Creating a new SQLModel session for DB: {settings.POSTGRES_DB} ..."
        )
        async with AsyncSession(
            engine, expire_on_commit=False
        ) as session:  # ← Add expire_on_commit=False
            yield session
