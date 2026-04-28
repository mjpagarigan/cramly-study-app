"""PDF extraction with pdfplumber primary + PyMuPDF fallback.

pdfplumber gives better layout fidelity for normal academic PDFs.
PyMuPDF (fitz) is faster and rescues some PDFs pdfplumber chokes on
(weird encodings, optimized PDFs, some scanned-text-with-OCR layers).

For pure scanned-image PDFs with no text layer, both will return empty —
those need OCR (sprint 3+ TODO: PDF→image→Tesseract pipeline).
"""

from __future__ import annotations

from shared.logging import get_logger

from . import ExtractionError, ExtractionResult

logger = get_logger(__name__)


def extract(pdf_path: str) -> ExtractionResult:
    text, pages = _try_pdfplumber(pdf_path)
    if not text.strip():
        logger.info("pdfplumber_empty_falling_back_to_pymupdf", extra={"path": pdf_path})
        text, pages = _try_pymupdf(pdf_path)

    if not text.strip():
        raise ExtractionError(
            "Could not extract any text — the PDF may be scanned-only "
            "(image-based). OCR for image PDFs is a future enhancement."
        )

    return ExtractionResult(text=text, page_count=pages)


def _try_pdfplumber(pdf_path: str) -> tuple[str, int]:
    try:
        import pdfplumber
    except ImportError as exc:
        raise ExtractionError(f"pdfplumber not installed: {exc}") from exc

    chunks: list[str] = []
    pages = 0
    try:
        with pdfplumber.open(pdf_path) as pdf:
            pages = len(pdf.pages)
            for page in pdf.pages:
                t = page.extract_text() or ""
                if t:
                    chunks.append(t)
        return ("\n\n".join(chunks), pages)
    except Exception as exc:
        logger.warning("pdfplumber_failed", extra={"error": str(exc)})
        return ("", pages)


def _try_pymupdf(pdf_path: str) -> tuple[str, int]:
    try:
        import fitz  # PyMuPDF
    except ImportError as exc:
        raise ExtractionError(f"PyMuPDF not installed: {exc}") from exc

    chunks: list[str] = []
    try:
        doc = fitz.open(pdf_path)
        pages = doc.page_count
        for page in doc:
            chunks.append(page.get_text())
        doc.close()
        return ("\n\n".join(chunks), pages)
    except Exception as exc:
        raise ExtractionError(f"PyMuPDF failed: {exc}") from exc
