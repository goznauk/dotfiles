# Full Codebase Sweep Report

This report tracks a ten-iteration maintenance sweep on branch `new`.

Generated artifacts, dependency folders, binary font files, and lockfile
internals are not summarized unless they affect behavior or verification.

## Baseline File Notes

### Repository entry points

- `README.md`: Top-level orientation for Ubuntu, chooser, pages integration, and
  legacy macOS setup. It connects users to `Ubuntu/README.md`,
  `docs/pages-integration.md`, and `chooser/README.md`. Risk: it does not list
  repository validation commands yet. Improvement: add a maintenance checklist
  after validation scripts exist.
- `setup.sh`: Dispatches to Ubuntu or macOS setup based on the target argument
  or host OS. It is the local entry point used by the chooser command. Risk:
  auto-detect maps all Linux hosts to Ubuntu and relies on the Ubuntu script to
  warn. Improvement: document target behavior and keep shell syntax checks.
- `install.sh`: Remote bootstrap entry point. It clones or updates the repo,
  checks out the selected ref, pulls fast-forward, then executes `setup.sh`.
  Risk: network and ref checkout errors stop setup, which is correct. Improvement:
  guard against an invalid install directory path if needed later.
- `.env.example`: Legacy macOS package and Git profile sample. It is read only
  after copying to `.env`. Risk: `GIT_PROFILE_COMPANY_SEPERATE` is misspelled
  and the current macOS script does not use those Git profile fields.

### Ubuntu setup

- `Ubuntu/setup-ubuntu.sh`: Main Ubuntu installer. It parses setup options,
  loads package lists, links dotfiles, installs shell plugins, uv, Rust, Node,
  Python, Java, and container runtime options. Risk: parsing logic is repeated,
  Docker preview and install behavior can drift from the chooser, and package
  list validation is manual. Improvement: add repo-local validation that checks
  catalog and Ubuntu package list consistency.
- `Ubuntu/packages/core.txt`: Required apt package list for development hosts.
  It feeds the default Ubuntu installer path. Risk: catalog and core list can
  drift. Improvement: validate that selected Ubuntu catalog packages are covered.
- `Ubuntu/packages/optional.txt`: Best-effort apt package list. The installer
  skips missing optional packages. Risk: optional package names can duplicate
  catalog entries or be unavailable on a target release. Improvement: validate
  duplicate package entries.
- `Ubuntu/README.md`: Documents Ubuntu use, package lists, dotfile links, Vim,
  tmux, OS notes, and Docker caveats. Risk: examples can drift from script
  options. Improvement: add version and toolchain examples after script checks.

### Common dotfiles

- `common/.zshrc`: zsh config, path setup, oh-my-zsh plugins, mise, direnv,
  aliases, tmux helpers, and small functions. Risk: plugin load order can fail
  if optional plugin dirs are missing, but oh-my-zsh handles absent plugins with
  warnings. Improvement: keep destructive aliases explicit and add syntax checks.
- `common/.vimrc`: Small Vim setup with vim-plug bootstrap and two plugins.
  Risk: plugin bootstrap uses network unless `DOTFILES_SKIP_NETWORK=1`; tests
  should set that variable. Improvement: add a validation command.
- `common/.tmux.conf`: tmux config with `C-a` prefix, pane/window bindings, copy
  mode, status line, and optional TPM block. Risk: clipboard copy command is
  Linux-first and may no-op on macOS. Improvement: validate syntax locally.
- `common/.gitconfig`: Git defaults, aliases, core editor and exclude file.
  Risk: includes `~/.gitconfig.local`, which must exist or Git may warn.
- `common/.gitexclude`: Global ignore patterns for OS files, local env, Node,
  Python, and build output. Risk: broad `dist/` ignores generated chooser output
  as intended.

### macOS setup

- `MacOS/setup-mac.sh`: Legacy Homebrew installer driven by `.env`. Risk: lacks
  `set -euo pipefail`, relies on `ENVPATH`, and uses interactive prompts only.
  Improvement: harden basics without expanding macOS scope.
- `MacOS/README.md`: Legacy checklist for manual macOS setup and old app list.
  Risk: app list is historical and not connected to script behavior.
- `MacOS/config_files/Karabiner_KorEng.json`: Karabiner complex modification for
  Korean and Hanja key behavior. Risk: formatting is inconsistent but JSON is
  valid. Improvement: keep validation in repo checks.
- `MacOS/config_files/iStat Menus Settings.ismp`: Legacy iStat Menus XML export.
  It is not read by scripts. Risk: line endings are mixed and the file is tool
  generated, so leave it unchanged unless needed.

