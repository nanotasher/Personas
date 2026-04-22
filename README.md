# Personas

Shared infrastructure and persona framework for the Inner Sanctum agent ecosystem.

This repo owns:
- Shared services: vLLM, PostgreSQL, audit log, health monitoring
- The persona template — the canonical starting point for every new persona
- Deploy scripts — automate persona wiring from `persona.json`
- The persona specification — the living standard all personas conform to

## Companion repo

Persona definitions live in `Council`. This repo has no knowledge of
specific personas. Individual personas depend on this repo.

## Quick start

### 1. Start shared infrastructure
```bash
cd /mnt/c/Projects/Personas
cd infrastructure
cp .env.example .env        # fill in secrets
docker compose up -d
```

### 2. Create a new persona
```bash
# In inner-sanctum-personas repo:
cp -r ../Personas/template personas/persona-id
cd personas/persona-id
# Edit SOUL.md, AGENTS.md, persona.json
```

### 3. Deploy a persona
```bash
cd /mnt/c/Projects/Personas
./scripts/deploy-persona.sh ../Council/personas/persona-id
```

## Repo structure

```
Personas/
├── infrastructure/          # Shared Docker services
│   ├── docker-compose.yml   # vLLM, PostgreSQL, audit, health
│   ├── .env.example
│   └── db/
│       └── init.sql         # Shared schema (audit log, health, memory)
├── template/        # Clone this to create a new persona
│   ├── SOUL.md
│   ├── AGENTS.md
│   ├── persona.json
│   ├── config.yaml
│   └── skills/
│       └── example.SKILL.md
├── scripts/
│   └── deploy-persona.sh    # Reads persona.json, generates Hermes config
└── docs/
    └── persona-spec.md      # The living standard
```
