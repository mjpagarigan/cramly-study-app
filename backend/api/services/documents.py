"""Document orchestration: register → extract → store.

Sprint 3 runs extraction synchronously inside the request handler. Small files
(a 10-page PDF, a 30-min YouTube transcript) finish in 1-3s — acceptable to
block. Large files (a 25 MB audio, a 200-page PDF) can take 30s+ and should
become async jobs in Sprint 4.

# TODO(sprint-4): move extraction to a `text_extraction` async job per spec §7.
"""

from __future__ import annotations

import os
import tempfile
from datetime import datetime, timezone
from typing import Optional

from fastapi import HTTPException, status
from google.cloud import firestore as gcf

from api.models.document import (
    FILE_SOURCES,
    DocumentCreate,
    DocumentRead,
    DocumentStatus,
    GeneratedAssets,
    SourceType,
)
from api.services.extraction import (
    ExtractionError,
    ExtractionResult,
    audio,
    docx,
    image,
    markdown,
    pdf,
    pptx,
    web,
    youtube,
)
from shared.firebase import get_bucket, get_db
from shared.logging import get_logger

logger = get_logger(__name__)


# --- Firestore helpers ---------------------------------------------------------


def _docs_collection(uid: str) -> gcf.CollectionReference:
    return get_db().collection("users").document(uid).collection("documents")


def _course_ref(uid: str, course_id: str) -> gcf.DocumentReference:
    return get_db().collection("users").document(uid).collection("courses").document(course_id)


def _to_dt(value) -> Optional[datetime]:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    return None


def _to_read(snap: gcf.DocumentSnapshot) -> DocumentRead:
    data = snap.to_dict() or {}
    return DocumentRead(
        id=snap.id,
        courseId=data.get("courseId", ""),
        sourceType=data.get("sourceType", "pdf"),
        title=data.get("title", ""),
        status=data.get("status", "extracting"),
        fileName=data.get("fileName"),
        fileSize=data.get("fileSize"),
        mimeType=data.get("mimeType"),
        storagePath=data.get("storagePath"),
        sourceUrl=data.get("sourceUrl"),
        pageCount=data.get("pageCount"),
        wordCount=int(data.get("wordCount", 0)),
        extractedTextPath=data.get("extractedTextPath"),
        errorMessage=data.get("errorMessage"),
        generatedAssets=GeneratedAssets(**(data.get("generatedAssets") or {})),
        uploadedAt=_to_dt(data.get("uploadedAt")),
        extractedAt=_to_dt(data.get("extractedAt")),
    )


# --- Public API ----------------------------------------------------------------


def list_documents(uid: str, course_id: Optional[str] = None) -> list[DocumentRead]:
    query: gcf.Query = _docs_collection(uid)
    if course_id:
        query = query.where(filter=gcf.FieldFilter("courseId", "==", course_id))
    query = query.order_by("uploadedAt", direction=gcf.Query.DESCENDING)
    return [_to_read(d) for d in query.stream()]


def get_document(uid: str, doc_id: str) -> DocumentRead:
    snap = _docs_collection(uid).document(doc_id).get()
    if not snap.exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Document not found")
    return _to_read(snap)


def create_document(uid: str, payload: DocumentCreate) -> DocumentRead:
    """Register the doc, run extraction synchronously, return final state.

    Sprint 4 will split this into:
      1. POST /documents → register + enqueue `text_extraction` job, return immediately
      2. worker picks up job, extracts, updates doc
    For now everything happens in one HTTP request.
    """
    # Verify the course exists and belongs to the user.
    course_snap = _course_ref(uid, payload.courseId).get()
    if not course_snap.exists:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Course {payload.courseId} not found",
        )

    title = payload.title or _derive_title(payload)

    doc_ref = _docs_collection(uid).document()
    doc_ref.set({
        "courseId": payload.courseId,
        "sourceType": payload.sourceType,
        "title": title,
        "status": "extracting",
        "fileName": payload.fileName,
        "fileSize": payload.fileSize,
        "mimeType": payload.mimeType,
        "storagePath": payload.storagePath,
        "sourceUrl": payload.sourceUrl,
        "pageCount": None,
        "wordCount": 0,
        "extractedTextPath": None,
        "errorMessage": None,
        "generatedAssets": GeneratedAssets().model_dump(),
        "uploadedAt": gcf.SERVER_TIMESTAMP,
        "extractedAt": None,
    })
    logger.info(
        "document_created",
        extra={"uid": uid, "doc_id": doc_ref.id, "source_type": payload.sourceType},
    )

    # --- Extraction (the blocking part) -------------------------------------
    try:
        result, derived_title = _run_extraction(uid, doc_ref.id, payload)
        extracted_path = _upload_extracted_text(uid, doc_ref.id, result.text)

        updates = {
            "status": "ready",
            "wordCount": result.word_count,
            "pageCount": result.page_count,
            "extractedTextPath": extracted_path,
            "extractedAt": gcf.SERVER_TIMESTAMP,
        }
        # Title from extraction (e.g. web article <title>) wins if user didn't pick one.
        if derived_title and not payload.title:
            updates["title"] = derived_title

        doc_ref.update(updates)

        # Bump parent course's documentCount.
        _course_ref(uid, payload.courseId).update({
            "documentCount": gcf.Increment(1),
            "updatedAt": gcf.SERVER_TIMESTAMP,
        })

        logger.info(
            "document_extracted",
            extra={
                "uid": uid,
                "doc_id": doc_ref.id,
                "word_count": result.word_count,
                "page_count": result.page_count,
            },
        )
    except ExtractionError as exc:
        doc_ref.update({"status": "failed", "errorMessage": str(exc)})
        logger.warning(
            "document_extraction_failed",
            extra={"uid": uid, "doc_id": doc_ref.id, "error": str(exc)},
        )
    except Exception as exc:  # noqa: BLE001
        # Unknown failure — record so the user can see something happened, then re-raise.
        doc_ref.update({"status": "failed", "errorMessage": f"Internal error: {exc}"})
        logger.error(
            "document_extraction_unexpected",
            extra={"uid": uid, "doc_id": doc_ref.id, "error": str(exc)},
        )
        raise

    return _to_read(doc_ref.get())


