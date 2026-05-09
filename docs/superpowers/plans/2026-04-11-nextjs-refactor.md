# Farm-AI Next.js Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the monolithic 400-line `page.jsx` into a componentized Next.js 14 app with voice input, PWA offline support, and BFF integration replacing the direct backend calls.

**Architecture:** Existing `page.jsx` logic is split into focused components, hooks, and lib utilities. A `lib/api.js` client calls Next.js API proxy routes (in `app/api/`) which forward to the BFF on port 8002 — keeping the BFF URL server-side only. Voice input uses the browser's `MediaRecorder` API. Offline queuing uses `idb-keyval` (IndexedDB wrapper). A service worker enables PWA installability and app-shell caching.

**Tech Stack:** Next.js 14.2.5, React 18, Tailwind CSS, Jest 29, @testing-library/react 14, idb-keyval 6, browser MediaRecorder API, IndexedDB, Web App Manifest, Service Worker

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `package.json` | Modify | Add tailwindcss, jest, RTL, idb-keyval |
| `tailwind.config.js` | Create | Tailwind content paths |
| `postcss.config.js` | Create | PostCSS for Tailwind |
| `jest.config.js` | Create | Jest + Next.js integration |
| `jest.setup.js` | Create | @testing-library/jest-dom import |
| `src/app/globals.css` | Create | Tailwind directives |
| `src/app/layout.js` | Create | Root layout, SW registration, globals.css import |
| `src/app/page.jsx` | Modify | Thin shell — tab state + compose components |
| `src/app/api/text/route.js` | Create | Proxy POST /text/chat → BFF |
| `src/app/api/voice/route.js` | Create | Proxy POST /voice/chat → BFF (multipart) |
| `src/app/api/sync/push/route.js` | Create | Proxy POST /sync/push → BFF |
| `src/app/api/sync/pull/[farmerId]/route.js` | Create | Proxy GET /sync/pull → BFF |
| `src/lib/agentConfig.js` | Create | AGENT_COLORS, AGENT_ICONS constants |
| `src/lib/demoMode.js` | Create | getDemoResponse() — fallback when BFF offline |
| `src/lib/quickAsks.js` | Create | QUICK_ASKS array |
| `src/lib/api.js` | Create | Client-side fetch wrappers (sendText, sendVoice, syncPull, syncPush) |
| `src/hooks/useFarmerProfile.js` | Create | farmer_id from localStorage |
| `src/hooks/useVoice.js` | Create | MediaRecorder state machine |
| `src/hooks/useOfflineQueue.js` | Create | IndexedDB queue + online event flush |
| `src/components/chat/MessageBubble.jsx` | Create | Single message — text + optional audio player |
| `src/components/chat/ThinkingBubble.jsx` | Create | Animated loading indicator |
| `src/components/chat/MessageList.jsx` | Create | Scrolling list of messages + thinking bubble |
| `src/components/chat/VoiceInput.jsx` | Create | Hold-to-record mic button |
| `src/components/chat/ChatScreen.jsx` | Create | Full chat UI — owns all chat state |
| `src/components/dashboard/FarmStats.jsx` | Create | Farm overview stat cards |
| `src/components/dashboard/AgentStatus.jsx` | Create | Agent + MCP tool status list |
| `public/manifest.json` | Create | PWA web app manifest |
| `public/sw.js` | Create | Service worker — app shell caching |
| `next.config.js` | Modify | Add BFF_URL env var, SW headers |
| `__tests__/lib/agentConfig.test.js` | Create | |
| `__tests__/lib/demoMode.test.js` | Create | |
| `__tests__/lib/api.test.js` | Create | |
| `__tests__/api/text.test.js` | Create | |
| `__tests__/api/voice.test.js` | Create | |
| `__tests__/api/sync.test.js` | Create | |
| `__tests__/hooks/useFarmerProfile.test.js` | Create | |
| `__tests__/hooks/useVoice.test.js` | Create | |
| `__tests__/hooks/useOfflineQueue.test.js` | Create | |
| `__tests__/components/MessageBubble.test.jsx` | Create | |
| `__tests__/components/ThinkingBubble.test.jsx` | Create | |
| `__tests__/components/MessageList.test.jsx` | Create | |
| `__tests__/components/VoiceInput.test.jsx` | Create | |
| `__tests__/components/ChatScreen.test.jsx` | Create | |
| `__tests__/components/FarmStats.test.jsx` | Create | |
| `__tests__/components/AgentStatus.test.jsx` | Create | |

---

## Task 1: Project setup — Tailwind CSS, layout, Jest config

**Files:**
- Modify: `frontend/package.json`
- Create: `frontend/tailwind.config.js`
- Create: `frontend/postcss.config.js`
- Create: `frontend/jest.config.js`
- Create: `frontend/jest.setup.js`
- Create: `frontend/src/app/globals.css`
- Create: `frontend/src/app/layout.js`

All commands run from `frontend/`.

- [ ] **Step 1: Install dependencies**

```bash
cd frontend
npm install idb-keyval
npm install -D tailwindcss postcss autoprefixer jest jest-environment-jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event
```

- [ ] **Step 2: Add test script to `package.json`**

Open `frontend/package.json`. Change the `scripts` section to:

```json
"scripts": {
  "dev": "next dev",
  "build": "next build",
  "start": "next start -p ${PORT:-3000}",
  "lint": "next lint",
  "test": "jest",
  "test:watch": "jest --watch"
}
```

- [ ] **Step 3: Create `frontend/tailwind.config.js`**

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/app/**/*.{js,jsx,ts,tsx}',
    './src/components/**/*.{js,jsx,ts,tsx}',
    './src/hooks/**/*.{js,jsx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

- [ ] **Step 4: Create `frontend/postcss.config.js`**

```js
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

- [ ] **Step 5: Create `frontend/jest.config.js`**

```js
const nextJest = require('next/jest')

const createJestConfig = nextJest({ dir: './' })

module.exports = createJestConfig({
  setupFilesAfterFramework: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  testMatch: ['**/__tests__/**/*.{js,jsx}', '**/*.test.{js,jsx}'],
})
```

- [ ] **Step 6: Create `frontend/jest.setup.js`**

```js
import '@testing-library/jest-dom'
```

- [ ] **Step 7: Create `frontend/src/app/globals.css`**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

- [ ] **Step 8: Create `frontend/src/app/layout.js`**

```jsx
import './globals.css'

