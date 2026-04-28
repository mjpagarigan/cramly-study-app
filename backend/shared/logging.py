"""Structured JSON logging.

Render aggregates logs by line; JSON makes them queryable. Both services
should call `configure_logging()` once at startup.
"""

from __future__ import annotations

import logging
import sys

from pythonjsonlogger import jsonlogger

from .config import settings


def configure_logging() -> None:
    root = logging.getLogger()
    if root.handlers:
        # Avoid double-config when imported multiple times (uvicorn reloader, tests)
        return

    handler = logging.StreamHandler(sys.stdout)
    formatter = jsonlogger.JsonFormatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s",
        rename_fields={"asctime": "timestamp", "levelname": "level"},
    )
    handler.setFormatter(formatter)
    root.addHandler(handler)
    root.setLevel(settings.LOG_LEVEL)

    # Tame noisy libraries
    for noisy in ("urllib3", "httpx", "httpcore"):
        logging.getLogger(noisy).setLevel(logging.WARNING)


def get_logger(name: str) -> logging.LoggerAdapter:
    """Return a logger pre-bound with the service name for log filtering."""
    base = logging.getLogger(name)
    return logging.LoggerAdapter(base, {"service": settings.SERVICE_NAME})
