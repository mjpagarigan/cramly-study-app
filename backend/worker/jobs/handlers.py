"""Dispatch and side effects for async job types."""

from __future__ import annotations

import json
from datetime import datetime, timezone

from google.cloud import firestore as gcf

from api.models.deck import CardCreate
from api.models.document import DocumentCreate
from api.services import decks as deck_service
from api.services import documents as document_service
from api.services import jobs as job_service
from api.services import summaries as summary_service
from api.services.extraction import ExtractionError
from shared.config import settings
from shared.groq_client import get_groq_client
from shared.logging import get_logger
from shared.prompts.flashcards import build_flashcard_messages
from shared.prompts.summary import build_summary_messages

logger = get_logger(__name__)


def dispatch_job(job: job_service.ClaimedJob) -> None:
    if job.type == "text_extraction":
        _handle_text_extraction(job)
        return
    if job.type == "flashcards_gen":
        _handle_flashcards_generation(job)
        return
    if job.type == "summary_gen":
        _handle_summary_generation(job)
        return
    raise job_service.UnrecoverableJobError(f"Unsupported job type: {job.type}")


def mark_job_failure(
    job: job_service.ClaimedJob,
    error_message: str,
    *,
    final_failure: bool,
) -> None:
    now = datetime.now(timezone.utc)
    try:
        if job.type == "text_extraction":
            document_id = _required_str(job.input_refs, "documentId")
            document_service.document_ref(job.uid, document_id).update({
                "status": "failed" if final_failure else "extracting",
                "errorMessage": error_message if final_failure else None,
            })
            return

        if job.type == "summary_gen":
            summary_id = _required_str(job.input_refs, "summaryId")
            summary_service.summary_ref(job.uid, summary_id).update({
                "status": "failed" if final_failure else "queued",
                "errorMessage": error_message if final_failure else None,
                "updatedAt": now,
            })
            return

        if job.type == "flashcards_gen":
            deck_id = _required_str(job.input_refs, "deckId")
            deck_service.deck_ref(job.uid, deck_id).update({
                "status": "failed" if final_failure else "queued",
                "errorMessage": error_message if final_failure else None,
                "updatedAt": now,
            })
    except Exception as exc:  # noqa: BLE001
        logger.warning(
            "job_artifact_failure_update_failed",
            extra={"job_id": job.id, "job_type": job.type, "error": str(exc)},
        )


def _handle_text_extraction(job: job_service.ClaimedJob) -> None:
    document_id = _required_str(job.input_refs, "documentId")
    ref = document_service.document_ref(job.uid, document_id)
    snap = ref.get()
    if not snap.exists:
        raise job_service.UnrecoverableJobError("Source document no longer exists")

    data = snap.to_dict() or {}
    if data.get("status") == "ready" and data.get("extractedTextPath"):
        job_service.complete_job(
            job,
            output_refs={
                "documentId": document_id,
                "extractedTextPath": data.get("extractedTextPath"),
            },
        )
        return

    payload = DocumentCreate(
        courseId=data.get("courseId", ""),
        sourceType=data.get("sourceType", "pdf"),
        title=data.get("title"),
        fileName=data.get("fileName"),
        fileSize=data.get("fileSize"),
        mimeType=data.get("mimeType"),
        storagePath=data.get("storagePath"),
        sourceUrl=data.get("sourceUrl"),
    )

    ref.update({"status": "extracting", "errorMessage": None})
    job_service.update_job_progress(job, 15)

    try:
        result, derived_title = document_service.run_extraction(payload)
    except ExtractionError as exc:
        raise job_service.UnrecoverableJobError(str(exc)) from exc

    job_service.update_job_progress(job, 70)
    extracted_path = document_service.upload_extracted_text(job.uid, document_id, result.text)

    updates: dict[str, object] = {
        "status": "ready",
        "wordCount": result.word_count,
        "pageCount": result.page_count,
        "extractedTextPath": extracted_path,
        "extractedAt": gcf.SERVER_TIMESTAMP,
        "errorMessage": None,
    }
    if derived_title and not bool(data.get("customTitle")):
        updates["title"] = derived_title
    ref.update(updates)

    job_service.complete_job(
        job,
        output_refs={
            "documentId": document_id,
            "extractedTextPath": extracted_path,
        },
    )
    logger.info(
        "document_extracted_async",
        extra={
            "uid": job.uid,
            "document_id": document_id,
            "job_id": job.id,
            "word_count": result.word_count,
            "page_count": result.page_count,
        },
    )


