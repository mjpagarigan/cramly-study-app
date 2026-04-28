"""Pydantic schemas for documents.

Mirrors `users/{uid}/documents/{documentId}` per spec §5.1, with two extensions
to support URL-based sources (YouTube, web articles): `sourceType` and
`sourceUrl`. File-based sources still set fileName/fileSize/storagePath.
"""

from __future__ import annotations

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field, field_validator, model_validator

SourceType = Literal["pdf", "docx", "pptx", "image", "audio", "youtube", "web_url"]
DocumentStatus = Literal["uploading", "extracting", "ready", "failed"]


# Sources that originate from a Firebase Storage upload (vs. a URL fetch).
FILE_SOURCES: tuple[SourceType, ...] = ("pdf", "docx", "pptx", "image", "audio")


class GeneratedAssets(BaseModel):
    deckIds: list[str] = Field(default_factory=list)
    quizIds: list[str] = Field(default_factory=list)
    summaryIds: list[str] = Field(default_factory=list)
    studyGuideIds: list[str] = Field(default_factory=list)
    podcastIds: list[str] = Field(default_factory=list)


class DocumentCreate(BaseModel):
    courseId: str = Field(min_length=1)
    sourceType: SourceType
    title: Optional[str] = Field(default=None, max_length=200)

    # File sources only
    fileName: Optional[str] = Field(default=None, max_length=255)
    fileSize: Optional[int] = Field(default=None, ge=0)
    mimeType: Optional[str] = Field(default=None, max_length=100)
    storagePath: Optional[str] = Field(default=None, max_length=500)

    # URL sources only (YouTube, web_url)
    sourceUrl: Optional[str] = Field(default=None, max_length=2000)

    @field_validator("title")
    @classmethod
    def _strip_title(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        stripped = v.strip()
        return stripped or None

    @model_validator(mode="after")
    def _validate_source_combinations(self) -> "DocumentCreate":
        if self.sourceType in FILE_SOURCES:
            if not self.storagePath:
                raise ValueError(
                    f"sourceType={self.sourceType} requires storagePath"
                )
            if not self.fileName:
                raise ValueError(f"sourceType={self.sourceType} requires fileName")
        else:
            if not self.sourceUrl:
                raise ValueError(
                    f"sourceType={self.sourceType} requires sourceUrl"
                )
        return self


class DocumentRead(BaseModel):
    id: str
    courseId: str
    sourceType: SourceType
    title: str
    status: DocumentStatus

    # File metadata (nullable for URL sources)
    fileName: Optional[str] = None
    fileSize: Optional[int] = None
    mimeType: Optional[str] = None
    storagePath: Optional[str] = None

    # URL metadata (nullable for file sources)
    sourceUrl: Optional[str] = None

    # Extraction outputs
    pageCount: Optional[int] = None
    wordCount: int = 0
    extractedTextPath: Optional[str] = None
    errorMessage: Optional[str] = None

    generatedAssets: GeneratedAssets = Field(default_factory=GeneratedAssets)
    uploadedAt: Optional[datetime] = None
    extractedAt: Optional[datetime] = None
