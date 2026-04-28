"""Audio transcription via Groq's Whisper endpoint.

Groq hosts `whisper-large-v3` and `whisper-large-v3-turbo`. Turbo is faster +
cheaper, slightly less accurate — fine for study material where the user is
expected to clean up afterwards.

Sprint 3 limit: 25 MB per file (Groq's hard cap). Sprint 11+ TODO: split with
pydub if file > 25 MB.
"""

from __future__ import annotations

from . import ExtractionError, ExtractionResult
from shared.groq_client import get_groq_client

_MODEL = "whisper-large-v3-turbo"
_MAX_MB = 25


def extract(audio_path: str) -> ExtractionResult:
    import os

    size_mb = os.path.getsize(audio_path) / (1024 * 1024)
    if size_mb > _MAX_MB:
        raise ExtractionError(
            f"Audio file is {size_mb:.1f} MB — Groq Whisper rejects files > {_MAX_MB} MB. "
            "Splitting/compression lands in a later sprint."
        )

    try:
        client = get_groq_client()
    except RuntimeError as exc:
        raise ExtractionError(str(exc)) from exc

    try:
        with open(audio_path, "rb") as f:
            transcription = client.audio.transcriptions.create(
                model=_MODEL,
                file=(os.path.basename(audio_path), f.read()),
                response_format="text",
            )
    except Exception as exc:
        raise ExtractionError(f"Whisper transcription failed: {exc}") from exc

    text = transcription if isinstance(transcription, str) else getattr(transcription, "text", "")
    if not text.strip():
        raise ExtractionError("No speech detected in audio")

    return ExtractionResult(text=text.strip())
