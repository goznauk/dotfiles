# Dotfiles chooser

React app for choosing OS setup options and copying install/config commands.

Current behavior:

- Ubuntu has a real bootstrap command through `install.sh`.
- macOS, Amazon Linux 2023, and RHEL generate package/config preview commands.
- The selected OS stays in a compact target selector instead of persistent
  option cards.
- Package names come from `../packages/catalog.json`.
- Docker uses an on/off toggle. When enabled, strategy choices are shown with
  the recommended path first.
- Config editors expose `.zshrc`, `.vimrc`, `.tmux.conf`, and `htoprc` as
  selectable, reorderable blocks with descriptions, keycaps, and editable block
  content.

## Develop

```sh
npm install
npm run dev
```

## Build

```sh
npm run build
```

Useful screenshot URLs:

```text
/?view=install
/?view=configs&config=tmux
/?view=summary
/?view=install&docker=off
```

The Ubuntu installer still reads `../Ubuntu/packages/*.txt` for its default
package set. The chooser uses `../packages/catalog.json` so package names can
vary by OS.
