"""Pydantic schemas for decks and cards."""

from __future__ import annotations

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field, field_validator

DeckGenerationMethod = Literal["ai", "manual"]
DeckStatus = Literal["queued", "generating", "ready", "failed"]


class CardSrs(BaseModel):
    easeFactor: float = 2.5
    interval: int = 0
    repetitions: int = 0
    nextReviewDate: datetime | None = None
    lastReviewedAt: datetime | None = None


class CardStats(BaseModel):
    timesShown: int = 0
    timesCorrect: int = 0
    timesWrong: int = 0


class CardCreate(BaseModel):
    front: str = Field(min_length=1, max_length=300)
    back: str = Field(min_length=1, max_length=2000)
    hint: Optional[str] = Field(default=None, max_length=500)
    explanation: Optional[str] = Field(default=None, max_length=2000)
    topic: Optional[str] = Field(default=None, max_length=120)

    @field_validator("front", "back", "hint", "explanation", "topic")
    @classmethod
    def _strip_strings(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None


class CardUpdate(BaseModel):
    front: Optional[str] = Field(default=None, min_length=1, max_length=300)
    back: Optional[str] = Field(default=None, min_length=1, max_length=2000)
    hint: Optional[str] = Field(default=None, max_length=500)
    explanation: Optional[str] = Field(default=None, max_length=2000)
    topic: Optional[str] = Field(default=None, max_length=120)

    @field_validator("front", "back", "hint", "explanation", "topic")
    @classmethod
    def _strip_strings(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None


class CardRead(BaseModel):
    id: str
    front: str
    back: str
    hint: Optional[str] = None
    explanation: Optional[str] = None
    topic: Optional[str] = None
    srs: CardSrs = Field(default_factory=CardSrs)
    stats: CardStats = Field(default_factory=CardStats)
    createdAt: datetime | None = None


class DeckCreate(BaseModel):
    courseId: str = Field(min_length=1)
    title: str = Field(min_length=1, max_length=200)
    description: Optional[str] = Field(default=None, max_length=500)
    sourceDocumentId: Optional[str] = Field(default=None, max_length=100)

    @field_validator("title", "description", "sourceDocumentId")
    @classmethod
    def _strip_strings(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None


class DeckUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=200)
    description: Optional[str] = Field(default=None, max_length=500)

    @field_validator("title", "description")
    @classmethod
    def _strip_strings(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None


class DeckRead(BaseModel):
    id: str
    courseId: str
    sourceDocumentId: Optional[str] = None
    title: str
    description: str = ""
    cardCount: int = 0
    generationMethod: DeckGenerationMethod = "manual"
    status: DeckStatus = "ready"
    jobId: Optional[str] = None
    errorMessage: Optional[str] = None
    createdAt: datetime | None = None
    updatedAt: datetime | None = None
    cards: list[CardRead] = Field(default_factory=list)
