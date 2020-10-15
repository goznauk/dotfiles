# Mac Setting



## Backup







## Format

- 포맷용 USB 만들기

```shell
sudo /Applications/Install\ macOS\ Catalina.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume
```





## Re-Install



### Initial Setting

- 클린한 사용을 위해 English(United States)로 MacOS 설치

- Homebrew 설치

  ```shell
  xcode-select --install
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  ```

- 포맷 직후 재설정을 원활히 하기 위하여

  - System Preference > Trackpad > Tab to Click : Enable
  - System Preference > Accessibility > Pointer Control > Trackpad Options.. > Enable dragging : three finger drag
  - System Preference > Language & Region > Preferred languages : 한국어 추가 (English Primary 유지)
  - System Preference > Keyboard > Use F1, F2, etc. keys as standard function keys
  - System Preference > Keyboard > Text : Remove all items in list
  - System Preference > Keyboard > Text > Correct spelling automatically : Disable
  - System Preference > Keyboard > Text > Capitalize words automatically : Disable
  - System Preference > Keyboard > Text > Add period with double-space : Disable
  - System Preference > Keyboard > Text > Use smart quotes and dashes : Disable

- iterm2 설치

  ```shell
  brew cask install iterm2
  ```

  - Preferences > Appearance > Windows > Hide scrollbars : Enable
  - Preferences > Appearance > Windows > Show line under title bar when the tab bar is not visible : Disable
  - Preferences > Keys > Hotkey > Create a Dedicated Hotkey Window.. > Click : Command + Shift + x

- KeepingYouAwake 설치

  ```shell
  brew cask install keepingyouawake
  ```

- Karabiner-Elements 설치 및 실행 (권한 설정 등)

  ```shell
  brew cask install karabiner-elements
  ```

  - ~/.config/karabiner/assets/complex_modifications에 Karabiner_KorEng.json 복사

- Google Chrome 설치

  ```shell
  brew cask install google-chrome
  ```

- Macs Fan Control 설치

  ```shell
  brew cask install macs-fan-control
  ```

  

  

### Preferences

- 시스템 및 기본 앱 설정

  - System Preference > General > Default web browser : Google Chrome.app
  - System Preference > Dock > Show recent applications in Dock : Disable
  - System Preference > Mission Control > Automatically rearrange Spaces based on most recent use : Disable
  - System Preference > Security & Privacy > Show a message when the screen is locked : Enable & Set Lock Message
  - System Preference > Bluetooth > Show Bluetooth in menu bar : Enable
  - System Preference > Sound > Show volume in menu bar : Enable
  - Finder > Preferences > Show these items on the desktop > Hard disks : Enable
  - Finder > Preferences > New Finder windows show : Home Folder
  - Finder > Preferences > Sidebar : Enable User Home (Disable Recents / Enable Pictures
  - Finder > Preferences > Advanced > Show all filename extensions : Enable
  - Finder > Preferences > Advanced > When performing a search : Search the Current Folder
  - Notes > Edit > Spelling and Grammar > Correct Spelling Automatically : Disable

- 키 누르고 있을 때 연속 입력

  ```shell
  defaults write -g ApplePressAndHoldEnabled -bool false
  ```

- 바탕 화면 파일 보이는거 지우기

  ```shell
  defaults write com.apple.finder CreateDesktop -bool false && killall Finder
  ```

- 숨김 파일 보이기

  ```shell
  defaults write com.apple.finder AppleShowAllFiles -bool YES && killall Finder
  ```

- Library 폴더 보이기

  ```shell
  chflags nohidden ~/Library/
  ```

- Screenshot 저장 위치 변경

  ```shell
  defaults write com.apple.screencapture location /path/;killall SystemUIServer
  defaults write com.apple.screencapture location ~/Screenshots && killall SystemUIServer
  ```

  









### 앱 설치 (개발)

- VS Code

  ```shell
  brew cask install visual-studio-code
  ```

- Postman

  ```shell
  brew cask install postman
  ```

- go2shell

  ```shell
  brew cask install go2shell
  ```

  





### 앱 설치 (일반)

- CheatSheet

  ```shell
  brew cask install cheatsheet
  ```

- Typora

  ```shell
  brew cask install typora
  ```

  - Preference > General > On Launch : Open custom folder
  - Preference > Appearance > Theme : Onedark (별도 다운로드 필요)

- Slack

  ```shell
  brew cask install slack
  ```

- VLC

  ```shell
  brew cask install vlc
  ```

  

- Bartender (유료)

  ```shell
  brew cask install bartender
  ```

- iStat menus (유료)

  ```shell
  brew cask install istat-menus
  ```

  - File > Import Settings

- MS Office (유료)

  ```shell
  brew cask install microsoft-office
  ```

- Parallels (유료)

  ```shell
  brew cask install parallels
  ```

  

- Battle-net

  ```shell
  brew cask install battle-net
  open /usr/local/Caskroom/battle-net/latest/Battle.net-Setup.app
  ```

  





### CLI 설정

- 필수적인 패키지만 설치 : DB 등 daemon으로 동작하는 프로그램은 웬만하면 Docker 사용

- iTerm2 Font change

  ```shell
  brew cask install homebrew/cask-fonts/font-meslo-for-powerline
  ```

- Preference > Profiles > Text > Font : MesloLGS NF

- `setup.sh` 실행



### Mac App Store

- Mac App Store에 로그인

- mas 설치

  ```shell
  brew install mas
  mas account
  ```

- 무료 앱

  ```shell
  mas install 869223134 # Kakao Talk
  mas install 1236050766 # Melon
  mas install 1295203466 # Microsoft Remote Desktop
  mas insatll 409183694 # Keynote
  mas install 409201541 # Pages
  mas install 409203825 # Numbers 
  mas install 416746898 # Hancom Office HWP 2014 VP Viewer
  mas install 942568098 # Patina
  mas install 1061525898 # Korea OnAir Radio
  ```

- 유료 앱 (따로 결제 필요)

  ```shell
  mas install 461788075 # Movist
  mas install 1035237815 # Commnader One Pro
  mas install 1206246482 # EdgeView 2
  ```

  






