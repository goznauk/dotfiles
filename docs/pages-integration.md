# Pages integration

The chooser is a static app after build. It can be published from this repository or copied into `goznauk.com`.

## This Repository

This repository has a GitHub Pages workflow at `.github/workflows/pages.yml`. It installs chooser dependencies, runs `npm run build`, and publishes `chooser/dist`.

The workflow also supports manual `workflow_dispatch`. Its automatic push trigger currently targets `main`; this repository's active base branch is `master`, so update the branch trigger separately before relying on automatic Pages deploys from the default branch.

Run `npm --prefix chooser run check` locally before relying on the Pages workflow; the workflow is intentionally limited to the static build.

## Use In `goznauk.com`

In `goznauk.com`:

```sh
git submodule add -b main https://github.com/goznauk/dotfiles.git vendor/dotfiles
```

If the branch name changes, update the submodule branch in `goznauk.com`.

## Build step

Add this after checkout and submodule update:

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
    npm run check
```

## Copy output

During the `goznauk.com` site build:

```sh
mkdir -p public/tools/dotfiles
cp -R vendor/dotfiles/chooser/dist/. public/tools/dotfiles/
```

Then add a site link to:

```text
/tools/dotfiles/
```

## Notes

- The app uses a relative Vite base, so it works under a subpath.
- Catalog data and default config content are bundled into the static assets.
- For external site integration, run `npm run check` instead of only `npm run build`; it catches catalog and command-generation mistakes before the site copies `dist`.
