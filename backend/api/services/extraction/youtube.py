"""YouTube transcript extraction via youtube-transcript-api.

Pulls the auto-generated or human captions for a video. Region-locked or
captions-disabled videos fail with a clear error.
"""

from __future__ import annotations

import re
from urllib.parse import parse_qs, urlparse

from . import ExtractionError, ExtractionResult

# Matches v=ID, /shorts/ID, /embed/ID, /v/ID, youtu.be/ID — the common forms.
_VIDEO_ID_RE = re.compile(r"^[A-Za-z0-9_-]{11}$")


def extract(url: str, languages: list[str] | None = None) -> ExtractionResult:
    video_id = _extract_video_id(url)

    try:
        from youtube_transcript_api import (
            NoTranscriptFound,
            TranscriptsDisabled,
            VideoUnavailable,
            YouTubeTranscriptApi,
        )
    except ImportError as exc:
        raise ExtractionError(
            f"youtube-transcript-api not installed: {exc}"
        ) from exc

    try:
        entries = YouTubeTranscriptApi.get_transcript(
            video_id,
            languages=languages or ["en"],
        )
    except TranscriptsDisabled as exc:
        raise ExtractionError("This video has captions disabled.") from exc
    except NoTranscriptFound as exc:
        raise ExtractionError(
            "No transcript available in the requested language."
        ) from exc
    except VideoUnavailable as exc:
        raise ExtractionError("This video is unavailable.") from exc
    except Exception as exc:
        raise ExtractionError(f"Could not fetch transcript: {exc}") from exc

    text = " ".join(entry["text"].strip() for entry in entries if entry.get("text"))
    if not text.strip():
        raise ExtractionError("Transcript is empty.")

    return ExtractionResult(text=text)


def _extract_video_id(url: str) -> str:
    """Tolerant URL parser — accepts watch URLs, shorts, youtu.be, raw IDs."""
    raw = url.strip()

    if _VIDEO_ID_RE.match(raw):
        return raw

    parsed = urlparse(raw if "://" in raw else f"https://{raw}")
    host = (parsed.hostname or "").lower()

    if host in {"youtu.be"}:
        candidate = parsed.path.lstrip("/")
    elif host.endswith("youtube.com") or host == "m.youtube.com":
        if parsed.path == "/watch":
            candidate = parse_qs(parsed.query).get("v", [""])[0]
        elif parsed.path.startswith("/shorts/"):
            candidate = parsed.path.split("/shorts/", 1)[1].split("/")[0]
        elif parsed.path.startswith("/embed/"):
            candidate = parsed.path.split("/embed/", 1)[1].split("/")[0]
        elif parsed.path.startswith("/v/"):
            candidate = parsed.path.split("/v/", 1)[1].split("/")[0]
        else:
            candidate = ""
    else:
        candidate = ""

    if not _VIDEO_ID_RE.match(candidate):
        raise ExtractionError(f"Could not parse a YouTube video ID from: {url}")
    return candidate
