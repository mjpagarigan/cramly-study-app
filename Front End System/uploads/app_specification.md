# StudyApp — App Specification

> Working title: `[APP_NAME]` — replace throughout when finalized.

---

## 1. Overview

A study app for college students that turns uploaded course materials (PDFs, slides, lecture notes) into AI-generated study tools: flashcards, practice exams, study guides, summaries, and two-speaker audio podcasts. Inspired by TheaApp's study material generation and NotebookLM's audio overviews, with spaced repetition, voice-based quizzes, and progress analytics layered on top.

### Inspiration & Differentiation
- **TheaApp** — file-to-study-material generation (flashcards, exams, study guides, manual exam builder)
- **NotebookLM** — two-speaker AI podcast generation
- **Anki** — spaced repetition system (SRS) for long-term retention
- **Differentiator** — combines all three in one mobile-first product targeted at college students, with strong analytics and voice-based study modes.

### Target User
- **Primary:** College students (undergraduate, any major)
- **Use cases:** Exam prep, weekly review, lecture digestion, group study material creation
- **Context:** Mobile-first usage, on-the-go study, mix of structured (exam-week cramming) and unstructured (daily review) sessions

### Pricing & Business Model
- **MVP v1:** Completely free
- **Future:** Freemium model TBD (premium features likely include unlimited podcasts, handwriting OCR, advanced analytics)

---

## 2. Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Mobile client | Flutter | Single codebase iOS + Android; dev already familiar |
| Backend API | FastAPI (Python) | Async-friendly, lightweight, great LLM ecosystem |
| Hosting | Render Pro | Two services (API + worker), no cold starts on Pro |
| Auth | Firebase Auth | Email, Google, Apple sign-in out of the box |
| Database | Cloud Firestore | Real-time listeners, scales free, no schema migrations |
| File storage | Firebase Storage | Direct mobile uploads, integrates with Auth |
| LLM | Groq + `openai/gpt-oss-120b` | Fastest hosted inference, smartest open model on Groq, $0.15/M input |
| Speech-to-text | Groq Whisper | Same provider, voice quiz mode |
| Text-to-speech | ElevenLabs (premium account) | High-quality voices for podcast feature |
| PDF extraction | `pdfplumber` + `PyMuPDF` | Free, robust, handles most academic PDFs |
| OCR (printed text) | Tesseract | Free, local, sufficient for printed pages in v1 |
| Async jobs | Firestore-as-queue + Render Background Worker | Zero new infra, real-time job pickup |

---

## 3. MVP v1 Feature Set

### 3.1 Content Ingestion
- **Multi-format upload**
  - PDF (primary)
  - DOCX, PPTX
  - Image upload with OCR (printed text only — handwriting deferred to v2)
  - YouTube URL (transcript extraction)
  - Web URL (article extraction)
  - Audio file upload (transcribed via Whisper)
- **Bulk upload** — multi-select to upload several files at once

### 3.2 AI-Generated Study Materials
On any uploaded document, the user explicitly chooses what to generate. Available generators:
- **Flashcards** (Anki-style: front/back, optional hint and explanation)
- **Practice exam / quiz** (mixed question types — see 3.4)
- **Study guide** (structured markdown document, headings + key points + examples)
- **Summary** (three depth levels: TL;DR, detailed, ELI5)
- **Manual exam builder** — full CRUD interface for users to write their own questions

### 3.3 Audio Features
- **Two-speaker AI podcast** — natural-sounding dialogue between two distinct ElevenLabs voices, generated from document content. Includes transcript view.
- **Voice-based quiz mode** — hands-free quiz: app reads question via TTS, user answers via mic, Whisper transcribes, AI grades response. Useful while commuting/exercising.

### 3.4 Quiz & Exam Variety
- **Question types supported**
  - Multiple choice (MCQ)
  - True/false
  - Fill-in-the-blank
  - Short answer (AI-graded with leniency)
  - Essay (AI-graded with rubric feedback)
  - Matching
  - Ordering / sequencing
