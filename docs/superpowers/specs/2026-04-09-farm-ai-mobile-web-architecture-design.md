# Farm-AI: Mobile + Web Scalable Architecture Design

**Date:** 2026-04-09
**Status:** Approved
**Scope:** Extend Farm-AI to support voice-first iOS/Android (Flutter) + web (Next.js) with offline capability

---

## Background

The existing Farm-AI codebase has a solid backend:
- FastAPI REST API with LangGraph multi-agent orchestration (5 specialist agents)
- MCP server with 4 tools (weather, soil, market, schemes)
- RAG pipeline with pgvector
- PostgreSQL farmer memory
- Next.js frontend (single 400-line `page.jsx`)

**Problem:** The frontend is not componentized, there is no mobile app, no voice input, no offline support, and no auth. Farmers in rural India need voice-first interaction in their local language and must be able to use the app without reliable connectivity.

---

## Goals

- Web (Next.js) + mobile (Flutter, iOS + Android) from a single backend
- Voice-first input and output in local languages (Hindi, Telugu, Punjabi, Marathi — Phase 1)
- Offline-first: core features work without connectivity, sync when back online
- Phone number + OTP auth (no email/password)
- Existing backend is untouched

---

## Chosen Approach

**Option C: Flutter mobile + Next.js web + shared BFF layer**

The existing backend is not modified. A new BFF (Backend for Frontend) service sits between clients and the backend, owning voice pipeline, offline sync, auth, and push notifications. Both Flutter and Next.js call only the BFF.

---

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │     │  Next.js Web    │
│  (iOS/Android)  │     │  (refactored)   │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └──────────┬────────────┘
                    ▼
         ┌─────────────────────┐
         │    BFF Service      │  port 8002 (new FastAPI service)
         │  - voice pipeline   │
         │  - offline sync     │
         │  - OTP auth + JWT   │
         │  - push notif reg   │
         └──────────┬──────────┘
                    ▼
         ┌─────────────────────┐
         │  Existing Backend   │  port 8000 (untouched)
         │  - LangGraph agents │
         │  - MCP tools        │
         │  - RAG pipeline     │
         │  - PostgreSQL       │
         └─────────────────────┘
```

---

## BFF Service

**Location:** `bff/` (new top-level directory)

```
bff/
├── main.py
├── config.py
├── routers/
│   ├── auth.py
│   ├── voice.py
│   ├── sync.py
│   └── notifications.py
├── services/
│   ├── whisper.py           ← STT via OpenAI Whisper API
│   ├── tts.py               ← TTS via OpenAI TTS
│   ├── translation.py       ← language detection + translation
│   ├── backend_client.py    ← HTTP client calling existing /api/chat
│   └── audio_store.py       ← saves TTS audio, returns URL
└── Dockerfile
```

**Endpoints:**

| Method | Path | Description |
|---|---|---|
| POST | `/auth/otp/send` | Send OTP to phone number |
| POST | `/auth/otp/verify` | Verify OTP, return JWT |
| POST | `/voice/chat` | Full voice pipeline (audio in → audio + text out) |
| POST | `/text/chat` | Text in → text + audio out (web fallback) |
| POST | `/sync/push` | Flush offline queue (batch) |
| GET | `/sync/pull/{farmer_id}` | Latest profile + recent history |
| POST | `/notifications/register` | Store FCM/APNs device token |

---

## Voice Pipeline

```
[Farmer holds mic] → audio recorded locally (.m4a)
        ↓
POST /voice/chat  (multipart: audio file + farmer_id + optional language_hint)
        ↓
BFF: Whisper API → transcribed text + detected language
        ↓
BFF: if not English → translate to English
        ↓
BFF: POST existing /api/chat → agent response (English)
        ↓
BFF: translate response to detected language
        ↓
BFF: TTS → audio file saved, URL returned
        ↓
Response: { text_response, translated_response, audio_url, agent_used, language_detected, queued }
```

**Phase 1 languages:** Hindi (`hi`), Telugu (`te`), Punjabi (`pa`), Marathi (`mr`)

**Translation service:** Google Cloud Translation API (best coverage for Indian languages). Language detection is also handled by Google Cloud Translation's `detectLanguage` endpoint — no separate library needed.

**TTS audio storage:** BFF saves generated audio files to local `/tmp/audio/<uuid>.mp3`. Files are served via a static route (`GET /audio/<uuid>.mp3`) and deleted after 1 hour via a background cleanup task. In production, replace with S3 + pre-signed URLs.

**Key principle:** The existing backend always receives and returns English. Translation is fully owned by the BFF.

---

## Auth

Phone number + OTP. No email or passwords.

```
[Enter phone] → BFF → Twilio/MSG91 → OTP SMS
[Enter OTP]   → BFF verifies → JWT issued (7-day expiry)

JWT storage:
  Flutter → flutter_secure_storage (device keychain)
  Web     → httpOnly cookie

All requests: Authorization: Bearer <JWT>
BFF validates JWT → extracts farmer_id → passes to existing backend
```

Existing backend remains stateless — it still receives `farmer_id` as before. Auth is fully BFF-owned.

---

## Offline Sync

### Core principle
Clients work locally first. Requests are queued when offline and flushed when connectivity is restored.

### Local storage schema

**Flutter (SQLite via Drift) / Web (IndexedDB):**

| Table | Contents |
|---|---|
| `farmer_profile` | Name, land, crops, location — synced at login |
| `conversations` | Last 20 conversations (text + local audio file path) |
| `offline_queue` | Pending requests waiting to be sent |
| `cached_knowledge` | Pre-downloaded regional crop guides |

**`offline_queue` table:**

| Column | Type | Description |
|---|---|---|
| `id` | UUID | Generated locally |
| `created_at` | timestamp | |
| `type` | enum | `"voice"` or `"text"` |
| `payload` | JSON | `{audio_path, language, farmer_id}` or `{text, farmer_id}` |
| `status` | enum | `"pending"`, `"sending"`, `"failed"` |
| `retry_count` | integer | Max 3 |

### Queue lifecycle

```
Farmer speaks → audio saved to local file → row inserted (status=pending)
UI shows "Queued — will send when connected"
        ↓
