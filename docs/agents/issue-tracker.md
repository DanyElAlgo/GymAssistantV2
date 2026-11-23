# Issue tracker: Jira

Issues for this repo live in the Jira project **SCRUM**, not in GitHub Issues. Use the Atlassian MCP tools; get the cloudId from `getAccessibleAtlassianResources` (there is one site). Write summaries and descriptions in Spanish, like the existing backlog, using `GLOSSARY.md` terms with code names in backticks.

## Backlog shape

- **Epic** (E1–E7): groups stories by objective; labels `OE1`…`OE5`.
- **Historia** (HU-01…HU-32): the thesis user stories, titled `HU-xx <resumen>`, parent = its Epic, labels = phase (`F1`…`F6`) plus requirement IDs (`RF-12`). Their acceptance criteria are in Análisis §4. Story points, sprint and status belong to the author: read stories, never edit their fields or create new ones without asking.
- **Tarea** labelled `spec`: a spec written by `/to-spec`.
- **Subtarea**: a ticket written by `/to-tickets`; parent = the Historia it delivers.
- Statuses: Por hacer → En curso → En revisión → Finalizado.

## Operations

- **Create**: `createJiraIssue` with project `SCRUM`, the issue type name, summary, markdown description, labels and, for a Subtarea, `parent`.
- **Read**: `getJiraIssue` with view `evidence`; it includes the parent and `issuelinks`.
- **List**: `searchJiraIssuesUsingJql`. Every query needs a restriction (unbounded JQL is rejected), so always start with `project = SCRUM`. E.g. `project = SCRUM AND labels = F1 AND labels = ready-for-agent AND statusCategory != Done`.
- **Comment**: `addOrEditJiraIssueComment`.
- **Labels**: `editJiraIssue`; it replaces the whole list, so read the current labels first and write them back with the change.
- **Blocking**: `executeWrite` → `createJiraIssueLink`, linkType `Blocks`, `inwardIssue` = the blocker, `outwardIssue` = the blocked ticket. A ticket is unblocked when every "is blocked by" issue is Finalizado.
- **Move status**: `listJiraIssueTransitions`, then `transitionJiraIssue`. A Subtarea goes to En curso when work starts, En revisión when its PR opens, Finalizado when the PR merges.
- **Branches and PRs**: put the issue key in the branch name and PR title (`SCRUM-45-...`) and link the PR from the issue.

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag.)_

## When a skill says "publish to the issue tracker"

- A **spec**: a Tarea labelled `spec` plus its phase label, with a `Relates` link to each Historia it covers.
- A **ticket**: a Subtarea under the Historia it delivers, labelled `ready-for-agent` plus its phase, with a `Relates` link to its spec and `Blocks` links for its edges. If no Historia fits, stop and ask the author to add one first.
- Anything else (a bug, a raw request): a Tarea, with `bug` for bugs.

## When a skill says "fetch the relevant ticket"

Read the issue, its parent Historia, and the Historia's acceptance criteria in Análisis §4.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: a Tarea labelled `wayfinder:map`.
- **Child ticket**: a Subtarea whose parent is the map, labelled `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`).
- **Blocking**: `Blocks` links, as above.
- **Frontier**: `project = SCRUM AND parent = <map> AND statusCategory != Done AND assignee is EMPTY`, minus any with an open "is blocked by" link. The first in key order wins.
- **Claim**: assign it to yourself (`atlassianUserInfo` gives your accountId) as the first write.
- **Resolve**: comment the answer, transition to Finalizado, and append a pointer to the map's description under Decisions so far.
