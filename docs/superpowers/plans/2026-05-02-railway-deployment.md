# Railway Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy the full Farm-AI stack (api, mcp-server, bff, frontend, postgres, redis) to Railway as six separate services using each service's Dockerfile.

**Architecture:** Railway hosts six services from the same GitHub repo. Postgres and Redis use Railway plugins (managed). The backend directory serves both the `api` and `mcp-server` services via a `SERVICE` env var dispatch script. Services communicate over Railway's private network using reference variables.

**Tech Stack:** Railway, Docker, Python 3.11-slim, Node 20-alpine, Next.js standalone output, FastMCP SSE transport.

---

## File Map

| Action | Path | Purpose |
|---|---|---|
| Create | `backend/start.sh` | Dispatch: `SERVICE=mcp` → python mcp/server.py; else → uvicorn on `$PORT` |
| Modify | `backend/Dockerfile` | Replace hardcoded CMD with `["bash", "start.sh"]` |
| Modify | `bff/Dockerfile` | Replace hardcoded CMD with shell-form `${PORT:-8002}` |
| Create | `frontend/Dockerfile` | Multi-stage Next.js standalone build |
| Create | `backend/railway.toml` | Healthcheck config for api + mcp-server services |
| Create | `bff/railway.toml` | Healthcheck config for bff service |
| Create | `frontend/railway.toml` | Healthcheck config for frontend service |
| Create | `.env.railway.example` | All Railway env vars with reference variable syntax |

---

## Task 1: Create `backend/start.sh` — service dispatch script

**Files:**
- Create: `backend/start.sh`

The backend Dockerfile is shared by both `api` and `mcp-server` Railway services. A `SERVICE` env var determines which process to start. The MCP server reads its port from `MCP_SERVER_PORT`, so we forward Railway's `$PORT` to it.

- [ ] **Step 1: Write `backend/start.sh`**

```bash
#!/bin/bash
set -e

if [ "$SERVICE" = "mcp" ]; then
  echo "Starting MCP server on port ${PORT:-8001}"
  export MCP_SERVER_PORT=${PORT:-8001}
  exec python mcp/server.py
else
  echo "Starting API server on port ${PORT:-8000}"
  exec uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}"
fi
```

- [ ] **Step 2: Verify dispatch logic (dry run)**

```bash
cd /path/to/farm-ai/backend

# Should print MCP line
SERVICE=mcp bash -c 'source start.sh; echo "MCP_SERVER_PORT=$MCP_SERVER_PORT"' 2>&1 | head -2
```

Expected: `Starting MCP server on port 8001`

- [ ] **Step 3: Make it executable**

```bash
chmod +x backend/start.sh
```

- [ ] **Step 4: Commit**

```bash
git add backend/start.sh
git commit -m "feat: add backend/start.sh dispatch script for Railway multi-service"
```

---

## Task 2: Update `backend/Dockerfile` to use start.sh

**Files:**
- Modify: `backend/Dockerfile`

Railway injects a `$PORT` env var into every service. The current exec-form CMD hardcodes port 8000, so Railway's port injection is ignored. We replace CMD with exec-form that invokes bash so shell variable expansion works.

- [ ] **Step 1: Read the current Dockerfile**

Current `backend/Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000 8001

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 2: Replace CMD line**

Replace:
```dockerfile
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```
With:
```dockerfile
RUN chmod +x start.sh
CMD ["bash", "start.sh"]
```

Full updated file:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000 8001

RUN chmod +x start.sh
CMD ["bash", "start.sh"]
```

- [ ] **Step 3: Build the image to verify it compiles**

```bash
docker build -t farmai-backend-test ./backend
```

Expected: `Successfully built <image_id>` (no errors)

- [ ] **Step 4: Run as api service on a custom port**

```bash
docker run --rm -e SERVICE=api -e PORT=9001 \
  -e ANTHROPIC_API_KEY=test \
  -e POSTGRES_URL=postgresql://x:x@localhost/x \
  farmai-backend-test 2>&1 | head -5
```

Expected output includes: `Starting API server on port 9001`

- [ ] **Step 5: Run as mcp service on a custom port**

```bash
docker run --rm -e SERVICE=mcp -e PORT=9002 \
  farmai-backend-test 2>&1 | head -3
```

Expected output includes: `Starting MCP server on port 9002`

- [ ] **Step 6: Stop the test containers and commit**

```bash
git add backend/Dockerfile
git commit -m "fix: use start.sh CMD so Railway \$PORT is respected"
```

---

## Task 3: Update `bff/Dockerfile` to respect `$PORT`

**Files:**
- Modify: `bff/Dockerfile`

Same issue: exec-form CMD hardcodes 8002. Shell-form CMD lets `${PORT:-8002}` expand at runtime.

