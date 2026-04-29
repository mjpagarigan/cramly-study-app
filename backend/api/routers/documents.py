"""Document endpoints per the app specification."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Response, status

from api.deps import get_current_user
from api.models.document import (
    DocumentCreate,
    DocumentGenerateRequest,
    DocumentGenerateResponse,
    DocumentRead,
)
from api.services import documents as service
from api.services import summaries as summaries_service

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


@router.post(
    "/{document_id}/generate",
    response_model=DocumentGenerateResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def generate_from_document(
    document_id: str,
    payload: DocumentGenerateRequest,
    uid: str = Depends(get_current_user),
) -> DocumentGenerateResponse:
    document = service.get_document(uid, document_id)
    raw_document = service.get_document_snapshot(uid, document_id).to_dict() or {}
    summary, job = summaries_service.create_summary_job(
        uid,
        document_id,
        course_id=document.courseId,
        document_status=document.status,
        extraction_job_id=raw_document.get("extractionJobId"),
        depth=payload.depth,
    )
    return DocumentGenerateResponse(job=job.to_read(), summary=summary)


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
