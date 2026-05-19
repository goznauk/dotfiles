# macOS setup

This path is legacy. Keep it for old rebuilds, but use the Ubuntu path for new
development machines.

## Manual first steps

Install command line tools and Homebrew:

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Useful first-run settings:

- Install macOS in English.
- Enable tap to click.
- Enable three finger drag.
- Add Korean as a secondary language if needed.
- Use F1, F2, and similar keys as standard function keys.
- Disable automatic spelling correction.
- Disable automatic capitalization.
- Disable double-space period insertion.
- Disable smart quotes and smart dashes.
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

Create `.env` first:

```sh
cp .env.example .env
vim .env
```

Run:

```sh
./setup.sh macos
```

Non-interactive:

```sh
./setup.sh macos --yes
```

The script installs Homebrew if missing, then asks before installing packages
from `OSX_PACKAGES`.

## Old app list

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

## Karabiner rule

```sh
mkdir -p ~/.config/karabiner/assets/complex_modifications
cp MacOS/config_files/Karabiner_KorEng.json ~/.config/karabiner/assets/complex_modifications/
```