export const metadata = {
  title: 'FarmAI',
  description: 'AI Agricultural Advisor powered by Claude + MCP + RAG',
  manifest: '/manifest.json',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
```

- [ ] **Step 9: Write a smoke test to verify jest works**

Create `frontend/__tests__/smoke.test.js`:

```js
test('jest is configured correctly', () => {
  expect(true).toBe(true)
})
```

- [ ] **Step 10: Run test to verify it passes**

```bash
cd frontend && npm test -- --testPathPattern=smoke
```

Expected: `1 passed`

- [ ] **Step 11: Verify dev server still starts**

```bash
cd frontend && npm run dev &
sleep 5 && curl -s http://localhost:3000 | head -5
kill %1
```

Expected: HTML response from Next.js

- [ ] **Step 12: Commit**

```bash
cd frontend
git add package.json package-lock.json tailwind.config.js postcss.config.js jest.config.js jest.setup.js src/app/globals.css src/app/layout.js __tests__/smoke.test.js
git commit -m "feat(frontend): add Tailwind CSS, Jest + RTL, root layout"
```

---

## Task 2: lib utilities — agentConfig, demoMode, quickAsks

**Files:**
- Create: `frontend/src/lib/agentConfig.js`
- Create: `frontend/src/lib/demoMode.js`
- Create: `frontend/src/lib/quickAsks.js`
- Create: `frontend/__tests__/lib/agentConfig.test.js`
- Create: `frontend/__tests__/lib/demoMode.test.js`

- [ ] **Step 1: Write `__tests__/lib/agentConfig.test.js`**

```js
import { AGENT_COLORS, AGENT_ICONS } from '@/lib/agentConfig'

const EXPECTED_AGENTS = ['crop_advisor', 'pest_detector', 'market_analyst', 'irrigation_planner', 'scheme_navigator', 'supervisor']

test('AGENT_COLORS has entry for every agent', () => {
  EXPECTED_AGENTS.forEach(agent => {
    expect(AGENT_COLORS).toHaveProperty(agent)
  })
})

test('AGENT_ICONS has entry for every agent', () => {
  EXPECTED_AGENTS.forEach(agent => {
    expect(AGENT_ICONS).toHaveProperty(agent)
  })
})

test('AGENT_COLORS values are Tailwind class strings', () => {
  Object.values(AGENT_COLORS).forEach(cls => {
    expect(typeof cls).toBe('string')
    expect(cls.length).toBeGreaterThan(0)
  })
})
```

- [ ] **Step 2: Write `__tests__/lib/demoMode.test.js`**

```js
import { getDemoResponse } from '@/lib/demoMode'

test('returns crop_advisor agent for crop keyword', () => {
  const result = getDemoResponse('which crop should I plant?')
  expect(result.agent).toBe('crop_advisor')
  expect(typeof result.text).toBe('string')
})

test('returns pest_detector agent for disease keyword', () => {
  const result = getDemoResponse('my tomato has brown spots disease')
  expect(result.agent).toBe('pest_detector')
})

test('returns market_analyst agent for price keyword', () => {
  const result = getDemoResponse('what is the current price at mandi?')
  expect(result.agent).toBe('market_analyst')
})

test('returns irrigation_planner agent for water keyword', () => {
  const result = getDemoResponse('should I irrigate today?')
  expect(result.agent).toBe('irrigation_planner')
})

test('returns scheme_navigator agent for scheme keyword', () => {
  const result = getDemoResponse('am I eligible for government scheme PM-KISAN?')
  expect(result.agent).toBe('scheme_navigator')
})

test('returns supervisor agent for unrecognized input', () => {
  const result = getDemoResponse('xyzzy unfamiliar topic')
  expect(result.agent).toBe('supervisor')
})

test('returned text is a non-empty string', () => {
  const result = getDemoResponse('hello')
  expect(result.text.length).toBeGreaterThan(10)
})
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
cd frontend && npm test -- --testPathPattern="lib/(agentConfig|demoMode)"
```

Expected: `FAILED` — `Cannot find module '@/lib/agentConfig'`

- [ ] **Step 4: Create `frontend/src/lib/agentConfig.js`**

```js
export const AGENT_COLORS = {
  crop_advisor: 'bg-green-100 text-green-800',
  pest_detector: 'bg-red-100 text-red-800',
  market_analyst: 'bg-blue-100 text-blue-800',
  irrigation_planner: 'bg-cyan-100 text-cyan-800',
  scheme_navigator: 'bg-purple-100 text-purple-800',
  supervisor: 'bg-gray-100 text-gray-800',
}

export const AGENT_ICONS = {
  crop_advisor: '🌾',
  pest_detector: '🔬',
  market_analyst: '📈',
  irrigation_planner: '💧',
  scheme_navigator: '🏛️',
  supervisor: '🧠',
}
```

- [ ] **Step 5: Create `frontend/src/lib/demoMode.js`**

```js
export function getDemoResponse(message) {
  const msg = message.toLowerCase()

  if (msg.includes('crop') || msg.includes('plant') || msg.includes('rabi') || msg.includes('kharif')) {
    return {
      agent: 'crop_advisor',
      text: '🌾 Based on your location in Telangana and the current Rabi season:\n\n**Top 3 recommendations:**\n\n1. **Wheat** (Variety: HI-8498)\n   - Sow: November 15 - December 15\n   - Expected yield: 35-40 q/ha\n\n2. **Chickpea (Chana)** (Variety: JG-11)\n   - Lower water need — good for drip system\n   - MSP: ₹5,440/quintal\n\n3. **Safflower** (drought tolerant)\n\n[Source: crop_guides knowledge base + MCP weather tool]',
    }
  }

  if (msg.includes('pest') || msg.includes('disease') || msg.includes('spots') || msg.includes('yellow') || msg.includes('blight')) {
    return {
      agent: 'pest_detector',
      text: '🔬 **Diagnosis: Early Blight (Alternaria solani)** — Confidence: HIGH\n\n**Immediate Action:**\nSpray Mancozeb 75% WP @ 2.5g/liter\n\n**Follow-up:** Spray every 10-14 days, avoid overhead irrigation.\n\n[Source: pest_library knowledge base]',
    }
  }

  if (msg.includes('price') || msg.includes('sell') || msg.includes('mandi') || msg.includes('market')) {
    return {
      agent: 'market_analyst',
      text: '📈 **Cotton Market Update — Telangana**\n\nModal price: ₹7,200/quintal\nMSP: ₹7,020/quintal (**above MSP** ✅)\n\n**Recommendation:** SELL NOW — prices trending up.\n\n[Source: MCP mandi_prices tool]',
    }
  }

  if (msg.includes('irrigat') || msg.includes('water')) {
    return {
      agent: 'irrigation_planner',
      text: '💧 **Irrigation Advisory**\n\nToday & Tomorrow: Skip (soil moisture adequate)\nWednesday: Rain expected — skip\nThursday-Friday: Resume drip — 40 min/day\n\n[Source: MCP weather_forecast + soil_analysis tools]',
    }
  }

  if (msg.includes('scheme') || msg.includes('subsid') || msg.includes('pm-kisan') || msg.includes('government')) {
    return {
      agent: 'scheme_navigator',
      text: '🏛️ **You are eligible for:**\n\n1. **PM-KISAN** ✅ — ₹6,000/year\n2. **PMFBY Crop Insurance** ✅ — 1.5% premium\n3. **Kisan Credit Card** ✅ — 4% interest loan\n\nStart with PM-KISAN registration at pmkisan.gov.in\n\n[Source: MCP government_schemes tool]',
    }
  }

  return {
    agent: 'supervisor',
    text: 'I understand your query. As FarmAI supervisor, I route to specialists:\n\n🌾 Crop Advisor — planting & fertilizer\n🔬 Pest Detector — disease diagnosis\n📈 Market Analyst — prices & selling\n💧 Irrigation Planner — water scheduling\n🏛️ Scheme Navigator — government benefits\n\nTry asking about one of these topics!',
  }
}
```

- [ ] **Step 6: Create `frontend/src/lib/quickAsks.js`**

```js
export const QUICK_ASKS = [
  { text: 'Which crop for Rabi season?', icon: '🌾' },
  { text: 'My tomato leaves have brown spots', icon: '🍅' },
  { text: 'Current wheat price in Telangana?', icon: '💰' },
  { text: 'Should I irrigate today?', icon: '💧' },
  { text: 'Am I eligible for PM-KISAN?', icon: '🏛️' },
  { text: 'Best time to sell my cotton?', icon: '📊' },
]
```

- [ ] **Step 7: Run tests to verify they pass**

```bash
cd frontend && npm test -- --testPathPattern="lib/(agentConfig|demoMode)"
```

Expected: `9 passed`

- [ ] **Step 8: Commit**

```bash
cd frontend
git add src/lib/ __tests__/lib/
git commit -m "feat(frontend): extract agentConfig, demoMode, quickAsks to lib/"
```

---

## Task 3: lib/api.js — client-side BFF proxy calls

**Files:**
- Create: `frontend/src/lib/api.js`
- Create: `frontend/__tests__/lib/api.test.js`

- [ ] **Step 1: Write `__tests__/lib/api.test.js`**

```js
import { sendText, sendVoice, syncPull, syncPush } from '@/lib/api'

beforeEach(() => {
  global.fetch = jest.fn()
})

afterEach(() => {
  jest.resetAllMocks()
})

test('sendText POSTs to /api/text with correct body', async () => {
  global.fetch.mockResolvedValue({
    ok: true,
    json: async () => ({ text_response: 'ok', agent_used: 'crop_advisor' }),
  })

  const result = await sendText('farmer-1', 'hello', 'hi')

  expect(global.fetch).toHaveBeenCalledWith('/api/text', expect.objectContaining({
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ farmer_id: 'farmer-1', text: 'hello', language: 'hi' }),
  }))
  expect(result.text_response).toBe('ok')
})

test('sendText defaults language to "hi"', async () => {
  global.fetch.mockResolvedValue({
    ok: true,
    json: async () => ({}),
  })

  await sendText('farmer-1', 'hello')

  const body = JSON.parse(global.fetch.mock.calls[0][1].body)
  expect(body.language).toBe('hi')
})

test('sendText throws on non-ok response', async () => {
  global.fetch.mockResolvedValue({ ok: false, status: 503 })
  await expect(sendText('f', 'x')).rejects.toThrow('503')
})

test('sendVoice POSTs FormData to /api/voice', async () => {
  global.fetch.mockResolvedValue({
    ok: true,
    json: async () => ({ audio_url: '/audio/test.mp3', text_response: 'ok' }),
  })

  const blob = new Blob(['audio'], { type: 'audio/m4a' })
  const result = await sendVoice('farmer-1', blob, 'hi')

  const [url, options] = global.fetch.mock.calls[0]
  expect(url).toBe('/api/voice')
  expect(options.method).toBe('POST')
  expect(options.body).toBeInstanceOf(FormData)
  expect(result.audio_url).toBe('/audio/test.mp3')
})

test('syncPull GETs /api/sync/pull/{farmerId}', async () => {
  global.fetch.mockResolvedValue({
    ok: true,
    json: async () => ({ farmer_profile: {}, recent_conversations: [] }),
  })

  await syncPull('farmer-1')

  expect(global.fetch).toHaveBeenCalledWith('/api/sync/pull/farmer-1')
})