- **Quiz/exam modes**
  - Standalone quizzes (created without a source document)
  - Document-tied quizzes (auto-generated from uploaded material)
  - Adaptive difficulty (questions get harder as user gets answers right)
  - Timed exam simulator (full timer, no pausing, mimics real exam)
  - Past-mistakes quiz (auto-rebuilt from previously wrong answers)

### 3.5 Spaced Repetition (SRS)
- **SM-2 algorithm** (the algorithm Anki uses) — well-documented, proven
- **Daily review queue** — surfaces due cards across all decks
- **Forgetting curve visualization** — chart showing retention over time per deck/topic
- **Leech detection with AI rewriting** — cards repeatedly failed get flagged; user can ask AI to rewrite them more clearly

### 3.6 Progress & Analytics
- **Knowledge gap heatmap** — color-coded grid by topic showing mastery levels
- **Mastery levels per concept/topic** (0–100%)
- **Study streaks** (consecutive days)
- **Time tracking** (per session, per course, per day)
- **Weakness detection** — surfaces topics with declining or low mastery
- **Pre-exam readiness score** — computed score (0–100) estimating exam preparedness, based on coverage, mastery, and recency

### 3.7 Organization
- **Courses/Subjects** — top-level folders. Every document, deck, and quiz lives inside a course.

### 3.8 Auth & Account
- Email/password signup
- Google sign-in
- Apple sign-in (required for App Store)
- Profile basics: display name, avatar, default language

---

## 4. Out of Scope (v1) — Future Versions

### v1.5 (post-launch, after first user feedback)
- Mind maps / concept maps
- Cornell notes auto-formatter
- Cheat sheet / formula extractor
- Glossary builder
- Cross-document synthesis (combine multiple PDFs into one study guide)
- Multilingual podcast generation (Filipino/Tagalog voices)
- Collaboration features (shared decks, study rooms)
- LMS integrations (Google Classroom, Canvas)

### v2
- Handwriting OCR (paid API, likely premium feature)
- Lecture recording with live transcription
- Solo narrator audio summaries
- AI tutor chat grounded in materials
- Socratic mode quizzes
- Adaptive difficulty refinements (proper IRT model)
- Public deck library
- Teacher/professor mode

---

## 5. Data Models — Firestore Schema

> All data lives under `users/{userId}` for clean security rules (`request.auth.uid == userId`).

### 5.1 Core Entities

```
users/{userId}
  email, displayName, photoURL
  createdAt, lastActiveAt
  settings: { theme, notifications, dailyGoalMinutes, preferredLanguage }
  stats:    { currentStreak, longestStreak, totalStudyMinutes, lastStudyDate }
  usage:    { dailyPodcasts, dailyGenerations, resetAt }   // rate limit counters
  readinessScore: number  // computed nightly across all courses

users/{userId}/courses/{courseId}
  name, color, icon
  documentCount, deckCount, quizCount  // denormalized for list views
  createdAt, updatedAt

users/{userId}/documents/{documentId}
  courseId
  title, fileName, fileSize, mimeType
  storagePath          // path in Firebase Storage
  status               // uploading | extracting | ready | failed
  pageCount, wordCount
  extractedTextPath    // separate Storage file (text often >1MB)
  generatedAssets: { deckIds, quizIds, summaryIds, studyGuideIds, podcastIds }
  uploadedAt
```

### 5.2 Generated Content

