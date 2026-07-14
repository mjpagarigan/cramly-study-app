# Cramly Feature Catalog

Last audited against the Flutter app and FastAPI/worker source: **July 14, 2026**.

Cramly is a mobile-first study app for college students. It turns course material into searchable extracted text, AI-generated flashcards, and AI-generated summaries. The broader product roadmap adds quizzes, spaced repetition, podcasts, voice study, and learning analytics.

## Status key

- **Implemented** — present in the current Flutter app and backend.
- **Partial** — some UI, data model, or infrastructure exists, but the complete user workflow is not available.
- **Planned** — described in the product specification or shown as a disabled placeholder, but not implemented.
- **Future** — intentionally deferred until after the MVP.

## Current feature summary

| Area | Status | What is available now |
|---|---|---|
| Authentication | Implemented | Email/password registration and sign-in, Google sign-in, persistent sessions, and sign-out |
| App navigation | Implemented | Five-tab mobile shell: Home, Library, Study, Progress, and Profile |
| Appearance | Implemented | Dark, light, and system themes with local persistence |
| Courses | Implemented | Create, search, view, edit, color-code, and delete courses |
| Content ingestion | Implemented | PDF, DOCX, PPTX, Markdown, image, audio, YouTube, and web article sources |
| Text extraction | Implemented | Background extraction/transcription with live status and errors |
| Flashcards | Implemented | AI generation, manual deck/card CRUD, and basic front/back review |
| Summaries | Implemented | AI summaries at TL;DR, Detailed, and ELI5 depths with Markdown rendering |
| Async processing | Implemented | Firestore-backed jobs, progress updates, dependencies, retries, and stuck-job recovery |
| Spaced repetition | Partial | SRS fields and indexes exist; scheduling, ratings, and the daily queue do not |
| Home dashboard | Partial | Personalized date/greeting exists; streak, due-card, and recent-activity data are placeholders |
| Quizzes and exams | Planned | Placeholder UI and planned data model only |
| Study guides | Planned | Planned data model and security path only |
| Podcasts | Planned | Placeholder UI and provider configuration only |
| Voice quiz mode | Planned | Product specification only |
| Progress and analytics | Planned | Placeholder screen and planned indexes/data model only |

## Implemented features

### 1. Authentication and account access

- Register with an email address and password.
- Sign in with an existing email/password account.
- Sign in with Google.
- Validate required email and password fields.
- Validate basic email shape and require at least eight password characters during registration.
- Display Firebase authentication errors without leaving the sign-in screen.
- Restore an existing Firebase session at launch.
- Show a splash screen while authentication state is being restored.
- Redirect signed-out users to Login and signed-in users away from Login/Splash to Home.
- Sign out from the Profile screen, including the Firebase and Google sessions.
- Attach the signed-in user's Firebase ID token to protected backend requests.

### 2. Mobile app shell and navigation

- Five persistent bottom-navigation destinations:
  - Home
  - Library
  - Study
  - Progress
  - Profile
- Each tab preserves its own navigation branch through an indexed navigation shell.
- A floating action button appears on Home and Library.
- The floating action menu provides shortcuts to:
  - Upload study material
  - Create a course
- Nested routes support course, document, deck, deck review, and summary detail screens.
- The Flutter codebase targets both iOS and Android.

### 3. Home screen

- Displays the current date.
- Uses the time of day for a morning, afternoon, or evening greeting.
- Personalizes the greeting with the user's display name or email prefix.
- Includes dashboard cards for study streak and cards due.
- Includes a recent-activity area and first-course onboarding prompt.

The streak and due-card values are currently hard-coded to zero, and recent activity is not yet connected to study data.

### 4. Profile and appearance

- Displays the user's name and email.
- Generates an initials avatar when no profile image is shown.
- Offers dark, light, and system-following theme modes.
- Persists the selected theme on the device with shared preferences.
- Provides a sign-out action.

### 5. Course organization