test('syncPush POSTs batch to /api/sync/push', async () => {
  global.fetch.mockResolvedValue({
    ok: true,
    json: async () => ({ results: [] }),
  })

  const requests = [{ id: 'req-1', text: 'hello', farmer_id: 'f1', language: 'hi', queued_at: '2026-01-01' }]
  await syncPush(requests)

  const body = JSON.parse(global.fetch.mock.calls[0][1].body)
  expect(body.requests).toHaveLength(1)
  expect(body.requests[0].id).toBe('req-1')
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd frontend && npm test -- --testPathPattern="lib/api"
```

Expected: `FAILED` — `Cannot find module '@/lib/api'`

- [ ] **Step 3: Create `frontend/src/lib/api.js`**

```js
export async function sendText(farmerId, text, language = 'hi') {
  const resp = await fetch('/api/text', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ farmer_id: farmerId, text, language }),
  })
  if (!resp.ok) throw new Error(String(resp.status))
  return resp.json()
}

export async function sendVoice(farmerId, audioBlob, languageHint = '') {
  const formData = new FormData()
  formData.append('farmer_id', farmerId)
  formData.append('audio', audioBlob, 'recording.m4a')
  if (languageHint) formData.append('language_hint', languageHint)

  const resp = await fetch('/api/voice', {
    method: 'POST',
    body: formData,
  })
  if (!resp.ok) throw new Error(String(resp.status))
  return resp.json()
}

export async function syncPull(farmerId) {
  const resp = await fetch(`/api/sync/pull/${farmerId}`)
  if (!resp.ok) throw new Error(String(resp.status))
  return resp.json()
}

export async function syncPush(requests) {
  const resp = await fetch('/api/sync/push', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ requests }),
  })
  if (!resp.ok) throw new Error(String(resp.status))
  return resp.json()
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd frontend && npm test -- --testPathPattern="lib/api"
```

Expected: `6 passed`

- [ ] **Step 5: Commit**

```bash
cd frontend
git add src/lib/api.js __tests__/lib/api.test.js
git commit -m "feat(frontend): add BFF API client (sendText, sendVoice, syncPull, syncPush)"
```

---

## Task 4: Next.js API proxy routes

**Files:**
- Create: `frontend/src/app/api/text/route.js`
- Create: `frontend/src/app/api/voice/route.js`
- Create: `frontend/src/app/api/sync/push/route.js`
- Create: `frontend/src/app/api/sync/pull/[farmerId]/route.js`
- Create: `frontend/__tests__/api/text.test.js`
- Create: `frontend/__tests__/api/voice.test.js`
- Create: `frontend/__tests__/api/sync.test.js`
- Modify: `frontend/next.config.js`

- [ ] **Step 1: Update `frontend/next.config.js` to expose BFF_URL server-side**

```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  },
  async headers() {
    return [
      {
        source: '/sw.js',
        headers: [
          { key: 'Cache-Control', value: 'public, max-age=0, must-revalidate' },
          { key: 'Service-Worker-Allowed', value: '/' },
        ],
      },
    ]
  },
}

module.exports = nextConfig
```

Note: `BFF_URL` is read server-side in API routes via `process.env.BFF_URL` — no NEXT_PUBLIC prefix needed (keeps BFF URL off the client).

- [ ] **Step 2: Write `__tests__/api/text.test.js`**

```js
import { POST } from '@/app/api/text/route'

beforeEach(() => {
  global.fetch = jest.fn()
  process.env.BFF_URL = 'http://test-bff:8002'
})

afterEach(() => jest.resetAllMocks())

test('POST proxies request to BFF /text/chat', async () => {
  global.fetch.mockResolvedValue({
    status: 200,
    json: async () => ({ text_response: 'Use drip irrigation', agent_used: 'irrigation_planner' }),
  })

  const req = new Request('http://localhost/api/text', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ farmer_id: 'farmer-1', text: 'How to water wheat?', language: 'hi' }),
  })

  const resp = await POST(req)
  const data = await resp.json()

  expect(global.fetch).toHaveBeenCalledWith(
    'http://test-bff:8002/text/chat',
    expect.objectContaining({ method: 'POST' })
  )
  expect(data.text_response).toBe('Use drip irrigation')
  expect(resp.status).toBe(200)
})
```

- [ ] **Step 3: Write `__tests__/api/voice.test.js`**

```js
import { POST } from '@/app/api/voice/route'

beforeEach(() => {
  global.fetch = jest.fn()
  process.env.BFF_URL = 'http://test-bff:8002'
})

afterEach(() => jest.resetAllMocks())

test('POST proxies FormData to BFF /voice/chat', async () => {
  global.fetch.mockResolvedValue({
    status: 200,
    json: async () => ({
      text_response: 'Use neem oil',
      translated_response: 'नीम तेल का उपयोग करें',
      audio_url: '/audio/test.mp3',
      agent_used: 'pest_detector',
      language_detected: 'hi',
      queued: false,
    }),
  })

  const formData = new FormData()
  formData.append('farmer_id', 'farmer-1')
  formData.append('audio', new Blob(['audio'], { type: 'audio/m4a' }), 'recording.m4a')

  const req = new Request('http://localhost/api/voice', {
    method: 'POST',
    body: formData,
  })

  const resp = await POST(req)
  const data = await resp.json()

  expect(global.fetch).toHaveBeenCalledWith(
    'http://test-bff:8002/voice/chat',
    expect.objectContaining({ method: 'POST' })
  )
  expect(data.audio_url).toBe('/audio/test.mp3')
})
```

- [ ] **Step 4: Write `__tests__/api/sync.test.js`**

```js
import { POST as syncPushPOST } from '@/app/api/sync/push/route'
import { GET as syncPullGET } from '@/app/api/sync/pull/[farmerId]/route'

beforeEach(() => {
  global.fetch = jest.fn()
  process.env.BFF_URL = 'http://test-bff:8002'
})

afterEach(() => jest.resetAllMocks())

test('sync/push proxies batch to BFF', async () => {
  global.fetch.mockResolvedValue({
    status: 200,
    json: async () => ({ results: [{ id: 'req-1', success: true }] }),
  })

  const req = new Request('http://localhost/api/sync/push', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ requests: [{ id: 'req-1', text: 'hello', farmer_id: 'f1', language: 'hi', queued_at: '2026-01-01T00:00:00Z' }] }),
  })

  const resp = await syncPushPOST(req)
  const data = await resp.json()

  expect(global.fetch).toHaveBeenCalledWith(
    'http://test-bff:8002/sync/push',
    expect.objectContaining({ method: 'POST' })
  )
  expect(data.results[0].success).toBe(true)
})

test('sync/pull proxies to BFF with correct farmerId', async () => {
  global.fetch.mockResolvedValue({
    status: 200,
    json: async () => ({ farmer_profile: { name: 'Raju' }, recent_conversations: [] }),
  })

  const req = new Request('http://localhost/api/sync/pull/farmer-1')
  const resp = await syncPullGET(req, { params: { farmerId: 'farmer-1' } })
  const data = await resp.json()

  expect(global.fetch).toHaveBeenCalledWith('http://test-bff:8002/sync/pull/farmer-1')
  expect(data.farmer_profile.name).toBe('Raju')
})
```

- [ ] **Step 5: Run tests to verify they fail**

```bash
cd frontend && npm test -- --testPathPattern="api/(text|voice|sync)"
```

Expected: `FAILED` — route files not found

- [ ] **Step 6: Create `frontend/src/app/api/text/route.js`**

```js
const BFF_URL = process.env.BFF_URL || 'http://localhost:8002'

