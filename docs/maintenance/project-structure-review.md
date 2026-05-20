# Project Structure Review

Date: 2026-05-21
Branch: new
Reviewer: Orchestrator Agent with Structure Reviewer, Documentation, Frontend Architecture, Setup/Script, and Validation agents.

## Executive Summary

The repository structure is coherent after the maintenance sweep and chooser UI work. The main public paths remain stable: `setup.sh`, `install.sh`, `Ubuntu/`, `common/`, `packages/`, `chooser/`, `scripts/`, and `docs/`.

No broad file moves are recommended for this branch. The highest-value cleanup was documentation-oriented: make the top-level structure list more complete, add an index for maintenance reports, and document deferred structural recommendations rather than moving files late in an active PR.

## Current Structure Overview

- `README.md`: root orientation and quick commands.
- `setup.sh` and `install.sh`: local dispatcher and remote bootstrap entry points.
- `Ubuntu/`: active setup implementation, package lists, and Ubuntu-specific docs.
- `MacOS/`: clearly legacy macOS setup path.
- `common/`: shared dotfiles installed into the target home directory.
- `packages/`: shared package catalog used by the chooser.
- `scripts/`: repo validation, catalog checks, setup invariants, and text policy checks.
- `chooser/`: React/Vite chooser app, package scripts, tests, and source modules.
- `docs/`: integration notes and maintenance reports.
- `fonts/`: Powerlevel10k MesloLGS font assets and license.

## Findings By Area

### Directory Layout

The top-level directories are clear and necessary. OS-specific setup files are under `Ubuntu/` and `MacOS/`; shared dotfiles are under `common/`; package catalog data is under `packages/`; validation helpers are under `scripts/`; and the chooser app is self-contained under `chooser/`.

Maintenance reports are correctly separated under `docs/maintenance/`. A small index was missing, so `docs/maintenance/README.md` was added to distinguish historical work logs from user-facing docs.

### Naming And Stale References

The current chooser ownership is clear across the source tree and maintenance index: `chooser/src/main.tsx` is the React entry wrapper and `chooser/src/App.tsx` owns page state and UI composition. `chooser/README.md` documents the `App.tsx` ownership, while the maintenance index calls out the `main.tsx` entry wrapper. Some older maintenance notes still mention `chooser/src/main.tsx` as the then-current app surface, which is acceptable as historical iteration context.

The `MacOS/` directory uses legacy capitalization, but renaming it would risk breaking existing paths and docs. Leave it as-is and continue to mark it as legacy.

### Documentation

Root docs and setup docs point to existing files and current commands. The root `README.md` now also lists `scripts/` and `docs/`, which were previously omitted from the structure overview.

Maintenance reports reference `.tmp/` screenshot paths. That is acceptable inside maintenance reports because those paths are QA evidence, and the new maintenance index clarifies that screenshots are temporary and not committed.

### Chooser App Structure

The chooser boundaries are much better than the historical single-file app state. Command generation is in `chooser/src/commandBuilder.ts`, catalog typing is in `chooser/src/catalog.ts`, config definitions are in `chooser/src/configDefinitions.ts`, and ID constants are in `chooser/src/ids.ts`.

Remaining size risks:

- `chooser/src/App.tsx`: about 2162 lines.
- `chooser/src/styles.css`: about 2072 lines.
- `Ubuntu/setup-ubuntu.sh`: about 1497 lines.

These are real maintainability risks but not good candidates for late broad movement in this PR. Future refactors should be behavior-preserving and test-backed.

### Setup And Scripts

Setup-related files are grouped sensibly. `Ubuntu/setup-ubuntu.sh` owns the active Linux setup path, `Ubuntu/packages/` owns default apt package lists, `packages/catalog.json` owns chooser package choices, and `scripts/validate-catalog.mjs` plus `scripts/check-ubuntu-apt-setup.mjs` guard the cross-file assumptions. The two package directories are easy to confuse, so the root README now describes the distinction explicitly.

Proxmox guest-agent, first-boot admin user setup, tmux prefix preferences, and tmux helpers are documented in Ubuntu/chooser docs and guarded by focused checks.

The setup/script review found one documentation mismatch: `Ubuntu/README.md` previously implied optional apt packages are skipped individually when missing, but the current installer installs the resolved package set as a single apt batch. The docs were corrected to match current behavior; making optional installs truly best-effort is deferred as a behavior change.

### Git Hygiene

Tracked files do not include `.tmp/`, `chooser/dist/`, `chooser/node_modules/`, screenshots, or generated screenshot manifests. Local ignored files currently include `.DS_Store`, `.tmp/`, `chooser/dist/`, and `chooser/node_modules/`, which is expected.

The repository also has local empty directories `docs/superpowers/` and `new/` in the working tree. They are not tracked and do not appear in `git status` because Git does not track empty directories. No repository change was made for them.

## Changes Implemented

- Added `docs/maintenance/README.md` as an index and scope note for maintenance reports.
- Added `docs/maintenance/project-structure-review.md` with current findings, risks, and validation evidence.
- Updated `README.md` so the structure overview includes `scripts/`, `docs/`, `Ubuntu/packages/`, and the distinction between the chooser catalog and installer apt lists.
- Clarified `docs/pages-integration.md` so this repository's Pages workflow and external `goznauk.com` integration path are separate.
- Added a historical baseline note to `docs/maintenance/full-codebase-sweep-report.md` and clarified the stale `main.tsx` complexity reference.

## Deferred Recommendations

- Split `chooser/src/App.tsx` into smaller view/panel modules if more UI work lands.
- Split `chooser/src/styles.css` by major app surface or section if style changes continue.
- Split `Ubuntu/setup-ubuntu.sh` into sourced helper files only if a test-backed shell module boundary is introduced first.
- Add config-definition tests for block ranges and generated config content before changing the current line-slice model.
- Harden the config write-command heredoc delimiter before making the Config editor a primary workflow for arbitrary user edits.
- Make Ubuntu optional package installation truly best-effort, or keep docs explicit that missing optional packages can fail the combined apt install.
- Add `openssh-server` to the chooser catalog or document/validate why it remains only in `Ubuntu/packages/optional.txt`.
- Clarify `DOTFILES_REPO_REF` branch-versus-detached-ref behavior before encouraging tag or commit-SHA bootstrap use.
- Centralize ASCII validation in `scripts/check-ascii.mjs` if text-policy roots keep growing.
- Consider warning in `setup.sh` when macOS is auto-detected, because `MacOS/` is intentionally legacy.
- Decide separately whether `.github/workflows/pages.yml` should run `npm run check` instead of only `npm run build`.
- Keep `MacOS/` capitalization and location for compatibility, despite the modern spelling convention usually being `macOS`.
- Consider a committed lightweight browser smoke script only if visual QA becomes routine.

## Validation Results

Validation was run after this review and passed:

- `git status --short --branch`
- `git ls-files`
- `git diff --check`
- `npm --prefix chooser run lint`
- `npm --prefix chooser run build`
- `./scripts/check.sh`

Additional hygiene checks found no tracked `.tmp`, screenshot, `dist`, or `node_modules` artifacts. The known environment warning remains: tmux cannot start in this sandbox, so `.tmux.conf` live-load validation is skipped by `./scripts/check.sh` while the script exits successfully.

## Remaining Risks

The main remaining risk is module size, not directory placement. The repository should avoid broad structure churn until there is a concrete implementation need and enough test coverage to protect behavior.
