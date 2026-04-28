# Cramly — Setup Checklist (do these now)

Status as of Sprint 2: backend can't authenticate yet because `backend/.env` doesn't exist. This file walks you through the exact steps to fix that, in order.

> **Goal:** finish all 6 steps below, then tap **Create** in the app and watch a course actually appear. Estimated time: **15–25 minutes**, mostly waiting for accounts/keys.
>
> If you want the long-form reference (deploy to Render, Apple Developer, cost breakdowns), see [SETUP.md](SETUP.md). This file is the fire-drill version.

---

## ☐ 1. Rotate the leaked Firebase service-account key

**Why:** the JSON file in `~/Downloads/cramly-cd9b5-firebase-adminsdk-fbsvc-17ee685578.json` was pasted into chat earlier. Treat it as compromised — anyone who saw the chat has admin access to your entire Firebase project until that key is revoked.

Five minutes. Do this *before* you do anything else with `.env`.

1. Open https://console.cloud.google.com/iam-admin/serviceaccounts?project=cramly-cd9b5
2. Click into `firebase-adminsdk-fbsvc@cramly-cd9b5.iam.gserviceaccount.com`.
3. **Keys** tab → find the key with ID starting **`17ee685578...`** → click ⋮ → **Delete** → confirm. The key is now revoked, instantly.
4. Same screen → **Add Key → Create new key → JSON → Create**. A new file downloads, e.g. `cramly-cd9b5-firebase-adminsdk-fbsvc-<NEW-ID>.json`.
5. Delete the old file from `~/Downloads/`:
   ```powershell
   Remove-Item "$HOME\Downloads\cramly-cd9b5-firebase-adminsdk-fbsvc-17ee685578.json"
   ```

You should now have **one** new JSON file in Downloads with a different filename.

---

## ☐ 2. Move the new JSON out of Downloads

`Downloads/` is volatile — easy to delete by accident, easy to upload by accident. Move it somewhere stable that you'll remember:

```powershell
New-Item -ItemType Directory -Force "$HOME\.cramly-secrets" | Out-Null
Move-Item "$HOME\Downloads\cramly-cd9b5-firebase-adminsdk-*.json" `
          "$HOME\.cramly-secrets\service-account.json"
```

Verify it's there:
```powershell
ls "$HOME\.cramly-secrets\"
```

You should see one file: `service-account.json`.

---

## ☐ 3. Create `backend/.env`

```powershell
cd C:\Users\iamha\OneDrive\Documents\GitHub\cramly-study-app\backend
Copy-Item .env.example .env
```

Now open it in VS Code:
```powershell
code .env
```

You'll see the template with empty `=` lines.

---

## ☐ 4. Paste the service-account JSON into `.env`

The JSON has line breaks — `.env` files require everything on one line per key. Use this PowerShell trick to compact it and copy it to your clipboard in one go:

```powershell
(Get-Content "$HOME\.cramly-secrets\service-account.json" -Raw) `
    -replace "`r`n","" -replace "`n","" `
    | Set-Clipboard
```

Now in `backend/.env`:
- Find the line `FIREBASE_SERVICE_ACCOUNT_JSON=`
- Click after the `=`
- Paste (Ctrl+V) — the whole JSON should appear as one very long line
- Save (Ctrl+S)

**Sanity check** — verify nothing broke during paste:

```powershell
cd C:\Users\iamha\OneDrive\Documents\GitHub\cramly-study-app\backend
.\.venv\Scripts\Activate.ps1
python -c "from shared.config import settings; import json; data = json.loads(settings.FIREBASE_SERVICE_ACCOUNT_JSON or '{}'); print('project_id:', data.get('project_id')); print('client_email:', data.get('client_email'))"
```

✅ Expected output:
```
project_id: cramly-cd9b5
client_email: firebase-adminsdk-fbsvc@cramly-cd9b5.iam.gserviceaccount.com
```

❌ If you see a JSON parse error → the paste mangled the content. Re-run the clipboard command in step 4 and paste again. The line in `.env` must be **one single line** with no breaks.

❌ If you see `project_id: None` → the JSON is empty. Confirm you did paste *after* the `=` and didn't accidentally paste over the variable name.

---

## ☐ 5. Get a Groq API key

You won't actually use this until Sprint 4 (LLM calls), but having it set means the backend can fully boot. Free tier — no credit card.

1. https://console.groq.com → **Sign up** (Google sign-in works).
2. Verify email if prompted.
3. Left sidebar → **API Keys** → **Create API Key**.
4. Name: `cramly-dev`. Click **Create**.
5. **Copy the key immediately** (shown once only). Format: `gsk_xxxxxxxxxxx...`.
6. In `backend/.env`, paste it after `GROQ_API_KEY=`:
   ```
   GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