[Connectivity restored]
        ↓
Sync service wakes → picks pending rows (ORDER BY created_at ASC)
Sets status=sending → sends to BFF
  Success → delete row, save response to conversations table
  Failure → status=failed, retry_count += 1
After 3 failures → show "failed — tap to retry"
```

### Retry policy
Exponential backoff: 2s → 4s → 8s. Max 3 retries. Manual retry available from UI.

### Audio files
Queue stores the local file path, not bytes. On sync, BFF reads and uploads the file, then deletes it locally on success. Keeps the queue table lightweight.

### Sync triggers

| Trigger | Flutter | Web |
|---|---|---|
| App foreground | Yes | Yes |
| Network restored | connectivity_plus | `online` event listener |
| Background fetch | Yes (every 15 min) | No |
| Manual pull-to-refresh | Yes | Yes |

### BFF sync endpoints

```
POST /sync/push     ← batch of queued requests, processed in order
GET  /sync/pull/{farmer_id} ← latest farmer profile + last 20 conversations
```

### Feature availability offline

| Feature | Offline | Notes |
|---|---|---|
| View past conversations | Yes | Cached locally |
| Send voice query | Queued | Sent when reconnected |
| View farmer profile | Yes | Cached at login |
| Mandi prices | No | Show last cached price + timestamp |
| Weather forecast | No | Show last cached forecast + timestamp |
| Common crop advice | Partial | Pre-cached regional knowledge pack |

### Pre-cached knowledge pack
Downloaded on first launch (or on WiFi). Compressed JSON of common Q&A pairs for the farmer's state and registered crops. Powers instant responses for the most common queries (pest ID, irrigation schedule, fertilizer dosage) with zero connectivity.

---

## Flutter App

**Location:** `flutter/` (new top-level directory)

```
lib/
├── main.dart
├── features/
│   ├── auth/
│   │   ├── otp_screen.dart
│   │   └── auth_service.dart
│   ├── chat/
│   │   ├── chat_screen.dart         ← main voice chat UI
│   │   ├── voice_recorder.dart      ← hold-to-record button
│   │   └── message_bubble.dart      ← text + audio playback
│   ├── dashboard/
│   │   ├── dashboard_screen.dart
│   │   └── agent_status_widget.dart
│   └── history/
│       └── history_screen.dart      ← from local SQLite
├── services/
│   ├── api_service.dart             ← BFF HTTP calls
│   ├── voice_service.dart           ← record + playback
│   ├── sync_service.dart            ← offline queue + background sync
│   └── storage_service.dart         ← SQLite via Drift
├── models/
│   ├── farmer.dart
│   ├── message.dart
│   └── queued_request.dart
└── core/
    ├── connectivity_watcher.dart
    └── theme.dart
```

**Key packages:**

| Package | Purpose |
|---|---|
| `drift` | SQLite ORM (offline storage + queue) |
| `record` | Audio recording |
| `just_audio` | Audio playback for TTS responses |
| `connectivity_plus` | Network state watching |
| `background_fetch` | Periodic background sync |
| `flutter_secure_storage` | JWT storage |
| `dio` | HTTP client |

---

## Next.js Refactor

Current `src/app/page.jsx` (400 lines) is split into focused components. The page becomes a thin shell.

```
src/
├── app/
│   ├── page.jsx                     ← thin shell
│   └── api/                         ← proxy routes to BFF
├── components/
│   ├── chat/
│   │   ├── ChatScreen.jsx
│   │   ├── VoiceInput.jsx           ← MediaRecorder API, hold-to-record
│   │   ├── MessageList.jsx
│   │   └── MessageBubble.jsx        ← text + inline audio player
│   └── dashboard/
│       ├── FarmStats.jsx
│       └── AgentStatus.jsx
├── hooks/
│   ├── useVoice.js                  ← recording state machine
│   ├── useOfflineQueue.js           ← IndexedDB queue + online listener
│   └── useFarmerProfile.js
├── lib/
│   └── api.js                       ← single BFF API client
└── public/
    ├── manifest.json                ← PWA manifest
    └── sw.js                        ← service worker (offline caching)
```

**Web offline strategy:** Service worker caches app shell + static assets. `useOfflineQueue` hook mirrors Flutter queue logic using IndexedDB + Background Sync API.

---

## Infrastructure Changes

`docker-compose.yml` additions:

```yaml
bff:
  build: ./bff
  ports:
    - "8002:8002"
  env_file: .env
  depends_on:
    - backend
```

No changes to existing services (postgres, redis, mcp, backend, frontend).

---

## What Is Not Changing

| Component | Status |
|---|---|
| `backend/agents/supervisor.py` | Untouched |
| `backend/mcp/` | Untouched |
| `backend/rag/` | Untouched |
| `backend/memory/store.py` | Untouched |
| `backend/main.py` | Untouched |
| `infra/postgres/init.sql` | Untouched |
| MCP SSE transport (internal) | Untouched — SSE is backend-to-backend, not client-facing |

---

## Build Order

1. BFF service (auth + voice pipeline + sync endpoints)
2. Next.js refactor (componentize + voice input + PWA/offline)
3. Flutter app (auth + voice chat + SQLite offline + sync)
4. Docker Compose update (add BFF service)
5. End-to-end testing (online + offline scenarios)
