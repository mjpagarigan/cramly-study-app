"""Image OCR via Tesseract.

Tesseract is a *native* binary, not a Python package. The user must install it
on the host. On Render this means switching to a Docker base image (TODO sprint
11). Until then, OCR returns ExtractionError pointing to setup docs when the
binary is missing.
"""

from __future__ import annotations

import os

from . import ExtractionError, ExtractionResult

# Common Windows install location. Linux/Mac usually have it on PATH already.
_WINDOWS_DEFAULT = r"C:\Program Files\Tesseract-OCR\tesseract.exe"


def extract(image_path: str) -> ExtractionResult:
    try:
        import pytesseract
        from PIL import Image
    except ImportError as exc:
        raise ExtractionError(f"pytesseract / Pillow not installed: {exc}") from exc

    # Auto-discover Tesseract on Windows if it's not on PATH.
    if os.name == "nt" and not _is_on_path() and os.path.isfile(_WINDOWS_DEFAULT):
        pytesseract.pytesseract.tesseract_cmd = _WINDOWS_DEFAULT

    try:
        img = Image.open(image_path)
    except Exception as exc:
        raise ExtractionError(f"Could not open image: {exc}") from exc

    try:
        text = pytesseract.image_to_string(img)
    except pytesseract.TesseractNotFoundError as exc:
        raise ExtractionError(
            "Tesseract binary not found on this host. Install from "
            "https://github.com/UB-Mannheim/tesseract/wiki (Windows) or "
            "`apt-get install tesseract-ocr` (Linux)."
        ) from exc
    except Exception as exc:
        raise ExtractionError(f"OCR failed: {exc}") from exc

    if not text.strip():
        raise ExtractionError(
            "No text detected in image — check resolution and contrast."
        )

    return ExtractionResult(text=text.strip())


def _is_on_path() -> bool:
    """Best-effort check that `tesseract` is callable from PATH."""
    from shutil import which

    return which("tesseract") is not None