```
users/{userId}/decks/{deckId}
  courseId
  sourceDocumentId        // nullable for manual decks
  title, description
  cardCount
  generationMethod        // ai | manual
  createdAt, updatedAt

users/{userId}/decks/{deckId}/cards/{cardId}      [subcollection]
  front, back
  hint, explanation
  topic                   // for heatmap and weakness detection
  srs: {
    easeFactor: 2.5,      // SM-2 starts at 2.5
    interval: 0,          // days until next review
    repetitions: 0,
    nextReviewDate: timestamp,
    lastReviewedAt: timestamp
  }
  stats: { timesShown, timesCorrect, timesWrong }
  createdAt

users/{userId}/quizzes/{quizId}
  courseId
  sourceDocumentId        // nullable for standalone quizzes
  title, description
  quizType                // practice | exam
  timeLimit               // seconds, nullable
  questionCount
  generationMethod        // ai | manual
  createdAt, updatedAt

users/{userId}/quizzes/{quizId}/questions/{questionId}    [subcollection]
  questionType            // mcq | true_false | fill_blank | short_answer | essay | matching | ordering
  prompt
  options                 // array (mcq, matching)
  correctAnswer           // shape varies by type
  explanation
  points
  difficulty              // easy | medium | hard
  topic
  order
  rubric                  // essays only

users/{userId}/summaries/{summaryId}
  courseId, sourceDocumentId
  depth                   // tldr | detailed | eli5
  content                 // markdown
  createdAt

users/{userId}/studyGuides/{studyGuideId}
  courseId, sourceDocumentId
  title, content          // markdown
  createdAt

users/{userId}/podcasts/{podcastId}
  courseId, sourceDocumentId
  title
  audioStoragePath
  duration                // seconds
  script                  // two-speaker dialogue, for transcript view
  status                  // generating | ready | failed
  createdAt
```

### 5.3 Activity & Progress

```
users/{userId}/quizAttempts/{attemptId}
  quizId
  mode                    // practice | exam | past_mistakes | adaptive
  status                  // in_progress | completed | abandoned
  startedAt, completedAt
  timeSpent
  score, totalPoints
  answers: [
    { questionId, userAnswer, isCorrect, pointsEarned, timeSpent, topic }
  ]

users/{userId}/reviewSessions/{sessionId}
  date                    // YYYY-MM-DD (one doc per day)
  durationMinutes
  cardsReviewed
  quizzesTaken
  sessionType             // flashcards | quiz | mixed

users/{userId}/topics/{topicId}
  name, courseId
  masteryScore            // 0-100, computed
  questionsAttempted, questionsCorrect
  cardsLearned, cardsLeeched
  lastReviewedAt
  // drives heatmap and weakness detection

users/{userId}/asyncJobs/{jobId}
  type                    // text_extraction | flashcards_gen | quiz_gen | summary_gen | study_guide_gen | podcast_gen
  status                  // queued | processing | completed | failed
  progress                // 0-100
  inputRefs               // { documentId, ... }
  outputRefs              // { deckId, podcastId, ... }
  errorMessage
  workerId                // which worker claimed it
  createdAt, startedAt, completedAt
```

### 5.4 Required Composite Indexes
- `cards` collection group: `nextReviewDate <= now`, order `nextReviewDate ASC`
- `documents`: `courseId == X`, order `uploadedAt DESC`
- `quizAttempts`: `status == completed`, order `completedAt DESC`
- `asyncJobs`: `status IN [queued, processing]`, order `createdAt DESC`
- `topics`: `courseId == X`, order `masteryScore ASC`

---

## 6. Firebase Storage Layout

```
/users/{userId}/documents/{documentId}/original.{ext}
/users/{userId}/documents/{documentId}/extracted.txt
/users/{userId}/podcasts/{podcastId}/audio.mp3
/users/{userId}/avatars/profile.jpg
```

---

## 7. Architecture — Async Job System

### 7.1 The Problem
A user uploading a 50-page PDF and requesting flashcards + quiz + podcast can require 5–10 minutes of total processing. HTTP requests time out long before that. Solution: fire-and-forget async jobs with real-time status updates via Firestore listeners.

### 7.2 Components

