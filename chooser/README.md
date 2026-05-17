# Dotfiles chooser

React app for choosing OS setup options and copying install/config commands.

Current behavior:

- Ubuntu has a real bootstrap command through `install.sh`.
- macOS, Amazon Linux 2023, and RHEL generate package/config preview commands.
- Package names come from `../packages/catalog.json`.
- Config editors expose `.zshrc`, `.vimrc`, `.tmux.conf`, and `htoprc` content.

## Develop

```sh
npm install
npm run dev
```

## Build

```sh
npm run build
```

The Ubuntu installer still reads `../Ubuntu/packages/*.txt` for its default
package set. The chooser uses `../packages/catalog.json` so package names can
vary by OS.