7. Save the file.

> Don't worry about ElevenLabs yet — leave `ELEVENLABS_API_KEY=` blank. We'll wire it up in Sprint 10 when the podcast feature lands.

---

## ☐ 6. Restart the backend and re-test

The backend's `--reload` watches Python files but won't always pick up `.env` changes. Restart it cleanly:

1. In the uvicorn terminal: **Ctrl+C** to stop.
2. Re-run:
   ```powershell
   uvicorn api.main:app --reload --port 8000
   ```
3. You should see `Uvicorn running on http://127.0.0.1:8000` and **no errors** about `firebase_admin`.
4. In your phone/emulator: tap **Library → +** → fill in name + color → **Create**.
5. ✅ The course should appear in the list. ❌ If you still get an error, see below.

---

## What to do if step 6 still fails

The error in the app and/or the uvicorn terminal will be different now (since I patched `deps.py`):

| Error message | What it means | Fix |
|---|---|---|
| `Server misconfigured: FIREBASE_SERVICE_ACCOUNT_JSON is empty` | `.env` has empty value | Redo step 4 |
| `Server misconfigured: FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON` | Paste mangled the JSON | Re-run the clipboard command in step 4, paste again |
| `Invalid ID token: ... audience claim ... does not match` | Service account is for a *different* Firebase project | The JSON in `.env` is from another project — re-download from `cramly-cd9b5` |
| `ID token expired` | Sign-in is stale | Sign out + sign back in on the app |
| Connection refused / Network error | App can't reach backend | Check the device / API base URL combo in [SETUP.md §7.4](SETUP.md#74-run-mobile-app-terminal-3) |

Paste the exact error message into chat and I'll pinpoint it.

---

## Done?

When step 6 succeeds (course actually appears in the list), you're ready for Sprint 3. Tell me and we'll proceed.

---

## ☐ Sprint 3 prereq — Tesseract OCR (only if you want Image upload to work)

Tesseract is a *native* binary, not a Python package. Without it, image OCR returns a clear error explaining the missing binary; PDF/DOCX/PPTX/audio/YouTube/Web URL all still work.

**Windows install (2 minutes):**

1. Download the installer from https://github.com/UB-Mannheim/tesseract/wiki — pick the latest 64-bit `tesseract-ocr-w64-setup-*.exe`.
2. Run the installer. **Default install path** is `C:\Program Files\Tesseract-OCR\` — keep that, the backend auto-discovers it.
3. (Optional) Add `C:\Program Files\Tesseract-OCR\` to your PATH — required if you ever change the install path.
4. Verify in PowerShell:
   ```powershell
   & "C:\Program Files\Tesseract-OCR\tesseract.exe" --version
   ```
   Should print a version line. No need to restart anything.

**Render deploy** — Render's Python buildpack doesn't include Tesseract. To enable OCR in production, we'll switch to a Docker base image in Sprint 11. Until then, image uploads will return a "Tesseract binary not found" error in production, but everything else works.

## ☐ Sprint 3 prereq — re-install backend deps

After pulling the latest changes, reinstall to pick up the new extraction libs:

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

This adds `pdfplumber`, `PyMuPDF`, `python-docx`, `python-pptx`, `pytesseract`, `Pillow`, `youtube-transcript-api`, `trafilatura`. Takes 1–3 minutes — `PyMuPDF` is the slow one.
