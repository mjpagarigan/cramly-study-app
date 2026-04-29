"""Markdown extraction.

Markdown is plain text by definition — no parsing required for our use case.
We just read the file as UTF-8 and pass it through. The LLM consumers handle
the rest (treating headings, lists, code fences as semantic structure).
"""

from __future__ import annotations

from . import ExtractionError, ExtractionResult


def extract(md_path: str) -> ExtractionResult:
    try:
        with open(md_path, "r", encoding="utf-8") as f:
            text = f.read()
    except UnicodeDecodeError:
        # Some editors save markdown as UTF-16 / Latin-1. Try a permissive fallback.
        try:
            with open(md_path, "r", encoding="utf-8", errors="replace") as f:
                text = f.read()
        except Exception as exc:
            raise ExtractionError(f"Could not decode markdown: {exc}") from exc
    except Exception as exc:
        raise ExtractionError(f"Could not open markdown file: {exc}") from exc

    if not text.strip():
        raise ExtractionError("Markdown file is empty")

    return ExtractionResult(text=text.strip())
