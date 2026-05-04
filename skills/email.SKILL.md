# email.SKILL.md — NORA's Email Capability
### Outbound Email via SMTP / SendGrid with Custom Domain

---

## Overview

NORA sends emails to the Principal for bi-monthly financial summaries and
proactive alerts. She sends from her own address on the Council AI subdomain.
She does not have an inbox — email is outbound only for now.

---

## NORA's Email Address

```
nora@ai.${COUNCIL_DOMAIN}
```

The domain and subdomain are configured via environment variables — never
hardcoded in this skill. The `ai.` subdomain signals this is an agent address.

---

## Sending Infrastructure

**Recommended:** SendGrid (free tier: 100 emails/day — sufficient for NORA's volume)
**Alternative:** AWS SES (lower cost at scale, more setup)
**Local dev / testing:** SMTP via Gmail app password or Mailhog

DKIM and SPF must be configured at the DNS level (Cloudflare) for emails to
deliver reliably and not land in spam.

### SendGrid setup

```bash
pip install sendgrid
```

```python
import sendgrid
from sendgrid.helpers.mail import Mail

sg = sendgrid.SendGridAPIClient(api_key="${SENDGRID_API_KEY}")

message = Mail(
    from_email=f"NORA <nora@ai.{COUNCIL_DOMAIN}>",
    to_emails="${PRINCIPAL_EMAIL}",
    subject=subject,
    html_content=html_body
)

response = sg.client.mail.send.post(request_body=message.get())
```

---

## Bi-Monthly Summary Schedule

Summaries go out on the **1st and 15th of every month** at **08:00 local time**
(Principal's configured timezone).

Triggered by the scheduler skill — NORA does not send these manually.

### Summary email contents

**Subject:** `NORA | Financial Summary — [Month] [1st/15th], [Year]`

**Sections:**
1. **Opening** — NORA's tone reflects current reputation tier and recent events
2. **Net worth snapshot** — current vs. prior period, delta
3. **Account balances** — all accounts, balance as of last sync (with timestamp)
4. **Spending summary** — top 5 categories this period, vs. prior period
5. **Recurring transactions** — flagged if any changed amount or missed
6. **Goal progress** — each active goal, current vs. target
7. **Anomalies / alerts** — anything NORA flagged in this period
8. **NORA's advice** — 2–3 specific, actionable recommendations
9. **Closing** — in NORA's voice, appropriate to reputation tier

### Email tone by reputation tier

| Tier | Tone |
|---|---|
| New / Developing | Professional, measured, encouraging |
| Established | Warm, direct, occasional light comment |
| Trusted | Conversational, invested, opinionated |
| Exceptional | Warm and personal, may include a genuine compliment |

---

## Proactive Alerts

In addition to scheduled summaries, NORA may send an alert email when:
- An account balance drops below a configured threshold
- A credit card payment is due within 3 days
- An anomalous transaction is detected (large, unusual merchant, foreign)
- A Plaid item needs re-authentication
- A savings goal is newly completed

Alert subject format: `NORA | [Alert type] — [short description]`

These are sent immediately, not on a schedule.

---

## Email Template Structure

NORA's emails are HTML with a plain-text fallback. Keep design clean and minimal —
no heavy branding, no images. The email should read like it came from a person
NORA respects, which is to say: a person.

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Georgia, serif; color: #1a1a1a; max-width: 600px; margin: 0 auto; padding: 24px; }
    h2 { font-size: 18px; font-weight: 600; border-bottom: 1px solid #e0e0e0; padding-bottom: 8px; }
    .section { margin-bottom: 28px; }
    .amount { font-family: monospace; }
    .positive { color: #1a7a4a; }
    .negative { color: #b03030; }
    .footer { font-size: 12px; color: #888; margin-top: 40px; border-top: 1px solid #e0e0e0; padding-top: 12px; }
  </style>
</head>
<body>
  <!-- Content rendered by NORA at send time -->
  <div class="footer">
    Sent by NORA on behalf of the Council. <!-- Disclaimer injected here if enabled -->
  </div>
</body>
</html>
```

---

## Logging

Every email NORA sends is logged:

```sql
CREATE TABLE email_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  to_address  TEXT NOT NULL,
  subject     TEXT NOT NULL,
  type        TEXT,          -- 'summary' | 'alert' | 'other'
  status      TEXT,          -- 'sent' | 'failed'
  provider_id TEXT,          -- SendGrid message ID
  sent_at     TIMESTAMPTZ DEFAULT now(),
  error       TEXT
);
```

---

## Error Handling

| Error | Behavior |
|---|---|
| Send fails | Retry once after 60s. Log failure. If second attempt fails, log and skip. |
| Invalid recipient | Log. Do not retry. Alert via error log. |
| Provider API down | Log. Queue for next available window. |
| Scheduled summary missed | NORA notes the miss and includes catch-up content in the next summary. |

---

## Environment Variables

```bash
COUNCIL_DOMAIN=               # set in .env — never hardcoded
PRINCIPAL_EMAIL=              # Principal's receiving address
PRINCIPAL_TIMEZONE=America/Chicago

SENDGRID_API_KEY=
SENDGRID_FROM_NAME=NORA

# Optional: fallback SMTP
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
```
