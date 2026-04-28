"""Cramly background worker entrypoint.

Sprint 1: empty heartbeat loop just to prove the second Render service
runs. Sprint 4 replaces this with the real job claim + dispatch loop.

Run from the `backend/` directory:
    python -m worker.worker

In production (Render Background Worker), `rootDir: backend` handles the cwd:
    python -m worker.worker
"""

from __future__ import annotations

import os
import signal
import time

from dotenv import load_dotenv

load_dotenv()

from shared.config import settings  # noqa: E402
from shared.logging import configure_logging, get_logger  # noqa: E402

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
    while not _shutdown_requested:
        # TODO(sprint-4): claim and dispatch jobs from asyncJobs collection
        now = time.monotonic()
        if now - last_heartbeat >= settings.WORKER_HEARTBEAT_INTERVAL_SECONDS:
            logger.info("worker_heartbeat", extra={"worker_id": worker_id})
            last_heartbeat = now
        time.sleep(settings.WORKER_POLL_INTERVAL_SECONDS)

    logger.info("worker_stopped", extra={"worker_id": worker_id})


if __name__ == "__main__":
    main()
