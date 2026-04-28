"""Course CRUD endpoints — spec §8.

All routes are user-scoped: the URL has no userId because we trust the verified
ID token's `uid` claim. Listing/reading/writing always targets the authenticated
user's data, never anyone else's.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, Response, status

from api.deps import get_current_user
from api.models.course import CourseCreate, CourseRead, CourseUpdate
from api.services import courses as service

router = APIRouter(prefix="/courses", tags=["courses"])


@router.get("", response_model=list[CourseRead])
async def list_courses(uid: str = Depends(get_current_user)) -> list[CourseRead]:
    return service.list_courses(uid)


@router.post("", response_model=CourseRead, status_code=status.HTTP_201_CREATED)
async def create_course(
    payload: CourseCreate,
    uid: str = Depends(get_current_user),
) -> CourseRead:
    return service.create_course(uid, payload)


@router.patch("/{course_id}", response_model=CourseRead)
async def update_course(
    course_id: str,
    payload: CourseUpdate,
    uid: str = Depends(get_current_user),
) -> CourseRead:
    return service.update_course(uid, course_id, payload)


@router.delete(
    "/{course_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
)
async def delete_course(
    course_id: str,
    uid: str = Depends(get_current_user),
):
    service.delete_course(uid, course_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
