"""Prompts for summary generation."""

from __future__ import annotations

from api.models.summary import SummaryDepth

MAX_SOURCE_CHARS = 60000

_DEPTH_INSTRUCTIONS: dict[SummaryDepth, str] = {
    "tldr": (
        "Keep it short and high signal. Use a title, a one-paragraph overview, "
        "and 4-6 bullets covering the most important takeaways."
    ),
    "detailed": (
        "Use a structured study-note format. Include a title, overview, key ideas, "
        "important supporting details, and a short recap section."
    ),
    "eli5": (
        "Explain the material in simpler language without becoming childish. "
        "Use short paragraphs, plain examples, and a tiny glossary for hard terms."
    ),
}


def build_summary_messages(
    *,
    title: str,
    depth: SummaryDepth,
    source_text: str,
) -> list[dict[str, str]]:
    excerpt, truncated = _trim_source_text(source_text)
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
                "that are not grounded in the provided material."
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
                "- Preserve important formulas, names, and technical terms when present.\n"
                "- If the source itself is incomplete or unclear, say so briefly instead of guessing."
                f"{truncation_note}\n\n"
                "Source material:\n"
                f"{excerpt}"
            ),
        },
    ]


def _trim_source_text(source_text: str) -> tuple[str, bool]:
    cleaned = source_text.strip()
    if len(cleaned) <= MAX_SOURCE_CHARS:
        return cleaned, False
    return cleaned[:MAX_SOURCE_CHARS], True
