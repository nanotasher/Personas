# Skill: [Skill Name]
#
# SKILL.md — A reusable procedure for a specific task.
#
# Skills are step-by-step methods the persona follows for well-defined tasks.
# Hermes loads skill files from HERMES_HOME/skills/ and may reference them
# when a relevant task is triggered. Hermes can also evolve skill files
# autonomously over time as it learns better methods — this is by design.
#
# WHAT BELONGS IN A SKILL FILE:
#   - A clearly named procedure with numbered steps
#   - Tool calls in the order they should happen
#   - Decision points and abort conditions
#   - Output format expectations (e.g. email body structure)
#   - Hard constraints specific to this task
#
# WHAT DOES NOT BELONG HERE:
#   - Personality and voice → SOUL.md
#   - Domain scope and tool inventory → AGENTS.md
#   - Trust level declarations → AGENTS.md + persona.json
#
# NAMING CONVENTION:
#   files must end in .SKILL.md to be recognized by deploy-persona.sh
#   use kebab-case: weekly-summary.SKILL.md, document-ingestion.SKILL.md
#
# ─────────────────────────────────────────────────────────────────────────────

**Version:** 1.0.0
**Persona:** [PERSONA NAME]
**Trigger:** [What causes this skill to run — scheduled job name, user phrase, or event]

---

## Purpose

[One paragraph. What does this skill accomplish? Why does it exist as a
discrete skill rather than just being described in AGENTS.md?]

---

## Procedure

### Step 1 — [Step name]

[What happens in this step. Which tools are called. What is checked.
What constitutes success vs. failure for this step.]

### Step 2 — [Step name]

[Continue for as many steps as needed. Keep steps atomic — one clear
action or decision per step.]

### Step N — [Final step]

[Often: confirm, log to audit, respond to Nathan or send output.]

---

## Abort Conditions

[List conditions that cause the skill to stop without completing.
Every abort must be logged to the audit trail with the reason.]

- [Condition that aborts the skill]
- [Another abort condition]

---

## Constraints

[Hard rules specific to this skill that cannot be overridden at runtime.
If there are none, remove this section.]

- [Constraint 1]
- [Constraint 2]
