# RC Files Design

## Goal

Make the generated rc files predictable for development machines and safe for automation while keeping the interactive terminal workflow compact.

## Scope

- Update `.zshrc`, `.vimrc`, `.tmux.conf`, and `.gitconfig`.
- Update the chooser config editor so ordering risks and dependencies are visible.
- Keep destructive command aliases explicit, not automatic.
- Keep plugin managers optional or installer-managed rather than hidden runtime downloads.

## Design

`.zshrc` should be interactive-shell only. It should preserve a small pre-load hook for local machine setup, keep prompt bootstrap near the top, use conservative history options, avoid forced locale overrides, and load post-framework local customizations at the end.

`.vimrc` should not download vim-plug from inside Vim startup. The installer can provide vim-plug; the rc file only uses it when present. Autocommands should live in an augroup so sourcing the file does not duplicate them.

`.tmux.conf` should keep Ctrl-A behavior and current pane/session workflow, add truecolor and macOS clipboard fallback, and keep TPM commented by default.

`.gitconfig` should keep personal identity out of the shared file while adding safer merge and diff defaults.

The chooser should classify config blocks as locked, ordered, side effect, or free. Moving or disabling a block should show the reason when order matters.

## Verification

- Run the chooser command tests and build.
- Run repository checks through `./scripts/check.sh`.
- Check the generated rc files with the existing shell and tmux validation where available.