- [ ] **Step 1: Read current bff/Dockerfile**

Current:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p /tmp/audio

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002"]
```

- [ ] **Step 2: Replace CMD with shell form**

Replace:
```dockerfile
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002"]
```
With:
```dockerfile
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8002}
```

Full updated file:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p /tmp/audio

CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8002}
```

- [ ] **Step 3: Build the image**

```bash
docker build -t farmai-bff-test ./bff
```

Expected: `Successfully built <image_id>`

- [ ] **Step 4: Verify port override works**

```bash
docker run --rm -e PORT=9003 \
  -e JWT_SECRET=test \
  -e BACKEND_URL=http://localhost:8000 \
  farmai-bff-test 2>&1 | head -5
```

Expected: uvicorn starts on port 9003 (look for `Uvicorn running on http://0.0.0.0:9003`)

- [ ] **Step 5: Commit**

```bash
git add bff/Dockerfile
git commit -m "fix: use shell-form CMD in bff/Dockerfile so Railway \$PORT is respected"
```

---

## Task 4: Create `frontend/Dockerfile` — Next.js standalone multi-stage build

**Files:**
- Create: `frontend/Dockerfile`

`frontend/next.config.js` already has `output: 'standalone'`. This produces a self-contained server in `.next/standalone/server.js` that reads `process.env.PORT` at startup — Railway's injected `PORT` is picked up automatically.

- [ ] **Step 1: Create `frontend/Dockerfile`**

```dockerfile
# Stage 1: install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: build
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# Stage 3: production runner (standalone output only)
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV HOSTNAME="0.0.0.0"

RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs

# Copy standalone server and static assets
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000

# server.js reads process.env.PORT — Railway injects it at runtime
CMD ["node", "server.js"]
```

- [ ] **Step 2: Build the image**

```bash
docker build -t farmai-frontend-test ./frontend
```

Expected: `Successfully built <image_id>` — three stages complete, no errors.

If the build fails on `npm run build` due to missing env vars, add `--build-arg NEXT_PUBLIC_API_URL=http://localhost:8000`:
```bash
docker build \
  --build-arg NEXT_PUBLIC_API_URL=http://localhost:8000 \
  -t farmai-frontend-test ./frontend
```

- [ ] **Step 3: Run on a custom port**

```bash
docker run --rm -e PORT=4000 -p 4000:4000 farmai-frontend-test 2>&1 | head -5
```

Expected: `Listening on port 4000`

- [ ] **Step 4: Confirm the app responds**

