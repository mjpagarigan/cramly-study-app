# Cramly — QA Regression Checklist

Manual smoke tests to run before kicking off a new sprint. Walks the happy path of every shipped feature plus the obvious edge cases. ~15–25 minutes if everything works, longer if you find something.

> **How to use:** open this on a second screen / tab. Walk top-to-bottom. Tick each row mentally. If anything misbehaves, copy the row + a screenshot + any uvicorn log output to chat.

---

## Pre-flight

Before you start, confirm the basics:

- [ ] **Backend running** — `uvicorn api.main:app --reload --port 8000` in one terminal, no startup errors
- [ ] **Worker running** — `python -m worker.worker` in another terminal, prints heartbeats every 30s (will gain real responsibilities in Sprint 4)
- [ ] **`/health` reachable** — open `http://localhost:8000/health` in browser → `{"status":"ok"}`
- [ ] **Mobile build is current** — kill + restart the app on your emulator/device (don't just hot-reload — pubspec changes need full restart)
- [ ] **Internet on the device works** — browser app inside the emulator can load google.com

---

## Sprint 1 — Auth, app shell, theme

### Auth happy path
- [ ] **Cold start with persisted session** → app shows Splash briefly → lands directly on **Home** (not Login). *Failure:* you're sent to Login despite having signed in before.
- [ ] **Sign out from Profile** → app routes to Login screen.
- [ ] **Email login** with correct credentials → lands on Home, sees your display name in greeting.
- [ ] **Email register** with a brand new email → account creates, lands on Home.
- [ ] **Google sign-in** → Google chooser opens, picking an account lands on Home.

### Auth error paths
- [ ] **Wrong password** on email login → red snackbar with Firebase auth message ("The password is invalid..."), stays on Login.
- [ ] **Empty email/password** → field-level validation errors ("Email is required", "Password is required").
- [ ] **Register with password < 8 chars** → field-level validation error.

### App shell
- [ ] **5-tab bottom nav** present on Home, Library, Study, Progress, Profile. Active tab in amber, others in muted gray.
- [ ] **Tap each tab** — content switches, no crashes. Study/Progress show "Coming in Sprint N" empty states.
- [ ] **FAB** visible only on Home + Library (not Study/Progress/Profile).
- [ ] **Tap FAB** → bottom sheet with "Upload file" + "New course" options.

### Theme
- [ ] **Profile → Appearance → Light** → app instantly recolors to light theme. Background goes from navy to off-white, accent from amber-light to amber-dark.
- [ ] **Kill app, reopen** → still in Light mode (persistence works).
- [ ] **Profile → Appearance → System** → app follows OS theme. Toggle OS-level dark mode → app re-renders. (Skip if you don't have OS theme switcher handy.)
- [ ] **Switch back to Dark** → returns to navy/amber.

---

## Sprint 2 — Courses CRUD

### Create
- [ ] **Library tab with no courses** → shows empty state "No courses yet" + "New course" button.
- [ ] **Tap FAB → New course** → bottom sheet with name input + 8-color picker.
- [ ] **Empty name → tap Create** → "Name is required" validation error inline.
- [ ] **Valid name + color → Create** → sheet closes, course appears in Library list **immediately** (real-time Firestore listener). *Failure:* course only appears after pull-to-refresh or app restart.
- [ ] **Course color** in the list matches the swatch you picked.

### Read / list
- [ ] **Course shows `0 docs · 0 decks · 0 quizzes`** in the subtitle.
- [ ] **Search** the Library — type a partial name → list filters in real-time.
- [ ] **Search with no matches** → "No matches" empty state with the query echoed.

### Edit
- [ ] **Tap a course → header → pencil icon** → bottom sheet pre-fills current name + color.
- [ ] **Change color and Save** → sheet closes, the color swatch on the course detail and the Library row both update without a refresh.

### Delete
- [ ] **Course detail → trash icon** → confirmation dialog.
- [ ] **Cancel** → dialog closes, course still there.
- [ ] **Delete** → routes back to Library, course is gone, count is back to previous-1.

### Persistence
- [ ] **Create a course → kill the app → reopen** → course still in Library.
- [ ] **Sign out → sign in as the same user** → courses still there.
- [ ] **Sign in as a different account** (if you have a 2nd test account) → that user's courses, not the first user's.

### Course detail tabs (Sprint 2 placeholders)
- [ ] **Documents tab** → shows documents (or empty state with Upload button — see Sprint 3).
- [ ] **Decks tab** → "No decks yet · Lands in Sprint 5" empty state.
- [ ] **Quizzes tab** → "No quizzes yet · Lands in Sprint 7" empty state.
- [ ] **Podcasts tab** → "No podcasts yet · Lands in Sprint 10" empty state.

---

## Sprint 3 — Document upload + extraction (7 formats)

### Upload entry points
- [ ] **FAB → Upload file** → routes to `/upload` with no preselected course.
- [ ] **Course detail → Documents tab → "Upload" button** → routes to `/upload?courseId=...` with that course preselected.
- [ ] **In the Assign step** the preselected course is highlighted with the amber checkmark.

### Source step — file picker
- [ ] **Drop zone** "Tap to upload a file" → system file picker opens.
- [ ] **Tap PDF tile** → narrow PDF picker.
- [ ] **Tap DOCX tile** → narrow DOCX picker.
- [ ] **Tap PPTX tile** → narrow PPTX picker.
- [ ] **Tap Markdown tile** → narrow markdown picker (`.md` / `.markdown`).
- [ ] **Tap Image tile** → image picker.
- [ ] **Tap Audio tile** → audio picker.
- [ ] **Cancel the picker** → returns to upload screen, no source selected, no crash.
- [ ] **Pick an unsupported file** (e.g. `.xlsx` via the broad picker) → red snackbar "Unsupported file type: .xlsx", stays on screen.
- [ ] **Pick a supported file** → "Selected" card appears with file icon + name + size.
- [ ] **Tap X on the Selected card** → clears the source, ready to pick again.

### Source step — URLs
- [ ] **YouTube tile** → bottom sheet with URL input.
- [ ] **Empty URL → Use this** → "Paste a URL" error.
- [ ] **Non-YouTube URL** → "That doesn't look like a YouTube URL" error.
- [ ] **Valid YouTube URL** → sheet closes, Selected card shows the URL.
- [ ] **Web tile** → bottom sheet, accepts any `http(s)://` URL.

### Assign step
- [ ] **Continue** with no source → button stays disabled (no source picked yet).
- [ ] **With source** → Continue routes to Assign step with title "Assign to course".
- [ ] **No courses exist** → empty state with inline "New course" button.
- [ ] **Existing courses** → list of courses with color dots.
- [ ] **Tap a course** → it gets the amber border + checkmark.
- [ ] **"Create new course" dashed card** at the bottom → opens course form sheet → after creation the new course is auto-selected.
- [ ] **Start button** disabled until a course is selected.
- [ ] **Tap Start** → routes to Processing step.

### Processing step
- [ ] **For file sources** — progress ring fills 0% → 100% as upload runs.
- [ ] **For URL sources** — progress jumps to 100% immediately (no upload phase), label switches to "Fetching + extracting".
- [ ] **Status label** changes from "Uploading" → "Extracting text" once upload hits 100%.
- [ ] **X close button is disabled** during upload (you can't bail mid-upload). *Failure:* tapping X cancels the upload halfway.

### Done step (per format)

For each, check: ✓ Done screen appears, ✓ "View in course" works, ✓ document appears in the Documents tab as **Ready** (green badge), ✓ tapping the doc opens detail with real extracted text.

- [ ] **PDF** — any 5–10 page PDF. Doc shows page count.
- [ ] **DOCX** — any Word document.
- [ ] **PPTX** — any PowerPoint deck. Doc detail shows slide-by-slide structure (`# Slide 1`, `# Slide 2`, ...).
- [ ] **Markdown** — any `.md` file. Should be near-instant.
- [ ] **Image** — only if you installed Tesseract per CHECKLIST.md. Use a clear photo of printed text. Will fail with a clear error if Tesseract isn't installed.
- [ ] **Audio** — a voice memo or short MP3. Uses Groq Whisper. Note Groq has a 25 MB hard cap per file.
- [ ] **YouTube** — any educational video with English captions. Video must have captions enabled or extraction fails clearly.
- [ ] **Web URL** — Wikipedia article URL works great as a baseline. Doc title may auto-update to the article title.

### Document detail screen
- [ ] **Header** shows the right icon for the source type (book / mic / link / etc.).
- [ ] **Status badge** says "Ready" in green.
- [ ] **Word count + page count** shown in the metadata row.
- [ ] **Extracted text scrolls smoothly**, supports text selection (long-press to select).
- [ ] **Generate buttons** (Flashcards, Quiz, Summary, Podcast) appear and are styled distinctly. Tooltip on long-press shows "Lands in Sprint X". *(They don't function — that's expected.)*

### Document delete
- [ ] **Document detail → trash icon** → confirmation dialog.
- [ ] **Confirm delete** → routes back to course Documents tab, document gone.
- [ ] **Course's `documentCount`** decremented (visible in Library row + course detail header).
- [ ] **Firestore Console check** (optional) → confirm document doc is gone under `users/{uid}/documents/{docId}` and the original file is gone from Storage.

### Failure paths
- [ ] **YouTube URL with disabled captions** → doc shows "Failed" badge, detail screen shows red error card with "This video has captions disabled."
- [ ] **Web URL of a paywalled / JS-heavy page** (try a NYT article) → "Failed" with "Could not extract readable article body".
- [ ] **Audio file > 25 MB** → "Failed" with "Audio file is X MB — Groq Whisper rejects files > 25 MB".
- [ ] **Empty PDF** (an image-only scanned PDF with no text layer) → "Failed" with "Could not extract any text — the PDF may be scanned-only".

### Persistence + real-time
- [ ] **Upload a doc → kill app → reopen** → doc still in the right course's Documents tab.
- [ ] **Open the doc on Firebase Console** while it's processing → status field flips from `extracting` to `ready` (uvicorn finishes the request).

---

## Cross-cutting smokes (run once at the end)

- [ ] **Switch theme to Light → upload a PDF → check Document detail** → all colors readable, no contrast bugs.
- [ ] **Sign out → sign in as a different account** → different user sees zero of the first user's courses/docs (security isolation).
- [ ] **Force-quit the backend** while the app is open → app surfaces friendly errors on the next write (e.g. course create) instead of crashing.
- [ ] **Restart the backend** → app recovers (next action works).
- [ ] **Toggle airplane mode on the device for 10 seconds → toggle back** → Firestore reconnects and any cached UI is intact.

---

## What to do when something breaks

For each failure:

1. Note the **exact step that failed** (which checkbox).
2. Screenshot the screen at the moment of failure.
3. Copy the last ~30 lines of uvicorn output between the previous successful action and the failure.
4. Note any red snackbar / dialog text.
5. Paste all of the above to chat.

Don't try to fix it yourself — easier for me to diagnose with the raw evidence.

---

## What you intentionally *won't* find working yet

These are correct as-is — they're scheduled for later sprints, not bugs:

- **Generate buttons** (Flashcards / Quiz / Summary / Podcast) on Document detail — disabled placeholders, Sprints 5/7/9/10
- **Study tab** — Sprint 6
- **Progress tab** — Sprint 12
- **Apple sign-in** — deferred
- **Multi-file bulk upload** — Sprint 3+ enhancement, not in v1
- **Editing extracted text** — out of scope; v1 just shows it read-only

---

*Last updated: end of Sprint 3. Append per-sprint sections as we ship them.*