export async function POST(request) {
  const body = await request.json()
  const resp = await fetch(`${BFF_URL}/text/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  const data = await resp.json()
  return Response.json(data, { status: resp.status })
}
```

- [ ] **Step 7: Create `frontend/src/app/api/voice/route.js`**

```js
const BFF_URL = process.env.BFF_URL || 'http://localhost:8002'

export async function POST(request) {
  const formData = await request.formData()
  const resp = await fetch(`${BFF_URL}/voice/chat`, {
    method: 'POST',
    body: formData,
  })
  const data = await resp.json()
  return Response.json(data, { status: resp.status })
}
```

- [ ] **Step 8: Create `frontend/src/app/api/sync/push/route.js`**

```js
const BFF_URL = process.env.BFF_URL || 'http://localhost:8002'

export async function POST(request) {
  const body = await request.json()
  const resp = await fetch(`${BFF_URL}/sync/push`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  const data = await resp.json()
  return Response.json(data, { status: resp.status })
}
```

- [ ] **Step 9: Create `frontend/src/app/api/sync/pull/[farmerId]/route.js`**

```js
const BFF_URL = process.env.BFF_URL || 'http://localhost:8002'

export async function GET(request, { params }) {
  const resp = await fetch(`${BFF_URL}/sync/pull/${params.farmerId}`)
  const data = await resp.json()
  return Response.json(data, { status: resp.status })
}
```

- [ ] **Step 10: Run tests to verify they pass**

```bash
cd frontend && npm test -- --testPathPattern="api/(text|voice|sync)"
```

Expected: `4 passed`

- [ ] **Step 11: Commit**

```bash
cd frontend
git add src/app/api/ next.config.js __tests__/api/
git commit -m "feat(frontend): add Next.js API proxy routes to BFF"
```

---

## Task 5: hooks/useFarmerProfile.js

**Files:**
- Create: `frontend/src/hooks/useFarmerProfile.js`
- Create: `frontend/__tests__/hooks/useFarmerProfile.test.js`

- [ ] **Step 1: Write `__tests__/hooks/useFarmerProfile.test.js`**

```js
import { renderHook, act } from '@testing-library/react'
import { useFarmerProfile } from '@/hooks/useFarmerProfile'

beforeEach(() => {
  localStorage.clear()
})

test('returns "demo-farmer" when no stored value', () => {
  const { result } = renderHook(() => useFarmerProfile())
  expect(result.current.farmerId).toBe('demo-farmer')
})

test('returns stored farmer_id from localStorage', () => {
  localStorage.setItem('farm-ai-farmer-id', 'raju-reddy')
  const { result } = renderHook(() => useFarmerProfile())
  expect(result.current.farmerId).toBe('raju-reddy')
})

test('setFarmerId updates value and persists to localStorage', () => {
  const { result } = renderHook(() => useFarmerProfile())
  act(() => {
    result.current.setFarmerId('balwinder-singh')
  })
  expect(result.current.farmerId).toBe('balwinder-singh')
  expect(localStorage.getItem('farm-ai-farmer-id')).toBe('balwinder-singh')
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd frontend && npm test -- --testPathPattern="hooks/useFarmerProfile"
```

Expected: `FAILED`

- [ ] **Step 3: Create `frontend/src/hooks/useFarmerProfile.js`**

```js
'use client'
import { useState, useEffect } from 'react'

const STORAGE_KEY = 'farm-ai-farmer-id'
const DEFAULT_FARMER_ID = 'demo-farmer'

export function useFarmerProfile() {
  const [farmerId, setFarmerIdState] = useState(DEFAULT_FARMER_ID)

  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored) setFarmerIdState(stored)
  }, [])

  const setFarmerId = (id) => {
    setFarmerIdState(id)
    localStorage.setItem(STORAGE_KEY, id)
  }

  return { farmerId, setFarmerId }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd frontend && npm test -- --testPathPattern="hooks/useFarmerProfile"
```

Expected: `3 passed`

- [ ] **Step 5: Commit**

```bash
cd frontend
git add src/hooks/useFarmerProfile.js __tests__/hooks/useFarmerProfile.test.js
git commit -m "feat(frontend): add useFarmerProfile hook with localStorage persistence"
```

---

## Task 6: hooks/useVoice.js

**Files:**
- Create: `frontend/src/hooks/useVoice.js`
- Create: `frontend/__tests__/hooks/useVoice.test.js`

- [ ] **Step 1: Write `__tests__/hooks/useVoice.test.js`**

```js
import { renderHook, act } from '@testing-library/react'
import { useVoice } from '@/hooks/useVoice'

function buildMockMediaRecorder() {
  const instance = {
    start: jest.fn(),
    stop: jest.fn(),
    state: 'inactive',
    ondataavailable: null,
    onstop: null,
  }
  return instance
}

beforeEach(() => {
  global.MediaRecorder = jest.fn().mockImplementation(() => buildMockMediaRecorder())
  global.MediaRecorder.isTypeSupported = jest.fn().mockReturnValue(true)
  global.navigator.mediaDevices = {
    getUserMedia: jest.fn().mockResolvedValue({ getTracks: () => [{ stop: jest.fn() }] }),
  }
})

afterEach(() => {
  delete global.MediaRecorder
  delete global.navigator.mediaDevices
  jest.resetAllMocks()
})

test('isSupported is true when MediaRecorder is available', () => {
  const { result } = renderHook(() => useVoice())
  expect(result.current.isSupported).toBe(true)
})

test('isSupported is false when MediaRecorder is not available', () => {
  delete global.MediaRecorder
  const { result } = renderHook(() => useVoice())
  expect(result.current.isSupported).toBe(false)
})

test('isRecording starts as false', () => {
  const { result } = renderHook(() => useVoice())
  expect(result.current.isRecording).toBe(false)
})

test('startRecording requests microphone and starts MediaRecorder', async () => {
  const { result } = renderHook(() => useVoice())
  await act(async () => {
    await result.current.startRecording()
  })
  expect(navigator.mediaDevices.getUserMedia).toHaveBeenCalledWith({ audio: true })
  expect(result.current.isRecording).toBe(true)
})

test('stopRecording sets isRecording to false and calls recorder.stop()', async () => {
  const { result } = renderHook(() => useVoice())
  await act(async () => {
    await result.current.startRecording()
  })
  act(() => {
    result.current.stopRecording()
  })
  expect(result.current.isRecording).toBe(false)
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd frontend && npm test -- --testPathPattern="hooks/useVoice"
```

Expected: `FAILED`

- [ ] **Step 3: Create `frontend/src/hooks/useVoice.js`**

```js
'use client'
import { useState, useRef, useCallback } from 'react'

export function useVoice() {
  const isSupported = typeof window !== 'undefined' && 'MediaRecorder' in window
  const [isRecording, setIsRecording] = useState(false)
  const [audioBlob, setAudioBlob] = useState(null)
  const [error, setError] = useState(null)
  const recorderRef = useRef(null)
  const chunksRef = useRef([])
  const streamRef = useRef(null)

  const startRecording = useCallback(async () => {
    if (!isSupported) return
    try {
      setError(null)
      setAudioBlob(null)
      chunksRef.current = []
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      streamRef.current = stream
      const recorder = new MediaRecorder(stream)
      recorderRef.current = recorder
      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data)
      }
      recorder.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: 'audio/m4a' })
        setAudioBlob(blob)
        streamRef.current?.getTracks().forEach((t) => t.stop())
      }
      recorder.start()
      setIsRecording(true)
    } catch (err) {
      setError(err.message)
    }
  }, [isSupported])

  const stopRecording = useCallback(() => {
    if (recorderRef.current && isRecording) {
      recorderRef.current.stop()
      setIsRecording(false)
    }
  }, [isRecording])

  const reset = useCallback(() => {
    setAudioBlob(null)
    setError(null)
  }, [])

  return { isSupported, isRecording, audioBlob, error, startRecording, stopRecording, reset }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd frontend && npm test -- --testPathPattern="hooks/useVoice"
```

Expected: `5 passed`

- [ ] **Step 5: Commit**

```bash
cd frontend
git add src/hooks/useVoice.js __tests__/hooks/useVoice.test.js
git commit -m "feat(frontend): add useVoice hook (MediaRecorder state machine)"
```

---

## Task 7: hooks/useOfflineQueue.js

**Files:**
- Create: `frontend/src/hooks/useOfflineQueue.js`
- Create: `frontend/__tests__/hooks/useOfflineQueue.test.js`

- [ ] **Step 1: Write `__tests__/hooks/useOfflineQueue.test.js`**

```js
import { renderHook, act, waitFor } from '@testing-library/react'
import { useOfflineQueue } from '@/hooks/useOfflineQueue'

// Mock idb-keyval
jest.mock('idb-keyval', () => ({
  createStore: jest.fn().mockReturnValue('mock-store'),
  set: jest.fn().mockResolvedValue(undefined),
  del: jest.fn().mockResolvedValue(undefined),
  entries: jest.fn().mockResolvedValue([]),
}))

// Mock @/lib/api
jest.mock('@/lib/api', () => ({
  syncPush: jest.fn(),
}))

import { set, entries } from 'idb-keyval'
import { syncPush } from '@/lib/api'

beforeEach(() => {
  jest.clearAllMocks()
  Object.defineProperty(navigator, 'onLine', { writable: true, value: true })
})

test('addToQueue stores item in IndexedDB', async () => {
  const { result } = renderHook(() => useOfflineQueue('demo-farmer'))
  await act(async () => {
    await result.current.addToQueue({ text: 'test', language: 'hi' })
  })
  expect(set).toHaveBeenCalledWith(
    expect.stringMatching(/^oq:/),
    expect.objectContaining({ text: 'test', language: 'hi', status: 'pending' }),
    'mock-store'
  )
})

test('flushQueue sends pending items to syncPush and removes them', async () => {
  const pendingItem = { id: 'oq:abc', text: 'hello', farmer_id: 'demo-farmer', language: 'hi', queued_at: '2026-01-01T00:00:00Z', status: 'pending' }
  entries.mockResolvedValue([['oq:abc', pendingItem]])
  syncPush.mockResolvedValue({ results: [{ id: 'oq:abc', success: true, response: { text_response: 'ok' } }] })

  const { result } = renderHook(() => useOfflineQueue('demo-farmer'))
  await act(async () => {
    await result.current.flushQueue()
  })

  expect(syncPush).toHaveBeenCalledWith(expect.arrayContaining([
    expect.objectContaining({ text: 'hello' })
  ]))
})

test('queueSize reflects number of pending items', async () => {
  entries.mockResolvedValue([
    ['oq:1', { status: 'pending' }],
    ['oq:2', { status: 'pending' }],
  ])
  const { result } = renderHook(() => useOfflineQueue('demo-farmer'))
  await waitFor(() => expect(result.current.queueSize).toBe(2))
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd frontend && npm test -- --testPathPattern="hooks/useOfflineQueue"
```

Expected: `FAILED`

- [ ] **Step 3: Create `frontend/src/hooks/useOfflineQueue.js`**

```js
'use client'
import { useState, useEffect, useCallback } from 'react'
import { createStore, set, del, entries } from 'idb-keyval'
import { syncPush } from '@/lib/api'

const queueStore = typeof window !== 'undefined'
  ? createStore('farm-ai-offline', 'queue')
  : null

export function useOfflineQueue(farmerId) {
  const [queueSize, setQueueSize] = useState(0)

  const refreshSize = useCallback(async () => {
    if (!queueStore) return
    const all = await entries(queueStore)
    setQueueSize(all.filter(([, v]) => v.status === 'pending').length)
  }, [])

  useEffect(() => {
    refreshSize()
  }, [refreshSize])

  const addToQueue = useCallback(async ({ text, language }) => {
    if (!queueStore) return
    const id = `oq:${Date.now()}-${Math.random().toString(36).slice(2)}`
    await set(id, {
      id,
      text,
      farmer_id: farmerId,
      language,
      queued_at: new Date().toISOString(),
      status: 'pending',
    }, queueStore)
    setQueueSize((n) => n + 1)
  }, [farmerId])

  const flushQueue = useCallback(async () => {
    if (!queueStore || !navigator.onLine) return
    const all = await entries(queueStore)
    const pending = all
      .filter(([, v]) => v.status === 'pending')
      .map(([, v]) => v)
    if (pending.length === 0) return

    try {
      const { results } = await syncPush(pending)
      for (const result of results) {
        if (result.success) await del(result.id, queueStore)
      }
    } catch {
      // Will retry on next flush
    }
    await refreshSize()
  }, [refreshSize])

  useEffect(() => {
    window.addEventListener('online', flushQueue)
    return () => window.removeEventListener('online', flushQueue)
  }, [flushQueue])

  return { addToQueue, flushQueue, queueSize }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd frontend && npm test -- --testPathPattern="hooks/useOfflineQueue"
```

Expected: `3 passed`

- [ ] **Step 5: Commit**

```bash
cd frontend
git add src/hooks/useOfflineQueue.js __tests__/hooks/useOfflineQueue.test.js
git commit -m "feat(frontend): add useOfflineQueue hook (IndexedDB + online flush)"
```

---

## Task 8: MessageBubble component

**Files:**
- Create: `frontend/src/components/chat/MessageBubble.jsx`
- Create: `frontend/__tests__/components/MessageBubble.test.jsx`

- [ ] **Step 1: Write `__tests__/components/MessageBubble.test.jsx`**

```jsx
import { render, screen } from '@testing-library/react'
import MessageBubble from '@/components/chat/MessageBubble'

const userMsg = {
  id: 1,
  role: 'user',
  content: 'Which crop for Rabi season?',
  timestamp: new Date('2026-01-01T10:00:00').toISOString(),
}

const assistantMsg = {
  id: 2,
  role: 'assistant',
  content: 'Plant wheat for Rabi season.',
  agent: 'crop_advisor',
  timestamp: new Date('2026-01-01T10:00:05').toISOString(),
}

const voiceAssistantMsg = {
  ...assistantMsg,
  audioUrl: 'http://localhost:8002/audio/test.mp3',
}

test('renders user message text', () => {
  render(<MessageBubble msg={userMsg} />)
  expect(screen.getByText('Which crop for Rabi season?')).toBeInTheDocument()
})

test('user message is right-aligned', () => {
  const { container } = render(<MessageBubble msg={userMsg} />)
  const wrapper = container.firstChild
  expect(wrapper.className).toMatch(/justify-end/)
})

test('assistant message is left-aligned', () => {
  const { container } = render(<MessageBubble msg={assistantMsg} />)
  const wrapper = container.firstChild
  expect(wrapper.className).toMatch(/justify-start/)
})

test('assistant message shows agent badge', () => {
  render(<MessageBubble msg={assistantMsg} />)
  expect(screen.getByText(/crop advisor/i)).toBeInTheDocument()
})

test('shows audio player when audioUrl is present', () => {
  render(<MessageBubble msg={voiceAssistantMsg} />)
  const audio = screen.getByRole('link', { hidden: true }) || document.querySelector('audio')
  // Audio element should exist
  expect(document.querySelector('audio')).toBeInTheDocument()
})

test('does not show audio player when no audioUrl', () => {
  render(<MessageBubble msg={assistantMsg} />)
  expect(document.querySelector('audio')).not.toBeInTheDocument()
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd frontend && npm test -- --testPathPattern="components/MessageBubble"
```

Expected: `FAILED`

- [ ] **Step 3: Create `frontend/src/components/chat/MessageBubble.jsx`**

```jsx
'use client'
import { AGENT_COLORS, AGENT_ICONS } from '@/lib/agentConfig'

export default function MessageBubble({ msg }) {
  const isUser = msg.role === 'user'

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'} mb-4`}>
      {!isUser && (
        <div className="w-8 h-8 rounded-full bg-green-500 flex items-center justify-center text-white text-sm mr-2 flex-shrink-0 mt-1">
          🌱
        </div>
      )}
      <div className={`max-w-2xl ${isUser ? 'items-end' : 'items-start'} flex flex-col`}>
        <div
          className={`px-4 py-3 rounded-2xl ${
            isUser
              ? 'bg-green-600 text-white rounded-tr-sm'
              : 'bg-white text-gray-800 rounded-tl-sm shadow-sm border border-gray-100'
          }`}
        >
          <p className="text-sm leading-relaxed whitespace-pre-wrap">{msg.content}</p>
          {msg.audioUrl && (
            <audio
              className="mt-2 w-full"
              controls
              src={msg.audioUrl}
            />
          )}
        </div>
        {msg.agent && (
          <div className="flex items-center gap-1 mt-1 ml-1">
            <span
              className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                AGENT_COLORS[msg.agent] || 'bg-gray-100 text-gray-600'
              }`}
            >
              {AGENT_ICONS[msg.agent]} {msg.agent.replace(/_/g, ' ')}
            </span>
          </div>
        )}
        <span className="text-xs text-gray-400 mt-1 px-1">
          {new Date(msg.timestamp).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}
        </span>
      </div>
      {isUser && (
        <div className="w-8 h-8 rounded-full bg-green-700 flex items-center justify-center text-white text-sm ml-2 flex-shrink-0 mt-1">
          👨‍🌾
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd frontend && npm test -- --testPathPattern="components/MessageBubble"
```

Expected: `6 passed`

- [ ] **Step 5: Commit**

```bash
cd frontend
git add src/components/chat/MessageBubble.jsx __tests__/components/MessageBubble.test.jsx
git commit -m "feat(frontend): add MessageBubble component with audio playback support"
```

---

## Task 9: ThinkingBubble + MessageList components

**Files:**
- Create: `frontend/src/components/chat/ThinkingBubble.jsx`
- Create: `frontend/src/components/chat/MessageList.jsx`
- Create: `frontend/__tests__/components/ThinkingBubble.test.jsx`
- Create: `frontend/__tests__/components/MessageList.test.jsx`

- [ ] **Step 1: Write `__tests__/components/ThinkingBubble.test.jsx`**

```jsx
import { render, screen } from '@testing-library/react'
import ThinkingBubble from '@/components/chat/ThinkingBubble'

test('renders three animated dots', () => {
  const { container } = render(<ThinkingBubble />)
  const dots = container.querySelectorAll('.animate-bounce')
  expect(dots.length).toBe(3)
})

test('renders "Agents working" text', () => {
  render(<ThinkingBubble />)
  expect(screen.getByText(/Agents working/i)).toBeInTheDocument()
})
```

- [ ] **Step 2: Write `__tests__/components/MessageList.test.jsx`**

```jsx
import { render, screen } from '@testing-library/react'
import MessageList from '@/components/chat/MessageList'

const messages = [
  { id: 1, role: 'assistant', content: 'Hello farmer', agent: 'supervisor', timestamp: new Date().toISOString() },
  { id: 2, role: 'user', content: 'Hello FarmAI', timestamp: new Date().toISOString() },
]

test('renders all messages', () => {
  render(<MessageList messages={messages} loading={false} />)
  expect(screen.getByText('Hello farmer')).toBeInTheDocument()
  expect(screen.getByText('Hello FarmAI')).toBeInTheDocument()
})

test('shows ThinkingBubble when loading is true', () => {
  render(<MessageList messages={messages} loading={true} />)
  expect(screen.getByText(/Agents working/i)).toBeInTheDocument()
})

test('does not show ThinkingBubble when loading is false', () => {
  render(<MessageList messages={messages} loading={false} />)
  expect(screen.queryByText(/Agents working/i)).not.toBeInTheDocument()
})
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
cd frontend && npm test -- --testPathPattern="components/(ThinkingBubble|MessageList)"
```

Expected: `FAILED`

- [ ] **Step 4: Create `frontend/src/components/chat/ThinkingBubble.jsx`**

```jsx
'use client'
import { useState, useEffect } from 'react'

export default function ThinkingBubble() {
  const [dots, setDots] = useState('.')
  useEffect(() => {
    const id = setInterval(() => setDots((d) => (d.length >= 3 ? '.' : d + '.')), 500)
    return () => clearInterval(id)
  }, [])

  return (
    <div className="flex justify-start mb-4">
      <div className="w-8 h-8 rounded-full bg-green-500 flex items-center justify-center text-white text-sm mr-2 flex-shrink-0">
        🌱
      </div>
      <div className="bg-white border border-gray-100 shadow-sm px-4 py-3 rounded-2xl rounded-tl-sm">
        <div className="flex items-center gap-2">
          <div className="flex gap-1">
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                className="w-2 h-2 bg-green-400 rounded-full animate-bounce"
                style={{ animationDelay: `${i * 0.15}s` }}
              />
            ))}
          </div>
          <span className="text-xs text-gray-500">Agents working{dots}</span>
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 5: Create `frontend/src/components/chat/MessageList.jsx`**

```jsx
'use client'
import { useRef, useEffect } from 'react'
import MessageBubble from './MessageBubble'
import ThinkingBubble from './ThinkingBubble'

export default function MessageList({ messages, loading }) {
  const endRef = useRef(null)

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, loading])

  return (
    <div
      className="flex-1 overflow-y-auto py-2 space-y-1 min-h-0"
      style={{ maxHeight: 'calc(100vh - 280px)' }}
    >
      {messages.map((msg) => (
        <MessageBubble key={msg.id} msg={msg} />
      ))}
      {loading && <ThinkingBubble />}
      <div ref={endRef} />
    </div>
  )
}
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
cd frontend && npm test -- --testPathPattern="components/(ThinkingBubble|MessageList)"
```

Expected: `5 passed`

- [ ] **Step 7: Commit**

```bash
cd frontend
git add src/components/chat/ThinkingBubble.jsx src/components/chat/MessageList.jsx __tests__/components/ThinkingBubble.test.jsx __tests__/components/MessageList.test.jsx
git commit -m "feat(frontend): add ThinkingBubble and MessageList components"
```

---

## Task 10: VoiceInput component

**Files:**
- Create: `frontend/src/components/chat/VoiceInput.jsx`
- Create: `frontend/__tests__/components/VoiceInput.test.jsx`

- [ ] **Step 1: Write `__tests__/components/VoiceInput.test.jsx`**

```jsx
import { render, screen, fireEvent } from '@testing-library/react'
import VoiceInput from '@/components/chat/VoiceInput'

