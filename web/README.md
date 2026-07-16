# Cramly web client

This directory contains the responsive React client for Cramly. Production reads come from the authenticated user's Firebase collections, live updates use Firestore listeners, file uploads go directly to the user's Firebase Storage namespace, and canonical mutations go through the existing FastAPI service.

## Toolchain

- Node.js 24.14 or newer
- pnpm 11.7 or newer
- React 19, React Router 7, Vite 8, TypeScript 6

All runtime and test dependency versions are pinned exactly in `package.json` and `pnpm-lock.yaml`.

## Setup

1. Copy `.env.example` to `.env.local`.
2. Register a Firebase Web app for the existing Firebase project and fill in the public `VITE_FIREBASE_*` values.
3. Set `VITE_API_BASE_URL` to the local or hosted FastAPI origin, without a trailing slash.
4. Install and start the client:

   ```sh
   pnpm install --frozen-lockfile
   pnpm dev
   ```

Firebase email/password and Google providers must already be enabled. Add the deployed browser hostname to Firebase Authentication's authorized domains. The web host must rewrite unknown application routes to `/index.html` so BrowserRouter deep links work.

No service-account JSON, server API key, LLM credential, or bearer token belongs in any `VITE_*` variable. Firebase Web configuration is public client configuration; Firestore and Storage rules remain the security boundary.

## Development-only visual fixtures

Set `VITE_DEMO_MODE=true` while running `pnpm dev` to use a read-only signed-in fixture for screenshots without Firebase. The flag is ignored in production builds (`import.meta.env.DEV` must also be true). Fixture routes include:

- `/login?signedOut=1`
- `/`
- `/library`
- `/library/demo-course`
- `/library/demo-course/document/demo-document`
- `/library/demo-course/deck/demo-deck`
- `/library/demo-course/deck/demo-deck/review`
- `/library/demo-course/document/demo-document/summary/demo-summary`
- `/study`
- `/progress`
- `/profile`
- `/upload?courseId=demo-course`
- `/not-a-real-route`

During development, append `theme=light`, `theme=dark`, or `theme=system` as a query parameter to lock visual-review captures to one appearance. Combine query parameters normally on the upload route.

The fixture is intentionally read-only. Create, edit, delete, upload, and generation actions remain wired to the real FastAPI/Firebase services and should be tested with a configured development project.

With the fixture dev server running on port 4173, `pnpm capture:demo` uses a locally installed Chrome through the DevTools protocol to capture every fixture route at 1440×900 in both themes. Set `CHROME_PATH`, `CRAMLY_CAPTURE_URL`, or `CRAMLY_CAPTURE_OUT` to override its defaults. This script adds no browser-test dependency.

## Verification

```sh
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

The responsive shell switches from a 248px sidebar to an opaque modal drawer below 1024px. Visual QA should cover widths around 560, 600, 700, 768, 850, and 1024px as well as the full viewport matrix in the project brief. Verify keyboard focus restoration for dialogs/drawer, tab arrow navigation, live upload/job announcements, light/dark/system appearance, and reduced motion.

## Behavior and known boundaries

- Course deletion removes only the course record. Its materials are not cascaded.
- Document deletion removes its uploaded/extracted Storage objects, but generated decks and summaries remain.
- A Storage upload whose API registration fails is retained and retried with the same path; Cramly does not silently re-upload or automatically delete it.
- The existing API cannot clear a previously nonempty optional deck description or card hint, topic, or explanation. Edit forms reject that attempt and explain the limitation.
- Reviews are linear, write-free browsers. They do not create sessions, collect recall ratings, update SRS fields, or schedule cards.
- Quizzes, podcasts, daily scheduling, voice study, and analytics remain disabled placeholders.
- Web article uploads reject clear local/private network targets. Extracted text is capped at 5 MiB and must decode as valid UTF-8.

## Fonts and licensing

Newsreader 500/600, Manrope 400/500/600/700, and IBM Plex Mono 500/600 are self-hosted under `public/fonts`. They are official Google Fonts distribution binaries. The corresponding SIL Open Font License files are bundled beside them.
