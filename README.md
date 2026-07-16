# Cramly

Study app for college students with Flutter and responsive web clients. It turns uploaded course material into extracted text, flashcard decks, and summaries. Quizzes, podcasts, spaced repetition, voice study, and analytics are planned but are not active in this build.

Spec: [docs/app_specification.md](docs/app_specification.md)

## Repo layout

```text
cramly-study-app/
|- mobile/          # Flutter app
|- web/             # React + TypeScript + Vite client
|- backend/
|  |- api/          # FastAPI service
|  |- worker/       # Background worker (Render Background Worker)
|  `- shared/       # Firebase, Groq, logging, config, prompts
|- docs/            # Specification + setup + deployment guides
|- firestore.rules
|- storage.rules
|- firebase.json
`- render.yaml      # Render blueprint (API + worker)
```

## Local development

### Backend

```bash
cd backend
python -m venv .venv
source .venv/Scripts/activate
# or in PowerShell: .\.venv\Scripts\Activate.ps1

pip install -r requirements.txt
cp .env.example .env
# Fill in .env with your Firebase service account JSON and Groq key.
```

Run the API:

```bash
uvicorn api.main:app --reload --port 8000
```

Open http://localhost:8000/health.

Run the worker in a separate terminal:

```bash
python -m worker.worker
```

### Mobile

See [docs/SETUP.md](docs/SETUP.md) for the full local setup flow.

### Web

See [web/README.md](web/README.md) for Firebase Web app setup, Vite environment variables, local commands, and SPA hosting requirements.

## Deploy

### Backend (Render)

Use the dedicated deployment guide: [docs/RENDER-DEPLOY.md](docs/RENDER-DEPLOY.md)

The repo-root [render.yaml](render.yaml) provisions:

- `cramly-api`
- `cramly-worker`

Current production secrets:

- `FIREBASE_SERVICE_ACCOUNT_JSON`
- `GROQ_API_KEY`

### Firebase rules

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Sprint progress

- [x] Sprint 1 - repo scaffold, auth, deployed services
- [x] Sprint 2 - courses CRUD
- [x] Sprint 3 - document upload + extraction
- [x] Sprint 4 - async job system
- [x] Sprint 5 - flashcard generation + manual deck CRUD
- [ ] Sprint 6 - SRS algorithm + daily review queue
- [ ] Sprint 7 - quiz generation + multi-type quiz UI
- [ ] Sprint 8 - quiz attempts, scoring, past-mistakes mode
- [x] Sprint 9 - summary generation
- [ ] Sprint 10 - podcast generation
- [ ] Sprint 11 - voice quiz mode
- [ ] Sprint 12 - analytics, polish, launch

See [docs/app_specification.md](docs/app_specification.md) for the full plan.

## Current data limitations

- Deleting a course removes only the course record; its existing resources are not cascaded.
- Deleting a document removes its source and extracted text, but generated decks and summaries are retained.
- A failed registration after a completed Storage upload can leave an abandoned object. Clients retry registration against the same canonical path and do not delete it automatically.
- Existing optional deck/card text cannot be cleared through the current API; the clients surface that limitation instead of reporting a false successful clear.