```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐
│   Flutter   │────────>│   FastAPI    │────────>│ Job Worker   │
│             │         │  (Render)    │         │  (Render)    │
│  - Upload   │<────────│              │<────────│              │
│  - Listen   │  Firestore listeners (real-time) │              │
└─────────────┘         └──────────────┘         └──────────────┘
```

- **Flutter** — uploads files directly to Firebase Storage; calls FastAPI to register documents and request generation; subscribes to Firestore for live job status.
- **FastAPI** — thin coordinator; validates requests, creates job records, returns in <300ms.
- **Job Worker** — separate Render Background Worker; pulls jobs from `asyncJobs` collection, calls Groq/ElevenLabs, writes results to Firestore.

### 7.3 Why a Separate Worker
- Survives API redeploys without losing jobs
- Doesn't block the API process
- Scales independently from the API
- Render Pro supports Background Workers natively

### 7.4 Job Queue: Firestore as Queue
- Worker watches `asyncJobs` where `status == queued`
- Atomic job claim via Firestore transaction (sets `status = processing`, attaches `workerId`)
- No additional infra — keeps MVP simple
- Migrate to Redis/RQ later if throughput demands it

### 7.5 Job Chaining
Jobs that depend on others are created at runtime by the worker, not upfront. Example: `flashcards_gen` is created only after `text_extraction` completes successfully. Prevents wasted API calls and orphaned jobs on extraction failure.

### 7.6 Idempotency & Retries
- Every job is safely retryable
- Workers delete partial outputs at job start if they detect a previous worker's incomplete state
- Outputs preferentially written only on success

### 7.7 Stuck-Job Janitor
- Cron task every 5 minutes
- Finds jobs where `status == processing` AND `startedAt < now − 15min`
- Resets them to `queued` for another worker to retry

### 7.8 Progress Reporting
- Workers update `progress` (0–100) on the job doc
- Throttled: update every 5–10% or every few seconds, whichever is less frequent
- Flutter listens to job docs and updates UI in real time

### 7.9 Cost Protection / Rate Limits
Per-user daily limits enforced in FastAPI before enqueueing jobs:
- Podcasts: max 3/day (ElevenLabs is the most expensive resource)
- Total AI generations: max 30/day
- File uploads: max 50/day, max 50MB/file
- Counters in `users/{userId}.usage`, reset by nightly Cloud Scheduler cron

---

## 8. API Endpoints (High-Level)

> Concrete request/response shapes to be defined during implementation.

### Auth
- Auth handled by Firebase SDK directly (no custom endpoints needed)
- FastAPI verifies Firebase ID token on every protected route

### Courses
- `POST   /courses` — create
- `GET    /courses` — list
- `PATCH  /courses/{id}` — update
- `DELETE /courses/{id}` — delete (cascades to documents, decks, quizzes)

### Documents
- `POST   /documents` — register a newly uploaded file, kick off extraction + requested generations
- `GET    /documents/{id}` — get details
- `DELETE /documents/{id}` — cascade delete generated assets
- `POST   /documents/{id}/generate` — request additional generation on existing doc

### Decks & Cards
- `POST   /decks` — create (manual or AI)
- `GET    /decks/{id}` — get with cards
- `PATCH  /decks/{id}` — update
- `DELETE /decks/{id}` — delete
- `POST   /decks/{id}/cards` — manually add card
- `PATCH  /decks/{id}/cards/{cardId}` — edit card
- `POST   /decks/{id}/cards/{cardId}/rewrite` — AI rewrite (leech)

### Reviews (SRS)
- `GET    /reviews/queue` — today's due cards across all decks
- `POST   /reviews/{cardId}/answer` — record review (Again/Hard/Good/Easy), updates SRS

### Quizzes
- `POST   /quizzes` — create (manual or AI)
- `GET    /quizzes/{id}` — get with questions
- `POST   /quizzes/{id}/attempts` — start attempt
- `PATCH  /quizzes/{id}/attempts/{attemptId}` — submit answers
- `POST   /quizzes/past-mistakes` — generate quiz from prior wrong answers