### Package catalog

- `packages/catalog.json`: Shared chooser catalog for OS targets, package groups,
  package names, and runtime strategies. It drives package search, command
  generation, and target version defaults. Risk: JSON has no schema validation,
  duplicate package names can creep in, and strategy defaults can be invalid.
  Improvement: add validation script.

### Chooser app

- `chooser/package.json`: React/Vite package scripts. Risk: only `build` exists,
  so validation requires manual shell commands. Improvement: add `check`.
- `chooser/package-lock.json`: Dependency lockfile. Risk: inspect only through
  package manager checks, not by hand.
- `chooser/tsconfig.json`: Strict TypeScript config for the chooser. Risk:
  `skipLibCheck` is pragmatic for app speed.
- `chooser/vite.config.ts`: Vite config with relative base for GitHub Pages,
  React plugin, source alias, local host, and limited fs allow. Risk: aliases are
  lightly used and `fs.allow` must remain broad enough for raw dotfile imports.
- `chooser/index.html`: Static app shell and metadata. Risk: description says
  Ubuntu even though previews cover multiple OS targets. Improvement: update copy.
- `chooser/src/vite-env.d.ts`: Raw import typing. Low risk.
- `chooser/src/main.tsx`: Main React app, state model, config block editor,
  package catalog UI, command generation, and summary. Risk: it is too large,
  pure command helpers are not tested independently, clipboard errors are not
  handled, and catalog data is cast without runtime validation. Improvements:
  split helpers or add focused validation first, then improve type boundaries.
- `chooser/src/styles.css`: Full app styling. Risk: large single stylesheet,
  compact package rows and command previews need responsive checks after UI
  edits. Improvement: keep visual checks on desktop and mobile.
- `chooser/README.md`: Chooser behavior and development notes. Risk: useful QA
  URLs omit newer version/group query URLs. Improvement: document them.
- `docs/pages-integration.md`: Instructions for mounting the chooser under
  `goznauk.com`. Risk: workflow example can drift from package scripts.

## Iteration 1

### Files and areas inspected

Repository entry points, Ubuntu installer and package lists, common dotfiles,
legacy macOS setup, package catalog, chooser app source/config/docs, GitHub Pages
integration notes, Karabiner JSON, binary asset inventory.

### Main findings

- The codebase is small enough for direct maintenance, but two files carry most
  complexity: `Ubuntu/setup-ubuntu.sh` and `chooser/src/main.tsx`.
- There is no single repo validation command.
- Package catalog data and Ubuntu package files can drift silently.
- The chooser has strict TypeScript checks, but command helpers and catalog data
  have no focused tests.
- The macOS setup path is intentionally legacy and should only receive safety
  hardening unless the scope changes.

### Improvements implemented

- Added this maintenance report with baseline file-level notes and the first
  prioritized sweep findings.

### Tests and checks run

- `git status --short --branch`
- `rg --files -g '!chooser/dist' -g '!chooser/node_modules' -g '!**/.git/**'`
- `python3 -m json.tool packages/catalog.json`
- `python3 -m json.tool MacOS/config_files/Karabiner_KorEng.json`
- `npm run build`
- `bash -n setup.sh install.sh Ubuntu/setup-ubuntu.sh MacOS/setup-mac.sh`
- `zsh -n common/.zshrc`
- `env DOTFILES_SKIP_NETWORK=1 vim -Nu common/.vimrc -n -es -c qall`
- `git diff --check`
- Smart quote and long dash scan across chooser, packages, Ubuntu, common,
  top-level scripts, README files, `.env.example`, and docs.

### Commits created

- Pending commit for this report.

### Deferred items

- Add a repo-local validation script and package consistency checks.
- Harden legacy macOS script basics.
- Split or test chooser command generation.
- Improve copy failure handling and summary empty states.

## Iteration 2

### Files and areas inspected

`packages/catalog.json`, `Ubuntu/packages/core.txt`,
`Ubuntu/packages/optional.txt`, `chooser/package.json`, `chooser/README.md`,
top-level `README.md`, and validation command structure.

### Main findings

- The chooser and Ubuntu installer both depend on package catalog consistency,
  but the repository had no automated catalog checks.
- Selected Ubuntu package names need to stay aligned with the apt package lists
  because the chooser emits an exact `--apt-packages` list.
- Package notes are now part of the UI, so missing notes reduce usefulness of
  the expanded package tree.

### Improvements implemented

- Added `scripts/validate-catalog.mjs`.
- Added `npm run check` for chooser validation plus production build.
- Documented the check command and added an expanded package screenshot URL.