- Create a course with a required name.
- Choose from eight course colors.
- List courses in most-recently-updated order.
- Search courses by name with live, case-insensitive filtering.
- Show dedicated empty states for no courses and no search matches.
- Open a course detail screen.
- Edit a course's name and color.
- Delete a course after confirmation.
- Display denormalized document, deck, and quiz counts.
- Receive live course changes through Firestore listeners.
- Keep Firestore's local cache available to support responsive reads and reconnection.
- Organize a course into Documents, Decks, Quizzes, and Podcasts tabs.

Documents and decks are functional. Quizzes and podcasts are placeholder tabs.

### 6. Study-material upload workflow

- Start an upload globally from the floating action button.
- Start an upload from a course with that course preselected.
- Select a source, review it, assign it to a course, process it, and see a completion state.
- Create a new course without leaving the assignment step; the new course is selected automatically.
- Display selected file name, type, and size before upload.
- Clear a selected source and choose another.
- Validate YouTube and web URLs before accepting them.
- Upload files directly from the mobile app to the user's Firebase Storage namespace.
- Show byte-level file upload progress as a percentage.
- Disable the upload screen's close action during the active upload phase.
- Show processing, ready, and failure states.
- Retry a failed upload workflow by resetting the form.
- Jump to the assigned course after creation or immediately begin another upload.

The current picker handles one source at a time; bulk/multi-file upload is not implemented.

### 7. Supported source types and extraction behavior

#### PDF

- Accepts `.pdf` files.
- Extracts text with `pdfplumber` first and PyMuPDF as a fallback.
- Records the PDF page count.
- Reports a clear error for scanned/image-only PDFs with no text layer.

#### DOCX

- Accepts `.docx` files.
- Extracts body paragraphs.
- Flattens table rows into readable, pipe-separated text.

#### PPTX

- Accepts `.pptx` files.
- Preserves slide order.
- Labels extracted sections by slide number.
- Extracts text shapes and speaker notes.
- Records the slide count as the document page count.

#### Markdown

- Accepts `.md` and `.markdown` files.
- Preserves the source text and its Markdown structure.
- Handles non-standard text bytes with a permissive UTF-8 fallback.

#### Images

- Accepts PNG, JPG/JPEG, WebP, BMP, and TIFF images.
- Uses Tesseract OCR to extract printed text.
- Reports missing Tesseract installation and empty OCR results clearly.

#### Audio

- Accepts MP3, M4A, WAV, FLAC, OGG, and WebM audio.
- Transcribes speech with Groq's `whisper-large-v3-turbo` model.
- Reports when no speech is detected.
- Enforces Groq's current 25 MB transcription limit.

#### YouTube

- Accepts standard watch URLs, Shorts URLs, embed URLs, `youtu.be` URLs, and raw video IDs.
- Fetches English human or auto-generated captions.
- Reports disabled captions, unavailable videos, missing transcripts, and invalid IDs.

#### Web articles

- Fetches and cleans article text with Trafilatura.
- Removes common navigation, advertising, comments, and sidebar noise.
- Includes readable table content when available.
- Uses extracted article metadata to improve the document title.
- Reports network, paywall, client-rendering, and unreadable-body failures.

### 8. Document library and detail view

- List a course's documents newest first with real-time updates.
- Show each source's type, title, extraction status, and metadata.
- Track document states as extracting, ready, or failed.
- Display word count and page/slide count when available.
- Load extracted text from Firebase Storage.
- Scroll and select extracted text.
- Show detailed extraction errors.
- Delete a document after confirmation.
- Delete both the original upload and extracted text from Storage when the document is deleted.
- Decrement the owning course's document count after deletion.
- Track IDs of generated decks and summaries on the source document.
- Open the latest generated deck or summary from the source document.

### 9. AI flashcard generation

- Generate a deck from a ready document.
- Choose an 8-card quick set, 12-card balanced set, or 16-card deeper set.
- Generate cards with Groq using the configured language model.
- Produce a front, back, and optional hint, explanation, and topic for each card.
- Retry oversized model requests with a smaller source excerpt.
- Return a helpful error when the document is too large for the configured model plan.
- Require a minimum number of usable generated cards before marking the deck ready.
- Track queued, generating, ready, and failed deck states.
- Display generation progress from the background job.
- Link generated decks to their source document and course.
- Update course deck counts and source-document generated-asset references.

### 10. Manual decks and cards

