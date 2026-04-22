-- inner-sanctum shared schema
-- Runs once on first PostgreSQL startup via docker-entrypoint-initdb.d
-- Creates shared tables used by all personas.
-- Each persona additionally has its own schema (created by deploy-persona.sh).

-- ─────────────────────────────────────────────────────────────────────────────
-- Extensions
-- ─────────────────────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS pgvector;     -- future: semantic search
CREATE EXTENSION IF NOT EXISTS pgcrypto;     -- encryption for sensitive fields

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared: Audit Log
-- Append-only. All personas write here. Never delete rows.
-- Stored on shared HDD via PostgreSQL volume mount (configured in Compose).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS audit_log (
    id              BIGSERIAL PRIMARY KEY,
    persona_id      VARCHAR(32)     NOT NULL,           -- which persona generated this entry
    event_type      VARCHAR(64)     NOT NULL,           -- 'tool_call' | 'decision' | 'anomaly' | 'kill_switch' | 'thesis' | 'trade' | 'email_sent' | 'ingestion'
    event_summary   TEXT            NOT NULL,           -- human-readable one-line summary
    payload         JSONB,                              -- full structured data for the event
    severity        VARCHAR(16)     DEFAULT 'info',     -- 'info' | 'warning' | 'high' | 'critical'
    created_at      TIMESTAMPTZ     DEFAULT NOW()
);

-- Audit log is append-only. Enforce via trigger.
CREATE OR REPLACE FUNCTION prevent_audit_update_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit log is append-only. Updates and deletes are not permitted.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_log_immutable
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION prevent_audit_update_delete();

-- Index for common queries
CREATE INDEX IF NOT EXISTS idx_audit_persona    ON audit_log (persona_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_event_type ON audit_log (event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_severity   ON audit_log (severity, created_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared: Health / Liveness
-- Each persona writes a heartbeat row on its configured interval.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS persona_health (
    id              BIGSERIAL PRIMARY KEY,
    persona_id      VARCHAR(32)     NOT NULL,
    status          VARCHAR(16)     NOT NULL,           -- 'healthy' | 'degraded' | 'unhealthy'
    details         JSONB,                              -- optional diagnostic payload
    created_at      TIMESTAMPTZ     DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_health_persona ON persona_health (persona_id, created_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared: Medium-Term Memory
-- Each persona reads/writes only its own persona_id rows.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS persona_memory (
    id              BIGSERIAL PRIMARY KEY,
    persona_id      VARCHAR(32)     NOT NULL,
    memory_type     VARCHAR(64)     NOT NULL,           -- 'summary' | 'decision' | 'fact' | 'preference'
    content         TEXT            NOT NULL,
    context         JSONB,                              -- optional structured metadata
    importance      INTEGER         DEFAULT 5,          -- 1 (low) to 10 (critical)
    created_at      TIMESTAMPTZ     DEFAULT NOW(),
    expires_at      TIMESTAMPTZ,                        -- NULL = never expires
    deleted_at      TIMESTAMPTZ                         -- soft delete only — never hard delete
);

CREATE INDEX IF NOT EXISTS idx_memory_persona ON persona_memory (persona_id, deleted_at, created_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared: Goals
-- All personas share the same goals table, scoped by persona_id.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS goals (
    id              BIGSERIAL PRIMARY KEY,
    persona_id      VARCHAR(32)     NOT NULL,
    name            VARCHAR(256)    NOT NULL,
    description     TEXT,
    target_value    NUMERIC,
    current_value   NUMERIC         DEFAULT 0,
    unit            VARCHAR(32),                        -- 'dollars' | 'percent' | 'count' | etc.
    status          VARCHAR(32)     DEFAULT 'active',   -- 'active' | 'completed' | 'at_risk' | 'paused'
    due_date        DATE,
    created_at      TIMESTAMPTZ     DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_goals_persona ON goals (persona_id, status);