### Voice Quiz
- `POST   /voice-quiz/transcribe` — Whisper STT
- `POST   /voice-quiz/grade` — AI grading of spoken answer
- `POST   /voice-quiz/tts` — ElevenLabs question audio

### Podcasts
- `POST   /podcasts` — request generation (returns job ID)
- `GET    /podcasts/{id}` — fetch with audio URL + transcript

### Analytics
- `GET    /analytics/heatmap` — topic mastery grid
- `GET    /analytics/streaks` — streak info
- `GET    /analytics/readiness` — readiness score per course
- `GET    /analytics/weaknesses` — top topics to focus on

### Jobs
- `GET    /jobs/{id}` — single job status (Flutter mostly uses Firestore listener instead)

---

## 9. Security Rules (Approach)

### Firestore Rules
- All `users/{userId}/**` documents: read/write only when `request.auth.uid == userId`
- No cross-user access in v1
- Server-side writes (analytics, job updates) use Firebase Admin SDK (bypasses rules)

### Storage Rules
- `/users/{userId}/**`: read/write only when `request.auth.uid == userId`
- File size limit: 50MB
- Content-type allowlist: `application/pdf`, `image/*`, `audio/*`, `application/vnd.openxmlformats-*`, `text/plain`

### API Auth
- Every FastAPI protected route verifies Firebase ID token from `Authorization: Bearer ...` header
- Use `firebase_admin.auth.verify_id_token()` in a FastAPI dependency

---

## 10. Non-Functional Requirements

- **Performance:** API p95 < 300ms (excluding async work)
- **Real-time:** Job status updates visible in UI within 1s of worker write
- **Offline:** Read-only access to previously synced decks and quizzes (Firestore offline cache handles this)
- **Mobile-first:** All flows must work on mobile; no desktop-only features
- **Accessibility:** Screen reader support, dynamic text sizing, color-contrast compliant
- **Localization-ready:** All strings externalized for future Filipino/Tagalog support

---

## 11. Suggested Build Order (12-Sprint Plan, ~3 Months Solo)

| Sprint | Focus | Deliverable |
|---|---|---|
| 1 | Project setup, auth, basic shell | Login + empty home screen, both services deployed |
| 2 | Courses CRUD | Create/list/edit/delete courses |
| 3 | Document upload + PDF extraction | Upload PDF → see extracted text |
| 4 | Async job system (worker, claiming, chaining) | Generic job runner with one job type working end-to-end |
| 5 | Flashcard generation + manual deck CRUD | Generate flashcards from PDF, edit them manually |
| 6 | SRS algorithm + daily review queue | Working flashcard review flow |
| 7 | Quiz generation + multi-type quiz UI | Generate quizzes, take all 7 question types |
| 8 | Quiz attempts, scoring, past-mistakes mode | Complete quiz loop with history |
| 9 | Summaries, study guides, manual exam builder | All non-audio AI generators done |
| 10 | Podcast generation (ElevenLabs integration) | Two-speaker podcasts working end-to-end |
| 11 | Voice quiz mode + audio polish | Full voice study mode |
| 12 | Analytics, heatmap, readiness score, polish | Launch-ready app |

Adjust as needed based on real progress.

---

## 12. Glossary

- **SRS** — Spaced Repetition System; algorithm-driven flashcard review schedule
- **SM-2** — The original SuperMemo algorithm Anki uses; chosen for v1 due to documentation and simplicity
- **Leech** — A flashcard the user repeatedly fails; flagged for rewriting or reformulation
- **Mastery score** — 0–100 metric per topic, derived from question/card performance, recency, and coverage
- **Readiness score** — 0–100 metric per course estimating exam preparedness
- **Async job** — Long-running background task (extraction, generation, transcription) tracked via Firestore

---

*End of specification.*
