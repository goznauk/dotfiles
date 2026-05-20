# Pages integration

Public URL:

```text
https://goznauk.com/dotfiles/
```

## Build source

- App: `chooser/`
- Build command: `npm --prefix chooser run build`
- Validation command: `npm --prefix chooser run check`
- Output directory: `chooser/dist`
- Vite base: `./`

The relative Vite base lets built assets resolve under `/dotfiles/`.

## Dotfiles Pages workflow

`.github/workflows/pages.yml` builds `chooser/`, uploads `chooser/dist` as the Pages artifact, and deploys it with `actions/deploy-pages`.

The workflow runs on pushes to `master` and on manual `workflow_dispatch`.

If GitHub Pages is not already configured for Actions, set **Settings -> Pages -> Build and deployment** to **GitHub Actions**.

## goznauk.com integration

The site repository tracks this repository as `vendor/dotfiles`.

The site deployment builds the chooser in the submodule, then copies:

```text
vendor/dotfiles/chooser/dist/. -> public/dotfiles/
```

That publishes the chooser at `/dotfiles/` on `goznauk.com`.

## Local validation

Run from this repository:

```sh
npm --prefix chooser run check
npm --prefix chooser run build
./scripts/check.sh
```

Run from the site repository after updating `vendor/dotfiles`:

```sh
npm --prefix vendor/dotfiles/chooser run check
```
