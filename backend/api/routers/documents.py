"""Document endpoints — spec §8 Documents.

Sprint 3 ships POST/GET/DELETE. The mobile client primarily reads via Firestore
listeners; GET endpoints are here for completeness + admin/debugging tools.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Response, status

from api.deps import get_current_user
from api.models.document import DocumentCreate, DocumentRead
from api.services import documents as service

router = APIRouter(prefix="/documents", tags=["documents"])


@router.get("", response_model=list[DocumentRead])
async def list_documents(
    courseId: str | None = Query(default=None),
    uid: str = Depends(get_current_user),
) -> list[DocumentRead]:
    return service.list_documents(uid, course_id=courseId)


@router.get("/{document_id}", response_model=DocumentRead)
async def get_document(
    document_id: str,
    uid: str = Depends(get_current_user),
) -> DocumentRead:
    return service.get_document(uid, document_id)


@router.post(
    "",
    response_model=DocumentRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_document(
    payload: DocumentCreate,
    uid: str = Depends(get_current_user),
) -> DocumentRead:
    return service.create_document(uid, payload)


@router.delete(
    "/{document_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
)
async def delete_document(
    document_id: str,
    uid: str = Depends(get_current_user),
):
    service.delete_document(uid, document_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
