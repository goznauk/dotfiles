export const OS_IDS = {
  UBUNTU: "ubuntu",
  MACOS: "macos",
  AMAZON: "amazon",
  RHEL: "rhel"
} as const;

export type OsId = (typeof OS_IDS)[keyof typeof OS_IDS];
export type CommandOsId = OsId;

export const VIEW_IDS = {
  TARGET: "target",
  PACKAGES: "packages",
  TOOLCHAINS: "toolchains",
  CONFIGS: "configs",
  SUMMARY: "summary"
} as const;

export type ViewId = (typeof VIEW_IDS)[keyof typeof VIEW_IDS];

export const THEME_MODES = {
  LIGHT: "light",
  DARK: "dark"
} as const;

export type ThemeMode = (typeof THEME_MODES)[keyof typeof THEME_MODES];

export const INSTALL_STEP_KEYS = {
  PACKAGES: "packages",
  SHELL: "shell",
  DOTFILES: "dotfiles",
  TOOLS: "tools"
} as const;

export type InstallStepKey = (typeof INSTALL_STEP_KEYS)[keyof typeof INSTALL_STEP_KEYS];

export const DOCKER_STRATEGY_IDS = {
  OFFICIAL: "official",
  DISTRO: "distro",
  PODMAN: "podman",
  NONE: "none"
} as const;

export type DockerStrategyId = (typeof DOCKER_STRATEGY_IDS)[keyof typeof DOCKER_STRATEGY_IDS];

export const NODE_STRATEGY_IDS = {
  MISE: "mise",
  NVM: "nvm",
  NONE: "none"
} as const;

export type NodeStrategyId = (typeof NODE_STRATEGY_IDS)[keyof typeof NODE_STRATEGY_IDS];

export const PYTHON_STRATEGY_IDS = {
  SYSTEM_UV: "system-uv",
  MISE: "mise",
  NONE: "none"
} as const;

export type PythonStrategyId = (typeof PYTHON_STRATEGY_IDS)[keyof typeof PYTHON_STRATEGY_IDS];

export const JAVA_STRATEGY_IDS = {
  MISE_TEMURIN_21: "mise-temurin-21",
  DISTRO_OPENJDK_21: "distro-openjdk-21",
  NONE: "none"
} as const;

export type JavaStrategyId = (typeof JAVA_STRATEGY_IDS)[keyof typeof JAVA_STRATEGY_IDS];

export const CONFIG_KEYS = {
  ZSHRC: "zshrc",
  VIMRC: "vimrc",
  TMUX: "tmux",
  HTOP: "htop"
} as const;

export type ConfigKey = (typeof CONFIG_KEYS)[keyof typeof CONFIG_KEYS];

export const CONFIG_BLOCK_KINDS = {
  LOCKED: "locked",
  ORDERED: "ordered",
  SIDE_EFFECT: "side-effect",
  FREE: "free"
} as const;

export type ConfigBlockKind = (typeof CONFIG_BLOCK_KINDS)[keyof typeof CONFIG_BLOCK_KINDS];
