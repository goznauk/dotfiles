# Dotfiles chooser

React app for choosing OS setup options and copying install/config commands.

Current behavior:

- Ubuntu has a real bootstrap command through `install.sh`.
- macOS, Amazon Linux 2023, and RHEL generate package/config preview commands.
- The install page starts with four compact target buttons. After choosing a
  target, it collapses to the selected OS plus version input. Changing it again
  opens a warning modal.
- Each OS has an editable version input seeded from the current known release.
- Package names come from `../packages/catalog.json`.
- Package groups expand into a compact vertical tree with descriptions and
  resolved package names per OS.
- Docker and runtime setup use on/off toggle controls. When enabled, each area
  shows the chosen strategy and keeps the full choice list behind `Modify`.
- Toolchain choices cover Node, Python, Java, and containers. Optional runtime
  installs use toggles instead of visible skip cards.
- Shell preferences include Powerlevel10k and TPM toggles. TPM is still tied to
  the `.tmux.conf` plugin block.
- Ubuntu commands can default to `apt update` plus bootstrap package install
  before setup, and can run setup inside a `tmux` session.
- Config editors expose `.zshrc`, `.vimrc`, `.tmux.conf`, and `htoprc` as an
  editor-style block view with clickable lines, descriptions, keycaps, reorder
  controls, reorder warnings, plugin notes, and editable block content.

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
tests, then builds the production app.

Useful screenshot URLs:

```text
/?view=install
/?view=install&group=base
/?view=configs&config=tmux
/?view=summary
/?view=install&docker=off
```

The Ubuntu installer still reads `../Ubuntu/packages/*.txt` for its default
package set. The chooser uses `../packages/catalog.json` so package names can
vary by OS.
