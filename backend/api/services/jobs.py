"""Firestore-backed async job queue shared by API routes and worker."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any

from google.api_core import exceptions as gexc
from google.cloud import firestore as gcf

from api.models.job import JobRead, JobType
from shared.firebase import get_db
from shared.logging import get_logger

logger = get_logger(__name__)

CLAIM_BATCH_SIZE = 20
CLAIM_FALLBACK_SCAN_SIZE = 100
STUCK_JOB_BATCH_SIZE = 25
STUCK_JOB_FALLBACK_SCAN_SIZE = 100
RETRY_BASE_SECONDS = 15
STUCK_JOB_TIMEOUT = timedelta(minutes=15)


class UnrecoverableJobError(RuntimeError):
    """Raised when retrying a job would not help."""


@dataclass(slots=True)
class ClaimedJob:
    uid: str
    id: str
    reference: gcf.DocumentReference
    type: JobType
    status: str
    progress: int
    input_refs: dict[str, Any]
    output_refs: dict[str, Any]
    error_message: str | None
    worker_id: str | None
    attempt_count: int
    max_attempts: int
    depends_on_job_id: str | None
    retry_at: datetime | None
    created_at: datetime | None
    started_at: datetime | None
    completed_at: datetime | None

    def to_read(self) -> JobRead:
        return JobRead(
            id=self.id,
            type=self.type,
            status=self.status,
            progress=self.progress,
            inputRefs=self.input_refs,
            outputRefs=self.output_refs,
            errorMessage=self.error_message,
            workerId=self.worker_id,
            attemptCount=self.attempt_count,
            maxAttempts=self.max_attempts,
            dependsOnJobId=self.depends_on_job_id,
            retryAt=self.retry_at,
            createdAt=self.created_at,
            startedAt=self.started_at,
            completedAt=self.completed_at,
        )


def jobs_collection(uid: str) -> gcf.CollectionReference:
    return get_db().collection("users").document(uid).collection("asyncJobs")


def job_ref(uid: str, job_id: str) -> gcf.DocumentReference:
    return jobs_collection(uid).document(job_id)


def get_job(uid: str, job_id: str) -> ClaimedJob | None:
    snap = job_ref(uid, job_id).get()
    if not snap.exists:
        return None
    return _from_snapshot(snap)


def enqueue_job(
    uid: str,
    job_type: JobType,
    input_refs: dict[str, Any],
    *,
    output_refs: dict[str, Any] | None = None,
    max_attempts: int = 3,
    depends_on_job_id: str | None = None,
) -> ClaimedJob:
    now = _utcnow()
    ref = jobs_collection(uid).document()
    ref.set({
        "type": job_type,
        "status": "queued",
        "progress": 0,
        "inputRefs": input_refs,
        "outputRefs": output_refs or {},
        "errorMessage": None,
        "workerId": None,
        "attemptCount": 0,
        "maxAttempts": max_attempts,
        "dependsOnJobId": depends_on_job_id,
        "retryAt": None,
        "createdAt": now,
        "startedAt": None,
        "completedAt": None,
    })
    snap = ref.get()
    job = _from_snapshot(snap)
    logger.info(
        "job_enqueued",
        extra={
            "uid": uid,
            "job_id": job.id,
            "job_type": job_type,
            "depends_on_job_id": depends_on_job_id,
        },
    )
    return job


def claim_next_job(worker_id: str) -> ClaimedJob | None:
    for candidate in _stream_claim_candidates():
        claimed = _claim_candidate(candidate.reference, worker_id)
        if claimed is not None:
            logger.info(
                "job_claimed",
                extra={
                    "uid": claimed.uid,
                    "job_id": claimed.id,
                    "job_type": claimed.type,
                    "worker_id": worker_id,
                    "attempt_count": claimed.attempt_count,
                },
            )
            return claimed
    return None


def update_job_progress(
    job: ClaimedJob,
    progress: int,
    *,
    output_refs: dict[str, Any] | None = None,
) -> None:
    updates: dict[str, Any] = {"progress": max(0, min(100, progress))}
    if output_refs:
        updates["outputRefs"] = {**job.output_refs, **output_refs}
        job.output_refs = updates["outputRefs"]
    job.reference.update(updates)
    job.progress = updates["progress"]


def complete_job(job: ClaimedJob, *, output_refs: dict[str, Any] | None = None) -> None:
    now = _utcnow()
    merged_output_refs = {**job.output_refs, **(output_refs or {})}
    job.reference.update({
        "status": "completed",
        "progress": 100,
        "outputRefs": merged_output_refs,
        "errorMessage": None,
        "completedAt": now,
    })
    logger.info(
        "job_completed",
        extra={
            "uid": job.uid,
            "job_id": job.id,
            "job_type": job.type,
            "worker_id": job.worker_id,
        },
    )


def fail_job(job: ClaimedJob, error_message: str) -> None:
    now = _utcnow()
    cleaned = _clean_error(error_message)
    job.reference.update({
        "status": "failed",
        "errorMessage": cleaned,
        "completedAt": now,
    })
    logger.error(
        "job_failed",
        extra={
            "uid": job.uid,
            "job_id": job.id,
            "job_type": job.type,
            "worker_id": job.worker_id,
            "attempt_count": job.attempt_count,
            "error": cleaned,
        },
    )


def retry_or_fail_job(job: ClaimedJob, error_message: str) -> str:
    cleaned = _clean_error(error_message)
    if job.attempt_count >= job.max_attempts:
        fail_job(job, cleaned)
        return "failed"

    retry_delay = timedelta(seconds=RETRY_BASE_SECONDS * (2 ** (job.attempt_count - 1)))
    retry_at = _utcnow() + retry_delay
    job.reference.update({
        "status": "queued",
        "progress": 0,
        "errorMessage": cleaned,
        "workerId": None,
        "startedAt": None,
        "completedAt": None,
        "retryAt": retry_at,
    })
    logger.warning(
        "job_requeued",
        extra={
            "uid": job.uid,
            "job_id": job.id,
            "job_type": job.type,
            "attempt_count": job.attempt_count,
            "retry_at": retry_at.isoformat(),
            "error": cleaned,
        },
    )
    return "queued"


def reset_stuck_jobs() -> int:
    cutoff = _utcnow() - STUCK_JOB_TIMEOUT

    recovered = 0
    for candidate in _stream_stuck_job_candidates(cutoff):
        if _reset_stuck_candidate(candidate.reference, cutoff):
            recovered += 1

    if recovered:
        logger.warning("stuck_jobs_requeued", extra={"count": recovered})
    return recovered


def _claim_candidate(
    reference: gcf.DocumentReference,
    worker_id: str,
) -> ClaimedJob | None:
    db = get_db()
    transaction = db.transaction()
    now = _utcnow()

    @gcf.transactional
    def _claim(transaction: gcf.Transaction):
        snap = reference.get(transaction=transaction)
        if not snap.exists:
            return None

        data = snap.to_dict() or {}
        if data.get("status") != "queued":
            return None

        retry_at = _to_dt(data.get("retryAt"))
        if retry_at and retry_at > now:
            return None

        dependency_id = data.get("dependsOnJobId")
        if dependency_id:
            dependency_ref = reference.parent.document(dependency_id)
            dependency_snap = dependency_ref.get(transaction=transaction)
            dependency_status = (
                (dependency_snap.to_dict() or {}).get("status")
                if dependency_snap.exists
                else None
            )

            if not dependency_snap.exists or dependency_status == "failed":
                transaction.update(reference, {
                    "status": "failed",
                    "progress": 0,
                    "errorMessage": "Dependency job failed before this job could start.",
                    "completedAt": now,
                })
                return "__dependency_failed__"

            if dependency_status != "completed":
                return None

        updates = {
            "status": "processing",
            "workerId": worker_id,
            "attemptCount": int(data.get("attemptCount", 0)) + 1,
            "errorMessage": None,
            "startedAt": now,
            "completedAt": None,
            "retryAt": None,
        }
        transaction.update(reference, updates)

        merged = dict(data)
        merged.update(updates)
        return merged

    result = _claim(transaction)
    if result in (None, "__dependency_failed__"):
        return None
    return _from_data(reference, result)


def _stream_claim_candidates():
    db = get_db()
    preferred_query = (
        db.collection_group("asyncJobs")
        .where(filter=gcf.FieldFilter("status", "==", "queued"))
        .order_by("createdAt", direction=gcf.Query.ASCENDING)
        .limit(CLAIM_BATCH_SIZE)
    )

    try:
        for candidate in preferred_query.stream():
            yield candidate
        return
    except (gexc.FailedPrecondition, gexc.InvalidArgument) as exc:
        logger.warning(
            "job_claim_query_fallback",
            extra={"error": str(exc)},
        )

    fallback_candidates = [
        candidate
        for candidate in db.collection_group("asyncJobs").limit(CLAIM_FALLBACK_SCAN_SIZE).stream()
        if (candidate.to_dict() or {}).get("status") == "queued"
    ]
    fallback_candidates.sort(key=lambda snap: _dt_sort_key((snap.to_dict() or {}).get("createdAt")))
    for candidate in fallback_candidates[:CLAIM_BATCH_SIZE]:
        yield candidate


def _stream_stuck_job_candidates(cutoff: datetime):
    db = get_db()
    preferred_query = (
        db.collection_group("asyncJobs")
        .where(filter=gcf.FieldFilter("status", "==", "processing"))
        .where(filter=gcf.FieldFilter("startedAt", "<=", cutoff))
        .limit(STUCK_JOB_BATCH_SIZE)
    )

    try:
        for candidate in preferred_query.stream():
            yield candidate
        return
    except (gexc.FailedPrecondition, gexc.InvalidArgument) as exc:
        logger.warning(
            "stuck_job_query_fallback",
            extra={"error": str(exc)},
        )

    fallback_candidates = [
        candidate
        for candidate in db.collection_group("asyncJobs").limit(STUCK_JOB_FALLBACK_SCAN_SIZE).stream()
        if (candidate.to_dict() or {}).get("status") == "processing"
    ]
    fallback_candidates = [
        candidate
        for candidate in fallback_candidates
        if (_to_dt((candidate.to_dict() or {}).get("startedAt")) or _utcnow()) <= cutoff
    ]
    fallback_candidates.sort(key=lambda snap: _dt_sort_key((snap.to_dict() or {}).get("startedAt")))
    for candidate in fallback_candidates[:STUCK_JOB_BATCH_SIZE]:
        yield candidate


def _reset_stuck_candidate(reference: gcf.DocumentReference, cutoff: datetime) -> bool:
    db = get_db()
    transaction = db.transaction()
    now = _utcnow()

    @gcf.transactional
    def _reset(transaction: gcf.Transaction) -> bool:
        snap = reference.get(transaction=transaction)
        if not snap.exists:
            return False

        data = snap.to_dict() or {}
        started_at = _to_dt(data.get("startedAt"))
        if data.get("status") != "processing" or started_at is None or started_at > cutoff:
            return False

        transaction.update(reference, {
            "status": "queued",
            "progress": 0,
            "workerId": None,
            "startedAt": None,
            "completedAt": None,
            "retryAt": now,
            "errorMessage": "Previous worker stopped before finishing. Retrying job.",
        })
        return True

    return _reset(transaction)


def _from_snapshot(snap: gcf.DocumentSnapshot) -> ClaimedJob:
    return _from_data(snap.reference, snap.to_dict() or {})


def _from_data(reference: gcf.DocumentReference, data: dict[str, Any]) -> ClaimedJob:
    uid_ref = reference.parent.parent
    uid = uid_ref.id if uid_ref is not None else ""
    return ClaimedJob(
        uid=uid,
        id=reference.id,
        reference=reference,
        type=data.get("type", "text_extraction"),
        status=data.get("status", "queued"),
        progress=int(data.get("progress", 0)),
        input_refs=dict(data.get("inputRefs") or {}),
        output_refs=dict(data.get("outputRefs") or {}),
        error_message=data.get("errorMessage"),
        worker_id=data.get("workerId"),
        attempt_count=int(data.get("attemptCount", 0)),
        max_attempts=int(data.get("maxAttempts", 3)),
        depends_on_job_id=data.get("dependsOnJobId"),
        retry_at=_to_dt(data.get("retryAt")),
        created_at=_to_dt(data.get("createdAt")),
        started_at=_to_dt(data.get("startedAt")),
        completed_at=_to_dt(data.get("completedAt")),
    )


def _clean_error(error_message: str) -> str:
    cleaned = " ".join(error_message.split())
    return cleaned[:1000] if len(cleaned) > 1000 else cleaned


def _dt_sort_key(value) -> datetime:
    return _to_dt(value) or datetime.max.replace(tzinfo=timezone.utc)


def _to_dt(value) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    return None


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)
