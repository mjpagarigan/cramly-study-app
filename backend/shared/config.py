"""Centralized settings, loaded from environment variables.

Both the API and worker import `settings` from here. Local dev reads from
backend/.env via python-dotenv (loaded in main entrypoints). On Render, env
vars are injected by the platform.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # Runtime
    ENV: Literal["development", "production"] = "development"
    LOG_LEVEL: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = "INFO"
    SERVICE_NAME: str = "cramly-api"

    # Firebase
    # Supply ONE of the two — path is preferred locally (no JSON-in-env escaping
    # mess), JSON string is required on Render.
    FIREBASE_SERVICE_ACCOUNT_PATH: str = Field(
        default="", description="Absolute path to the service-account JSON file"
    )
    FIREBASE_SERVICE_ACCOUNT_JSON: str = Field(
        default="", description="Service account JSON as single-line string"
    )
    FIREBASE_PROJECT_ID: str = "cramly-cd9b5"
    FIREBASE_STORAGE_BUCKET: str = "cramly-cd9b5.firebasestorage.app"

    # LLM
    GROQ_API_KEY: str = ""
    GROQ_MODEL: str = "openai/gpt-oss-120b"

    # TTS
    ELEVENLABS_API_KEY: str = ""

    # Worker
    WORKER_ID: str = ""
    WORKER_POLL_INTERVAL_SECONDS: float = 2.0
    WORKER_HEARTBEAT_INTERVAL_SECONDS: float = 30.0


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