def _handle_flashcards_generation(job: job_service.ClaimedJob) -> None:
    document_id = _required_str(job.input_refs, "documentId")
    deck_id = _required_str(job.input_refs, "deckId")
    card_count = _required_int(job.input_refs, "cardCount")

    deck_ref = deck_service.deck_ref(job.uid, deck_id)
    deck_snap = deck_ref.get()
    if not deck_snap.exists:
        raise job_service.UnrecoverableJobError("Deck record no longer exists")

    deck_data = deck_snap.to_dict() or {}
    if deck_data.get("status") == "ready" and int(deck_data.get("cardCount", 0)) > 0:
        job_service.complete_job(job, output_refs={"deckId": deck_id})
        return

    document_ref = document_service.document_ref(job.uid, document_id)
    document_snap = document_ref.get()
    if not document_snap.exists:
        raise job_service.UnrecoverableJobError("Source document no longer exists")

    document_data = document_snap.to_dict() or {}
    document_status = document_data.get("status")
    if document_status == "failed":
        raise job_service.UnrecoverableJobError(
            "Document extraction failed, so flashcards could not be generated"
        )
    if document_status != "ready" or not document_data.get("extractedTextPath"):
        raise RuntimeError("Document extraction is not finished yet")

    deck_ref.update({
        "status": "generating",
        "errorMessage": None,
        "updatedAt": datetime.now(timezone.utc),
    })
    job_service.update_job_progress(job, 20)

    extracted_text = document_service.download_extracted_text(
        document_data["extractedTextPath"]
    )
    if not extracted_text.strip():
        raise job_service.UnrecoverableJobError(
            "The extracted document text is empty, so there is nothing to turn into flashcards"
        )

    job_service.update_job_progress(job, 45)
    generated = _generate_flashcards(
        title=document_data.get("title", "Untitled"),
        source_text=extracted_text,
        card_count=card_count,
    )
    if len(generated["cards"]) < 4:
        raise job_service.UnrecoverableJobError(
            "The generator could not produce enough high-confidence flashcards from this document"
        )

    job_service.update_job_progress(job, 80)
    deck_service.replace_ai_deck_cards(
        job.uid,
        deck_id,
        cards=generated["cards"],
        title=generated["title"] or deck_data.get("title"),
        description=generated["description"],
    )

    now = datetime.now(timezone.utc)
    deck_ref.update({
        "status": "ready",
        "jobId": job.id,
        "errorMessage": None,
        "updatedAt": now,
    })
    document_ref.update({
        "generatedAssets.deckIds": gcf.ArrayUnion([deck_id]),
    })

    job_service.complete_job(
        job,
        output_refs={
            "documentId": document_id,
            "deckId": deck_id,
        },
    )
    logger.info(
        "flashcards_generated",
        extra={
            "uid": job.uid,
            "document_id": document_id,
            "deck_id": deck_id,
            "job_id": job.id,
            "card_count": len(generated["cards"]),
        },
    )