- Create a standalone manual deck inside a course.
- Set and edit a deck title and optional description.
- Delete a deck and all of its cards after confirmation.
- Distinguish AI-generated and manual decks in the UI.
- List decks by most recent update with real-time Firestore updates.
- Add, edit, and delete individual flashcards.
- Require a front and back for every card.
- Optionally add a hint, explanation, and topic.
- Keep the deck card count synchronized after card changes.
- Remove a deleted AI deck from its source document's generated-assets list.

### 11. Basic flashcard review

- Review every card in a selected deck in creation order.
- Show the current card number and total card count.
- Display the card's question, optional topic, and optional hint.
- Tap the card or button to reveal/hide its answer.
- Display an optional explanation on the answer side.
- Move to the previous or next card.
- Finish the session after the last card.

This is a linear review browser. It does not yet collect recall ratings, update card statistics, schedule the next review, or create a study-session record.

### 12. AI summaries

- Generate a summary from a ready document.
- Choose one of three depths:
  - **TL;DR** — only the biggest takeaways
  - **Detailed** — structured notes with supporting detail
  - **ELI5** — simpler language for quick understanding
- Generate the summary with Groq in a background job.
- Retry oversized requests with a smaller document excerpt.
- Track queued, generating, ready, and failed states.
- Show live background-job progress.
- Render generated content as selectable GitHub-flavored Markdown.
- Style headings, lists, blockquotes, and tables for mobile reading.
- Link the summary to its source document and course.
- Open the most recently generated summary from the document detail screen.

### 13. Background jobs and reliability

- Store long-running work in a Firestore-backed async queue.
- Currently process these job types:
  - Text extraction/transcription
  - Flashcard generation
  - Summary generation
- Return API requests quickly while work continues in a separate worker.
- Stream job and artifact status changes to the mobile app through Firestore.
- Track percentage progress, timestamps, worker ID, attempts, errors, inputs, and outputs.
- Chain generation jobs behind document extraction when required.
- Claim jobs transactionally to reduce duplicate processing.
- Retry recoverable failures up to the configured attempt limit.
- Mark unrecoverable content errors as failed immediately.
- Detect and requeue jobs abandoned by a stopped worker.
- Use idempotency checks to avoid repeating already-completed extraction or generation work.
- Expose a backend health endpoint with version, environment, and uptime.

### 14. Security and data isolation

- Store user-owned Firestore data under `users/{userId}`.
- Restrict Firestore reads and writes to the authenticated owner.
- Allow clients to read async-job status while reserving async-job writes for the server.
- Store uploads under a per-user Firebase Storage path.
- Restrict Storage access to the authenticated owner.
- Restrict client uploads to an allowlist of document, text, image, and audio MIME types.
- Enforce a Storage rules limit of less than 50 MB per uploaded file.
- Verify Firebase bearer tokens on protected FastAPI routes.
- Scope every course, document, deck, card, and summary operation to the verified user ID.

## Partial and planned MVP features

### Spaced repetition and the Study tab — Partial / Planned

Already present:

- Card records contain ease factor, interval, repetitions, next review date, and last-reviewed date fields.
- Card records contain times-shown, times-correct, and times-wrong counters.
- A collection-group index exists for next-review dates.
- The app has a Study navigation tab.

Still planned:

- SM-2 scheduling calculations.
- Recall-quality/rating controls after each card.
- A cross-deck daily review queue.
- Persisted review sessions and study time.
- Due-card counts on Home.
- Forgetting-curve visualization.
- Leech detection and AI-assisted card rewriting.

### Quizzes and exams — Planned

- AI-generated, document-tied quizzes.
- Standalone manually authored quizzes/exams.
- Manual exam builder with full question CRUD.
- Multiple choice, true/false, fill-in-the-blank, short answer, essay, matching, and ordering questions.
- Practice and timed exam modes.
- Adaptive difficulty.
- AI grading for short answers and essays, including rubric feedback.
- Attempt history, scoring, per-answer timing, and completion states.
- Past-mistakes quizzes rebuilt from previously incorrect answers.

Firestore security paths, an attempts index, course counters, and placeholder UI exist, but there is no current quiz API or usable quiz screen.

