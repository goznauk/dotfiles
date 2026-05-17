# Ubuntu setup

This setup targets a development machine with shell tools, build tools, Python,
Rust, Node, Vim, tmux, Docker, and common inspection commands.

Ubuntu 25.04 reached end of life on 2026-01-15. The script still supports it,
but use Ubuntu 24.04 LTS or 26.04 LTS when possible.

## Run

Interactive:

```sh
./setup.sh ubuntu
```

One-shot:

```sh
./setup.sh ubuntu --yes
```

Useful variants:

```sh
./setup.sh ubuntu --yes --skip-apt
./setup.sh ubuntu --yes --skip-tools
./setup.sh ubuntu --yes --with-tpm
./setup.sh ubuntu --yes --apt-packages git,zsh,vim,tmux
./setup.sh ubuntu --yes --optional-packages bat,eza,btop
./setup.sh ubuntu --yes --no-optional-packages
./setup.sh ubuntu --yes --docker-strategy official
./setup.sh ubuntu --yes --node-strategy nvm
```

## What it installs

- Apt packages listed in `Ubuntu/packages/core.txt` and
  `Ubuntu/packages/optional.txt`.
- Python through Ubuntu packages, with `python3-venv`, `pipx`, and `uv`.
- Rust through `rustup`, including `rustfmt` and `clippy`.
- Node LTS through `mise` by default, or `nvm` with `--node-strategy nvm`.
- Container runtime through `--docker-strategy`: Docker official repository,
  Ubuntu packages, Podman compatibility, or none.
- Shell tools: `zsh`, oh-my-zsh, Powerlevel10k, syntax highlighting,
  autosuggestions, completions, `direnv`, `ripgrep`, `fd`, `fzf`, `jq`, `tmux`,
  and `vim`.
- Optional tools if available in apt: `bat`, `eza`, `hyperfine`, `btop`, `yq`,
  `shfmt`, and `nmap`.

## Package lists

Ubuntu apt packages live outside the installer:

- `Ubuntu/packages/core.txt` is required. Missing packages stop the apt install.
- `Ubuntu/packages/optional.txt` is best effort. Missing packages are skipped
  with a warning.

Use one package name per line. Blank lines and lines starting with `#` are
ignored.

The chooser app uses `packages/catalog.json` to map semantic package choices to
Ubuntu, macOS, Amazon Linux 2023, and RHEL package names. The Ubuntu installer
can accept the chooser output through `--apt-packages`.

## Dotfiles

The installer links these files into `$HOME`:

- `common/.zshrc` -> `~/.zshrc`
- `common/.vimrc` -> `~/.vimrc`
- `common/.tmux.conf` -> `~/.tmux.conf`
- `common/.gitconfig` -> `~/.gitconfig`
- `common/.gitexclude` -> `~/.gitexclude`

Existing files are moved to `*.backup.YYYYMMDDHHMMSS` first.

`rm`, `cp`, and `mv` are not aliased. Use these when you want prompts:

- `rmi` for `rm -i`
- `rmri` for `rm -ri`
- `cpi` for `cp -i`
- `mvi` for `mv -i`

## Vim

Vim keeps `vim-plug`. Vim 8 native packages are fine, but `vim-plug` remains a
simple and common default for plain Vim configs. The plugin list is intentionally
small:

- `tpope/vim-sensible`
- `editorconfig/editorconfig-vim`

## tmux

Prefix is `C-a`.

Common aliases from zsh:

- `ta 0` attaches to session `0`
- `ta0` attaches to session `0`
- `tls` lists sessions
- `tn name` creates a named session

TPM is not loaded by default. Use `--with-tpm` if you want it installed, then
uncomment the TPM block in `common/.tmux.conf`.

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

Ubuntu desktop and server installs may differ. NetworkManager usually owns
desktop networking. Server installs often use netplan files in `/etc/netplan`.

Docker:

```sh
docker version
docker compose version
groups
```

The official Docker repository strategy follows Docker's supported Ubuntu
release list. For Ubuntu 25.04, prefer upgrading the OS; if you continue on it,
use `--docker-strategy distro`, `--docker-strategy podman`, or
`--docker-strategy none`.

After the installer adds your user to the Docker group, log out and back in.

Local config locations:

- User shell: `~/.zshrc`
- User Git config: `~/.gitconfig` and `~/.gitconfig.local`
- SSH client config: `~/.ssh/config`
- User systemd services: `~/.config/systemd/user`
- System services: `/etc/systemd/system`
- System environment: `/etc/environment`