def _handle_summary_generation(job: job_service.ClaimedJob) -> None:
    document_id = _required_str(job.input_refs, "documentId")
    summary_id = _required_str(job.input_refs, "summaryId")
    depth = _required_str(job.input_refs, "depth")

    summary_ref = summary_service.summary_ref(job.uid, summary_id)
    summary_snap = summary_ref.get()
    if not summary_snap.exists:
        raise job_service.UnrecoverableJobError("Summary record no longer exists")

    summary_data = summary_snap.to_dict() or {}
    if summary_data.get("status") == "ready" and summary_data.get("content"):
        job_service.complete_job(job, output_refs={"summaryId": summary_id})
        return

    document_ref = document_service.document_ref(job.uid, document_id)
    document_snap = document_ref.get()
    if not document_snap.exists:
        raise job_service.UnrecoverableJobError("Source document no longer exists")

    document_data = document_snap.to_dict() or {}
    document_status = document_data.get("status")
    if document_status == "failed":
        raise job_service.UnrecoverableJobError(
            "Document extraction failed, so the summary could not be generated"
        )
    if document_status != "ready" or not document_data.get("extractedTextPath"):
        raise RuntimeError("Document extraction is not finished yet")

    summary_ref.update({
        "status": "generating",
        "errorMessage": None,
        "updatedAt": datetime.now(timezone.utc),
    })
    job_service.update_job_progress(job, 20)

    extracted_text = document_service.download_extracted_text(
        document_data["extractedTextPath"]
    )
    if not extracted_text.strip():
        raise job_service.UnrecoverableJobError(
            "The extracted document text is empty, so there is nothing to summarize"
        )

    job_service.update_job_progress(job, 45)
    content = _generate_summary_content(
        title=document_data.get("title", "Untitled"),
        depth=depth,
        source_text=extracted_text,
    )
    job_service.update_job_progress(job, 85)

    now = datetime.now(timezone.utc)
    summary_ref.update({
        "status": "ready",
        "content": content,
        "errorMessage": None,
        "jobId": job.id,
        "updatedAt": now,
    })
    document_ref.update({
        "generatedAssets.summaryIds": gcf.ArrayUnion([summary_id]),
    })

    job_service.complete_job(
        job,
        output_refs={
            "documentId": document_id,
            "summaryId": summary_id,
        },
    )
    logger.info(
        "summary_generated",
        extra={
            "uid": job.uid,
            "document_id": document_id,
            "summary_id": summary_id,
            "job_id": job.id,
            "depth": depth,
        },
    )


def _generate_flashcards(
    *,
    title: str,
    source_text: str,
    card_count: int,
) -> dict[str, object]:
    try:
        client = get_groq_client()
    except RuntimeError as exc:
        raise job_service.UnrecoverableJobError(str(exc)) from exc

    try:
        return _request_flashcard_completion(
            client=client,
            title=title,
            source_text=source_text,
            card_count=card_count,
            aggressive_trim=False,
        )
    except Exception as exc:  # noqa: BLE001
        if not _should_retry_with_smaller_excerpt(exc):
            raise

        logger.warning(
            "flashcards_generation_retrying_with_smaller_excerpt",
            extra={"card_count": card_count, "error": str(exc)},
        )
        try:
            return _request_flashcard_completion(
                client=client,
                title=title,
                source_text=source_text,
                card_count=card_count,
                aggressive_trim=True,
            )
        except Exception as retry_exc:  # noqa: BLE001
            if _should_retry_with_smaller_excerpt(retry_exc):
                raise job_service.UnrecoverableJobError(
                    "This flashcard request is too large for the current Groq plan. "
                    "Try a smaller document or generate cards from a shorter source."
                ) from retry_exc
            raise


def _generate_summary_content(
    *,
    title: str,
    depth: str,
    source_text: str,
) -> str:
    try:
        client = get_groq_client()
    except RuntimeError as exc:
        raise job_service.UnrecoverableJobError(str(exc)) from exc

    try:
        return _request_summary_completion(
            client=client,
            title=title,
            depth=depth,
            source_text=source_text,
            aggressive_trim=False,
        )
    except Exception as exc:  # noqa: BLE001
        if not _should_retry_with_smaller_excerpt(exc):
            raise

        logger.warning(
            "summary_generation_retrying_with_smaller_excerpt",
            extra={"depth": depth, "error": str(exc)},
        )
        try:
            return _request_summary_completion(
                client=client,
                title=title,
                depth=depth,
                source_text=source_text,
                aggressive_trim=True,
            )
        except Exception as retry_exc:  # noqa: BLE001
            if _should_retry_with_smaller_excerpt(retry_exc):
                raise job_service.UnrecoverableJobError(
                    _summary_request_too_large_message(depth)
                ) from retry_exc
            raise


