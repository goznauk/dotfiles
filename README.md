# Dotfiles

Personal setup files for development machines.

The active path is Ubuntu. macOS is kept for old rebuilds, but it is not the main target right now.

## What is here

- `Ubuntu/setup-ubuntu.sh`: Ubuntu installer.
- `common/`: shared `.zshrc`, `.vimrc`, `.tmux.conf`, `.gitconfig`, and global Git ignore file.
- `packages/catalog.json`: package names for Ubuntu, macOS, Amazon Linux 2023, and RHEL.
- `chooser/`: React app that builds setup commands and config files.
- `MacOS/`: legacy Homebrew setup path.
- `fonts/`: MesloLGS NF files for Powerlevel10k.

## Quick Ubuntu run

Interactive:

```sh
./setup.sh ubuntu
```

Recommended local run:

```sh
sudo apt update
sudo apt install -y tmux
tmux new-session -A -s dotfiles './setup.sh ubuntu --yes'
```

Preview the Ubuntu plan without changing the machine:

```sh
./setup.sh ubuntu --dry-run --target-version 26.04
```

For Proxmox/QEMU VMs, opt into the guest agent:

```sh
./setup.sh ubuntu --yes --proxmox-guest-agent
```

For a first root login on a fresh VM, create the normal sudo user first:

```sh
sudo ./Ubuntu/setup-ubuntu.sh --create-admin-user --admin-user john --save-setup-preferences
su - john
```

The password is prompted interactively and is not stored.

See [Ubuntu setup](./Ubuntu/README.md) for user setup, package lists, runtime tools, Node package manager choices, Git identity, Vim, tmux, Docker, and OS notes.

## Web chooser

The chooser is a local web app for selecting a target OS, sudo user, packages, runtime tools, config blocks, and the final install command.

```sh
cd chooser
npm install
npm run dev
```

Open:

```text
http://127.0.0.1:5173/
```

See [Chooser](./chooser/README.md) for development and check commands.

## Pages

The chooser can be published as a static app or copied into `goznauk.com` during that site's build.

See [Pages integration](./docs/pages-integration.md).

## macOS

The macOS setup is legacy and uses `.env`.

```sh
cp .env.example .env
vim .env
./setup.sh macos
```

See [macOS setup](./MacOS/README.md).

## Check

Run this before merging:

```sh
./scripts/check.sh
```

The check script validates the package catalog, chooser TypeScript build, lint rules, shell syntax, JSON files, text policy, and Git diff whitespace.