### Study guides — Planned

- Generate a structured Markdown study guide from source material.
- Organize it with headings, key points, and examples.
- Associate the guide with its source document and course.

A planned Firestore path/data shape exists, but there is no generator, API, or reader screen.

### AI podcasts — Planned

- Generate a natural two-speaker dialogue from course material.
- Synthesize two distinct voices with ElevenLabs.
- Play the generated audio in the app.
- Read the complete dialogue transcript.
- Track queued, generating, ready, and failed states.

The Podcasts tab, disabled document action, storage/security paths, and an ElevenLabs configuration field exist. Podcast generation and playback are not implemented.

### Voice quiz mode — Planned

- Read questions aloud with text-to-speech.
- Record spoken answers through the device microphone.
- Transcribe answers with Whisper.
- Grade spoken answers with AI.
- Support hands-free study while commuting or exercising.

### Progress and analytics — Planned

- Knowledge-gap heatmap by topic.
- Topic/concept mastery scores from 0–100%.
- Consecutive-day and longest study streaks.
- Time tracking per session, course, and day.
- Weakness detection for low or declining mastery.
- Forgetting-curve views.
- Pre-exam readiness score from coverage, mastery, and recency.
- Home-screen recent activity and live dashboard statistics.

The Progress tab is currently an empty-state placeholder. Some planned Firestore paths and indexes exist, but no analytics computation or charts are implemented.

### Remaining account features — Planned

- Apple sign-in.
- Edit display name.
- Upload or change an avatar.
- Select a default/preferred language.
- Notification preferences.
- Daily study-goal settings.

### Upload enhancements — Planned

- Bulk/multi-file upload.
- OCR for scanned/image-only PDFs.
- Handwriting recognition.
- Audio splitting or compression for files over 25 MB.
- Production-ready Tesseract packaging on the current native Render deployment.

## Post-MVP feature roadmap

### Version 1.5

- Mind maps and concept maps.
- Cornell-notes auto-formatting.
- Cheat-sheet and formula extraction.
- Glossary generation.
- Cross-document synthesis into one study guide.
- Multilingual podcast generation, including Filipino/Tagalog voices.
- Shared decks and study rooms.
- Google Classroom and Canvas integrations.

### Version 2

- Handwriting OCR through a paid recognition service.
- Lecture recording with live transcription.
- Solo-narrator audio summaries.
- AI tutor chat grounded in uploaded material.
- Socratic quiz mode.
- More advanced adaptive difficulty using an item-response model.
- Public deck library.
- Teacher/professor mode.

## Current limitations and caveats

- Course deletion currently deletes only the course record. It does **not** cascade to that course's documents, files, decks, cards, summaries, or future assets, despite the destructive confirmation text in the UI.
- Deleting a source document removes its original and extracted text, but does not delete decks or summaries already generated from it.
- Image OCR requires the native Tesseract binary and is not production-ready on the current native Render worker setup.
- Scanned PDFs are not routed through image OCR.
- YouTube extraction currently requests English captions.
- Web extraction may fail on paywalled or heavily client-rendered pages.
- The mobile client retrieves at most 5 MB for an extracted-text preview.
- Summary history has no dedicated list or delete workflow; the document screen links only to the latest summary ID.
- Basic deck review does not yet write SRS state, performance statistics, streaks, or analytics.
- The Home, Study, and Progress tabs contain intentional placeholders for later sprints.
- The `README.md` sprint checklist has not been updated for the shipped flashcard flow; the source and recent Sprint 5 commit show that AI flashcards and manual deck/card CRUD are implemented.

## Primary implementation stack

- **Mobile:** Flutter and Dart
- **State management:** Riverpod
- **Navigation:** GoRouter
- **Authentication:** Firebase Authentication
- **Database and live updates:** Cloud Firestore
- **File storage:** Firebase Storage
- **Backend API:** FastAPI
- **Background processing:** Python worker with Firestore as the queue
- **LLM generation:** Groq with the configured `openai/gpt-oss-120b` model
- **Audio transcription:** Groq Whisper
- **OCR:** Tesseract
- **Deployment:** Render web service and background worker
