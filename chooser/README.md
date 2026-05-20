# Dotfiles chooser

This is a small React app for building a machine setup plan.

It shows target OS choices, package groups, runtime tools, editable config
blocks, and the final command to run.

## Run locally

```sh
npm install
npm run dev
```

Open:

```text
http://127.0.0.1:5173/
```

## Build

```sh
npm run build
```

The app builds to `chooser/dist`.

## Check

```sh
npm run check
```

This runs:

- package catalog validation
- ESLint
- Prettier check
- ASCII text check
- command builder tests
- TypeScript build
- Vite build

Use this before changing package data or command generation.

## What the app supports

- Ubuntu install commands through `install.sh`.
- macOS, Amazon Linux 2023, and RHEL preview commands.
- Light and dark theme toggle.
- One scrolling flow: Target, Packages, Toolchains, Config, Run.
- Version buttons for each OS target.
- Sudo user setting for the setup command.
- Root first-boot admin user creation command that prompts for a password outside the chooser.
- Saved non-secret setup preference flags.
- Package search and package group expansion.
- Chromium browser package option for Ubuntu web testing.
- Proxmox VM guest-agent package option that emits `--proxmox-guest-agent`.
- Docker or Podman strategy choices.
- Node, Python, and Java strategy choices.
- Node package manager choices. `pnpm` is the default.
- Developer tool toggles for Rust, Go, Bun, Deno, GitHub CLI, Ruby, and dotnet.
- Coding agent CLI choices after Node setup.
- `.zshrc`, `.vimrc`, `.tmux.conf`, `.gitconfig`, and `htoprc` block editing.
- Powerlevel10k setting next to `.zshrc`.
- TPM and prefix settings next to `.tmux.conf`.
- Final install command and local command.

## Data files

Main data:

- `../packages/catalog.json`: OS targets, package groups, package names,
  runtime strategies, and coding agent tools.
- `../common/`: default config file content loaded by the editor.

The Ubuntu installer still uses `../Ubuntu/packages/core.txt` and
`../Ubuntu/packages/optional.txt` for its default apt package list.

## Useful test URLs

```text
/?view=target
/?view=packages
/?view=toolchains
/?view=configs&config=zshrc
/?view=configs&config=gitconfig
/?view=summary
/?view=summary&os=macos&theme=dark
/?view=packages&os=ubuntu&group=base
/?view=toolchains&os=ubuntu&theme=dark
/?view=summary&os=ubuntu&docker=off
```

`?theme=light` and `?theme=dark` are supported for visual checks.

## Code notes

- `src/App.tsx` owns page state and UI composition.
- `src/catalog.ts` types the JSON catalog.
- `src/configDefinitions.ts` defines editable config blocks.
- `src/commandBuilder.ts` builds shell commands.
- `src/commandBuilder.test.ts` covers command behavior without a test
  framework.

Formatting rules are simple:

- Always use braces for control flow.
- A compact one-line block is fine, like `{ return value; }`.
- Keep source text ASCII.
- Use normal `"`, `'`, and `-` characters only.