### Tests and checks run

- `node scripts/validate-catalog.mjs`
- `npm run check`
- `bash -n setup.sh install.sh Ubuntu/setup-ubuntu.sh MacOS/setup-mac.sh`

### Commits created

- Pending commit for catalog validation.

### Deferred items

- Add shell and dotfile validation to one repo-level command.
- Consider focused tests for command generation after helper extraction.

## Iteration 3

### Files and areas inspected

`scripts/validate-catalog.mjs`, shell scripts, common dotfiles, JSON config
files, `README.md`, and validation flow from the repository root.

### Main findings

- Validation still required several manual commands.
- The local environment does not allow a tmux server to start from this sandbox,
  so tmux config loading must be optional in automated local checks.
- The repository text policy can be checked with an ASCII scan over source and
  docs while excluding generated and dependency folders.

### Improvements implemented

- Added `scripts/check.sh` as a root-level validation command.
- The script runs chooser checks, shell syntax checks, zsh syntax, Vim config
  load with network disabled, optional tmux config load, JSON parsing, ASCII
  text policy scan, and `git diff --check`.
- Updated top-level README validation instructions to use `./scripts/check.sh`.

### Tests and checks run

- `./scripts/check.sh`

The check passed. Vite printed a Node version warning because this shell used
Node 22.9.0, while Vite asks for 20.19+ or 22.12+ in the Node 22 line. The
build still completed with exit code 0.

### Commits created

- Pending commit for root validation.

### Deferred items

- Add command-helper tests after extracting pure chooser command logic.

## Iteration 4

### Files and areas inspected

`MacOS/setup-mac.sh`, `.env.example`, `MacOS/README.md`, `setup.sh`, and the
root validation script.

### Main findings

- The macOS script was intentionally legacy but still lacked basic Bash safety
  settings.
- The script assumed `ENVPATH` was set by the dispatcher and failed unclearly if
  `.env` was missing.
- Package installation used unquoted word splitting.

### Improvements implemented

- Rewrote `MacOS/setup-mac.sh` with `set -euo pipefail`, usage handling,
  `--yes`, explicit `.env` validation, safer prompts, and quoted package array
  installs.
- Kept the legacy script scope limited to Homebrew packages and Java cask.
- Documented the non-interactive macOS path.

### Tests and checks run

- `./scripts/check.sh`

The check passed with the same Vite Node version warning and the sandbox tmux
skip warning.

### Commits created

- Pending commit for macOS script hardening.

### Deferred items

- The old Git profile fields in `.env.example` are still not used by the macOS
  script; leave them until the macOS path is actively rebuilt.

## Iteration 5

### Files and areas inspected

`chooser/src/main.tsx`, command generation helpers, install step definitions,
config write command generation, and chooser build output.

### Main findings

- `chooser/src/main.tsx` mixed UI rendering with command construction,
  preview command generation, shell quoting, and install step metadata.
- Command construction is a stable domain boundary and should be easier to test
  than the full React app.

### Improvements implemented

- Added `chooser/src/commandBuilder.ts`.
- Moved repository constants, install step metadata, shell quoting, setup command
  generation, package preview generation, and config write command generation
  out of the React entry file.
- Reduced `chooser/src/main.tsx` by about 190 lines while preserving behavior.

### Tests and checks run

- `npm run build`
- `./scripts/check.sh`

The root check passed with the known Vite Node version warning and tmux sandbox
skip warning.

### Commits created

- Pending commit for command builder extraction.

### Deferred items

- Add direct tests for `commandBuilder.ts`.
- Continue splitting catalog selection helpers from `main.tsx`.

## Iteration 6

### Files and areas inspected

`chooser/src/commandBuilder.ts`, command output behavior, chooser npm scripts,
TypeScript test compilation, `.gitignore`, and chooser README.

### Main findings

- The extracted command builder contains critical shell quoting and flag logic
  that should be covered without launching the React app.
- Adding a full test framework would be unnecessary for this repository right
  now; TypeScript plus a small Node test is enough for the command boundary.

### Improvements implemented

- Added `chooser/src/commandBuilder.test.ts`.
- Added `chooser/tsconfig.test.json` to compile command tests to `.tmp`.
- Added `npm run test:commands` and included it in `npm run check`.
- Ignored `.tmp/` and documented the command-builder test coverage.

### Tests and checks run

- `npm run test:commands`
- `npm run build`
- `./scripts/check.sh`

The root check passed with the known Vite Node version warning and tmux sandbox
skip warning.

### Commits created

- Pending commit for command-builder tests.

