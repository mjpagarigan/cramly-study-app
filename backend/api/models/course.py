"""Pydantic schemas for the courses resource.

Mirrors the Firestore shape under `users/{uid}/courses/{courseId}` (spec §5.1).
The Flutter client reads via Firestore listeners directly; these schemas only
shape the create/update/return payloads on the FastAPI side.
"""

from __future__ import annotations

import re
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, field_validator

# Hex color, 3- or 6-digit, '#' optional.
_HEX_RE = re.compile(r"^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$")


def _normalize_hex(value: str) -> str:
    """Always return a 7-character `#RRGGBB`."""
    if not _HEX_RE.match(value):
        raise ValueError("color must be a hex string like '#E8A84C'")
    cleaned = value.lstrip("#")
    if len(cleaned) == 3:
        cleaned = "".join(ch * 2 for ch in cleaned)
    return f"#{cleaned.upper()}"


class CourseCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    color: str = Field(default="#E8A84C")
    icon: Optional[str] = Field(default=None, max_length=64)

    @field_validator("name")
    @classmethod
    def _strip_name(cls, v: str) -> str:
        stripped = v.strip()
        if not stripped:
            raise ValueError("name is required")
        return stripped

    @field_validator("color")
    @classmethod
    def _normalize_color(cls, v: str) -> str:
        return _normalize_hex(v)


class CourseUpdate(BaseModel):
    """All fields optional — sent in PATCH bodies."""

    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    color: Optional[str] = None
    icon: Optional[str] = Field(default=None, max_length=64)

    @field_validator("name")
    @classmethod
    def _strip_name(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        stripped = v.strip()
        if not stripped:
            raise ValueError("name cannot be empty")
        return stripped

    @field_validator("color")
    @classmethod
    def _normalize_color(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        return _normalize_hex(v)


class CourseRead(BaseModel):
    id: str
    name: str
    color: str
    icon: Optional[str] = None
    documentCount: int = 0
    deckCount: int = 0
    quizCount: int = 0
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None
