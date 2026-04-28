"""Per-format text extractors.

Each module exposes `extract(...) -> ExtractionResult`. The dispatcher in
`api/services/documents.py` picks the right extractor based on `sourceType`.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional


@dataclass
class ExtractionResult:
    """Common return shape for every extractor."""

    text: str
    page_count: Optional[int] = None  # PDF, PPTX
    word_count: int = 0

    def __post_init__(self) -> None:
        if not self.word_count and self.text:
            self.word_count = len(self.text.split())


class ExtractionError(Exception):
    """Raised when an extractor cannot process its input.

    Caller catches this and writes status='failed' with the message onto the
    Firestore document.
    """
