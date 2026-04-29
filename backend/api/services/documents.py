"""Document orchestration: register docs and queue extraction jobs."""

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
    GeneratedAssets,
    SourceType,
)
from api.services import jobs as job_service
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


def docs_collection(uid: str) -> gcf.CollectionReference:
    return get_db().collection("users").document(uid).collection("documents")


def course_ref(uid: str, course_id: str) -> gcf.DocumentReference:
    return get_db().collection("users").document(uid).collection("courses").document(course_id)


def document_ref(uid: str, doc_id: str) -> gcf.DocumentReference:
    return docs_collection(uid).document(doc_id)


def get_document_snapshot(uid: str, doc_id: str) -> gcf.DocumentSnapshot:
    return document_ref(uid, doc_id).get()


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


def list_documents(uid: str, course_id: Optional[str] = None) -> list[DocumentRead]:
    query: gcf.Query = docs_collection(uid)
    if course_id:
        query = query.where(filter=gcf.FieldFilter("courseId", "==", course_id))
    query = query.order_by("uploadedAt", direction=gcf.Query.DESCENDING)
    return [_to_read(d) for d in query.stream()]


def get_document(uid: str, doc_id: str) -> DocumentRead:
    snap = get_document_snapshot(uid, doc_id)
    if not snap.exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Document not found")
    return _to_read(snap)


def create_document(uid: str, payload: DocumentCreate) -> DocumentRead:
    """Register the doc, enqueue extraction, and return immediately."""
    course_snap = course_ref(uid, payload.courseId).get()
    if not course_snap.exists:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Course {payload.courseId} not found",
        )

    title = payload.title or _derive_title(payload)

    ref = docs_collection(uid).document()
    ref.set({
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
        "customTitle": bool(payload.title),
        "extractionJobId": None,
    })
    logger.info(
        "document_created",
        extra={"uid": uid, "doc_id": ref.id, "source_type": payload.sourceType},
    )

    try:
        course_ref(uid, payload.courseId).update({
            "documentCount": gcf.Increment(1),
            "updatedAt": gcf.SERVER_TIMESTAMP,
        })
        job = job_service.enqueue_job(
            uid,
            "text_extraction",
            {"documentId": ref.id},
            output_refs={"documentId": ref.id},
        )
        ref.update({"extractionJobId": job.id})
        logger.info(
            "document_queued_for_extraction",
            extra={"uid": uid, "doc_id": ref.id, "job_id": job.id},
        )
    except Exception as exc:  # noqa: BLE001
        ref.update({
            "status": "failed",
            "errorMessage": f"Failed to enqueue extraction job: {exc}",
        })
        logger.error(
            "document_enqueue_failed",
            extra={"uid": uid, "doc_id": ref.id, "error": str(exc)},
        )
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "Failed to queue document extraction",
        ) from exc

    return _to_read(ref.get())


def delete_document(uid: str, doc_id: str) -> None:
    ref = document_ref(uid, doc_id)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Document not found")

    data = snap.to_dict() or {}
    course_id = data.get("courseId")

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

    ref.delete()

    if course_id:
        try:
            course_ref(uid, course_id).update({
                "documentCount": gcf.Increment(-1),
                "updatedAt": gcf.SERVER_TIMESTAMP,
            })
        except Exception as exc:  # noqa: BLE001
            logger.warning(
                "course_count_decrement_failed",
                extra={"course_id": course_id, "error": str(exc)},
            )

    logger.info("document_deleted", extra={"uid": uid, "doc_id": doc_id})


def _derive_title(payload: DocumentCreate) -> str:
    if payload.fileName:
        return os.path.splitext(payload.fileName)[0]
    if payload.sourceType == "youtube":
        return f"YouTube - {payload.sourceUrl}"
    if payload.sourceType == "web_url":
        return payload.sourceUrl or "Web article"
    return "Untitled"


def run_extraction(payload: DocumentCreate) -> tuple[ExtractionResult, str | None]:
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


def upload_extracted_text(uid: str, doc_id: str, text: str) -> str:
    path = f"users/{uid}/documents/{doc_id}/extracted.txt"
    bucket = get_bucket()
    blob = bucket.blob(path)
    blob.upload_from_string(text, content_type="text/plain; charset=utf-8")
    return path


def download_extracted_text(path: str) -> str:
    bucket = get_bucket()
    blob = bucket.blob(path)
    if not blob.exists():
        raise ExtractionError(f"Extracted text not found in Storage: {path}")
    return blob.download_as_text(encoding="utf-8")
