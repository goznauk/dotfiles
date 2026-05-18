# Dotfiles chooser

React app for choosing OS setup options and copying install/config commands.

Current behavior:

- Ubuntu has a real bootstrap command through `install.sh`.
- macOS, Amazon Linux 2023, and RHEL generate package/config preview commands.
- The selected OS stays in a compact target selector instead of persistent
  option cards.
- Each OS has an editable version input seeded from the current known release.
- Package names come from `../packages/catalog.json`.
- Package groups expand into a compact vertical tree with descriptions and
  resolved package names per OS.
- Docker uses an on/off toggle. When enabled, strategy choices are shown with
  the recommended path first.
- Toolchain choices cover Node, Python, Java, and containers. Optional runtime
  installs use toggles instead of visible skip cards.
- Config editors expose `.zshrc`, `.vimrc`, `.tmux.conf`, and `htoprc` as an
  editor-style block view with clickable lines, descriptions, keycaps, reorder
  controls, and editable block content.

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
