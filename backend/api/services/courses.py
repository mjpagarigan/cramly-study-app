"""Firestore CRUD for courses, scoped per user.

All paths live under `users/{uid}/courses/{courseId}`. Server stamps timestamps
via `SERVER_TIMESTAMP` so all clients see consistent ordering. Counts default
to 0; sprint 3+ will increment them when documents/decks/quizzes are created.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from fastapi import HTTPException, status
from google.cloud import firestore as gcf

from api.models.course import CourseCreate, CourseRead, CourseUpdate
from shared.firebase import get_db
from shared.logging import get_logger

logger = get_logger(__name__)


def _collection(uid: str) -> gcf.CollectionReference:
    return get_db().collection("users").document(uid).collection("courses")


def _to_read(snap: gcf.DocumentSnapshot) -> CourseRead:
    data = snap.to_dict() or {}
    return CourseRead(
        id=snap.id,
        name=data.get("name", ""),
        color=data.get("color", "#E8A84C"),
        icon=data.get("icon"),
        documentCount=int(data.get("documentCount", 0)),
        deckCount=int(data.get("deckCount", 0)),
        quizCount=int(data.get("quizCount", 0)),
        createdAt=_to_dt(data.get("createdAt")),
        updatedAt=_to_dt(data.get("updatedAt")),
    )


def _to_dt(value) -> Optional[datetime]:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    return None


def list_courses(uid: str) -> list[CourseRead]:
    docs = (
        _collection(uid)
        .order_by("updatedAt", direction=gcf.Query.DESCENDING)
        .stream()
    )
    return [_to_read(d) for d in docs]


def create_course(uid: str, payload: CourseCreate) -> CourseRead:
    ref = _collection(uid).document()
    ref.set({
        "name": payload.name,
        "color": payload.color,
        "icon": payload.icon,
        "documentCount": 0,
        "deckCount": 0,
        "quizCount": 0,
        "createdAt": gcf.SERVER_TIMESTAMP,
        "updatedAt": gcf.SERVER_TIMESTAMP,
    })
    snap = ref.get()
    logger.info("course_created", extra={"uid": uid, "course_id": ref.id})
    return _to_read(snap)


def update_course(uid: str, course_id: str, payload: CourseUpdate) -> CourseRead:
    ref = _collection(uid).document(course_id)
    if not ref.get().exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Course not found"
        )

    updates: dict = {"updatedAt": gcf.SERVER_TIMESTAMP}
    if payload.name is not None:
        updates["name"] = payload.name
    if payload.color is not None:
        updates["color"] = payload.color
    if payload.icon is not None:
        updates["icon"] = payload.icon

    ref.update(updates)
    snap = ref.get()
    logger.info("course_updated", extra={"uid": uid, "course_id": course_id})
    return _to_read(snap)


def delete_course(uid: str, course_id: str) -> None:
    ref = _collection(uid).document(course_id)
    if not ref.get().exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Course not found"
        )
    # TODO(sprint-3+): cascade-delete child documents, decks, quizzes,
    # podcasts, study guides, summaries when they exist. For sprint 2 the
    # course has no children so a single-doc delete is sufficient.
    ref.delete()
    logger.info("course_deleted", extra={"uid": uid, "course_id": course_id})
