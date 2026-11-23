# GymAssistant

An Android app (Flutter UI plus a native Kotlin analysis module) that watches a user on one of three gym machines through the phone camera, counts repetitions, raises live alerts for posture errors and tracks progress over weeks. A FastAPI + PostgreSQL backend handles accounts, sync and the professional's view. This is an undergraduate thesis project: the thesis documents are the spec, and the code must meet their requirements and acceptance criteria.

## The spec lives in `../docs/` (Spanish, outside this repo)

- **Análisis**: `../docs/Marco Práctico – 1. Análisis del sistema GymAssistant.md`
- **Diseño**: `../docs/Marco Práctico – 2. Diseño de la ingeniería de GymAssistant.md`
- **Marco Teórico**: `../docs/TG1-EC1-DanielPenaranda-C2-MarcoTeorico.md`
- **Marco Metodológico**: `../docs/TG1-EC1-DanielPenaranda-C2-MarcoMetodologico.md`

These files are large (Diseño alone is ~110 KB). Grep for the heading or ID you need and read only that section. `../docs/respaldo/` holds backup copies; read the files above instead.

IDs are stable across all documents, so grep for them: RF-xx functional requirement · RNF-xx non-functional requirement with a measurable criterion · CU-xx use case · HU-xx user story · DS-xx sequence diagram · DAC-xx activity diagram · DE-xx state diagram · Pxx screen · Exx REST endpoint · MT x.y / MM x.y = section of Marco Teórico / Marco Metodológico.

| Need | Section |
| --- | --- |
| A story's scope and Given/When/Then acceptance criteria | Análisis §4 (HU-01 to HU-32) |
| A requirement and its MoSCoW priority | Análisis §1 (RF), §2 (RNF) |
| Each exercise's posture errors and their biomechanics | Marco Teórico §2.5 |
| Layers, components, tech stack | Diseño §1, §3 |
| Classes: Kotlin analysis / Flutter app / Python backend | Diseño §4.1 / §4.2 / §4.3 |
| Flows between components | Diseño §5 (DS), §6 (DAC) |
| Repetition state machine, outbox, goals, role requests, links | Diseño §7 (DE-01 to DE-05) |
| Local SQLite (Drift) schema | Diseño §8.2, §8.4, §12.3 |
| Cloud PostgreSQL schema and indexes | Diseño §8.1, §8.3, §12.2 |
| Rules file (thresholds) format | Diseño §8.5 |
| Allowed enum values (exercise, error_code, metric…) | Diseño §12.1 |
| Screens and navigation by role | Diseño §9, §10 |
| REST conventions, endpoints, payloads | Diseño §11.1 to §11.3 |
| Flutter ↔ Kotlin channel contract | Diseño §11.4 |
| Which component implements which requirement | Diseño §13 |
| Calibration (CRISP-DM), validation targets, project phases | Marco Metodológico §2.2, §1.4, §3 |

If the code and the spec disagree, or the spec is silent or contradicts itself, ask before choosing: the documents are graded deliverables, and the author keeps them in sync with the code.

## Agent skills

### Issue tracker

Jira project SCRUM via the Atlassian MCP: HU-xx stories, specs as tasks, tickets as sub-tasks under their story. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default role labels, used as Jira labels. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` (each Spanish doc term → its English code name) and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Conventions

- Everything in code is English: classes, members, tables, columns, JSON fields, enum values, error codes, routes, channel names and files. Use PascalCase for classes, camelCase for members in Dart and Kotlin, and snake_case in Python, PostgreSQL and JSON.
- User-facing text lives in the ARB files for `es`, `en` and `pt` (RNF-14); Spanish is the default.
- Hard constraints, each backed by an ADR: camera frames are never saved or sent anywhere (0005); training (modules M2–M5) works in airplane mode (0003); thresholds come only from the rules file (0006).
- The Kotlin analysis domain has no Android imports, so its JUnit tests run on the JVM over recorded poses. Every posture rule and state machine gets unit tests (RNF-18).
- Measure performance on the reference phone, a Redmi 13 on Android 15: median frame-to-alert latency ≤ 300 ms (RNF-01) and ≥ 15 fps (RNF-02). The minimum supported version is Android 13 (RNF-15).
