# Cramly — Setup Guide

End-to-end instructions to get Cramly running locally and deployed. Follow top-to-bottom on a fresh machine; sections are independent so you can re-read just the part you need later.

> **Audience:** the project owner (you) or any future collaborator. If you're doing this for the first time, budget **2–3 hours**. If you're just rotating credentials, jump to the relevant section.

---

## Table of contents

1. [What you're setting up](#1-what-youre-setting-up)
2. [Local toolchain](#2-local-toolchain-windows)
3. [Firebase (auth, database, file storage)](#3-firebase-auth-database-file-storage)
4. [Groq (LLM + Whisper)](#4-groq-llm--whisper)
5. [ElevenLabs (text-to-speech)](#5-elevenlabs-text-to-speech)
6. [Backend `.env` file](#6-backend-env-file)
7. [Run locally](#7-run-locally)
8. [Deploy to Render (when ready)](#8-deploy-to-render-when-ready)
9. [Apple Developer (later, before App Store)](#9-apple-developer-later-before-app-store)
10. [Cost expectations](#10-cost-expectations)
11. [Troubleshooting cheatsheet](#11-troubleshooting-cheatsheet)

---

## 1. What you're setting up

| Service | What it does | When you need it | Free tier? |
|---|---|---|---|
| **Firebase** | Auth, Firestore database, file storage | Sprint 1 (now) | Yes — Spark plan |
| **Groq** | LLM (gpt-oss-120b) + Whisper STT | Sprint 4+ | Yes — generous limits |
| **ElevenLabs** | TTS for podcasts + voice quiz | Sprint 10+ | Yes — limited chars/month |
| **Render** | Hosting (FastAPI + worker) | Sprint 11+ (TestFlight build) | No — Pro starts ~$25/mo |
| **Apple Developer** | iOS App Store + Apple sign-in | Pre-launch (Sprint 12) | $99/year |

**Your current state (per Sprint 2):** Firebase done, Groq + ElevenLabs not started, Render not started, Apple skipped.

---

## 2. Local toolchain (Windows)

Verify each by running the listed command in PowerShell. If a command fails, install per the link.

| Tool | Required version | Verify | Install |
|---|---|---|---|
| Git | any recent | `git --version` | https://git-scm.com/download/win |
| Python | 3.11 or 3.12 | `python --version` | https://www.python.org/downloads/ |
| Node.js | 20.x LTS | `node --version` | https://nodejs.org/ |
| Flutter SDK | 3.41+ stable | `flutter --version` | https://docs.flutter.dev/get-started/install/windows |
| Android Studio | latest | open it | https://developer.android.com/studio |
| Firebase CLI | 13+ | `firebase --version` | `npm install -g firebase-tools` |
| FlutterFire CLI | 1.3+ | `dart pub global list \| Select-String flutterfire` | `dart pub global activate flutterfire_cli` |

**Notes:**

- **Python:** Miniconda's bundled Python 3.13 also works, but pin per-project to 3.11 to match Render. Avoid `python` from the Microsoft Store — it routes through a launcher that confuses venvs.
- **Flutter:** After install, run `flutter doctor` and resolve every red ✗. The Android license acceptance step (`flutter doctor --android-licenses`) is mandatory.
- **Android Studio:** Open at least once and let it install: Android SDK Platform 34 (UpsideDownCake), Android SDK Build-Tools 34, Android Emulator. SDK Manager is at `Tools → SDK Manager`.

---

## 3. Firebase (auth, database, file storage)

You've already created a project (`cramly-cd9b5`). This section documents the full setup so you can re-create or rotate later.

### 3.1 Create a Firebase project (skip if done)

1. Go to https://console.firebase.google.com → **Add project**.
2. Name: `Cramly`. Project ID is auto-generated (e.g. `cramly-cd9b5`).
3. Disable Google Analytics for now (can add later).
4. Wait ~1 min for provisioning.

### 3.2 Enable Authentication providers

1. In the Firebase Console: **Authentication → Get started**.
2. **Sign-in method** tab → enable:
   - **Email/Password** → toggle on, save.
   - **Google** → toggle on, set **support email** (your account email), save.
   - **Apple** → defer until pre-launch (needs Apple Developer account).

### 3.3 Create Firestore Database

1. Console: **Firestore Database → Create database**.
2. Mode: **Production mode** (security rules are enforced from day one — already set in [firestore.rules](../firestore.rules)).
3. Location: **asia-southeast1** (Singapore, low latency for PH users). Region is *permanent* — choose carefully.

### 3.4 Create Cloud Storage bucket

1. Console: **Storage → Get started**.
2. Mode: **Production mode**.
3. Location: same as Firestore (`asia-southeast1`).
4. Default bucket name will be `cramly-cd9b5.firebasestorage.app` (Firebase's new default; reflected throughout the codebase).

### 3.5 Generate the Service Account JSON (backend admin credential)

The backend uses this to bypass security rules — **never** commit it.

1. Console: **⚙ Project settings → Service accounts** tab.
2. Click **Generate new private key** → confirm. A JSON file downloads.
3. Move it OUT of `Downloads/` somewhere safer, e.g. `C:\Users\<you>\.cramly-secrets\service-account.json`.
4. **Never** paste this file's contents into chat, screenshots, screen recordings, or commits. The `private_key` field is the keys to your kingdom.
5. If a key ever leaks: Console → Service accounts → click into it → **Keys** tab → delete the leaked key → generate a new one. Old key dies instantly.

### 3.6 Register the SHA-1 (Android Google sign-in)

Without this, Google sign-in on Android returns an opaque "API_NOT_AVAILABLE" or "10:" error.

1. From Android Studio:
   - Open `mobile/` as a Flutter project.
   - Right-edge **Gradle** tab → `cramly → mobile → Tasks → android → signingReport` → double-click.
   - In the Run output, find the block under `Variant: debug` and copy the `SHA1` line (40 hex chars).
2. Console: **⚙ Project settings → Your apps → Android app** (`com.cramly.app`) → **Add fingerprint** → paste SHA-1 → save.
3. Re-pull config:
   ```powershell
   cd mobile
   dart pub global run flutterfire_cli:flutterfire configure `
     --project=cramly-cd9b5 --platforms=android,ios --yes
   ```

### 3.7 Deploy security rules + indexes (already done, repeat after edits)

```powershell
firebase use cramly-cd9b5
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Re-run any time you edit [firestore.rules](../firestore.rules), [firestore.indexes.json](../firestore.indexes.json), or [storage.rules](../storage.rules).

---

## 4. Groq (LLM + Whisper)

Groq hosts the `openai/gpt-oss-120b` model (smartest open model on Groq) and Whisper for speech-to-text. Both are used by the worker starting Sprint 4.

### 4.1 Create account

1. https://console.groq.com → **Sign up** (free; supports Google sign-in).
2. Verify email if prompted.

### 4.2 Generate API key

1. Console: **API Keys** (left sidebar) → **Create API Key**.
2. Name: `cramly-dev` (one per environment).
3. **Copy the key immediately** — it's shown only once. Format: `gsk_...` (~50 chars).
4. Save it somewhere safe (password manager).

### 4.3 Note free-tier limits

As of writing, free tier on `openai/gpt-oss-120b` is roughly:
- 30 requests / minute
- 6,000 tokens / minute
- 14,400 requests / day

Plenty for solo dev. Bump to paid ($0.15/M input, $0.75/M output) before launch — needs a credit card on file.

### 4.4 Where the key goes

- Local: `backend/.env` → `GROQ_API_KEY=gsk_...`
- Render (later): Render dashboard → service → Environment → add `GROQ_API_KEY` with the value, **mark as secret**.

---

## 5. ElevenLabs (text-to-speech)

Used for two-speaker podcasts (Sprint 10) and voice quiz mode (Sprint 11). You can defer signing up until then, but creating the account now means you don't have to context-switch later.

### 5.1 Create account

1. https://elevenlabs.io → **Sign up**.
2. Free tier: 10,000 characters/month — enough for ~5 minutes of generated audio. **Way too low for production**, OK for dev testing.

### 5.2 Generate API key

1. Settings (top-right avatar) → **API Keys** → **Create API Key**.
2. Permissions: **All** (or scope to TTS + voice library).
3. Copy and save.

### 5.3 Pick voices for the podcast (defer to Sprint 10)

In Sprint 10 you'll choose two ElevenLabs voices for the host/guest dialogue. Browse https://elevenlabs.io/app/voice-library — recommended starting pair:
- Host: `Adam` (deep, calm)
- Guest: `Rachel` (bright, conversational)

We'll pin specific `voice_id` values in [backend/shared/prompts/](../backend/shared/prompts/) when we build the podcast generator.

### 5.4 Pricing for launch

Free tier won't cut it. Recommended Sprint 10+ tier: **Creator ($22/mo)** — 100k chars/mo, ~50 min of audio, commercial use allowed. Per-user 3-podcast/day limit (already enforced) keeps you in budget for early users.

### 5.5 Where the key goes

Same as Groq: `backend/.env` → `ELEVENLABS_API_KEY=...`, plus Render env var for production.

---

## 6. Backend `.env` file

The backend reads config from `backend/.env`. This file is gitignored — never commit it.

### 6.1 Create the file

```powershell
cd backend
Copy-Item .env.example .env
notepad .env  # or open in VS Code
```

### 6.2 Fill in each value

```bash
# --- Runtime ---
ENV=development
LOG_LEVEL=INFO
SERVICE_NAME=cramly-api

# --- Firebase Admin SDK ---
# Paste the entire service-account JSON from §3.5 as a SINGLE LINE.
# Use this PowerShell trick to compact + copy to clipboard:
#   (Get-Content "$HOME\.cramly-secrets\service-account.json" -Raw) `
#       -replace "`r`n","" -replace "`n","" | Set-Clipboard
# Then paste into the line below after the = sign.
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...all on one line...}

FIREBASE_PROJECT_ID=cramly-cd9b5
FIREBASE_STORAGE_BUCKET=cramly-cd9b5.firebasestorage.app

# --- LLM (Groq from §4) ---
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GROQ_MODEL=openai/gpt-oss-120b

# --- TTS (ElevenLabs from §5; can leave blank until Sprint 10) ---
ELEVENLABS_API_KEY=

# --- Worker tuning (worker service only — leave defaults) ---
WORKER_ID=
WORKER_POLL_INTERVAL_SECONDS=2
WORKER_HEARTBEAT_INTERVAL_SECONDS=30
```

### 6.3 Verify

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python -c "from shared.config import settings; print('PROJECT:', settings.FIREBASE_PROJECT_ID); print('GROQ KEY OK:', bool(settings.GROQ_API_KEY))"
```

Should print your project ID and `GROQ KEY OK: True`. If `GROQ KEY OK: False`, the .env isn't being read — check the file is at `backend/.env` (not `backend/api/.env`).

---

## 7. Run locally

You'll usually have **three terminals** open: backend API, worker, and Flutter.

### 7.1 First-time backend install

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

If `pip install` is slow on Windows, that's normal — `firebase-admin` and `cryptography` are large.

### 7.2 Run API (terminal 1)

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
uvicorn api.main:app --reload --port 8000
```

Verify in a browser or new terminal: http://localhost:8000/health → `{"status":"ok",...}`

Auto-generated OpenAPI docs: http://localhost:8000/docs

### 7.3 Run worker (terminal 2 — only needed Sprint 4+)

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python -m worker.worker
```

You should see `worker_starting` and then a heartbeat every 30s. Real job processing starts Sprint 4.

### 7.4 Run mobile app (terminal 3)

```powershell
cd mobile
flutter run
```

A device/emulator picker appears. Pick your Android emulator (created in §2) or your physical device (USB debugging enabled).

**Network setup for the app to reach your backend:**

| Where the app runs | API base URL the app uses | How |
|---|---|---|
| Android emulator | `http://10.0.2.2:8000` | Auto (default) |
| iOS simulator | `http://localhost:8000` | Auto (default) |
| Physical Android phone (USB) | `http://<your-PC-LAN-IP>:8000` | `flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8000` |
| Physical iPhone (USB) | `http://<your-PC-LAN-IP>:8000` | Same as above |

To find your LAN IP: PowerShell → `ipconfig` → look for `IPv4 Address` under your Wi-Fi adapter (usually `192.168.x.x`).

For physical devices, you also need:
1. PC and phone on the **same Wi-Fi network**
2. Windows Firewall: allow inbound on port 8000 (first run will prompt)

### 7.5 The first-run flow

1. Sign in (email/password OR Google).
2. Land on Home tab. Greeting appears.
3. Tap **Library** → tap **+** → fill name + color → Create.
4. New course appears in the list (real-time via Firestore listener).
5. Tap the course → segmented control with 4 placeholder tabs (Documents/Decks/Quizzes/Podcasts).
6. Tap edit/delete to verify writes.
7. Open Profile → toggle Dark/Light/System theme → app re-renders instantly.

If everything above works, your local environment is correct.

---

## 8. Deploy to Render (when ready)

The current Render deployment walkthrough now lives in [RENDER-DEPLOY.md](./RENDER-DEPLOY.md).
Use that guide as the source of truth for the API + worker Blueprint, required production secrets, verification steps, and the native-runtime OCR limitation.

**Don't do this until Sprint 11/12** — there's no point spending $25/mo until you have a TestFlight/Play build to demo.

### 8.1 Account setup

1. https://render.com → sign up (Google or GitHub auth).
2. Connect your GitHub account (the one hosting the cramly repo).

### 8.2 Choose plan

For two services (API + worker), the **Starter plan ($7/mo per service = $14/mo)** is enough for Sprint 11/12 demos. Bump to **Standard ($25/mo per service)** when you have real users — eliminates cold starts and gives more memory.

### 8.3 Deploy via blueprint (`render.yaml`)

The repo includes [render.yaml](../render.yaml) which provisions both services automatically.

1. Render Dashboard → **New → Blueprint**.
2. Connect the repo: `cramly-study-app`.
3. Render reads `render.yaml` → shows two services to be created (`cramly-api`, `cramly-worker`).
4. Click **Apply**.
5. Both services start building. Build will fail the first time because secret env vars aren't set yet — that's fine.

### 8.4 Set secret env vars in Render dashboard

For **each** service (`cramly-api` AND `cramly-worker`):

1. Click into the service → **Environment** tab.
2. Add two secret env vars (mark each as **Secret**):
   - `FIREBASE_SERVICE_ACCOUNT_JSON` = (paste the same single-line JSON you put in `.env`)
   - `GROQ_API_KEY` = `gsk_...`
3. Click **Save Changes** → triggers a redeploy.

### 8.5 Verify

- API URL appears at top of `cramly-api` service page (e.g. `https://cramly-api.onrender.com`).
- Hit `https://cramly-api.onrender.com/health` → should return `{"status":"ok","env":"production",...}`.
- Worker logs (in `cramly-worker` service → Logs tab) should show `worker_starting` and heartbeat lines.

### 8.6 Point the mobile app at production

For TestFlight/Play builds:

```powershell
cd mobile
flutter build apk --release `
  --dart-define=API_BASE_URL=https://cramly-api.onrender.com
```

For TestFlight (iOS): same `--dart-define`, build via `flutter build ipa`.

---

## 9. Apple Developer (later, before App Store)

Not needed until you're ready to ship to TestFlight. Steps when you are:

1. https://developer.apple.com/programs → enroll → $99/year. Approval: minutes to days.
2. Once approved: enable **Sign in with Apple** in Firebase Console → Auth → Sign-in method.
3. Generate a **Services ID** + private key in Apple Developer portal, paste both into Firebase's Apple sign-in config.
4. Add `sign_in_with_apple` Flutter dep, wire it into [auth_providers.dart](../mobile/lib/core/auth/auth_providers.dart), add an Apple sign-in button to [login_screen.dart](../mobile/lib/features/auth/login_screen.dart).
5. App Store Connect: create the app listing, upload via `flutter build ipa` + Transporter or Xcode.

We'll do this end-to-end as a sub-sprint of Sprint 12.

---

## 10. Cost expectations

For **dev only** (just you):

| Item | Monthly | Notes |
|---|---|---|
| Firebase | $0 | Spark plan covers this comfortably |
| Groq | $0 | Free tier |
| ElevenLabs | $0 | Free tier (10k chars/mo) for testing |
| Render | $0 | Don't deploy until Sprint 11+ |
| **Total dev** | **$0** | — |

For **TestFlight + Play beta** (you + ~20 testers):

| Item | Monthly | Notes |
|---|---|---|
| Firebase | $0–5 | Spark covers most; might tip over Storage |
| Groq | $0–10 | Pay-as-you-go ~$0.15/M tokens |
| ElevenLabs Creator | $22 | 100k chars/mo |
| Render Starter (2 services) | $14 | $7 × 2 |
| Apple Developer | $8 | $99/year amortized |
| **Total beta** | **~$50** | — |

For **public launch** (1000+ users): plan ~$200–500/mo depending on usage. Per-user limits enforced in [backend/api/services/courses.py](../backend/api/services/courses.py) (3 podcasts/day, 30 generations/day) keep this bounded.

---

## 11. Troubleshooting cheatsheet

### Backend

| Symptom | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError: firebase_admin` | venv not activated | `.\.venv\Scripts\Activate.ps1` |
| `FIREBASE_SERVICE_ACCOUNT_JSON is empty` | `.env` not read | Confirm file is at `backend/.env`, not nested |
| `FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON` | Multi-line JSON | Compact to single line per §6.2 |
| `Status code 204 must not have a response body` | FastAPI 0.115 strict | Already fixed; rebase if you see this |
| Uvicorn 401 on every request | Mobile not sending auth | Check `flutter run` shows the right `API_BASE_URL` |

### Mobile

| Symptom | Cause | Fix |
|---|---|---|
| Google sign-in fails with `10:` or `API_NOT_AVAILABLE` | SHA-1 not registered | §3.6 |
| App can't reach backend on physical device | LAN IP / firewall | §7.4 |
| `firebase_options.dart` import error | Never ran flutterfire | `dart pub global run flutterfire_cli:flutterfire configure --project=cramly-cd9b5 --yes` |
| Hot reload not picking up code changes | Code-gen file (freezed/json) needs rebuild | `dart run build_runner build --delete-conflicting-outputs` |
| Theme switch doesn't persist | shared_preferences denied write | Reinstall app — first install wasn't granted storage perm |

### Firebase

| Symptom | Cause | Fix |
|---|---|---|
| Firestore writes silently fail | Rules block | Check Firestore Console → Rules tab matches [firestore.rules](../firestore.rules). Re-deploy if needed |
| "Missing index" error in mobile logs | Index not deployed | `firebase deploy --only firestore:indexes` |
| Storage upload 403 | Rules block | Check user is authenticated; rules require `request.auth.uid == userId` |

### Render

| Symptom | Cause | Fix |
|---|---|---|
| Build fails: `pip install` errors | Python version mismatch | Confirm `pythonVersion: "3.11"` in `render.yaml` |
| Service crashes on start | Env vars missing | Re-check all three secrets are set on **both** services |
| 502 on first request after deploy | Cold start (Starter plan) | Either upgrade to Standard, or accept the 30s warmup |

---

## Appendix: Resetting from scratch

If something is corrupted and you want to nuke + restart:

```powershell
# Backend
cd backend
Remove-Item -Recurse -Force .venv
Remove-Item .env
# then redo §6 + §7.1

# Mobile
cd mobile
flutter clean
Remove-Item -Recurse -Force .dart_tool
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Firebase deployments — does not affect production data
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Your Firestore data and Storage files are *not* affected by any of the above — you'd have to delete them manually from the Firebase Console.

---

*Last updated: Sprint 2 — refresh this file whenever the stack changes.*
