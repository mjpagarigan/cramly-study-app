"""Pydantic schemas for generated summaries."""

from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel

SummaryDepth = Literal["tldr", "detailed", "eli5"]
SummaryStatus = Literal["queued", "generating", "ready", "failed"]


class SummaryRead(BaseModel):
    id: str
    courseId: str
    sourceDocumentId: str
    depth: SummaryDepth
    status: SummaryStatus = "queued"
    content: str = ""
    jobId: str | None = None
    errorMessage: str | None = None
    createdAt: datetime | None = None
    updatedAt: datetime | None = None
