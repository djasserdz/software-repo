from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


# Settings class that inherits from BaseSettings (extracts env variables)
class Settings(BaseSettings):
    # General project settings
    PROJECT_NAME: str
    DOMAIN_NAME: str

    TEAM_LIMIT: int = 4

    # Database connection settings
    POSTGRES_DB: str
    POSTGRES_HOST: str
    POSTGRES_PORT: int
    POSTGRES_USER: str
    POSTGRES_PASSWORD: SecretStr

    # Initial admin setup
    REDIS_HOST: str
    REDIS_PORT: int
    REDIS_PASSWORD: str

    SECRET_KEY: SecretStr
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int

    # Additional configuration for Pydantic settings
    model_config = SettingsConfigDict(
        case_sensitive=True,
    )


# Creating an instance of the Settings class to avoid env reprocessing
settings = Settings()  # type: ignore
