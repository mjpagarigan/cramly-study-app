"""Deck and card endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Response, status

from api.deps import get_current_user
from api.models.deck import CardCreate, CardRead, CardUpdate, DeckCreate, DeckRead, DeckUpdate
from api.services import decks as service

router = APIRouter(prefix="/decks", tags=["decks"])


@router.get("", response_model=list[DeckRead])
async def list_decks(
    courseId: str | None = Query(default=None),
    uid: str = Depends(get_current_user),
) -> list[DeckRead]:
    return service.list_decks(uid, course_id=courseId)


@router.get("/{deck_id}", response_model=DeckRead)
async def get_deck(deck_id: str, uid: str = Depends(get_current_user)) -> DeckRead:
    return service.get_deck(uid, deck_id)


@router.post("", response_model=DeckRead, status_code=status.HTTP_201_CREATED)
async def create_deck(
    payload: DeckCreate,
    uid: str = Depends(get_current_user),
) -> DeckRead:
    return service.create_manual_deck(uid, payload)


@router.patch("/{deck_id}", response_model=DeckRead)
async def update_deck(
    deck_id: str,
    payload: DeckUpdate,
    uid: str = Depends(get_current_user),
) -> DeckRead:
    return service.update_deck(uid, deck_id, payload)


@router.delete(
    "/{deck_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
)
async def delete_deck(
    deck_id: str,
    uid: str = Depends(get_current_user),
):
    service.delete_deck(uid, deck_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/{deck_id}/cards",
    response_model=CardRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_card(
    deck_id: str,
    payload: CardCreate,
    uid: str = Depends(get_current_user),
) -> CardRead:
    return service.create_card(uid, deck_id, payload)


@router.patch("/{deck_id}/cards/{card_id}", response_model=CardRead)
async def update_card(
    deck_id: str,
    card_id: str,
    payload: CardUpdate,
    uid: str = Depends(get_current_user),
) -> CardRead:
    return service.update_card(uid, deck_id, card_id, payload)


@router.delete(
    "/{deck_id}/cards/{card_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
)
async def delete_card(
    deck_id: str,
    card_id: str,
    uid: str = Depends(get_current_user),
):
    service.delete_card(uid, deck_id, card_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
