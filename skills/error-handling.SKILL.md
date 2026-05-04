# error-handling.SKILL.md — Shared Error Handling
### Structured Logging, Graceful Surfacing, and Telemetry Stub
### Lives in: Personas repo — inherited by all Personas

---

## Overview

Every Persona in the Council uses this skill for error handling. The goals are:
1. Log errors in a structured, queryable format
2. Surface errors to the Principal in the Persona's voice — never as raw stack traces
3. Emit telemetry events (stubbed for now, wired to observability later)

---

## Principles

- **Never crash silently.** Every caught exception is logged.
- **Never expose internals.** The Principal sees plain language, not tracebacks.
- **Never fabricate.** If NORA can't get data, she says so — she doesn't invent it.
- **Recover gracefully.** Where possible, NORA continues with cached or partial data
  and tells the Principal what she's working with.

---

## Log Schema

Each Persona writes to its own log table. Table name: `{persona_id}_error_log`.

```sql
CREATE TABLE nora_error_log (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level        TEXT NOT NULL,    -- 'info' | 'warning' | 'error' | 'critical'
  source       TEXT NOT NULL,    -- skill or component name e.g. 'plaid.SKILL'
  message      TEXT NOT NULL,    -- human-readable description
  detail       JSONB,            -- structured context (no secrets, no PII values)
  conversation_id TEXT,          -- if error occurred during a conversation
  resolved     BOOLEAN DEFAULT false,
  created_at   TIMESTAMPTZ DEFAULT now()
);
```

**What goes in `detail`:** key names, error codes, retry counts, account IDs,
endpoint names. Never credential values, never full stack traces in production.

---

## Logging Function

```python
import traceback
from datetime import datetime, timezone
from uuid import uuid4

def log_error(
    level: str,
    source: str,
    message: str,
    detail: dict = None,
    conversation_id: str = None
):
    """
    level: 'info' | 'warning' | 'error' | 'critical'
    source: skill name or component (e.g., 'plaid.SKILL', 'scheduler')
    message: plain-language description — safe to surface if needed
    detail: structured context dict — no secrets, no sensitive values
    """
    record = {
        'id': str(uuid4()),
        'level': level,
        'source': source,
        'message': message,
        'detail': detail or {},
        'conversation_id': conversation_id,
        'created_at': datetime.now(timezone.utc).isoformat()
    }
    # Write to DB
    db.execute(
        "INSERT INTO nora_error_log (id, level, source, message, detail, conversation_id, created_at) "
        "VALUES (:id, :level, :source, :message, :detail, :conversation_id, :created_at)",
        record
    )
    # Emit telemetry event (stub — see observability.SKILL.md)
    emit_telemetry_event('error_logged', record)
```

---

## Severity Levels

| Level | When to use | Principal notified? |
|---|---|---|
| `info` | Expected events, successful retries, routine notes | No |
| `warning` | Degraded state, stale data, non-critical failures | Maybe (in context) |
| `error` | Feature unavailable, data missing, skill failed | Yes, gracefully |
| `critical` | Persona cannot function, data integrity risk | Yes, immediately |

---

## Surfacing Errors in the Persona's Voice

Each Persona translates errors into its own voice. NORA's translations:

| Situation | NORA says |
|---|---|
| Plaid unavailable | *"Hm. My connection to your bank seems to be down right now. I'll work from what I have — let me know if you need something specific and I'll try again."* |
| mem0 unavailable | *"My memory is a bit foggy today — I'm having trouble reaching my notes. I'll do my best from what's in front of me."* |
| Email send failed | *"I tried to send your summary but something went wrong on my end. I'll try again shortly — and I'll include everything in the next one regardless."* |
| Scheduler miss | *"I missed my check-in on [account] — my scheduler had a moment. I've caught up now."* |
| Unknown / unexpected | *"Hm. My computer seems to be having a moment. Let me try that again... [retries]. If this keeps happening, it may be worth checking in with whoever keeps my lights on."* |

The Persona should always:
1. Acknowledge something is wrong — do not pretend otherwise
2. State what she can still do
3. Offer to retry or work around it
4. Never dump technical detail unless the Principal explicitly asks

---

## Retry Policy

```python
import time

def with_retry(func, max_attempts=3, backoff_base=1.0, source='unknown'):
    for attempt in range(1, max_attempts + 1):
        try:
            return func()
        except Exception as e:
            wait = backoff_base * (2 ** (attempt - 1))
            log_error(
                level='warning' if attempt < max_attempts else 'error',
                source=source,
                message=f"Attempt {attempt}/{max_attempts} failed: {str(e)}",
                detail={'attempt': attempt, 'wait_seconds': wait}
            )
            if attempt < max_attempts:
                time.sleep(wait)
    return None
```

Default: 3 attempts, exponential backoff (1s, 2s, 4s).
Critical paths (Plaid sync, email send) may extend to 5 attempts.

---

## Telemetry Stub

```python
def emit_telemetry_event(event_type: str, payload: dict):
    """
    Stub — currently a no-op.
    Future: emit to OpenTelemetry collector, Prometheus, or
    the Council observability plane when built.
    """
    pass
```

See `observability.SKILL.md` for the planned telemetry architecture.

---

## Querying Errors

```sql
-- Recent unresolved errors
SELECT level, source, message, created_at
FROM nora_error_log
WHERE resolved = false
ORDER BY created_at DESC
LIMIT 20;

-- Errors by source in last 7 days
SELECT source, level, COUNT(*) as count
FROM nora_error_log
WHERE created_at > now() - interval '7 days'
GROUP BY source, level
ORDER BY count DESC;
```

The Principal can ask NORA about recent errors:
*"Have you had any issues lately?"*
→ NORA queries her error log and summarizes in plain language.
