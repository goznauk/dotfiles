# Ubuntu setup

This setup is for a development machine.

It installs shell tools, build tools, Python, Rust, Node, Vim, tmux, Docker or
Podman, Git defaults, and small system inspection tools.

Ubuntu ships Bash 4 or newer, which this script needs. Ubuntu 25.04 reached end
of life on 2026-01-15. The script still runs on it, but use Ubuntu 24.04 LTS or
26.04 LTS when possible.

## Run

Interactive:

```sh
./setup.sh ubuntu
```

One-shot:

```sh
./setup.sh ubuntu --yes
```

Recommended local run:

```sh
sudo apt update
sudo apt install -y tmux
tmux new-session -A -s dotfiles './setup.sh ubuntu --yes'
```

Dry run:

```sh
./setup.sh ubuntu --dry-run --target-version 26.04
```

## Common flags

```sh
./setup.sh ubuntu --yes --skip-apt
./setup.sh ubuntu --yes --skip-tools
./setup.sh ubuntu --yes --skip-shell
./setup.sh ubuntu --yes --skip-dotfiles
./setup.sh ubuntu --yes --target-version 26.04
./setup.sh ubuntu --yes --apt-packages git,zsh,vim,tmux
./setup.sh ubuntu --yes --optional-packages bat,eza,btop
./setup.sh ubuntu --yes --no-optional-packages
```

Tool choices:

```sh
./setup.sh ubuntu --yes --docker-strategy official
./setup.sh ubuntu --yes --docker-strategy distro
./setup.sh ubuntu --yes --docker-strategy podman
./setup.sh ubuntu --yes --docker-strategy none
./setup.sh ubuntu --yes --node-strategy mise
./setup.sh ubuntu --yes --node-strategy nvm
./setup.sh ubuntu --yes --python-strategy system-uv
./setup.sh ubuntu --yes --python-strategy mise
./setup.sh ubuntu --yes --java-strategy mise-temurin-21
./setup.sh ubuntu --yes --java-strategy distro-openjdk-21
./setup.sh ubuntu --yes --agent-tools claude-code,openai-codex
./setup.sh ubuntu --yes --no-agent-tools
```

Config choices:

```sh
./setup.sh ubuntu --yes --with-tpm
./setup.sh ubuntu --yes --no-powerlevel10k
```

## Install steps

The installer has four main steps:

1. Apt packages.
2. Shell setup.
3. Dotfile links.
4. uv, Rust, language runtimes, and coding agent CLIs.

Use `--skip-apt`, `--skip-shell`, `--skip-dotfiles`, or `--skip-tools` to skip a
step.

## Apt packages

Default apt package lists live here:

- `Ubuntu/packages/core.txt`: required packages.
- `Ubuntu/packages/optional.txt`: best effort packages.

Missing required packages stop the apt install. Missing optional packages are
skipped with a warning.

The chooser uses `packages/catalog.json` to map one package choice to different
package names on Ubuntu, macOS, Amazon Linux 2023, and RHEL. Ubuntu commands can
pass the resolved names through `--apt-packages`.

Use one package name per line in the text files. Blank lines and lines starting
with `#` are ignored.

## Runtime tools

Python:

- Default: system Python packages plus `uv` and `pipx`.
- Optional: `mise` managed Python with `--python-strategy mise`.

Rust:

- Installed through `rustup`.
- Adds `rustfmt` and `clippy`.

Node:

- Default: Node LTS through `mise`.
- Optional: `nvm` with `--node-strategy nvm`.
- The zsh config activates `mise` when it exists.
- The installer enables `.nvmrc` and `.node-version` support for `mise`.

Coding agent CLIs:

- Default: Claude Code and OpenAI Codex CLI.
- They install through npm after Node is ready.
- With the default `mise` Node setup, npm runs through `mise exec node@lts` so an
  older system npm is not used.
- Use `--no-agent-tools` to skip them.

Java:

- Optional and off by default.
- Use `--java-strategy mise-temurin-21` or
  `--java-strategy distro-openjdk-21`.

## Docker and Podman

Container runtime choices:

- `official`: Docker official apt repository.
- `distro`: Ubuntu `docker.io` packages.
- `podman`: Podman plus Docker-compatible CLI behavior.
- `none`: no container runtime.

After the installer adds your user to the Docker group, log out and back in.

For Ubuntu 25.04, prefer upgrading the OS. If you keep using it, choose
`--docker-strategy distro`, `--docker-strategy podman`, or
`--docker-strategy none`.

## Dotfiles

The installer links these files into `$HOME`:

- `common/.zshrc` to `~/.zshrc`
- `common/.vimrc` to `~/.vimrc`
- `common/.tmux.conf` to `~/.tmux.conf`
- `common/.gitconfig` to `~/.gitconfig`
- `common/.gitexclude` to `~/.gitexclude`

Existing files are moved to `*.backup.YYYYMMDDHHMMSS` before links are made.

Local files:

- `~/.zshrc.local.pre`: loaded before prompt setup.
- `~/.zshrc.local`: loaded at the end of `.zshrc`.
- `~/.gitconfig.local`: local Git identity.

## Git identity

Shared Git defaults live in `common/.gitconfig`. Personal name and email stay in
`~/.gitconfig.local`, which the installer creates if it is missing.

For one account:

```ini
[user]
	name = Your Name
	email = you@example.com
```

For different work and personal identities, use `includeIf`. The base
`.gitconfig` has commented examples for `~/work/` and `~/personal/`.

Example `~/.gitconfig.work`:

```ini
[user]
	name = Your Name
	email = you@company.com
```

## Shell

Powerlevel10k is the default zsh prompt. Use `--no-powerlevel10k` to keep the
default oh-my-zsh prompt. The installer records that choice in `~/.zshrc.local`.

`rm`, `cp`, and `mv` are not aliased. Use these only when you want prompts:

- `rmi` for `rm -i`
- `rmri` for `rm -ri`
- `cpi` for `cp -i`
- `mvi` for `mv -i`

Useful aliases:

- `ta 0`: attach to tmux session `0`
- `ta0`: attach to tmux session `0`
- `tls`: list tmux sessions
- `tn name`: create a named tmux session
- `ipb`: short IP address output
- `ports`: listening TCP ports

## Vim

Vim keeps `vim-plug`. The plugin list is small:

- `tpope/vim-sensible`
- `editorconfig/editorconfig-vim`

The setup script installs `vim-plug`. `.vimrc` only uses it when it exists.

## tmux

Prefix is `C-a`.

TPM is not loaded by default. Use `--with-tpm` if you want it installed, then
enable the TPM block in `common/.tmux.conf`.

## Ubuntu notes

Package management:

```sh
sudo apt update
sudo apt upgrade
sudo apt install <package>
apt search <name>
apt show <package>
```

Services and logs:

```sh
systemctl status <service>
sudo systemctl enable --now <service>
journalctl -u <service> -f
```

Network:

```sh
ip -brief addr
hostname -I
ip route
resolvectl status
nmcli device status
```

Ubuntu desktop and server installs can differ. NetworkManager usually owns
desktop networking. Server installs often use netplan files in `/etc/netplan`.

Local config locations:

- User shell: `~/.zshrc`
- User Git config: `~/.gitconfig` and `~/.gitconfig.local`
- SSH client config: `~/.ssh/config`
- User systemd services: `~/.config/systemd/user`
- System services: `/etc/systemd/system`
- System environment: `/etc/environment`

## Check

From the repository root:

```sh
./scripts/check.sh
```
