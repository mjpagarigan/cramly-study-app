"""Cramly FastAPI service entrypoint.

Run from the `backend/` directory:
    uvicorn api.main:app --reload --port 8000

In production (Render), `rootDir: backend` puts us in the right cwd:
    uvicorn api.main:app --host 0.0.0.0 --port $PORT
"""

from __future__ import annotations

import time
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Load .env before importing settings-dependent modules
load_dotenv()

from shared.config import settings  # noqa: E402
from shared.logging import configure_logging, get_logger  # noqa: E402

configure_logging()
logger = get_logger(__name__)

from api.routers import courses as courses_router  # noqa: E402
from api.routers import documents as documents_router  # noqa: E402

START_TIME = time.monotonic()
API_VERSION = "0.1.0"


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("api_startup", extra={"env": settings.ENV, "version": API_VERSION})
    yield
    logger.info("api_shutdown")


app = FastAPI(
    title="Cramly API",
    version=API_VERSION,
    lifespan=lifespan,
)

# CORS: Flutter mobile clients don't send Origin, but local web debug builds do.
# Tighten this once we know the dev/prod web origins (if any).
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO(sprint-2): restrict to known origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health() -> dict:
    return {
        "status": "ok",
        "version": API_VERSION,
        "uptime_seconds": round(time.monotonic() - START_TIME, 2),
        "env": settings.ENV,
    }


app.include_router(courses_router.router)
app.include_router(documents_router.router)
