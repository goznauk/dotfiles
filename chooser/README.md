# Dotfiles chooser

React app for choosing OS setup options and copying install/config commands.

Current behavior:

- Ubuntu has a real bootstrap command through `install.sh`.
- macOS, Amazon Linux 2023, and RHEL generate package/config preview commands.
- The flow starts with four compact target buttons. After choosing a
  target, it collapses to the selected OS plus version input. Changing it again
  opens a warning modal.
- Light and dark themes use a compact icon toggle in the page header and persist
  in `localStorage`. `?theme=light` and `?theme=dark` are supported for visual
  QA.
- Target, Packages, Toolchains, Config, and Run are one scrolling flow. The slim
  section bar sticks to the top of the viewport and scrolls to each section
  instead of switching pages.
- Each OS has an editable version input seeded from the current known release.
- Package names come from `../packages/catalog.json`.
- Package groups expand into a compact vertical tree with descriptions and
  resolved package names per OS.
- Docker and runtime setup use on/off toggle controls. Disabled toolchains hide
  their strategy details. Enabled areas show the chosen strategy and keep the
  full choice list behind `Modify`.
- Toolchain choices cover Node, Python, Java, and containers. Optional runtime
  installs use toggles instead of visible skip cards.
- Powerlevel10k is configured beside `.zshrc`. TPM is configured beside
  `.tmux.conf`.
- Ubuntu commands can default to `apt update` plus bootstrap package install
  before setup, and can run setup inside a `tmux` session.
- Config editors expose `.zshrc`, `.vimrc`, `.tmux.conf`, and `htoprc` as an
  editor-style block view with clickable lines, descriptions, keycaps, reorder
  controls, reorder warnings, plugin notes, and editable block content.
- The final install command appears at the end of the flow in Run.

## Develop

```sh
npm install
npm run dev
```

## Build

```sh
npm run build
```

## Check

```sh
npm run check
```

The check command validates the package catalog, runs focused command-builder
tests, checks lint and format rules, rejects non-ASCII typography, then builds
the production app.

Formatting:

```sh
npm run format
npm run lint
```

Linting requires braces for control-flow blocks, allows compact single-line
blocks such as `{ return value; }`, and rejects smart quotes or dash-like
Unicode characters in TypeScript UI text.

Useful screenshot URLs:

```text
/?view=install
/?view=target
/?view=packages
/?view=toolchains
/?view=install&group=base
/?view=configs&config=tmux
/?view=summary
/?view=install&docker=off
```

The Ubuntu installer still reads `../Ubuntu/packages/*.txt` for its default
package set. The chooser uses `../packages/catalog.json` so package names can
vary by OS.
