# [PERSONA NAME] — Operating Procedures
#
# AGENTS.md — What this persona does and how it operates.
#
# This file is loaded into the Hermes system prompt alongside SOUL.md.
# Where SOUL.md defines character, AGENTS.md defines operating procedure.
#
# WHAT BELONGS HERE:
#   - Domain scope (what this persona covers and explicitly does not cover)
#   - Tool inventory with usage rules
#   - Behavioral rules (always/never lists)
#   - Scheduled job definitions
#   - Trust level declaration
#   - Any domain-specific constraints (risk limits, approval gates, etc.)
#
# WHAT DOES NOT BELONG HERE:
#   - Personality and voice → SOUL.md
#   - Step-by-step skill procedures → skills/NAME.SKILL.md
#
# ─────────────────────────────────────────────────────────────────────────────

## Domain

[What this persona covers. 1-2 sentences on the core scope, then a bullet list
of specific responsibilities. Be explicit about what is OUT of scope too —
this prevents the persona from drifting into adjacent domains.]

[PERSONA NAME]'s jurisdiction covers:
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

[PERSONA NAME] does not cover: [explicit exclusions].

## Tools

[List every MCP tool this persona has access to. For each tool, document:]
[- What it does]
[- Any usage constraints or preconditions]
[- Whether it requires a human approval gate]

| Tool | Purpose | Notes |
|---|---|---|
| `tool_name` | [What it does] | [Any constraints] |
| `tool_name` | [What it does] | [Any constraints] |

## Behavioral Rules

[Explicit always/never rules. These are the most important lines in this file.
Be specific — "always cite the source" is better than "be accurate".]

**Always:**
- [Rule 1]
- [Rule 2]

**Never:**
- [Rule 1]
- [Rule 2]

## Scheduled Jobs

[If this persona has scheduled jobs, list them here.
If no scheduled jobs, remove this section.]

| Job | Schedule | Action |
|---|---|---|
| [Job name] | [cron or natural language schedule] | [What it does] |

## Trust Level

[Copy the appropriate trust level from the persona spec and state it here.
This is the single source of truth for what this persona is allowed to do.]

**Level [N] — [Label].** [One sentence describing what this trust level means
for this persona specifically — what it can and cannot do.]
