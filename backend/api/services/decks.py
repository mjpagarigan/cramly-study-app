"""Deck and card CRUD plus flashcard-generation orchestration."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from fastapi import HTTPException, status
from google.cloud import firestore as gcf

from api.models.deck import (
    CardCreate,
    CardRead,
    CardSrs,
    CardStats,
    CardUpdate,
    DeckCreate,
    DeckRead,
    DeckUpdate,
)
from api.services import jobs as job_service
from shared.firebase import get_db
from shared.logging import get_logger

logger = get_logger(__name__)


def decks_collection(uid: str) -> gcf.CollectionReference:
    return get_db().collection("users").document(uid).collection("decks")


def deck_ref(uid: str, deck_id: str) -> gcf.DocumentReference:
    return decks_collection(uid).document(deck_id)


def cards_collection(uid: str, deck_id: str) -> gcf.CollectionReference:
    return deck_ref(uid, deck_id).collection("cards")


def card_ref(uid: str, deck_id: str, card_id: str) -> gcf.DocumentReference:
    return cards_collection(uid, deck_id).document(card_id)


def course_ref(uid: str, course_id: str) -> gcf.DocumentReference:
    return get_db().collection("users").document(uid).collection("courses").document(course_id)


def document_ref(uid: str, document_id: str) -> gcf.DocumentReference:
    return get_db().collection("users").document(uid).collection("documents").document(document_id)


def list_decks(uid: str, course_id: Optional[str] = None) -> list[DeckRead]:
    query: gcf.Query = decks_collection(uid)
    if course_id:
        query = query.where(filter=gcf.FieldFilter("courseId", "==", course_id))
    query = query.order_by("updatedAt", direction=gcf.Query.DESCENDING)
    return [_to_deck_read(deck) for deck in query.stream()]


def get_deck(uid: str, deck_id: str) -> DeckRead:
    snap = deck_ref(uid, deck_id).get()
    if not snap.exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Deck not found")
    cards = _list_cards(uid, deck_id)
    return _to_deck_read(snap, cards=cards)


def create_manual_deck(uid: str, payload: DeckCreate) -> DeckRead:
    course_snap = course_ref(uid, payload.courseId).get()
    if not course_snap.exists:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Course not found")

    ref = decks_collection(uid).document()
    now = datetime.now(timezone.utc)
    ref.set({
        "courseId": payload.courseId,
        "sourceDocumentId": payload.sourceDocumentId,
        "title": payload.title,
        "description": payload.description or "",
        "cardCount": 0,
        "generationMethod": "manual",
        "status": "ready",
        "jobId": None,
        "errorMessage": None,
        "createdAt": now,
        "updatedAt": now,
    })
    course_ref(uid, payload.courseId).update({
        "deckCount": gcf.Increment(1),
        "updatedAt": gcf.SERVER_TIMESTAMP,
    })
    logger.info("deck_created", extra={"uid": uid, "deck_id": ref.id, "kind": "manual"})
    return _to_deck_read(ref.get())


def update_deck(uid: str, deck_id: str, payload: DeckUpdate) -> DeckRead:
    ref = deck_ref(uid, deck_id)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Deck not found")

    updates: dict[str, object] = {
        "updatedAt": datetime.now(timezone.utc),
    }
    if payload.title is not None:
        updates["title"] = payload.title
    if payload.description is not None:
        updates["description"] = payload.description
    ref.update(updates)
    logger.info("deck_updated", extra={"uid": uid, "deck_id": deck_id})
    return _to_deck_read(ref.get(), cards=_list_cards(uid, deck_id))


def delete_deck(uid: str, deck_id: str) -> None:
    ref = deck_ref(uid, deck_id)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Deck not found")

    data = snap.to_dict() or {}
    _delete_all_cards(uid, deck_id)
    ref.delete()

    course_id = data.get("courseId")
    if isinstance(course_id, str) and course_id:
        course_ref(uid, course_id).update({
            "deckCount": gcf.Increment(-1),
            "updatedAt": gcf.SERVER_TIMESTAMP,
        })

    source_document_id = data.get("sourceDocumentId")
    if isinstance(source_document_id, str) and source_document_id:
        document_ref(uid, source_document_id).update({
            "generatedAssets.deckIds": gcf.ArrayRemove([deck_id]),
        })

    logger.info("deck_deleted", extra={"uid": uid, "deck_id": deck_id})


def create_card(uid: str, deck_id: str, payload: CardCreate) -> CardRead:
    deck_snap = deck_ref(uid, deck_id).get()
    if not deck_snap.exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Deck not found")

    ref = cards_collection(uid, deck_id).document()
    now = datetime.now(timezone.utc)
    ref.set({
        "front": payload.front,
        "back": payload.back,
        "hint": payload.hint,
        "explanation": payload.explanation,
        "topic": payload.topic,
        "srs": CardSrs().model_dump(),
        "stats": CardStats().model_dump(),
        "createdAt": now,
    })
    deck_ref(uid, deck_id).update({
        "cardCount": gcf.Increment(1),
        "updatedAt": now,
    })
    logger.info("card_created", extra={"uid": uid, "deck_id": deck_id, "card_id": ref.id})
    return _to_card_read(ref.get())


def update_card(uid: str, deck_id: str, card_id: str, payload: CardUpdate) -> CardRead:
    ref = card_ref(uid, deck_id, card_id)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Card not found")

    updates: dict[str, object] = {}
    if payload.front is not None:
        updates["front"] = payload.front
    if payload.back is not None:
        updates["back"] = payload.back
    if payload.hint is not None:
        updates["hint"] = payload.hint
    if payload.explanation is not None:
        updates["explanation"] = payload.explanation
    if payload.topic is not None:
        updates["topic"] = payload.topic
    if updates:
        ref.update(updates)
        deck_ref(uid, deck_id).update({"updatedAt": datetime.now(timezone.utc)})
    logger.info("card_updated", extra={"uid": uid, "deck_id": deck_id, "card_id": card_id})
    return _to_card_read(ref.get())


def delete_card(uid: str, deck_id: str, card_id: str) -> None:
    ref = card_ref(uid, deck_id, card_id)
    if not ref.get().exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Card not found")
    ref.delete()
    deck_ref(uid, deck_id).update({
        "cardCount": gcf.Increment(-1),
        "updatedAt": datetime.now(timezone.utc),
    })
    logger.info("card_deleted", extra={"uid": uid, "deck_id": deck_id, "card_id": card_id})


def create_flashcards_job(
    uid: str,
    document_id: str,
    *,
    course_id: str,
    document_status: str,
    document_title: str,
    extraction_job_id: str | None,
    card_count: int,
) -> tuple[DeckRead, job_service.ClaimedJob]:
    if document_status == "failed":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Cannot generate flashcards from a failed document",
        )

    depends_on_job_id = None
    if document_status != "ready":
        if not extraction_job_id:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                "Document extraction is still pending and no extraction job was found",
            )
        depends_on_job_id = extraction_job_id

    now = datetime.now(timezone.utc)
    ref = decks_collection(uid).document()
    ref.set({
        "courseId": course_id,
        "sourceDocumentId": document_id,
        "title": f"{document_title} Flashcards",
        "description": "AI-generated flashcards from your document.",
        "cardCount": 0,
        "generationMethod": "ai",
        "status": "queued",
        "jobId": None,
        "errorMessage": None,
        "createdAt": now,
        "updatedAt": now,
    })

    course_ref(uid, course_id).update({
        "deckCount": gcf.Increment(1),
        "updatedAt": gcf.SERVER_TIMESTAMP,
    })

    job = job_service.enqueue_job(
        uid,
        "flashcards_gen",
        {
            "documentId": document_id,
            "deckId": ref.id,
            "cardCount": card_count,
        },
        output_refs={"deckId": ref.id},
        depends_on_job_id=depends_on_job_id,
    )
    ref.update({"jobId": job.id, "updatedAt": now})

    logger.info(
        "flashcards_job_created",
        extra={
            "uid": uid,
            "document_id": document_id,
            "deck_id": ref.id,
            "job_id": job.id,
            "card_count": card_count,
            "depends_on_job_id": depends_on_job_id,
        },
    )
    return _to_deck_read(ref.get()), job


def replace_ai_deck_cards(
    uid: str,
    deck_id: str,
    *,
    cards: list[CardCreate],
    title: str | None = None,
    description: str | None = None,
) -> None:
    ref = deck_ref(uid, deck_id)
    if not ref.get().exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Deck not found")

    _delete_all_cards(uid, deck_id)

    batch = get_db().batch()
    now = datetime.now(timezone.utc)
    for payload in cards:
        card_document = cards_collection(uid, deck_id).document()
        batch.set(card_document, {
            "front": payload.front,
            "back": payload.back,
            "hint": payload.hint,
            "explanation": payload.explanation,
            "topic": payload.topic,
            "srs": CardSrs().model_dump(),
            "stats": CardStats().model_dump(),
            "createdAt": now,
        })

    deck_updates: dict[str, object] = {
        "cardCount": len(cards),
        "updatedAt": now,
    }
    if title:
        deck_updates["title"] = title
    if description is not None:
        deck_updates["description"] = description
    batch.update(ref, deck_updates)
    batch.commit()


def _list_cards(uid: str, deck_id: str) -> list[CardRead]:
    snaps = cards_collection(uid, deck_id).order_by("createdAt", direction=gcf.Query.ASCENDING).stream()
    return [_to_card_read(snap) for snap in snaps]


def _delete_all_cards(uid: str, deck_id: str) -> None:
    snaps = list(cards_collection(uid, deck_id).stream())
    if not snaps:
        return
    batch = get_db().batch()
    for snap in snaps:
        batch.delete(snap.reference)
    batch.commit()


def _to_card_read(snap: gcf.DocumentSnapshot) -> CardRead:
    data = snap.to_dict() or {}
    return CardRead(
        id=snap.id,
        front=data.get("front", ""),
        back=data.get("back", ""),
        hint=data.get("hint"),
        explanation=data.get("explanation"),
        topic=data.get("topic"),
        srs=CardSrs(**(data.get("srs") or {})),
        stats=CardStats(**(data.get("stats") or {})),
        createdAt=_to_dt(data.get("createdAt")),
    )


def _to_deck_read(
    snap: gcf.DocumentSnapshot,
    *,
    cards: list[CardRead] | None = None,
) -> DeckRead:
    data = snap.to_dict() or {}
    return DeckRead(
        id=snap.id,
        courseId=data.get("courseId", ""),
        sourceDocumentId=data.get("sourceDocumentId"),
        title=data.get("title", ""),
        description=data.get("description", ""),
        cardCount=int(data.get("cardCount", 0)),
        generationMethod=data.get("generationMethod", "manual"),
        status=data.get("status", "ready"),
        jobId=data.get("jobId"),
        errorMessage=data.get("errorMessage"),
        createdAt=_to_dt(data.get("createdAt")),
        updatedAt=_to_dt(data.get("updatedAt")),
        cards=cards or [],
    )


def _to_dt(value) -> Optional[datetime]:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    return None
