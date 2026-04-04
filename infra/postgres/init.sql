-- ============================================================
-- FarmAI PostgreSQL + pgvector Schema
-- ============================================================
-- Run automatically by Docker Compose on first startup.
--
-- 📖 NOTE: pgvector is a PostgreSQL extension that adds a
-- new column type: vector(N)
-- This lets you store embedding vectors directly in Postgres
-- and run similarity searches with SQL operators:
--   embedding <-> query_vector  (L2 distance)
--   embedding <#> query_vector  (inner product)
--   embedding <=> query_vector  (cosine similarity)
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Farmer Profiles ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS farmer_profiles (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          TEXT NOT NULL,
    phone         TEXT UNIQUE,
    location      TEXT,
    state         TEXT,
    land_acres    DECIMAL(10, 2),
    current_crops TEXT[],           -- Array of crop names
    irrigation_type TEXT,           -- drip, flood, sprinkler, rain-fed
    category      TEXT,             -- small/marginal/large
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── Interaction History ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS farm_history (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id   UUID REFERENCES farmer_profiles(id) ON DELETE CASCADE,
    query       TEXT NOT NULL,
    response    TEXT NOT NULL,
    agent_used  TEXT,               -- which specialist agent handled it
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_history_farmer_id ON farm_history(farmer_id);
CREATE INDEX IF NOT EXISTS idx_history_created_at ON farm_history(created_at DESC);

-- ── pgvector Knowledge Store ──────────────────────────────────────────────────
-- LangChain's PGVector creates and manages these tables automatically.
-- We define them here for reference and to pre-create indexes.

CREATE TABLE IF NOT EXISTS langchain_pg_collection (
    uuid    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name    TEXT NOT NULL UNIQUE,
    cmetadata JSONB
);

CREATE TABLE IF NOT EXISTS langchain_pg_embedding (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collection_id UUID REFERENCES langchain_pg_collection(uuid) ON DELETE CASCADE,
    embedding     vector(1024),    -- Voyage-3 embeddings are 1024-dimensional
    document      TEXT,            -- The actual text chunk
    cmetadata     JSONB,           -- Source file, collection name, etc.
    custom_id     TEXT
);

-- IVFFlat index for approximate nearest neighbor search
-- probes=10 means check 10 clusters during search (higher = more accurate, slower)
-- lists=100 means divide vectors into 100 clusters (rule of thumb: sqrt(num_rows))
CREATE INDEX IF NOT EXISTS idx_embedding_cosine
    ON langchain_pg_embedding
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

-- ── Seed Demo Farmer ──────────────────────────────────────────────────────────
INSERT INTO farmer_profiles (id, name, phone, location, state, land_acres, current_crops, irrigation_type, category)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'Raju Reddy', '9876543210', 'Warangal', 'telangana', 5.5, ARRAY['cotton', 'tomato'], 'drip', 'small'),
    ('00000000-0000-0000-0000-000000000002', 'Balwinder Singh', '9876543211', 'Ludhiana', 'punjab', 15.0, ARRAY['wheat', 'rice'], 'flood', 'marginal'),
    ('00000000-0000-0000-0000-000000000003', 'Sunita Devi', '9876543212', 'Nashik', 'maharashtra', 3.0, ARRAY['grapes', 'onion'], 'drip', 'small')
ON CONFLICT (phone) DO NOTHING;
