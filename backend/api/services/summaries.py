"""Summary generation orchestration on top of async jobs."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from fastapi import HTTPException, status
from google.cloud import firestore as gcf

from api.models.summary import SummaryDepth, SummaryRead
from api.services import jobs as job_service
from shared.firebase import get_db
from shared.logging import get_logger

logger = get_logger(__name__)


def summaries_collection(uid: str) -> gcf.CollectionReference:
    return get_db().collection("users").document(uid).collection("summaries")


def summary_ref(uid: str, summary_id: str) -> gcf.DocumentReference:
    return summaries_collection(uid).document(summary_id)


def get_summary(uid: str, summary_id: str) -> SummaryRead:
    snap = summary_ref(uid, summary_id).get()
    if not snap.exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Summary not found")
    return _to_read(snap)


def create_summary_job(
    uid: str,
    document_id: str,
    *,
    course_id: str,
    document_status: str,
    extraction_job_id: str | None,
    depth: SummaryDepth,
) -> tuple[SummaryRead, job_service.ClaimedJob]:
    if document_status == "failed":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Cannot generate a summary from a failed document",
        )

    depends_on_job_id = None
    if document_status != "ready":
        if not extraction_job_id:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                "Document extraction is still pending and no extraction job was found",
            )
        depends_on_job_id = extraction_job_id

    now = datetime.now(timezone.utc)
    ref = summaries_collection(uid).document()
    ref.set({
        "courseId": course_id,
        "sourceDocumentId": document_id,
        "depth": depth,
        "status": "queued",
        "content": "",
        "jobId": None,
        "errorMessage": None,
        "createdAt": now,
        "updatedAt": now,
    })

    job = job_service.enqueue_job(
        uid,
        "summary_gen",
        {
            "documentId": document_id,
            "summaryId": ref.id,
            "depth": depth,
        },
        output_refs={"summaryId": ref.id},
        depends_on_job_id=depends_on_job_id,
    )
    ref.update({"jobId": job.id, "updatedAt": now})

    logger.info(
        "summary_job_created",
        extra={
            "uid": uid,
            "document_id": document_id,
            "summary_id": ref.id,
            "job_id": job.id,
            "depth": depth,
            "depends_on_job_id": depends_on_job_id,
        },
    )
    return _to_read(ref.get()), job


def _to_read(snap: gcf.DocumentSnapshot) -> SummaryRead:
    data = snap.to_dict() or {}
    return SummaryRead(
        id=snap.id,
        courseId=data.get("courseId", ""),
        sourceDocumentId=data.get("sourceDocumentId", ""),
        depth=data.get("depth", "detailed"),
        status=data.get("status", "queued"),
        content=data.get("content", ""),
        jobId=data.get("jobId"),
        errorMessage=data.get("errorMessage"),
        createdAt=_to_dt(data.get("createdAt")),
        updatedAt=_to_dt(data.get("updatedAt")),
    )


def _to_dt(value) -> Optional[datetime]:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    return None