def _request_flashcard_completion(
    *,
    client,
    title: str,
    source_text: str,
    card_count: int,
    aggressive_trim: bool,
) -> dict[str, object]:
    response = client.chat.completions.create(
        model=settings.GROQ_MODEL,
        temperature=0.2,
        max_tokens=1600,
        response_format={"type": "json_object"},
        messages=build_flashcard_messages(
            title=title,
            source_text=source_text,
            card_count=card_count,
            aggressive_trim=aggressive_trim,
        ),
    )
    content = (response.choices[0].message.content or "").strip()
    if not content:
        raise RuntimeError("Groq returned empty flashcards")
    return _parse_flashcard_payload(content, fallback_title=title, card_count=card_count)


def _request_summary_completion(
    *,
    client,
    title: str,
    depth: str,
    source_text: str,
    aggressive_trim: bool,
) -> str:
    response = client.chat.completions.create(
        model=settings.GROQ_MODEL,
        temperature=0.2,
        messages=build_summary_messages(
            title=title,
            depth=depth,  # type: ignore[arg-type]
            source_text=source_text,
            aggressive_trim=aggressive_trim,
        ),
    )
    content = response.choices[0].message.content or ""
    if not content.strip():
        raise RuntimeError("Groq returned an empty summary")
    return content.strip()


def _parse_flashcard_payload(
    raw_content: str,
    *,
    fallback_title: str,
    card_count: int,
) -> dict[str, object]:
    cleaned = raw_content.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.strip("`")
        cleaned = cleaned.removeprefix("json").strip()

    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start != -1 and end != -1:
        cleaned = cleaned[start : end + 1]

    try:
        payload = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Groq returned invalid flashcard JSON: {exc}") from exc

    if not isinstance(payload, dict):
        raise RuntimeError("Groq returned an unexpected flashcard payload")

    raw_cards = payload.get("cards")
    if not isinstance(raw_cards, list):
        raise RuntimeError("Groq did not return a cards array")

    cards: list[CardCreate] = []
    for item in raw_cards[:card_count]:
        if not isinstance(item, dict):
            continue
        front = _clean_optional_str(item.get("front"))
        back = _clean_optional_str(item.get("back"))
        if not front or not back:
            continue
        cards.append(
            CardCreate(
                front=front[:300],
                back=back[:2000],
                hint=_truncate_optional(item.get("hint"), 500),
                explanation=_truncate_optional(item.get("explanation"), 2000),
                topic=_truncate_optional(item.get("topic"), 120),
            )
        )

    if not cards:
        raise RuntimeError("Groq returned no usable flashcards")

    title = _clean_optional_str(payload.get("title")) or f"{fallback_title} Flashcards"
    description = _clean_optional_str(payload.get("description")) or "AI-generated flashcards."
    return {
        "title": title[:200],
        "description": description[:500],
        "cards": cards,
    }


def _should_retry_with_smaller_excerpt(exc: Exception) -> bool:
    message = str(exc).lower()
    return any(
        needle in message
        for needle in (
            "request too large",
            "reduce your message size",
            "rate_limit_exceeded",
            "tokens per minute",
            "request size",
        )
    )


def _summary_request_too_large_message(depth: str) -> str:
    if depth == "eli5":
        return (
            "This ELI5 summary is still too large for the current Groq plan. "
            "Try generating TL;DR or Detailed first, or split the document into smaller chunks."
        )
    return (
        "This summary request is too large for the current Groq plan. "
        "Try a shorter depth or split the document into smaller chunks."
    )


def _required_int(data: dict[str, object], key: str) -> int:
    value = data.get(key)
    if isinstance(value, bool):
        raise job_service.UnrecoverableJobError(f"Job field is not an integer: {key}")
    if isinstance(value, int):
        return value
    if isinstance(value, float) and value.is_integer():
        return int(value)
    raise job_service.UnrecoverableJobError(f"Job is missing required integer field: {key}")


def _required_str(data: dict[str, object], key: str) -> str:
    value = data.get(key)
    if isinstance(value, str) and value:
        return value
    raise job_service.UnrecoverableJobError(f"Job is missing required field: {key}")


def _clean_optional_str(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    stripped = value.strip()
    return stripped or None


def _truncate_optional(value: object, max_length: int) -> str | None:
    cleaned = _clean_optional_str(value)
    if cleaned is None:
        return None
    return cleaned[:max_length]