test('renders mic button', () => {
  render(<VoiceInput isSupported={true} isRecording={false} onStart={jest.fn()} onStop={jest.fn()} />)
  expect(screen.getByRole('button', { name: /hold to record|recording/i })).toBeInTheDocument()
})

test('button is disabled when isSupported is false', () => {
  render(<VoiceInput isSupported={false} isRecording={false} onStart={jest.fn()} onStop={jest.fn()} />)
  expect(screen.getByRole('button')).toBeDisabled()
})

test('calls onStart on mousedown', () => {
  const onStart = jest.fn()
  render(<VoiceInput isSupported={true} isRecording={false} onStart={onStart} onStop={jest.fn()} />)
  fireEvent.mouseDown(screen.getByRole('button'))
  expect(onStart).toHaveBeenCalledTimes(1)
})

test('calls onStop on mouseup', () => {
  const onStop = jest.fn()
  render(<VoiceInput isSupported={true} isRecording={true} onStart={jest.fn()} onStop={onStop} />)
  fireEvent.mouseUp(screen.getByRole('button'))
  expect(onStop).toHaveBeenCalledTimes(1)
})

test('shows "Recording..." label when isRecording is true', () => {
  render(<VoiceInput isSupported={true} isRecording={true} onStart={jest.fn()} onStop={jest.fn()} />)
  expect(screen.getByText(/Recording\.\.\./i)).toBeInTheDocument()
})

