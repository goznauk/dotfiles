# UI UX Review

Date: 2026-05-20
Branch: new
App: chooser
Local URL: http://127.0.0.1:5173/

## Summary

The chooser is running locally and answers on port 5173. The current Ubuntu
flow shows the target picker, sudo user setting, visible version buttons,
package selection, toolchain choices, config editing, and final command output.

This file is a work log for the UI state after the recent Ubuntu setup changes.
It is not the main user manual. For normal usage, start with `README.md`,
`Ubuntu/README.md`, and `chooser/README.md`.

## Current UI Checks

- Local server answered `HTTP/1.1 200 OK`.
- Browser opened the target section at the local chooser URL.
- The page title is `Dotfiles Chooser`.
- The target page shows `goznauk/dotfiles`.
- Ubuntu version buttons are visible, including `24.04 LTS`.
- The summary command keeps the selected Ubuntu version after moving between
  sections.
- Chromium is included in the default Ubuntu package command as
  `chromium-browser`.
- No horizontal page overflow was found in the checked browser view.

## Areas Reviewed

- Target OS row and version choices.
- Sudo user setting.
- Package catalog and default Ubuntu package command.
- Toolchain defaults for Node, pnpm, Python, developer tools, and agent CLIs.
- Summary command output.
- Dark theme layout.

## Changes Covered By This Review

- Ubuntu version choice changed from a datalist input to visible buttons.
- Chromium browser was added as a default Ubuntu package option.
- Ubuntu `universe` repository setup was added before apt package install.
- Sudo user setup was added to the command and installer.
- Developer tools were added as options, with Rust, Go, Bun, Deno, and GitHub
  CLI on by default.
- Node package manager choice was added, with pnpm as the default.

## Validation

- `curl -I http://127.0.0.1:5173`
- `./scripts/check.sh`
- Browser smoke check against the local chooser page.

## Notes

- macOS, Amazon Linux 2023, and RHEL remain preview targets in the chooser.
- Ubuntu is still the main implemented installer path.
- Chromium on Ubuntu uses the `chromium-browser` apt package. On supported
  Ubuntu releases this is a transitional package that installs the Chromium
  snap.
- If Docker is installed, the configured admin user is added to the `docker`
  group. A new login session is needed before that group change is active.