In a separate terminal:
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/
```

Expected: `200`

- [ ] **Step 5: Stop the container and commit**

```bash
git add frontend/Dockerfile
git commit -m "feat: add Next.js standalone Dockerfile for Railway"
```

---

## Task 5: Create `railway.toml` files for healthchecks

**Files:**
- Create: `backend/railway.toml`
- Create: `bff/railway.toml`
- Create: `frontend/railway.toml`

Railway uses `railway.toml` in the service's root directory (the directory set as "Root Directory" in the service settings). These files configure healthchecks and restart policy. Railway polls `healthcheckPath` on the service's `$PORT` — a non-2xx response keeps the deploy pending.

- [ ] **Step 1: Create `backend/railway.toml`**

Used by both `api` and `mcp-server` Railway services (same build context).

```toml
[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

- [ ] **Step 2: Create `bff/railway.toml`**

```toml
[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

- [ ] **Step 3: Create `frontend/railway.toml`**

```toml
[deploy]
healthcheckPath = "/"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

- [ ] **Step 4: Commit**

```bash
git add backend/railway.toml bff/railway.toml frontend/railway.toml
git commit -m "feat: add railway.toml healthcheck config for all services"
```

---

## Task 6: Create `.env.railway.example`

**Files:**
- Create: `.env.railway.example`

Documents every env var required in the Railway dashboard. Railway reference variable syntax (`${{ServiceName.VAR}}`) is resolved by Railway at deploy time — it wires inter-service URLs automatically. Angles brackets (`<...>`) indicate values the operator must supply manually.

- [ ] **Step 1: Create `.env.railway.example`**

```bash
# =============================================================================
# Farm-AI Railway Environment Variables
# =============================================================================
# Set these in Railway Dashboard → Service → Variables tab.
# Reference variables (${{ServiceName.VAR}}) are resolved by Railway at runtime.
# Generate secrets with: openssl rand -hex 32
# =============================================================================

# =============================================================================
# SERVICE: api
# Root Directory: ./backend
# =============================================================================
SERVICE=api
ENVIRONMENT=production

# Auth → Anthropic
ANTHROPIC_API_KEY=<your-anthropic-api-key>
CLAUDE_MODEL=claude-sonnet-4-20250514

# Database (from Railway Postgres plugin — copy the DATABASE_URL it provides)
# Railway's plugin exposes DATABASE_URL; our config reads POSTGRES_URL
POSTGRES_URL=${{Postgres.DATABASE_URL}}
POSTGRES_URL_ASYNC=${{Postgres.DATABASE_URL}}

# Redis (from Railway Redis plugin)
REDIS_URL=${{Redis.REDIS_URL}}

# MCP Server (private network — Railway resolves at deploy time)
MCP_SERVER_URL=http://${{mcp-server.RAILWAY_PRIVATE_DOMAIN}}/sse

# External APIs
OPENWEATHER_API_KEY=<your-openweathermap-api-key>
AGMARKNET_API_KEY=<your-agmarknet-api-key>

# CORS — comma-separated, must include the frontend Railway public URL
CORS_ORIGINS=https://<your-frontend-railway-domain>

# =============================================================================
# SERVICE: mcp-server
# Root Directory: ./backend
# =============================================================================
SERVICE=mcp

# Database
POSTGRES_URL=${{Postgres.DATABASE_URL}}

# External APIs (same keys as api)
OPENWEATHER_API_KEY=<your-openweathermap-api-key>
AGMARKNET_API_KEY=<your-agmarknet-api-key>

# =============================================================================
# SERVICE: bff
# Root Directory: ./bff
# =============================================================================

# Points to the api service over private network
BACKEND_URL=http://${{api.RAILWAY_PRIVATE_DOMAIN}}

# Redis (from Railway Redis plugin)
REDIS_URL=${{Redis.REDIS_URL}}

# Auth
JWT_SECRET=<openssl rand -hex 32>
JWT_EXPIRY_DAYS=7

# Twilio (for OTP SMS)
TWILIO_ACCOUNT_SID=<your-twilio-account-sid>
TWILIO_AUTH_TOKEN=<your-twilio-auth-token>
TWILIO_PHONE_NUMBER=<your-twilio-from-number>

# OpenAI (Whisper STT + TTS)
OPENAI_API_KEY=<your-openai-api-key>

# Google Cloud Translation
GOOGLE_TRANSLATE_API_KEY=<your-google-translate-api-key>

# Public URL of the BFF service itself (for audio file URLs in responses)
BFF_BASE_URL=https://<your-bff-railway-domain>

# CORS — must include the frontend Railway public URL
CORS_ORIGINS=https://<your-frontend-railway-domain>

# =============================================================================
# SERVICE: frontend
# Root Directory: ./frontend
# =============================================================================

# Points to the api service (direct) — update to BFF URL once web is BFF-integrated
NEXT_PUBLIC_API_URL=https://<your-api-railway-domain>

# =============================================================================
# RAILWAY PLUGINS (auto-configured — no manual setup needed)
# =============================================================================
# Postgres plugin → exposes: DATABASE_URL, PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
# Redis plugin   → exposes: REDIS_URL, REDISHOST, REDISPORT, REDISPASSWORD
```

- [ ] **Step 2: Commit**

```bash
git add .env.railway.example
git commit -m "docs: add .env.railway.example with Railway reference variables"
```

---

## Task 7: Manual Railway Dashboard Setup

This task is a checklist of steps performed in the Railway web UI. No code changes.

**Pre-requisite:** Push all commits from Tasks 1–6 to GitHub main before starting.

```bash
git push origin main
```

### 7a. Create project and plugins

- [ ] Go to [railway.app](https://railway.app) → New Project → Deploy from GitHub repo → select `farm-ai`
- [ ] In the project, click **+ New** → **Database** → **Add PostgreSQL** (Railway managed plugin)
- [ ] Click **+ New** → **Database** → **Add Redis** (Railway managed plugin)
- [ ] Wait for both plugins to be provisioned (green status)

### 7b. Create the `mcp-server` service

- [ ] **+ New** → **GitHub Repo** → select `farm-ai`
- [ ] Go to service **Settings** → rename to `mcp-server`
- [ ] **Settings** → **Root Directory** → set to `backend`
- [ ] **Settings** → **Dockerfile Path** → set to `Dockerfile` (auto-detected)
- [ ] **Variables** tab → add all vars from `.env.railway.example` block `SERVICE: mcp-server`
  - `SERVICE` = `mcp`
  - `POSTGRES_URL` = `${{Postgres.DATABASE_URL}}`
  - `OPENWEATHER_API_KEY` = `<your key>`
  - `AGMARKNET_API_KEY` = `<your key>`
- [ ] Deploy and wait for green healthcheck on `/health`

### 7c. Create the `api` service

- [ ] **+ New** → **GitHub Repo** → select `farm-ai`
- [ ] Rename to `api`, Root Directory = `backend`
- [ ] **Variables** tab → add all vars from `.env.railway.example` block `SERVICE: api`
  - `SERVICE` = `api`
  - `ANTHROPIC_API_KEY` = `<your key>`
  - `POSTGRES_URL` = `${{Postgres.DATABASE_URL}}`
  - `POSTGRES_URL_ASYNC` = `${{Postgres.DATABASE_URL}}`
  - `REDIS_URL` = `${{Redis.REDIS_URL}}`
  - `MCP_SERVER_URL` = `http://${{mcp-server.RAILWAY_PRIVATE_DOMAIN}}/sse`
  - `OPENWEATHER_API_KEY`, `AGMARKNET_API_KEY` = `<your keys>`
  - `CORS_ORIGINS` = `https://<frontend-domain>` (update after frontend is deployed)
  - `ENVIRONMENT` = `production`
- [ ] Deploy and wait for green healthcheck on `/health`

### 7d. Create the `bff` service

- [ ] **+ New** → **GitHub Repo** → select `farm-ai`
- [ ] Rename to `bff`, Root Directory = `bff`
- [ ] **Variables** tab → add all vars from `.env.railway.example` block `SERVICE: bff`
  - `BACKEND_URL` = `http://${{api.RAILWAY_PRIVATE_DOMAIN}}`
  - `REDIS_URL` = `${{Redis.REDIS_URL}}`
  - `JWT_SECRET` = `<generate: openssl rand -hex 32>`
  - `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER` = `<Twilio creds>`
  - `OPENAI_API_KEY` = `<your key>`
  - `GOOGLE_TRANSLATE_API_KEY` = `<your key>`
  - `BFF_BASE_URL` = `https://<bff-railway-domain>` (get from Settings → Domains after first deploy)
  - `CORS_ORIGINS` = `https://<frontend-domain>` (update after frontend is deployed)
- [ ] Deploy and wait for green healthcheck on `/health`

### 7e. Create the `frontend` service

- [ ] **+ New** → **GitHub Repo** → select `farm-ai`
- [ ] Rename to `frontend`, Root Directory = `frontend`
- [ ] **Variables** tab:
  - `NEXT_PUBLIC_API_URL` = `https://<api-railway-domain>` (from api service Settings → Domains)
- [ ] Deploy and wait for green healthcheck on `/`

### 7f. Update CORS after all services are deployed

Once all public domains are known:
- [ ] `api` service Variables → update `CORS_ORIGINS` = `https://<frontend-domain>`
- [ ] `bff` service Variables → update `CORS_ORIGINS` = `https://<frontend-domain>` and `BFF_BASE_URL` = `https://<bff-domain>`
- [ ] Redeploy api and bff

### 7g. Smoke test the full stack

- [ ] Open `https://<frontend-domain>` in a browser — should load the Farm-AI UI
- [ ] Send a text query — should receive an agent response
- [ ] Check api service logs in Railway dashboard for successful requests

---

## Self-Review

### Spec coverage

| Requirement | Task |
|---|---|
| Railway injects `$PORT` — services must listen on it | Tasks 2, 3, 4 |
| `api` and `mcp-server` share `backend/` Dockerfile | Task 1 (start.sh dispatch) |
| Healthchecks for Railway | Task 5 |
| Env var documentation with private network reference vars | Task 6 |
| Full setup walkthrough | Task 7 |

### Notes

**POSTGRES_URL vs DATABASE_URL:** Railway's Postgres plugin exposes `DATABASE_URL`. The backend `config.py` reads `POSTGRES_URL` and `POSTGRES_URL_ASYNC`. These must be set separately in Railway Variables, both pointing to `${{Postgres.DATABASE_URL}}`.

**pgvector:** Railway's managed Postgres is standard PostgreSQL; pgvector is NOT pre-installed. The backend's `infra/postgres/init.sql` runs `CREATE EXTENSION IF NOT EXISTS vector;`. This init script only runs on a fresh database — it won't run on Railway's managed Postgres automatically. **Workaround:** After provisioning the Railway Postgres plugin, connect and run manually:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```
Connect via:
```bash
# Get connection string from Railway Postgres plugin Variables tab
psql "$DATABASE_URL" -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

**Audio storage:** The BFF saves TTS audio to `/tmp/audio/` and serves it via a static route. `/tmp` is ephemeral on Railway (wiped on redeploy). This is acceptable for Phase 1 (files expire after 1 hour by design). Production upgrade: replace with S3 + pre-signed URLs.

**MCP server private domain:** Railway's private network domain format is `<service-name>.railway.internal`. The reference variable `${{mcp-server.RAILWAY_PRIVATE_DOMAIN}}` resolves to this at deploy time. The api service's `MCP_SERVER_URL` must use this — not the public domain — to avoid unnecessary egress.
