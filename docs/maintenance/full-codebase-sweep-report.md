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
