# Cramly - Render Deployment Guide

Deploy the current backend to Render using the repo-root [render.yaml](../render.yaml). This guide targets the live Sprint 4 backend shape:

- `cramly-api` - FastAPI web service
- `cramly-worker` - background worker for `text_extraction` and `summary_gen`

This deployment uses Render's native Python runtime, not Docker.

## What this deployment supports

Working on native Render:

- PDF, DOCX, PPTX, Markdown extraction
- YouTube transcript extraction
- Web article extraction
- Audio transcription via Groq Whisper
- Async jobs
- Summary generation via Groq

Known limitation on native Render:

- Image OCR is not production-ready because the image extractor depends on the Tesseract host binary, which this repo does not provision on native Render. Image uploads may fail with the documented Tesseract warning until a later Docker migration.

## Prerequisites

Before you open Render:

1. Push this repo to GitHub.
2. Create a Firebase service account JSON and keep it outside the repo.
3. Compact that JSON to a single line for Render:

```powershell
(Get-Content "$HOME\.cramly-secrets\service-account.json" -Raw) `
  -replace "`r`n","" -replace "`n","" | Set-Clipboard
```

4. Have your Groq API key ready.
5. Deploy the latest Firebase rules and indexes:

```powershell
firebase use cramly-cd9b5
firebase deploy --only firestore:rules,firestore:indexes,storage
```

If indexes are not deployed, the worker will fall back to a slower scan path and log a warning. Deploy the indexes anyway so queue claiming and stuck-job recovery use the intended indexed queries and the `asyncJobs.status` collection-group single-field index is available.

## Blueprint layout

The repo's [render.yaml](../render.yaml) is the source of truth.

- `cramly-api`
  - `type: web`
  - `runtime: python`
  - `rootDir: backend`
  - `PYTHON_VERSION=3.11.11` via service environment variables
  - `buildCommand: pip install -r requirements.txt`
  - `startCommand: uvicorn api.main:app --host 0.0.0.0 --port $PORT`
  - `healthCheckPath: /health`
- `cramly-worker`
  - `type: worker`
  - `runtime: python`
  - `rootDir: backend`
  - `PYTHON_VERSION=3.11.11` via service environment variables
  - `buildCommand: pip install -r requirements.txt`
  - `startCommand: python -m worker.worker`

Both services deploy in `singapore` on the `starter` plan.

## Required environment variables

Shared non-secret vars already defined in the Blueprint:

- `ENV=production`
- `LOG_LEVEL=INFO`
- `PYTHON_VERSION=3.11.11`
- `FIREBASE_PROJECT_ID=cramly-cd9b5`
- `FIREBASE_STORAGE_BUCKET=cramly-cd9b5.firebasestorage.app`
- `GROQ_MODEL=openai/gpt-oss-120b`

Service-specific vars already defined in the Blueprint:

- API: `SERVICE_NAME=cramly-api`
- Worker: `SERVICE_NAME=cramly-worker`
- Worker: `WORKER_POLL_INTERVAL_SECONDS=2`
- Worker: `WORKER_HEARTBEAT_INTERVAL_SECONDS=30`

Secrets you must provide on both services during Blueprint creation:

- `FIREBASE_SERVICE_ACCOUNT_JSON`
- `GROQ_API_KEY`

Not needed for the current deployed sprint:

- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `WORKER_ID`
- `ELEVENLABS_API_KEY`

## Deploy on Render

1. Go to [Render](https://render.com/) and sign in.
2. Connect the GitHub repo that contains this project.
3. In the Render dashboard, click `New` -> `Blueprint`.
4. Select this repo.
5. Keep the Blueprint path as `render.yaml` at the repo root.
6. Choose the branch you want Render to track, usually `main`.
7. Review the services Render shows:
   - `cramly-api`
   - `cramly-worker`
8. When Render prompts for Blueprint secrets, paste:
   - `FIREBASE_SERVICE_ACCOUNT_JSON`
   - `GROQ_API_KEY`
9. Deploy the Blueprint.

Render should provision both services from the same repo.

## Verify the deployment

### API

After the web service is live:

1. Open the `cramly-api` service page.
2. Copy the `.onrender.com` URL.
3. Hit the health endpoint in a browser:

```text
https://<your-api-host>/health
```

Expected result:

- `status` is `ok`
- `env` is `production`

### Worker

Open `cramly-worker` -> `Logs`.

Expected log lines include:

- `worker_starting`
- periodic `worker_heartbeat`

If you enqueue extraction or summary jobs later, you should also see job claim and completion logs.

## End-to-end production check

Once both services are up:

1. Point the mobile app to the Render API URL.
2. Sign in.
3. Upload or register a non-image document.
4. Confirm extraction finishes.
5. Open the document and generate a Summary.
6. Confirm the summary appears and the worker completes both jobs.

Recommended test sources:

- PDF
- DOCX
- Markdown
- Web URL
- YouTube URL

Skip image OCR in deployment acceptance for this native-runtime setup.

## Point the mobile app at Render

For release builds, provide the Render API URL through `API_BASE_URL`.

Android example:

```powershell
cd mobile
flutter build apk --release `
  --dart-define=API_BASE_URL=https://<your-api-host>
```

iOS/TestFlight uses the same `--dart-define=API_BASE_URL=...` pattern.

## Troubleshooting

### API fails on startup

Common causes:

- `FIREBASE_SERVICE_ACCOUNT_JSON` is missing
- the JSON was pasted with line breaks
- `GROQ_API_KEY` is missing

What to check:

- Render service -> `Environment`
- Render service -> `Logs`

Expected Firebase failure messages include:

- `FIREBASE_SERVICE_ACCOUNT_JSON is empty`
- `FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON`

### Worker is running but jobs never complete

Check:

- `cramly-worker` logs for claim/retry/failure lines
- Firestore indexes are deployed
- `GROQ_API_KEY` exists on the worker service, not just the API service

If you see `job_claim_query_fallback` or `stuck_job_query_fallback` in the worker logs, Render is running on the non-indexed fallback path and you should re-deploy Firestore indexes. The repo now includes the required `asyncJobs.status` collection-group single-field override in [firestore.indexes.json](../firestore.indexes.json).

Re-deploy indexes if needed:

```powershell
firebase deploy --only firestore:indexes
```

### Health check never goes green

Check:

- the API start command is exactly `uvicorn api.main:app --host 0.0.0.0 --port $PORT`
- the health check path is `/health`
- `PYTHON_VERSION` is set to a valid Render-supported Python version

Expected health URL:

```text
https://<your-api-host>/health
```

### Image uploads fail on Render

That is expected in this native-runtime deployment if the flow requires OCR. The current image extractor depends on Tesseract being installed on the host. Move to Docker in a later deployment iteration if production OCR is required.

### Starter plan feels slow

That is expected for early-stage hosting. Starter is acceptable for initial testing, but expect slower cold starts and less headroom than Standard.

## Useful references

- [Render Blueprint YAML Reference](https://render.com/docs/blueprint-spec)
- [Render Blueprints (IaC)](https://render.com/docs/infrastructure-as-code)
- [Render Health Checks](https://render.com/docs/health-checks)
- [Render Deploys and Shutdown Delay](https://render.com/docs/deploys/)
