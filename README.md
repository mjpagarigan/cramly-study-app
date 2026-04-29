# Cramly

Mobile study app for college students. Turns uploaded course materials into AI-generated flashcards, quizzes, study guides, summaries, and two-speaker podcasts. Spaced repetition (SM-2), voice quiz mode, and analytics on top.

Spec: [docs/app_specification.md](docs/app_specification.md)

## Repo layout

```text
cramly-study-app/
|- mobile/          # Flutter app
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
- [ ] Sprint 5 - flashcard generation + manual deck CRUD
- [ ] Sprint 6 - SRS algorithm + daily review queue
- [ ] Sprint 7 - quiz generation + multi-type quiz UI
- [ ] Sprint 8 - quiz attempts, scoring, past-mistakes mode
- [x] Sprint 9 - summary generation
- [ ] Sprint 10 - podcast generation
- [ ] Sprint 11 - voice quiz mode
- [ ] Sprint 12 - analytics, polish, launch

See [docs/app_specification.md](docs/app_specification.md) for the full plan.
