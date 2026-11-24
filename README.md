# EasyNet

**Your personal assistant for the entire internet.** People ask by voice or text in English, हिंदी or ಕನ್ನಡ and get simple numbered steps, with links to the official websites.

First version (v0.1): assistant chat only.

## What's inside

| Part | Where | What it does |
|---|---|---|
| App (Flutter: Android, iOS, web) | `lib/` | Home screen with a big mic, text box, language switch, 4 suggested tasks, recent tasks. Chat screen with steps, sources, Read aloud, Copy. Privacy screen to delete all chats. |
| Server (Vercel function) | `api/chat.js`, `server/core.js` | Holds the Gemini key, hides card/Aadhaar/account numbers and OTPs, asks Gemini with Google Search, returns the answer and sources. |
| Landing page | `public/index.html` | Simple page at the Vercel address. |
| Build | `.github/workflows/build.yml` | Tests the server, then builds the Android APK and the web app on GitHub. |
| Permissions | `scripts/add_permissions.py` | Adds microphone/speech permissions to Android and iOS after `flutter create .`. Safe to run twice. |

Chats are stored only on the phone. The assistant never asks for passwords or OTPs and never pays or submits forms for the user.

## Setup steps

1. **GitHub:** create an empty repo `easynet` and push this folder to it.
2. **Gemini key:** get one at https://aistudio.google.com/apikey.
3. **Vercel:** *Add New → Project →* import the `easynet` repo. Framework preset: **Other**. Add the environment variable `GEMINI_API_KEY`. Deploy. Note the address, e.g. `https://easynet-xyz.vercel.app`.
4. **Point the app at the server:** in GitHub, *Settings → Secrets and variables → Actions → Variables*, add `API_URL` = your Vercel address (no trailing slash). Re-run the **build** workflow.
5. **Get the APK:** open the finished workflow run in the *Actions* tab and download **easynet-android-apk**. Install it on your phone (allow "install unknown apps").

Test the server directly:

```bash
curl -X POST https://YOUR-APP.vercel.app/api/chat \
  -H "Content-Type: application/json" \
  -d '{"lang":"kn","messages":[{"role":"user","text":"How do I check PNR status?"}]}'
```

## Run on your own computer (optional)

```bash
flutter create --platforms=android,ios,web --project-name easynet --org in.easynet .
python3 scripts/add_permissions.py .
flutter run --dart-define=API_URL=https://YOUR-APP.vercel.app
npm test   # server tests
```

## Later versions

Website explainer, document and form helper, scam-link checker, paid plans.
