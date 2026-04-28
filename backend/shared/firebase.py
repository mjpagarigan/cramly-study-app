"""Firebase Admin SDK initialization.

Importing `db`, `bucket`, or `auth` from this module triggers a lazy init
of the admin app. Both api and worker share the same singleton.
"""

from __future__ import annotations

import json
import os
from functools import lru_cache

import firebase_admin
from firebase_admin import auth as fb_auth
from firebase_admin import credentials, firestore, storage

from .config import settings
from .logging import get_logger

logger = get_logger(__name__)


def _load_credentials() -> credentials.Certificate:
    """Resolve service-account credentials from path (local) or JSON string (Render).

    Path wins if both are set so a developer can override the bundled config
    without editing files.
    """
    if settings.FIREBASE_SERVICE_ACCOUNT_PATH:
        path = settings.FIREBASE_SERVICE_ACCOUNT_PATH
        if not os.path.isfile(path):
            raise RuntimeError(
                f"FIREBASE_SERVICE_ACCOUNT_PATH points to a file that doesn't exist: {path}"
            )
        return credentials.Certificate(path)

    if settings.FIREBASE_SERVICE_ACCOUNT_JSON:
        try:
            info = json.loads(settings.FIREBASE_SERVICE_ACCOUNT_JSON)
        except json.JSONDecodeError as exc:
            raise RuntimeError(
                "FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON"
            ) from exc
        return credentials.Certificate(info)

    raise RuntimeError(
        "Set FIREBASE_SERVICE_ACCOUNT_PATH (local dev, recommended) or "
        "FIREBASE_SERVICE_ACCOUNT_JSON (Render) in your .env"
    )


@lru_cache(maxsize=1)
def _init_app() -> firebase_admin.App:
    cred = _load_credentials()
    app = firebase_admin.initialize_app(
        cred,
        {
            "projectId": settings.FIREBASE_PROJECT_ID,
            "storageBucket": settings.FIREBASE_STORAGE_BUCKET,
        },
    )
    logger.info("firebase_admin initialized", extra={"project_id": settings.FIREBASE_PROJECT_ID})
    return app


def get_db() -> firestore.firestore.Client:
    _init_app()
    return firestore.client()


def get_bucket():
    _init_app()
    return storage.bucket()


def get_auth():
    _init_app()
    return fb_auth
