# macOS setup

This path is legacy. The current work is focused on Ubuntu, but these notes are
kept as a compact checklist for an old macOS rebuild.

## Manual setup

Install command line tools and Homebrew:

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Recommended first-run settings:

- Install macOS in English.
- Enable tap to click.
- Enable three finger drag.
- Add Korean as a secondary language if needed.
- Use F1, F2, and similar keys as standard function keys.
- Disable automatic spelling correction, automatic capitalization, double-space
  period insertion, smart quotes, and smart dashes.
- Set Chrome as the default browser.
- Disable recent applications in the Dock.
- Disable automatic Space rearranging.
- Show Bluetooth and sound in the menu bar.
- Show filename extensions in Finder.
- Set Finder search to the current folder.

Useful defaults:

```sh
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write com.apple.finder CreateDesktop -bool false && killall Finder
defaults write com.apple.finder AppleShowAllFiles -bool YES && killall Finder
chflags nohidden ~/Library/
mkdir -p ~/Screenshots
defaults write com.apple.screencapture location ~/Screenshots && killall SystemUIServer
```

## Script path

The legacy script reads package settings from `.env`:

```sh
./setup.sh macos
```

It installs Homebrew if missing, then asks before installing packages from
`OSX_PACKAGES`.

## App notes

Old app list:

- iTerm2
- Karabiner-Elements
- Google Chrome
- KeepingYouAwake
- Macs Fan Control
- Visual Studio Code
- Postman
- Slack
- VLC
- Typora
- Microsoft Office
- Parallels

Karabiner rule file:

```sh
mkdir -p ~/.config/karabiner/assets/complex_modifications
cp MacOS/config_files/Karabiner_KorEng.json ~/.config/karabiner/assets/complex_modifications/
```
