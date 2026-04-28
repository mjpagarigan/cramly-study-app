"""FastAPI dependencies.

`get_current_user` is the auth gate for every protected route. It verifies
the Firebase ID token from the Authorization header and returns the user's
UID. Routes that need it should add `user_id: str = Depends(get_current_user)`.

Not yet attached to any route in Sprint 1 — exists so Sprint 2's first
protected endpoint can plug straight in.
"""

from __future__ import annotations

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from shared.firebase import get_auth
from shared.logging import get_logger

logger = get_logger(__name__)

bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> str:
    """Verify the Firebase ID token and return the user's UID.

    - 401 when the request itself is unauthenticated (missing/malformed/expired token).
    - 500 when the server is misconfigured (service account missing or unusable).
      That's an ops issue, not the client's fault — surfacing it as 401 hides bugs.
    """
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or malformed Authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    try:
        auth = get_auth()
    except RuntimeError as exc:
        # FIREBASE_SERVICE_ACCOUNT_JSON empty/invalid → 500, not 401.
        logger.error("firebase_admin_init_failed", extra={"error": str(exc)})
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Server misconfigured: {exc}",
        ) from exc

    try:
        decoded = auth.verify_id_token(token)
    except auth.ExpiredIdTokenError as exc:
        logger.info("id_token_expired")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="ID token expired — please sign in again",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    except auth.InvalidIdTokenError as exc:
        logger.warning("id_token_invalid", extra={"error": str(exc)})
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid ID token: {exc}",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    except Exception as exc:
        # Catch-all — log full type + message so misconfigs surface in the API logs.
        logger.error(
            "id_token_verify_unexpected",
            extra={"error_type": type(exc).__name__, "error": str(exc)},
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token verification failed: {type(exc).__name__}: {exc}",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    uid = decoded.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing uid claim",
        )
    return uid