### Deferred items

- Add UI smoke coverage only if a lightweight browser test path becomes stable
  enough for this repo.

## Iteration 7

### Files and areas inspected

`chooser/src/main.tsx`, `chooser/src/styles.css`, summary view, command copy
buttons, browser DOM output, and responsive screenshot output.

### Main findings

- Clipboard writes can fail in browser contexts, but the UI previously had no
  visible fallback or status.
- Copy buttons all had the same visible text, so assistive technologies could
  not distinguish which command would be copied.
- The summary package panel rendered an empty block if every package was
  disabled.

### Improvements implemented

- Added copy failure handling with a visible `role="status"` message.
- Added descriptive `aria-label` text to command copy buttons.
- Added an explicit empty package message in the summary view.
- Added styling for copy failure status.

### Tests and checks run

- `npm run build`
- Browser DOM check for summary view, copy labels, and console errors
- Headless Chrome screenshot:
  `/private/tmp/dotfiles-chooser/summary-ux-iteration7.png`
- `./scripts/check.sh`

The root check passed with the known Vite Node version warning and tmux sandbox
skip warning.

### Commits created

- Pending commit for chooser UX hardening.

### Deferred items

- Browser screenshot through the in-app browser runtime still times out in this
  environment, so visual capture uses headless Chrome as the fallback.

## Iteration 8

### Files and areas inspected

Top-level repository conventions, Ubuntu README examples, Pages integration
workflow notes, validation commands, and source formatting expectations.

### Main findings

- The repository had no editor-level formatting guidance.
- Ubuntu README examples did not show the newer target version, Python, and Java
  strategy flags.
- Pages integration still referenced `npm run build`, missing the stronger
  `npm run check` path.

### Improvements implemented

- Added `.editorconfig` for consistent line endings, final newlines, and
  two-space indentation in source and docs.
- Updated Ubuntu README examples for target version, Python, and Java strategy
  flags.
- Updated Pages integration to run `npm run check`.

### Tests and checks run

- `./scripts/check.sh`

The root check passed with the known Vite Node version warning and tmux sandbox
skip warning.

### Commits created

- Pending commit for developer documentation and formatting conventions.

### Deferred items

- Add CI workflow only when this branch is ready to publish automation.

## Iteration 9

### Files and areas inspected

`Ubuntu/setup-ubuntu.sh`, Ubuntu package resolution flow, script help text,
Ubuntu README examples, and root validation.

### Main findings

- Package resolution existed only inside the apt install function, which made
  previewing installer choices harder.
- The Ubuntu setup script had no safe built-in way to inspect resolved package
  choices before making system changes.

### Improvements implemented

- Extracted shared `resolve_apt_packages`.
- Added `--dry-run` to print selected steps, toolchain strategies, target
  version, TPM choice, and resolved apt packages without touching the system.
- Added an explicit Bash 4+ guard for the Ubuntu installer.
- Documented the dry-run command.

### Tests and checks run

- `bash Ubuntu/setup-ubuntu.sh --dry-run --target-version 26.04`
- `bash -n Ubuntu/setup-ubuntu.sh`
- `./scripts/check.sh`

The dry-run command reached the new Bash version guard on this macOS host,
which uses Bash 3.2. The script targets Ubuntu, where Bash 4+ is available by
default. The root check passed with the known Vite Node version warning and
tmux sandbox skip warning.

### Commits created

- Pending commit for Ubuntu dry-run support.

### Deferred items

- The chooser does not expose `--dry-run` as a UI option because its command
  panel is already a preview surface.

## Iteration 10

### Files and areas inspected

`scripts/check.sh`, `.editorconfig`, `.gitignore`, maintained macOS text files,
Karabiner JSON, docs, shell scripts, package catalog, and final validation
coverage.

### Main findings

- The root ASCII/text policy scan did not cover `.editorconfig`, `.gitignore`,
  or maintained macOS text files.
- These files are part of the reviewed source surface and should be checked
  before final verification.

### Improvements implemented

- Expanded `scripts/check.sh` ASCII/text policy coverage to include
  `.editorconfig`, `.gitignore`, `MacOS/README.md`, `MacOS/setup-mac.sh`, and
  `MacOS/config_files/Karabiner_KorEng.json`.

### Tests and checks run

- `./scripts/check.sh`

The root check passed with the known Vite Node version warning and tmux sandbox
skip warning.

### Commits created

- Pending commit for check coverage hardening.

### Deferred items

- Binary fonts and the legacy iStat Menus export remain outside text policy
  scans because they are tool assets rather than maintained source text.
