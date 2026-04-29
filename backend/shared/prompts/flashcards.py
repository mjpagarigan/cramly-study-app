"""Prompts for flashcard generation."""

from __future__ import annotations

import re

_MAX_SOURCE_CHARS = 9000
_FALLBACK_SOURCE_CHARS = 4500


def build_flashcard_messages(
    *,
    title: str,
    source_text: str,
    card_count: int,
    aggressive_trim: bool = False,
) -> list[dict[str, str]]:
    excerpt, truncated = _trim_source_text(
        source_text,
        aggressive_trim=aggressive_trim,
    )
    truncation_note = (
        "\nThe source excerpt was truncated to stay within the model context window. "
        "Only create cards that are directly supported by the excerpt."
        if truncated
        else ""
    )

    return [
        {
            "role": "system",
            "content": (
                "You create college-study flashcards from extracted course material. "
                "Return JSON only, with no markdown, code fences, or commentary. "
                "Use this exact shape: "
                '{"title":"string","description":"string","cards":[{"front":"string","back":"string","hint":"string","explanation":"string","topic":"string"}]}. '
                "Every card must be unique, accurate, and useful for active recall."
            ),
        },
        {
            "role": "user",
            "content": (
                f"Document title: {title}\n"
                f"Target card count: {card_count}\n\n"
                "Requirements:\n"
                f"- Generate exactly {card_count} cards when the material supports it. Otherwise generate as many high-confidence cards as possible, but never fewer than 4.\n"
                "- Keep each front concise and answerable without extra context.\n"
                "- Keep each back direct and compact. Avoid long paragraphs.\n"
                "- Prefer concepts, comparisons, causes/effects, definitions, and processes over trivia.\n"
                "- Use `hint` for a short nudge when it genuinely helps.\n"
                "- Use `explanation` for a one- or two-sentence clarification only when useful.\n"
                "- Use a short `topic` label when you can infer one.\n"
                "- If a field is not needed, return an empty string for it.\n"
                f"{truncation_note}\n\n"
                "Source material:\n"
                f"{excerpt}"
            ),
        },
    ]


def _trim_source_text(
    source_text: str,
    *,
    aggressive_trim: bool,
) -> tuple[str, bool]:
    cleaned = _normalize_source_text(source_text)
    limit = _FALLBACK_SOURCE_CHARS if aggressive_trim else _MAX_SOURCE_CHARS
    if len(cleaned) <= limit:
        return cleaned, False
    return cleaned[:limit], True


def _normalize_source_text(source_text: str) -> str:
    cleaned = source_text.replace("\r\n", "\n").replace("\r", "\n").strip()
    cleaned = re.sub(r"[ \t]+", " ", cleaned)
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)
    return cleaned