def delete_document(uid: str, doc_id: str) -> None:
    doc_ref = _docs_collection(uid).document(doc_id)
    snap = doc_ref.get()
    if not snap.exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Document not found")

    data = snap.to_dict() or {}
    course_id = data.get("courseId")

    # Best-effort cleanup of Storage objects. Failures are logged, not fatal.
    bucket = get_bucket()
    for path in (data.get("storagePath"), data.get("extractedTextPath")):
        if not path:
            continue
        try:
            bucket.blob(path).delete()
        except Exception as exc:  # noqa: BLE001
            logger.warning(
                "storage_delete_failed",
                extra={"path": path, "error": str(exc)},
            )

    doc_ref.delete()

    # Decrement parent course's documentCount.
    if course_id:
        try:
            _course_ref(uid, course_id).update({
                "documentCount": gcf.Increment(-1),
                "updatedAt": gcf.SERVER_TIMESTAMP,
            })
        except Exception as exc:  # noqa: BLE001
            logger.warning(
                "course_count_decrement_failed",
                extra={"course_id": course_id, "error": str(exc)},
            )

    # TODO(sprint-5+): cascade-delete generatedAssets (decks, quizzes, etc.)
    logger.info("document_deleted", extra={"uid": uid, "doc_id": doc_id})


# --- Internals ----------------------------------------------------------------


def _derive_title(payload: DocumentCreate) -> str:
    """Best-effort title before extraction. Web URL extractor may overwrite later."""
    if payload.fileName:
        return os.path.splitext(payload.fileName)[0]
    if payload.sourceType == "youtube":
        return f"YouTube — {payload.sourceUrl}"
    if payload.sourceType == "web_url":
        return payload.sourceUrl or "Web article"
    return "Untitled"


def _run_extraction(
    uid: str,
    doc_id: str,
    payload: DocumentCreate,
) -> tuple[ExtractionResult, str | None]:
    """Returns (result, optional_derived_title)."""
    if payload.sourceType in FILE_SOURCES:
        if not payload.storagePath:
            raise ExtractionError("Missing storagePath for file source")
        local_path = _download_to_temp(payload.storagePath, payload.fileName)
        try:
            return _dispatch_file(payload.sourceType, local_path), None
        finally:
            try:
                os.remove(local_path)
            except OSError:
                pass

    if payload.sourceType == "youtube":
        return youtube.extract(payload.sourceUrl or ""), None

    if payload.sourceType == "web_url":
        result, derived = web.extract(payload.sourceUrl or "")
        return result, derived

    raise ExtractionError(f"Unsupported source type: {payload.sourceType}")


def _dispatch_file(source_type: SourceType, local_path: str) -> ExtractionResult:
    if source_type == "pdf":
        return pdf.extract(local_path)
    if source_type == "docx":
        return docx.extract(local_path)
    if source_type == "pptx":
        return pptx.extract(local_path)
    if source_type == "markdown":
        return markdown.extract(local_path)
    if source_type == "image":
        return image.extract(local_path)
    if source_type == "audio":
        return audio.extract(local_path)
    raise ExtractionError(f"Unsupported file source: {source_type}")


def _download_to_temp(storage_path: str, file_name: Optional[str]) -> str:
    bucket = get_bucket()
    blob = bucket.blob(storage_path)
    if not blob.exists():
        raise ExtractionError(f"File not found in Storage: {storage_path}")

    suffix = os.path.splitext(file_name or storage_path)[1] or ""
    fd, temp_path = tempfile.mkstemp(suffix=suffix)
    os.close(fd)
    blob.download_to_filename(temp_path)
    return temp_path


def _upload_extracted_text(uid: str, doc_id: str, text: str) -> str:
    """Writes extracted text to Storage, returns the storage path.

    Storage layout per spec §6:
        /users/{uid}/documents/{doc_id}/extracted.txt
    """
    path = f"users/{uid}/documents/{doc_id}/extracted.txt"
    bucket = get_bucket()
    blob = bucket.blob(path)
    blob.upload_from_string(text, content_type="text/plain; charset=utf-8")
    return path
