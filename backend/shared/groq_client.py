"""Thin wrapper around the Groq SDK.

Centralizing client creation here keeps API keys out of route handlers and
gives us a single place to add retries, timeouts, and prompt-caching headers
later. Not called yet in Sprint 1 — wired in Sprint 4 when the worker starts
making LLM calls.
"""

from __future__ import annotations

from functools import lru_cache

from groq import Groq

from .config import settings
from .logging import get_logger

logger = get_logger(__name__)


@lru_cache(maxsize=1)
def get_groq_client() -> Groq:
    if not settings.GROQ_API_KEY:
        raise RuntimeError("GROQ_API_KEY is empty. Set it in your .env or Render env vars.")
    return Groq(api_key=settings.GROQ_API_KEY)
