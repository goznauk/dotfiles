# Dotfiles

Personal shell, Git, Vim, tmux, and OS setup files.

## Ubuntu

For an interactive install:

```sh
./setup.sh ubuntu
```

For a one-shot install:

```sh
./setup.sh ubuntu --yes
```

See [Ubuntu setup](./Ubuntu/README.md) for package details and system notes.

## Chooser

The React chooser builds a static GitHub Pages app for selecting Ubuntu setup
options, OS package names, runtime strategies, config files, and copying an
install command.

```sh
cd chooser
npm install
npm run dev
```

See [Pages integration](./docs/pages-integration.md) for the `goznauk.com`
submodule deployment path.

Validation:

```sh
cd chooser
npm run check
```

## macOS

The macOS setup path is still legacy and uses `.env`.

```sh
cp .env.example .env
vim .env
./setup.sh macos
```
