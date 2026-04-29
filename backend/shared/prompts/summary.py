"""Prompts for summary generation."""

from __future__ import annotations

import re

from api.models.summary import SummaryDepth

_MAX_SOURCE_CHARS_BY_DEPTH: dict[SummaryDepth, int] = {
    "tldr": 9000,
    "detailed": 18000,
    "eli5": 5000,
}

_FALLBACK_SOURCE_CHARS_BY_DEPTH: dict[SummaryDepth, int] = {
    "tldr": 5000,
    "detailed": 10000,
    "eli5": 2500,
}

_DEPTH_INSTRUCTIONS: dict[SummaryDepth, str] = {
    "tldr": (
        "Keep it short and high signal. Use a title, a one-paragraph overview, "
        "and 4-6 bullets covering the most important takeaways. Keep it around "
        "120-180 words."
    ),
    "detailed": (
        "Use a structured study-note format. Include a title, overview, key ideas, "
        "important supporting details, and a short recap section. Keep it focused "
        "and usually under 500 words unless the source clearly needs more."
    ),
    "eli5": (
        "Explain the material in simpler language without becoming childish. "
        "Use short paragraphs, plain examples, and a tiny glossary for hard terms. "
        "Keep the explanation compact, focus on the clearest core ideas first, "
        "and usually stay within 180-260 words."
    ),
}


def build_summary_messages(
    *,
    title: str,
    depth: SummaryDepth,
    source_text: str,
    aggressive_trim: bool = False,
) -> list[dict[str, str]]:
    excerpt, truncated = _trim_source_text(
        source_text,
        depth=depth,
        aggressive_trim=aggressive_trim,
    )
    truncation_note = (
        "\nThe source excerpt was truncated to stay within the model context window. "
        "Summarize only what you can support from the excerpt."
        if truncated
        else ""
    )

    return [
        {
            "role": "system",
            "content": (
                "You turn extracted study material into student-friendly summaries. "
                "Return Markdown only. Do not use code fences. Do not invent facts "
                "that are not grounded in the provided material. Do not use markdown "
                "tables; use headings, bullets, and short paragraphs instead."
            ),
        },
        {
            "role": "user",
            "content": (
                f"Document title: {title}\n"
                f"Requested depth: {depth}\n\n"
                "Output requirements:\n"
                f"- {_DEPTH_INSTRUCTIONS[depth]}\n"
                "- Prefer concise headings and bullets over long walls of text.\n"
                "- Do not use markdown tables. If you need comparisons, convert them to bullets.\n"
                "- Preserve important formulas, names, and technical terms when present.\n"
                "- If the source itself is incomplete or unclear, say so briefly instead of guessing."
                f"{truncation_note}\n\n"
                "Source material:\n"
                f"{excerpt}"
            ),
        },
    ]


def _trim_source_text(
    source_text: str,
    *,
    depth: SummaryDepth,
    aggressive_trim: bool,
) -> tuple[str, bool]:
    cleaned = _normalize_source_text(source_text)
    limit = (
        _FALLBACK_SOURCE_CHARS_BY_DEPTH[depth]
        if aggressive_trim
        else _MAX_SOURCE_CHARS_BY_DEPTH[depth]
    )
    if len(cleaned) <= limit:
        return cleaned, False
    return cleaned[:limit], True


def _normalize_source_text(source_text: str) -> str:
    cleaned = source_text.replace("\r\n", "\n").replace("\r", "\n").strip()
    cleaned = re.sub(r"[ \t]+", " ", cleaned)
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)
    return cleaned
