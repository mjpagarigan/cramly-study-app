"""Cramly background worker entrypoint."""

from __future__ import annotations

import os
import signal
import time

from dotenv import load_dotenv

load_dotenv()

from api.services import jobs as job_service  # noqa: E402
from shared.config import settings  # noqa: E402
from shared.logging import configure_logging, get_logger  # noqa: E402
from worker.jobs.handlers import dispatch_job, mark_job_failure  # noqa: E402

configure_logging()
logger = get_logger(__name__)

_shutdown_requested = False


def _request_shutdown(signum: int, _frame) -> None:
    global _shutdown_requested
    logger.info("worker_shutdown_signal", extra={"signal": signum})
    _shutdown_requested = True


def main() -> None:
    worker_id = settings.WORKER_ID or os.environ.get("RENDER_INSTANCE_ID", "local")
    logger.info(
        "worker_starting",
        extra={
            "worker_id": worker_id,
            "env": settings.ENV,
            "poll_interval": settings.WORKER_POLL_INTERVAL_SECONDS,
        },
    )

    signal.signal(signal.SIGTERM, _request_shutdown)
    signal.signal(signal.SIGINT, _request_shutdown)

    last_heartbeat = 0.0
    last_janitor_run = 0.0

    while not _shutdown_requested:
        now = time.monotonic()
        try:
            if now - last_janitor_run >= settings.WORKER_HEARTBEAT_INTERVAL_SECONDS:
                job_service.reset_stuck_jobs()
                last_janitor_run = now

            job = job_service.claim_next_job(worker_id)
        except Exception:  # noqa: BLE001
            logger.exception("worker_firestore_loop_error", extra={"worker_id": worker_id})
            time.sleep(settings.WORKER_POLL_INTERVAL_SECONDS)
            continue

        if job is not None:
            try:
                dispatch_job(job)
            except job_service.UnrecoverableJobError as exc:
                mark_job_failure(job, str(exc), final_failure=True)
                job_service.fail_job(job, str(exc))
            except Exception as exc:  # noqa: BLE001
                error_message = f"{type(exc).__name__}: {exc}"
                final_failure = job.attempt_count >= job.max_attempts
                mark_job_failure(job, error_message, final_failure=final_failure)
                job_service.retry_or_fail_job(job, error_message)
            continue

        if now - last_heartbeat >= settings.WORKER_HEARTBEAT_INTERVAL_SECONDS:
            logger.info("worker_heartbeat", extra={"worker_id": worker_id})
            last_heartbeat = now

        time.sleep(settings.WORKER_POLL_INTERVAL_SECONDS)

    logger.info("worker_stopped", extra={"worker_id": worker_id})


if __name__ == "__main__":
    main()
