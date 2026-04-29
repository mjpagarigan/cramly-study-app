"""Pydantic schemas for async jobs."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field

JobType = Literal[
    "text_extraction",
    "flashcards_gen",
    "quiz_gen",
    "summary_gen",
    "study_guide_gen",
    "podcast_gen",
]
JobStatus = Literal["queued", "processing", "completed", "failed"]


class JobRead(BaseModel):
    id: str
    type: JobType
    status: JobStatus
    progress: int = Field(default=0, ge=0, le=100)
    inputRefs: dict[str, Any] = Field(default_factory=dict)
    outputRefs: dict[str, Any] = Field(default_factory=dict)
    errorMessage: str | None = None
    workerId: str | None = None
    attemptCount: int = 0
    maxAttempts: int = 3
    dependsOnJobId: str | None = None
    retryAt: datetime | None = None
    createdAt: datetime | None = None
    startedAt: datetime | None = None
    completedAt: datetime | None = None
