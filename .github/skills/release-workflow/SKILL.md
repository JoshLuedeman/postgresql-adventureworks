---
name: release-workflow
description: "Workflow for preparing and publishing a release, including changelog finalization, schema validation, and version bumping. Use when the team is ready to cut a release."
---

# Release Preparation Workflow

## Overview

Workflow for preparing and publishing a release — including changelog finalization, schema
validation, security scanning, version bumping, and release artifact creation. Use this workflow
when the team is ready to cut a release, whether it is a major version, minor version, patch,
or pre-release. This workflow coordinates multiple roles to ensure the release is complete,
correct, and well-documented before it reaches users.

For this database project, a "release" consists of: a git tag, a GitHub Release with the
`AdventureWorksPG.gz` database dump artifact, an updated CHANGELOG.md, and an updated
README.md reflecting the current state of the schema.

## Trigger

A human decides the codebase is ready for a new release. This may be driven by:

- **Milestone completion** — all planned features and fixes for a version are merged
- **Scheduled cadence** — the team releases on a regular schedule
- **Critical fix** — a hotfix needs to be published as a formal release
- **User demand** — users need access to recent changes via a stable release

## Steps

| # | Role | Action | Inputs | Outputs | Success Criteria |
|---|------|--------|--------|---------|------------------|
| 0 | **Orchestrator** | Initialize workflow: create state file, validate inputs | Trigger event, goal description | `.teamwork/state/<id>.yaml`, metrics log entry | State file created with status `active` |
| 1 | **Human** | Initiates the release; specifies target version number and included scope | Release decision, version strategy | Release request with version number, scope, target date | Version number follows conventions; scope is defined |
| 2 | **Planner** | Reviews merged work since last release; compiles list of included changes; identifies gaps | Release request, git log, closed issues | Inclusion list (features, fixes, breaking changes), gap report | All merged work accounted for; gaps identified |
| 3 | **Tester** | Runs full schema validation; performs smoke tests via psql on key tables and views | Inclusion list, validation queries | Validation query results, restore verification report | All validation queries pass; no regressions detected |
| 4 | **Security Auditor** | Performs final security scan — access control review, secrets scan, credential check | Repository at release point | Security scan results, clearance or blockers | No unresolved high/critical vulnerabilities; no leaked secrets or credentials |
| 5 | **Documenter** | Finalizes changelog, updates version numbers in docs, writes release notes | Inclusion list, previous changelog, version number | Updated changelog, release notes, version-bumped docs | Changelog is complete; release notes are user-facing |
| 6 | **Coder** | Creates release tag; regenerates `AdventureWorksPG.gz` dump if schema changed; updates version references | Version number, release notes | Release tag, updated database dump artifact, PR | Version references consistent; tag created; dump artifact is current |
| 7 | **Reviewer** | Final review — verifies changelog accuracy, version consistency, release readiness | PR, changelog, release notes, test results, security scan | Review decision, release sign-off | All artifacts consistent; no blockers; PR approved |
| 8 | **Human** | Approves the release; merges PR; publishes GitHub Release with `AdventureWorksPG.gz` artifact | Approved PR, release notes | Published GitHub Release with tagged dump artifact | Release published; `AdventureWorksPG.gz` available to users |
| 9 | **Orchestrator** | Complete workflow: validate all gates passed, update state | All step outputs, quality gate results | State file with status `completed`, final metrics | All completion criteria verified |

## Handoff Contracts

Each step must produce specific artifacts before the next step can begin.

The orchestrator validates each handoff artifact before dispatching the next role. Handoffs are stored in `.teamwork/handoffs/<workflow-id>/` following the format in `.teamwork/docs/protocols.md`.

**Human → Planner**
- Release request with:
  - Target version number (following semver or project conventions)
  - Scope: what is included (milestone, date range, or specific PRs)
  - Target release date
  - Any known blockers or items to exclude

**Planner → Tester**
- Inclusion list with:
  - Schema changes added (with PR references)
  - Bugs fixed (with issue references)
  - Breaking changes (with migration notes)
  - PowerShell script updates
  - Gap report: anything planned but not yet merged

**Tester → Security Auditor**
- Full validation query results (pass/fail summary)
- Restore verification report (successful `pg_restore` of `AdventureWorksPG.gz`)
- List of any validation failures with assessment

**Security Auditor → Documenter**
- Security scan results: access control review, credential check, secrets scan
- Clearance statement or list of blockers that must be resolved before release

**Documenter → Coder**
- Finalized changelog with all entries for this release
- Release notes (user-facing summary of changes)
- List of files requiring version reference updates

**Coder → Reviewer**
- Open PR with:
  - Updated version references in README and docs
  - Finalized changelog and release notes committed
  - Release tag created; `AdventureWorksPG.gz` regenerated if schema changed

**Reviewer → Human**
- GitHub PR review: approved or changes requested
- Release readiness checklist confirmation

## Completion Criteria

- All planned items are accounted for in the changelog (included or explicitly deferred).
- Validation queries confirm expected schema and data integrity; `pg_restore` succeeds cleanly.
- Security scan shows no unresolved high or critical vulnerabilities.
- Version references are consistent across README, CHANGELOG, and documentation.
- Changelog and release notes are complete and accurate.
- Release tag or branch is created and points to the correct commit.
- Release is published and artifacts are available to users.

## Notes

- **Pre-release checklist**: Before starting this workflow, verify: all planned PRs are
  merged, schema changes apply cleanly (no SQL errors), no release-blocking issues are open,
  and the team agrees on the version number.
- **Version bumping conventions**: Follow the project's versioning scheme (semver
  recommended). Major for breaking changes, minor for new features, patch for bug fixes.
  Pre-release versions (alpha, beta, rc) follow the same workflow with appropriate labels.
- **Changelog hygiene**: The Documenter should verify that every merged PR since the last
  release has a corresponding changelog entry. Missing entries are added during step 5,
  not retroactively to old changelogs.
- **Release branch strategy**: The Coder creates a release branch (e.g., `release/v2.1.0`)
  or tag depending on the project's branching strategy. The branch should be created from
  the target commit, not from a moving branch head.
- **GitHub Release publishing**: The release is published as a GitHub Release with the
  `AdventureWorksPG.gz` artifact attached. See `docs/releasing.md` for the detailed process.
- **Iteration loops**: If the Reviewer finds issues (wrong version, missing changelog entry,
  test failure), control returns to the appropriate role. The Reviewer blocks the release
  until all checklist items are satisfied.
- **Orchestrator coordination:** The orchestrator manages workflow state throughout. If any
  quality gate fails, the orchestrator keeps the workflow at the current step and notifies
  the responsible role. If a blocker is raised, the orchestrator sets the workflow to
  `blocked` and escalates to the human.
- **Release process reference**: See `docs/releasing.md` for the mechanical release process,
  including `make release` automation, CHANGELOG conventions, semver strategy, and dual-repo
  sync with `gh-teamwork`. This skill defines the multi-role workflow; `docs/releasing.md`
  defines the technical steps.
