# Pages integration

This repository can publish the chooser directly through its own GitHub Pages
workflow. It can also be mounted under `goznauk.com` the same way `MyTools` is
mounted.

## Add as a submodule in goznauk.com

```sh
git submodule add -b main https://github.com/goznauk/dotfiles.git vendor/dotfiles
```

## Build in goznauk.com workflow

Add a build step after checkout and submodule update:

```yaml
- uses: actions/setup-node@v6
  with:
    node-version: 22
    cache: npm
    cache-dependency-path: vendor/dotfiles/chooser/package-lock.json

- name: Build dotfiles chooser
  working-directory: vendor/dotfiles/chooser
  run: |
    npm ci
    npm run build
```

Copy the built app during site assembly:

```sh
mkdir -p public/tools/dotfiles
cp -R vendor/dotfiles/chooser/dist/. public/tools/dotfiles/
```

Then add a link to `/tools/dotfiles/` in the `goznauk.com` site navigation and
tools list.

The chooser is self-contained after build. Its catalog and default config
content are bundled into the static assets.