test('shows mic label when not recording', () => {
  render(<VoiceInput isSupported={true} isRecording={false} onStart={jest.fn()} onStop={jest.fn()} />)
  expect(screen.getByText(/Hold to record/i)).toBeInTheDocument()
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd frontend && npm test -- --testPathPattern="components/VoiceInput"
```

Expected: `FAILED`

- [ ] **Step 3: Create `frontend/src/components/chat/VoiceInput.jsx`**

```jsx
'use client'

export default function VoiceInput({ isSupported, isRecording, onStart, onStop }) {
  return (
    <button
      onMouseDown={onStart}
      onMouseUp={onStop}
      onTouchStart={(e) => { e.preventDefault(); onStart() }}
      onTouchEnd={(e) => { e.preventDefault(); onStop() }}
      disabled={!isSupported}
      aria-label={isRecording ? 'Recording...' : 'Hold to record'}
      className={`flex flex-col items-center justify-center w-12 h-12 rounded-full transition-all flex-shrink-0 ${
        !isSupported
          ? 'bg-gray-200 text-gray-400 cursor-not-allowed opacity-50'
          : isRecording
          ? 'bg-red-500 text-white shadow-lg scale-110 animate-pulse'
          : 'bg-green-100 text-green-700 hover:bg-green-200'
      }`}
    >
      <span className="text-xl">{isRecording ? '⏺' : '🎤'}</span>
      <span className="text-[9px] leading-none mt-0.5">
        {isRecording ? 'Recording...' : 'Hold to record'}
      </span>
    </button>
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd frontend && npm test -- --testPathPattern="components/VoiceInput"
```

Expected: `6 passed`

- [ ] **Step 5: Commit**

```bash
cd frontend
git add src/components/chat/VoiceInput.jsx __tests__/components/VoiceInput.test.jsx
git commit -m "feat(frontend): add VoiceInput hold-to-record component"
```

---

## Task 11: ChatScreen component

**Files:**
- Create: `frontend/src/components/chat/ChatScreen.jsx`
- Create: `frontend/__tests__/components/ChatScreen.test.jsx`

- [ ] **Step 1: Write `__tests__/components/ChatScreen.test.jsx`**

```jsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import ChatScreen from '@/components/chat/ChatScreen'

// Mock all hooks and lib
jest.mock('@/hooks/useFarmerProfile', () => ({
  useFarmerProfile: () => ({ farmerId: 'demo-farmer', setFarmerId: jest.fn() }),
}))
jest.mock('@/hooks/useVoice', () => ({
  useVoice: () => ({
    isSupported: false,
    isRecording: false,
    audioBlob: null,
    startRecording: jest.fn(),
    stopRecording: jest.fn(),
    reset: jest.fn(),
  }),
}))
jest.mock('@/hooks/useOfflineQueue', () => ({
  useOfflineQueue: () => ({ addToQueue: jest.fn(), flushQueue: jest.fn(), queueSize: 0 }),
}))
jest.mock('@/lib/api', () => ({
  sendText: jest.fn(),
  sendVoice: jest.fn(),
}))
jest.mock('@/lib/demoMode', () => ({
  getDemoResponse: jest.fn(() => ({ text: 'Demo response', agent: 'crop_advisor' })),
}))

import { sendText } from '@/lib/api'
import { getDemoResponse } from '@/lib/demoMode'

beforeEach(() => jest.clearAllMocks())

test('renders initial welcome message', () => {
  render(<ChatScreen />)
  expect(screen.getByText(/Namaste/i)).toBeInTheDocument()
})

test('shows quick-ask buttons when few messages', () => {
  render(<ChatScreen />)
  expect(screen.getByText(/Which crop for Rabi season/i)).toBeInTheDocument()
})

test('sends message on Send button click', async () => {
  sendText.mockResolvedValue({ text_response: 'Plant wheat', translated_response: 'Plant wheat', agent_used: 'crop_advisor', queued: false })

  render(<ChatScreen />)
  const textarea = screen.getByPlaceholderText(/Ask about crops/i)
  fireEvent.change(textarea, { target: { value: 'What to plant?' } })
  fireEvent.click(screen.getByRole('button', { name: /send/i }))

  await waitFor(() => {
    expect(sendText).toHaveBeenCalledWith('demo-farmer', 'What to plant?', 'hi')
  })
})

test('falls back to demo mode when API throws', async () => {
  sendText.mockRejectedValue(new Error('Network error'))

  render(<ChatScreen />)
  const textarea = screen.getByPlaceholderText(/Ask about crops/i)
  fireEvent.change(textarea, { target: { value: 'crop question' } })
  fireEvent.click(screen.getByRole('button', { name: /send/i }))

  await waitFor(() => {
    expect(getDemoResponse).toHaveBeenCalledWith('crop question')
  })
})

test('Send button is disabled when input is empty', () => {
  render(<ChatScreen />)
  expect(screen.getByRole('button', { name: /send/i })).toBeDisabled()
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd frontend && npm test -- --testPathPattern="components/ChatScreen"
```

Expected: `FAILED`

- [ ] **Step 3: Create `frontend/src/components/chat/ChatScreen.jsx`**

```jsx
'use client'
import { useState, useEffect, useRef } from 'react'
import MessageList from './MessageList'
import VoiceInput from './VoiceInput'
import { useFarmerProfile } from '@/hooks/useFarmerProfile'
import { useVoice } from '@/hooks/useVoice'
import { useOfflineQueue } from '@/hooks/useOfflineQueue'
import { sendText, sendVoice } from '@/lib/api'
import { getDemoResponse } from '@/lib/demoMode'
import { QUICK_ASKS } from '@/lib/quickAsks'

const WELCOME_MSG = {
  id: 1,
  role: 'assistant',
  content: 'Namaste! 🙏 I\'m FarmAI — your agricultural advisor powered by AI.\n\nI can help you with:\n• Crop planning and variety selection\n• Pest and disease diagnosis\n• Market prices and selling timing\n• Irrigation scheduling\n• Government scheme eligibility\n\nWhat would you like to know today?',
  agent: 'supervisor',
  timestamp: new Date().toISOString(),
}

const DEFAULT_LANGUAGE = 'hi'

export default function ChatScreen() {
  const [messages, setMessages] = useState([WELCOME_MSG])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const { farmerId } = useFarmerProfile()
  const { isSupported, isRecording, audioBlob, startRecording, stopRecording, reset } = useVoice()
  const { addToQueue, queueSize } = useOfflineQueue(farmerId)

  // Handle voice blob when recording stops
  useEffect(() => {
    if (!audioBlob) return
    handleVoiceSend(audioBlob)
    reset()
  }, [audioBlob]) // eslint-disable-line react-hooks/exhaustive-deps

  const addUserMessage = (content) => {
    const msg = { id: Date.now(), role: 'user', content, timestamp: new Date().toISOString() }
    setMessages((prev) => [...prev, msg])
    return msg
  }

  const addAssistantMessage = ({ text_response, translated_response, audio_url, agent_used }) => {
    setMessages((prev) => [
      ...prev,
      {
        id: Date.now() + 1,
        role: 'assistant',
        content: translated_response || text_response,
        agent: agent_used,
        audioUrl: audio_url,
        timestamp: new Date().toISOString(),
      },
    ])
  }

  const handleTextSend = async (text) => {
    const message = text || input.trim()
    if (!message) return
    setInput('')
    addUserMessage(message)
    setLoading(true)
    try {
      const data = await sendText(farmerId, message, DEFAULT_LANGUAGE)
      addAssistantMessage(data)
    } catch {
      if (!navigator.onLine) {
        await addToQueue({ text: message, language: DEFAULT_LANGUAGE })
        setMessages((prev) => [
          ...prev,
          {
            id: Date.now() + 1,
            role: 'assistant',
            content: 'No internet connection. Your message has been queued and will be sent when you\'re back online.',
            agent: 'supervisor',
            timestamp: new Date().toISOString(),
          },
        ])
      } else {
        const demo = getDemoResponse(message)
        addAssistantMessage({ text_response: demo.text, agent_used: demo.agent })
      }
    } finally {
      setLoading(false)
    }
  }

  const handleVoiceSend = async (blob) => {
    if (!navigator.onLine) {
      setMessages((prev) => [
        ...prev,
        {
          id: Date.now(),
          role: 'assistant',
          content: 'No internet connection. Voice messages require a connection — please try again when online.',
          agent: 'supervisor',
          timestamp: new Date().toISOString(),
        },
      ])
      return
    }
    addUserMessage('🎤 Voice message')
    setLoading(true)
    try {
      const data = await sendVoice(farmerId, blob)
      addAssistantMessage(data)
    } catch {
      const demo = getDemoResponse('')
      addAssistantMessage({ text_response: demo.text, agent_used: demo.agent })
    } finally {
      setLoading(false)
    }
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleTextSend()
    }
  }

  return (
    <div className="flex-1 max-w-4xl mx-auto w-full px-4 py-4 flex flex-col">
      <MessageList messages={messages} loading={loading} />

      {messages.length <= 2 && (
        <div className="py-2">
          <p className="text-xs text-gray-500 mb-2 text-center">Try asking:</p>
          <div className="flex flex-wrap gap-2 justify-center">
            {QUICK_ASKS.map((q, i) => (
              <button
                key={i}
                onClick={() => handleTextSend(q.text)}
                className="text-xs bg-white border border-green-200 text-green-700 rounded-full px-3 py-1.5 hover:bg-green-50 transition-colors shadow-sm"
              >
                {q.icon} {q.text}
              </button>
            ))}
          </div>
        </div>
      )}

      {queueSize > 0 && (
        <p className="text-xs text-amber-600 text-center mb-1">
          ⏳ {queueSize} message{queueSize > 1 ? 's' : ''} queued — will send when online
        </p>
      )}

      <div className="py-3">
        <div className="flex gap-2 bg-white rounded-2xl shadow-sm border border-gray-200 p-2">
          <VoiceInput
            isSupported={isSupported}
            isRecording={isRecording}
            onStart={startRecording}
            onStop={stopRecording}
          />
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Ask about crops, pests, prices, or schemes..."
            className="flex-1 resize-none border-none outline-none text-sm text-gray-700 px-2 pt-1"
            rows={1}
            style={{ minHeight: '36px', maxHeight: '120px' }}
          />
          <button
            onClick={() => handleTextSend()}
            disabled={loading || !input.trim()}
            aria-label="Send"
            className="bg-green-600 text-white rounded-xl px-4 py-2 text-sm font-medium disabled:opacity-40 hover:bg-green-700 transition-colors flex-shrink-0"
          >
            {loading ? '...' : 'Send'}
          </button>
        </div>
        <p className="text-xs text-gray-400 text-center mt-1">
          Multi-agent AI • MCP tools • RAG knowledge base
        </p>
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd frontend && npm test -- --testPathPattern="components/ChatScreen"
```

Expected: `5 passed`

- [ ] **Step 5: Commit**

```bash
cd frontend
git add src/components/chat/ChatScreen.jsx __tests__/components/ChatScreen.test.jsx
git commit -m "feat(frontend): add ChatScreen with voice, offline queue, BFF integration"
```

---

## Task 12: Dashboard components

**Files:**
- Create: `frontend/src/components/dashboard/FarmStats.jsx`
- Create: `frontend/src/components/dashboard/AgentStatus.jsx`
- Create: `frontend/__tests__/components/FarmStats.test.jsx`
- Create: `frontend/__tests__/components/AgentStatus.test.jsx`

- [ ] **Step 1: Write `__tests__/components/FarmStats.test.jsx`**

```jsx
import { render, screen } from '@testing-library/react'
import FarmStats from '@/components/dashboard/FarmStats'

test('renders Farm Overview heading', () => {
  render(<FarmStats />)
  expect(screen.getByText(/Farm Overview/i)).toBeInTheDocument()
})

test('renders all four stat cards', () => {
  render(<FarmStats />)
  expect(screen.getByText(/Current Crops/i)).toBeInTheDocument()
  expect(screen.getByText(/Location/i)).toBeInTheDocument()
  expect(screen.getByText(/Land/i)).toBeInTheDocument()
  expect(screen.getByText(/Irrigation/i)).toBeInTheDocument()
})
```

- [ ] **Step 2: Write `__tests__/components/AgentStatus.test.jsx`**

```jsx
import { render, screen } from '@testing-library/react'
import AgentStatus from '@/components/dashboard/AgentStatus'

test('renders Agent System Status heading', () => {
  render(<AgentStatus />)
  expect(screen.getByText(/Agent System Status/i)).toBeInTheDocument()
})

test('renders all 5 specialist agents', () => {
  render(<AgentStatus />)
  expect(screen.getByText(/crop advisor/i)).toBeInTheDocument()
  expect(screen.getByText(/pest detector/i)).toBeInTheDocument()
  expect(screen.getByText(/market analyst/i)).toBeInTheDocument()
  expect(screen.getByText(/irrigation planner/i)).toBeInTheDocument()
  expect(screen.getByText(/scheme navigator/i)).toBeInTheDocument()
})

test('renders MCP Tools section', () => {
  render(<AgentStatus />)
  expect(screen.getByText(/MCP Tools Active/i)).toBeInTheDocument()
  expect(screen.getByText(/weather_forecast/i)).toBeInTheDocument()
})
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
cd frontend && npm test -- --testPathPattern="components/(FarmStats|AgentStatus)"
```

Expected: `FAILED`

- [ ] **Step 4: Create `frontend/src/components/dashboard/FarmStats.jsx`**

```jsx
'use client'

function StatCard({ icon, label, value, sub }) {
  return (
    <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
      <div className="flex items-center gap-3">
        <div className="text-2xl">{icon}</div>
        <div>
          <div className="text-xs text-gray-500">{label}</div>
          <div className="text-lg font-bold text-gray-800">{value}</div>
          {sub && <div className="text-xs text-green-600">{sub}</div>}
        </div>
      </div>
    </div>
  )
}

export default function FarmStats() {
  return (
    <div className="space-y-4">
      <h2 className="text-lg font-bold text-gray-700">Farm Overview</h2>
      <div className="grid grid-cols-2 gap-3">
        <StatCard icon="🌾" label="Current Crops" value="Cotton, Tomato" sub="Kharif season" />
        <StatCard icon="📍" label="Location" value="Warangal" sub="Telangana" />
        <StatCard icon="🏞️" label="Land" value="5.5 acres" sub="Small farmer" />
        <StatCard icon="💧" label="Irrigation" value="Drip system" sub="Installed" />
      </div>
    </div>
  )
}
```

- [ ] **Step 5: Create `frontend/src/components/dashboard/AgentStatus.jsx`**

```jsx
'use client'
import { AGENT_ICONS } from '@/lib/agentConfig'

const MCP_TOOLS = [
  '🌤 weather_forecast(location, days)',
  '💰 mandi_prices(crop, state)',
  '🌍 soil_analysis(lat, lon)',
  '🏛 government_schemes(state, crop, category)',
]

export default function AgentStatus() {
  return (
    <div className="space-y-4 mt-6">
      <h2 className="text-lg font-bold text-gray-700">Agent System Status</h2>
      <div className="space-y-2">
        {Object.entries(AGENT_ICONS)
          .filter(([agent]) => agent !== 'supervisor')
          .map(([agent, icon]) => (
            <div
              key={agent}
              className="bg-white rounded-xl p-3 shadow-sm border border-gray-100 flex items-center justify-between"
            >
              <div className="flex items-center gap-2">
                <span>{icon}</span>
                <span className="text-sm font-medium text-gray-700 capitalize">
                  {agent.replace(/_/g, ' ')}
                </span>
              </div>
              <div className="flex items-center gap-1">
                <div className="w-2 h-2 bg-green-400 rounded-full" />
                <span className="text-xs text-green-600">Ready</span>
              </div>
            </div>
          ))}
      </div>

      <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
        <h3 className="font-bold text-gray-700 mb-2">🔌 MCP Tools Active</h3>
        <div className="space-y-2">
          {MCP_TOOLS.map((tool) => (
            <div key={tool} className="text-xs text-gray-600 font-mono bg-gray-50 px-2 py-1 rounded">
              {tool}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
cd frontend && npm test -- --testPathPattern="components/(FarmStats|AgentStatus)"
```

Expected: `5 passed`

- [ ] **Step 7: Commit**

```bash
cd frontend
git add src/components/dashboard/ __tests__/components/FarmStats.test.jsx __tests__/components/AgentStatus.test.jsx
git commit -m "feat(frontend): add FarmStats and AgentStatus dashboard components"
```

---

## Task 13: Thin app/page.jsx

**Files:**
- Modify: `frontend/src/app/page.jsx`

- [ ] **Step 1: Replace `frontend/src/app/page.jsx` with the thin shell**

```jsx
'use client'
import { useState, useEffect } from 'react'
import ChatScreen from '@/components/chat/ChatScreen'
import FarmStats from '@/components/dashboard/FarmStats'
import AgentStatus from '@/components/dashboard/AgentStatus'

export default function FarmAIApp() {
  const [activeTab, setActiveTab] = useState('chat')

  useEffect(() => {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(() => {
        // SW registration is best-effort — don't throw if it fails
      })
    }
  }, [])

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50 flex flex-col">
      <header className="bg-green-700 text-white px-4 py-3 shadow-md">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="text-2xl">🌱</div>
            <div>
              <h1 className="font-bold text-lg leading-tight">FarmAI</h1>
              <p className="text-green-200 text-xs">Powered by Claude + MCP + RAG + Multi-Agent</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-green-300 rounded-full animate-pulse" />
            <span className="text-xs text-green-200">All agents active</span>
          </div>
        </div>
      </header>

      <div className="bg-white border-b border-gray-200 px-4">
        <div className="max-w-4xl mx-auto flex gap-4">
          {['chat', 'dashboard'].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`py-3 px-2 text-sm font-medium border-b-2 transition-colors ${
                activeTab === tab
                  ? 'border-green-600 text-green-700'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              {tab === 'chat' ? '💬 Chat' : '📊 Dashboard'}
            </button>
          ))}
        </div>
      </div>

      {activeTab === 'chat' ? (
        <ChatScreen />
      ) : (
        <div className="flex-1 max-w-4xl mx-auto w-full px-4 py-4">
          <FarmStats />
          <AgentStatus />
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Verify dev server starts and renders correctly**

```bash
cd frontend && npm run dev &
sleep 5 && curl -s http://localhost:3000 | grep -i farmai
kill %1
```

Expected: HTML containing "FarmAI"

- [ ] **Step 3: Run full test suite**

```bash
cd frontend && npm test
```

Expected: all tests pass

- [ ] **Step 4: Commit**

```bash
cd frontend
git add src/app/page.jsx
git commit -m "feat(frontend): replace monolithic page.jsx with thin shell composing components"
```

---

## Task 14: PWA — manifest + service worker + config

**Files:**
- Create: `frontend/public/manifest.json`
- Create: `frontend/public/sw.js`

- [ ] **Step 1: Create `frontend/public/manifest.json`**

```json
{
  "name": "FarmAI — Agricultural Advisor",
  "short_name": "FarmAI",
  "description": "AI-powered agricultural advisory for farmers, powered by Claude + MCP + RAG",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#f0fdf4",
  "theme_color": "#166534",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🌱</text></svg>",
      "sizes": "any",
      "type": "image/svg+xml",
      "purpose": "any maskable"
    }
  ]
}
```

- [ ] **Step 2: Create `frontend/public/sw.js`**

```js
const CACHE_NAME = 'farmai-v1'
const APP_SHELL = ['/', '/manifest.json']

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  )
  self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  )
  self.clients.claim()
})

self.addEventListener('fetch', (event) => {
  // Only cache GET requests; skip API routes and BFF calls
  if (event.request.method !== 'GET') return
  if (event.request.url.includes('/api/')) return

  event.respondWith(
    caches.match(event.request).then((cached) => {
      const networkFetch = fetch(event.request).then((resp) => {
        if (resp.ok && event.request.url.startsWith(self.location.origin)) {
          const clone = resp.clone()
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone))
        }
        return resp
      })
      // Return cached first (offline), fall back to network
      return cached || networkFetch
    })
  )
})
```

- [ ] **Step 3: Add manifest link to `frontend/src/app/layout.js`**

The `metadata.manifest` we set in Task 1 (`manifest: '/manifest.json'`) is already wired in Next.js 14 via the `metadata` export — no extra changes needed.

Verify by checking `src/app/layout.js` contains:
```js
export const metadata = {
  ...
  manifest: '/manifest.json',
}
```

- [ ] **Step 4: Verify manifest is accessible**

```bash
cd frontend && npm run dev &
sleep 5
curl -s http://localhost:3000/manifest.json | python3 -m json.tool | head -5
kill %1
```

Expected: valid JSON with `"name": "FarmAI — Agricultural Advisor"`

- [ ] **Step 5: Run full test suite one final time**

```bash
cd frontend && npm test
```

Expected: all tests pass. Note the exact count.

- [ ] **Step 6: Commit**

```bash
cd frontend
git add public/manifest.json public/sw.js
git commit -m "feat(frontend): add PWA manifest and service worker for offline app-shell caching"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered by |
|---|---|
| Componentized from 400-line page.jsx | Tasks 8–13 |
| BFF integration (replaces direct backend calls) | Tasks 3, 4 |
| BFF URL stays server-side | Task 4 (no NEXT_PUBLIC prefix) |
| Voice input — MediaRecorder, hold-to-record | Tasks 6, 10, 11 |
| Offline queue — IndexedDB + online flush | Task 7 |
| Voice offline: show error, not queue | Task 11 (ChatScreen) |
| `useVoice` hook | Task 6 |
| `useOfflineQueue` hook | Task 7 |
| `useFarmerProfile` hook | Task 5 |
| `lib/api.js` single BFF client | Task 3 |
| `components/chat/VoiceInput.jsx` | Task 10 |
| `components/chat/ChatScreen.jsx` | Task 11 |
| `components/chat/MessageBubble.jsx` + audio player | Task 8 |
| `components/chat/MessageList.jsx` | Task 9 |
| `components/dashboard/FarmStats.jsx` | Task 12 |
| `components/dashboard/AgentStatus.jsx` | Task 12 |
| PWA manifest | Task 14 |
| Service worker (app shell caching) | Task 14 |
| Tailwind CSS properly configured | Task 1 |
| `app/layout.js` root layout | Task 1 |
| Quick-ask buttons | Task 2 (quickAsks.js) + Task 11 (ChatScreen) |
| Demo mode fallback | Task 2 (demoMode.js) + Task 11 (ChatScreen) |
| Next.js API proxy routes | Task 4 |

All spec requirements covered. No TBDs or placeholders.
