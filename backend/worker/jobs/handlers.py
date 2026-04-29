"""Dispatch and side effects for async job types."""

from __future__ import annotations

from datetime import datetime, timezone

from google.cloud import firestore as gcf

from api.models.document import DocumentCreate
from api.services import documents as document_service
from api.services import jobs as job_service
from api.services import summaries as summary_service
from api.services.extraction import ExtractionError
from shared.config import settings
from shared.groq_client import get_groq_client
from shared.logging import get_logger
from shared.prompts.summary import build_summary_messages

logger = get_logger(__name__)


def dispatch_job(job: job_service.ClaimedJob) -> None:
    if job.type == "text_extraction":
        _handle_text_extraction(job)
        return
    if job.type == "summary_gen":
        _handle_summary_generation(job)
        return
    raise job_service.UnrecoverableJobError(f"Unsupported job type: {job.type}")


def mark_job_failure(
    job: job_service.ClaimedJob,
    error_message: str,
    *,
    final_failure: bool,
) -> None:
    now = datetime.now(timezone.utc)
    try:
        if job.type == "text_extraction":
            document_id = _required_str(job.input_refs, "documentId")
            document_service.document_ref(job.uid, document_id).update({
                "status": "failed" if final_failure else "extracting",
                "errorMessage": error_message if final_failure else None,
            })
            return

        if job.type == "summary_gen":
            summary_id = _required_str(job.input_refs, "summaryId")
            summary_service.summary_ref(job.uid, summary_id).update({
                "status": "failed" if final_failure else "queued",
                "errorMessage": error_message if final_failure else None,
                "updatedAt": now,
            })
    except Exception as exc:  # noqa: BLE001
        logger.warning(
            "job_artifact_failure_update_failed",
            extra={"job_id": job.id, "job_type": job.type, "error": str(exc)},
        )


def _handle_text_extraction(job: job_service.ClaimedJob) -> None:
    document_id = _required_str(job.input_refs, "documentId")
    ref = document_service.document_ref(job.uid, document_id)
    snap = ref.get()
    if not snap.exists:
        raise job_service.UnrecoverableJobError("Source document no longer exists")

    data = snap.to_dict() or {}
    if data.get("status") == "ready" and data.get("extractedTextPath"):
        job_service.complete_job(
            job,
            output_refs={
                "documentId": document_id,
                "extractedTextPath": data.get("extractedTextPath"),
            },
        )
        return

    payload = DocumentCreate(
        courseId=data.get("courseId", ""),
        sourceType=data.get("sourceType", "pdf"),
        title=data.get("title"),
        fileName=data.get("fileName"),
        fileSize=data.get("fileSize"),
        mimeType=data.get("mimeType"),
        storagePath=data.get("storagePath"),
        sourceUrl=data.get("sourceUrl"),
    )

    ref.update({"status": "extracting", "errorMessage": None})
    job_service.update_job_progress(job, 15)

    try:
        result, derived_title = document_service.run_extraction(payload)
    except ExtractionError as exc:
        raise job_service.UnrecoverableJobError(str(exc)) from exc

    job_service.update_job_progress(job, 70)
    extracted_path = document_service.upload_extracted_text(job.uid, document_id, result.text)

    updates: dict[str, object] = {
        "status": "ready",
        "wordCount": result.word_count,
        "pageCount": result.page_count,
        "extractedTextPath": extracted_path,
        "extractedAt": gcf.SERVER_TIMESTAMP,
        "errorMessage": None,
    }
    if derived_title and not bool(data.get("customTitle")):
        updates["title"] = derived_title
    ref.update(updates)

    job_service.complete_job(
        job,
        output_refs={
            "documentId": document_id,
            "extractedTextPath": extracted_path,
        },
    )
    logger.info(
        "document_extracted_async",
        extra={
            "uid": job.uid,
            "document_id": document_id,
            "job_id": job.id,
            "word_count": result.word_count,
            "page_count": result.page_count,
        },
    )


def _handle_summary_generation(job: job_service.ClaimedJob) -> None:
    document_id = _required_str(job.input_refs, "documentId")
    summary_id = _required_str(job.input_refs, "summaryId")
    depth = _required_str(job.input_refs, "depth")

    summary_ref = summary_service.summary_ref(job.uid, summary_id)
    summary_snap = summary_ref.get()
    if not summary_snap.exists:
        raise job_service.UnrecoverableJobError("Summary record no longer exists")

    summary_data = summary_snap.to_dict() or {}
    if summary_data.get("status") == "ready" and summary_data.get("content"):
        job_service.complete_job(job, output_refs={"summaryId": summary_id})
        return

    document_ref = document_service.document_ref(job.uid, document_id)
    document_snap = document_ref.get()
    if not document_snap.exists:
        raise job_service.UnrecoverableJobError("Source document no longer exists")

    document_data = document_snap.to_dict() or {}
    document_status = document_data.get("status")
    if document_status == "failed":
        raise job_service.UnrecoverableJobError(
            "Document extraction failed, so the summary could not be generated"
        )
    if document_status != "ready" or not document_data.get("extractedTextPath"):
        raise RuntimeError("Document extraction is not finished yet")

    summary_ref.update({
        "status": "generating",
        "errorMessage": None,
        "updatedAt": datetime.now(timezone.utc),
    })
    job_service.update_job_progress(job, 20)

    extracted_text = document_service.download_extracted_text(
        document_data["extractedTextPath"]
    )
    if not extracted_text.strip():
        raise job_service.UnrecoverableJobError(
            "The extracted document text is empty, so there is nothing to summarize"
        )

    job_service.update_job_progress(job, 45)
    content = _generate_summary_content(
        title=document_data.get("title", "Untitled"),
        depth=depth,
        source_text=extracted_text,
    )
    job_service.update_job_progress(job, 85)

    now = datetime.now(timezone.utc)
    summary_ref.update({
        "status": "ready",
        "content": content,
        "errorMessage": None,
        "jobId": job.id,
        "updatedAt": now,
    })
    document_ref.update({
        "generatedAssets.summaryIds": gcf.ArrayUnion([summary_id]),
    })

    job_service.complete_job(
        job,
        output_refs={
            "documentId": document_id,
            "summaryId": summary_id,
        },
    )
    logger.info(
        "summary_generated",
        extra={
            "uid": job.uid,
            "document_id": document_id,
            "summary_id": summary_id,
            "job_id": job.id,
            "depth": depth,
        },
    )


def _generate_summary_content(
    *,
    title: str,
    depth: str,
    source_text: str,
) -> str:
    try:
        client = get_groq_client()
    except RuntimeError as exc:
        raise job_service.UnrecoverableJobError(str(exc)) from exc

    response = client.chat.completions.create(
        model=settings.GROQ_MODEL,
        temperature=0.2,
        messages=build_summary_messages(
            title=title,
            depth=depth,  # type: ignore[arg-type]
            source_text=source_text,
        ),
    )
    content = response.choices[0].message.content or ""
    if not content.strip():
        raise RuntimeError("Groq returned an empty summary")
    return content.strip()


def _required_str(data: dict[str, object], key: str) -> str:
    value = data.get(key)
    if isinstance(value, str) and value:
        return value
    raise job_service.UnrecoverableJobError(f"Job is missing required field: {key}")
