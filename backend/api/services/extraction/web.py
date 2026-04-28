"""Web article extraction via trafilatura.

trafilatura is purpose-built for clean article extraction (drops nav, ads,
related-content sidebars). Returns the article body + a derived title.
"""

from __future__ import annotations

from . import ExtractionError, ExtractionResult


def extract(url: str) -> tuple[ExtractionResult, str | None]:
    """Returns (result, derived_title). Title is used as the document name."""
    try:
        import trafilatura
    except ImportError as exc:
        raise ExtractionError(f"trafilatura not installed: {exc}") from exc

    raw = trafilatura.fetch_url(url)
    if raw is None:
        raise ExtractionError(
            f"Could not fetch URL (network error or 4xx/5xx): {url}"
        )

    text = trafilatura.extract(
        raw,
        include_comments=False,
        include_tables=True,
        no_fallback=False,
    )
    if not text or not text.strip():
        raise ExtractionError(
            "Could not extract readable article body — the page may be JS-rendered "
            "or paywalled."
        )

    title: str | None = None
    try:
        meta = trafilatura.extract_metadata(raw)
        if meta is not None:
            title = (meta.title or "").strip() or None
    except Exception:
        # Metadata failure is non-fatal; we just won't have a derived title.
        title = None

    return ExtractionResult(text=text.strip()), title
