# Cramly

Mobile study app for college students. Turns uploaded course materials into AI-generated flashcards, quizzes, study guides, summaries, and two-speaker podcasts. Spaced repetition (SM-2), voice quiz mode, and analytics on top.

Spec: [docs/app_specification.md](docs/app_specification.md)

## Repo layout

```
cramly-study-app/
├── mobile/          # Flutter app (Sprint 1.5+)
├── backend/
│   ├── api/         # FastAPI service
│   ├── worker/      # Background worker (Render Background Worker)
│   └── shared/      # Firebase, Groq, logging, config, prompts
├── docs/            # Specification + ADRs
├── firestore.rules
├── storage.rules
├── firebase.json
└── render.yaml      # Render blueprint (two services)
```

## Local development

### Backend

```bash
cd backend
python -m venv .venv
source .venv/Scripts/activate     # Windows bash
# or: .\.venv\Scripts\Activate.ps1   # PowerShell

pip install -r requirements.txt
cp .env.example .env
# Fill in .env with your Firebase service account JSON, Groq key, ElevenLabs key
```

Run the API:
```bash
uvicorn api.main:app --reload --port 8000
```
Open http://localhost:8000/health.

Run the worker (separate terminal):
```bash
python -m worker.worker
```

### Mobile

Sprint 1.5+ — pending folder rename and `flutter create`.

## Deploy

### Backend (Render)
1. Push to `main`
2. Connect this repo on Render — `render.yaml` auto-creates both services
3. In Render dashboard, set the secret env vars on each service:
   - `FIREBASE_SERVICE_ACCOUNT_JSON` (paste the entire JSON as a single line)
   - `GROQ_API_KEY`
   - `ELEVENLABS_API_KEY`

### Firebase rules
```bash
firebase deploy --only firestore:rules,storage
```

## Sprint progress

- [x] Sprint 1 — repo scaffold, auth, deployed services *(in progress)*
- [ ] Sprint 2 — courses CRUD
- [ ] Sprint 3 — document upload + PDF extraction
- [ ] Sprint 4 — async job system
- [ ] Sprint 5 — flashcard generation + manual deck CRUD
- [ ] Sprint 6 — SRS algorithm + daily review queue
- [ ] Sprint 7 — quiz generation + multi-type quiz UI
- [ ] Sprint 8 — quiz attempts, scoring, past-mistakes mode
- [ ] Sprint 9 — summaries, study guides, manual exam builder
- [ ] Sprint 10 — podcast generation
- [ ] Sprint 11 — voice quiz mode
- [ ] Sprint 12 — analytics, polish, launch

See [docs/app_specification.md](docs/app_specification.md) for the full plan.
