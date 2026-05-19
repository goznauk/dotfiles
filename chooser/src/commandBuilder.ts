import {
  AGENT_TOOL_IDS,
  DEVELOPER_TOOL_IDS,
  DOCKER_STRATEGY_IDS,
  INSTALL_STEP_KEYS,
  JAVA_STRATEGY_IDS,
  NODE_STRATEGY_IDS,
  NODE_PACKAGE_MANAGER_IDS,
  OS_IDS,
  PYTHON_STRATEGY_IDS,
  type AgentToolId,
  type CommandOsId,
  type DeveloperToolId,
  type DockerStrategyId,
  type InstallStepKey,
  type JavaStrategyId,
  type NodePackageManagerId,
  type NodeStrategyId,
  type PythonStrategyId
} from "./ids.js";

export const REPO_OWNER = "goznauk";
export const REPO_NAME = "dotfiles";
export const DEFAULT_REF = "main";

export const AGENT_TOOL_PACKAGES: Record<AgentToolId, string> = {
  [AGENT_TOOL_IDS.CLAUDE_CODE]: "@anthropic-ai/claude-code",
  [AGENT_TOOL_IDS.OPENAI_CODEX]: "@openai/codex"
};

export const MISE_DEVELOPER_TOOLS: Partial<Record<DeveloperToolId, string>> = {
  [DEVELOPER_TOOL_IDS.GO]: "go@latest",
  [DEVELOPER_TOOL_IDS.BUN]: "bun@latest",
  [DEVELOPER_TOOL_IDS.DENO]: "deno@latest",
  [DEVELOPER_TOOL_IDS.RUBY]: "ruby@latest",
  [DEVELOPER_TOOL_IDS.DOTNET]: "dotnet@latest"
};

export type CommandTarget = {
  commandTarget: string;
};

export type CommandSet = {
  primary: string;
  local: string;
  packageCommand: string;
};

export const installSteps: Array<{
  key: InstallStepKey;
  title: string;
  description: string;
  skipFlag: string;
}> = [
  {
    key: INSTALL_STEP_KEYS.PACKAGES,
    title: "OS packages",
    description: "Install package-manager packages selected from the catalog.",
    skipFlag: "--skip-apt"
  },
  {
    key: INSTALL_STEP_KEYS.SHELL,
    title: "Shell setup",
    description: "oh-my-zsh, Powerlevel10k, syntax highlighting, autosuggestions.",
    skipFlag: "--skip-shell"
  },
  {
    key: INSTALL_STEP_KEYS.DOTFILES,
    title: "Dotfile links",
    description: "Link zsh, Vim, tmux, Git config, and Git exclude files.",
    skipFlag: "--skip-dotfiles"
  },
  {
    key: INSTALL_STEP_KEYS.TOOLS,
    title: "Runtime tools",
    description: "uv, language runtimes, developer tools, and selected CLIs.",
    skipFlag: "--skip-tools"
  }
];

export type BuildCommandInput = {
  activeOs: CommandOsId;
  activeTarget: CommandTarget;
  targetVersion: string;
  selectedPackageNames: string[];
  stepSelection: Record<InstallStepKey, boolean>;
  assumeYes: boolean;
  installTpm: boolean;
  dockerEnabled: boolean;
  dockerStrategy: DockerStrategyId;
  nodeStrategy: NodeStrategyId;
  nodePackageManager: NodePackageManagerId;
  pythonStrategy: PythonStrategyId;
  javaEnabled: boolean;
  javaStrategy: JavaStrategyId;
  selectedAgentToolIds: AgentToolId[];
  selectedDeveloperToolIds: DeveloperToolId[];
  powerlevel10k: boolean;
  prepareSystem: boolean;
  runInTmux: boolean;
  repoRef: string;
};

export const shellQuote = (value: string) => `'${value.replaceAll("'", "'\\''")}'`;
export const shellDoubleQuote = (value: string) =>
  `"${value
    .replaceAll("\\", "\\\\")
    .replaceAll('"', '\\"')
    .replaceAll("$", "\\$")
    .replaceAll("`", "\\`")
    .replaceAll("!", "\\!")}"`;

export const buildCommands = (input: BuildCommandInput): CommandSet => {
  const activeRef = input.repoRef.trim() || DEFAULT_REF;
  const flags: string[] = [];

  if (input.assumeYes) {
    flags.push("--yes");
  }

  if (input.targetVersion.trim()) {
    flags.push("--target-version", input.targetVersion.trim());
  }

  for (const step of installSteps) {
    if (!input.stepSelection[step.key]) {
      flags.push(step.skipFlag);
    }
  }

  if (input.stepSelection[INSTALL_STEP_KEYS.SHELL] && !input.powerlevel10k) {
    flags.push("--no-powerlevel10k");
  }

  if (input.stepSelection[INSTALL_STEP_KEYS.PACKAGES]) {
    if (input.selectedPackageNames.length > 0) {
      flags.push("--apt-packages", input.selectedPackageNames.join(","));
    } else {
      flags.push("--skip-apt");
    }
    flags.push("--docker-strategy", input.dockerEnabled ? input.dockerStrategy : DOCKER_STRATEGY_IDS.NONE);
  }

  if (input.stepSelection[INSTALL_STEP_KEYS.TOOLS]) {
    flags.push("--node-strategy", input.nodeStrategy);
    if (input.nodeStrategy !== NODE_STRATEGY_IDS.NONE) {
      flags.push("--node-package-manager", input.nodePackageManager);
    }
    flags.push("--python-strategy", input.pythonStrategy);
    flags.push("--java-strategy", input.javaEnabled ? input.javaStrategy : JAVA_STRATEGY_IDS.NONE);
    if (input.selectedDeveloperToolIds.length > 0) {
      flags.push("--developer-tools", input.selectedDeveloperToolIds.join(","));
    } else {
      flags.push("--no-developer-tools");
    }
    if (input.selectedAgentToolIds.length > 0) {
      flags.push("--agent-tools", input.selectedAgentToolIds.join(","));
    } else {
      flags.push("--no-agent-tools");
    }
  }

  if (input.installTpm) {
    flags.push("--with-tpm");
  }

  const setupArgs = [input.activeTarget.commandTarget, ...flags].map(shellQuote).join(" ");
  const envPrefix = activeRef === DEFAULT_REF ? "" : `DOTFILES_REPO_REF=${shellQuote(activeRef)} `;
  const url = `https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${activeRef}/install.sh`;
  const remoteCommand = `curl -fsSL ${shellQuote(url)} | ${envPrefix}bash -s -- ${setupArgs}`;
  const localCommand = `./setup.sh ${setupArgs}`;

  return {
    primary: wrapSetupCommand(input.activeOs, remoteCommand, input.prepareSystem, input.runInTmux, "remote"),
    local: wrapSetupCommand(input.activeOs, localCommand, input.prepareSystem, input.runInTmux, "local"),
    packageCommand: buildPackageCommand(
      input.activeOs,
      input.targetVersion,
      input.selectedPackageNames,
      input.dockerEnabled ? input.dockerStrategy : DOCKER_STRATEGY_IDS.NONE,
      input.nodeStrategy,
      input.nodePackageManager,
      input.pythonStrategy,
      input.javaEnabled ? input.javaStrategy : JAVA_STRATEGY_IDS.NONE,
      input.selectedAgentToolIds,
      input.selectedDeveloperToolIds
    )
  };
};

const wrapSetupCommand = (
  osId: CommandOsId,
  command: string,
  prepareSystem: boolean,
  runInTmux: boolean,
  mode: "local" | "remote"
) => {
  if (osId !== OS_IDS.UBUNTU) {
    return command;
  }

  const setupCommand = runInTmux ? `tmux new-session -A -s dotfiles ${shellDoubleQuote(command)}` : command;
  if (!prepareSystem) {
    return setupCommand;
  }

  const packages =
    mode === "remote" ? ["ca-certificates", "curl", "git", ...(runInTmux ? ["tmux"] : [])] : runInTmux ? ["tmux"] : [];
  const packageInstall = packages.length > 0 ? `sudo apt install -y ${packages.map(shellQuote).join(" ")} && ` : "";

  return `sudo apt update && ${packageInstall}${setupCommand}`;
};

export const buildPackageCommand = (
  osId: CommandOsId,
  targetVersion: string,
  packages: string[],
  dockerStrategy: DockerStrategyId,
  nodeStrategy: NodeStrategyId,
  nodePackageManager: NodePackageManagerId,
  pythonStrategy: PythonStrategyId,
  javaStrategy: JavaStrategyId,
  selectedAgentToolIds: AgentToolId[] = [],
  selectedDeveloperToolIds: DeveloperToolId[] = []
) => {
  const installLine =
    osId === OS_IDS.UBUNTU
      ? packages.length > 0
        ? `sudo apt install -y ${packages.map(shellQuote).join(" ")}`
        : "# No apt packages selected"
      : osId === OS_IDS.MACOS
        ? packages.length > 0
          ? `brew install ${packages.map(shellQuote).join(" ")}`
          : "# No brew packages selected"
        : packages.length > 0
          ? `sudo dnf install -y ${packages.map(shellQuote).join(" ")}`
          : "# No dnf packages selected";
  const targetLine = targetVersion.trim() ? `# Target OS version: ${targetVersion.trim()}` : "";
  const dockerLine = dockerPreviewLine(osId, dockerStrategy);
  const nodeLine = nodePreviewLine(nodeStrategy);
  const nodePackageManagerLine = nodePackageManagerPreviewLine(nodeStrategy, nodePackageManager);
  const agentToolsLine = agentToolsPreviewLine(nodeStrategy, selectedAgentToolIds);
  const developerToolsLine = developerToolsPreviewLine(osId, selectedDeveloperToolIds);
  const pythonLine = pythonPreviewLine(pythonStrategy);
  const javaLine = javaPreviewLine(osId, javaStrategy);

  return [
    targetLine,
    installLine,
    dockerLine,
    nodeLine,
    nodePackageManagerLine,
    agentToolsLine,
    developerToolsLine,
    pythonLine,
    javaLine
  ]
    .filter(Boolean)
    .join("\n");
};

const dockerPreviewLine = (osId: CommandOsId, strategy: DockerStrategyId) => {
  if (strategy === DOCKER_STRATEGY_IDS.NONE) {
    return "# Container runtime skipped";
  }
  if (osId === OS_IDS.MACOS) {
    return strategy === DOCKER_STRATEGY_IDS.OFFICIAL || strategy === DOCKER_STRATEGY_IDS.DISTRO
      ? "brew install --cask docker"
      : "# Podman on macOS usually needs podman machine setup";
  }
  if (strategy === DOCKER_STRATEGY_IDS.PODMAN) {
    return "sudo dnf install -y podman podman-docker";
  }
  if (strategy === DOCKER_STRATEGY_IDS.DISTRO) {
    return "sudo dnf install -y docker";
  }
  return "# Use Docker official repository instructions for this OS";
};

const nodePreviewLine = (strategy: NodeStrategyId) => {
  if (strategy === NODE_STRATEGY_IDS.NONE) {
    return "# Node setup skipped";
  }
  if (strategy === NODE_STRATEGY_IDS.NVM) {
    return "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash";
  }
  return "curl -fsSL https://mise.run | sh && mise use -g node@lts && mise settings add idiomatic_version_file_enable_tools node";
};

const nodePackageManagerPreviewLine = (nodeStrategy: NodeStrategyId, packageManager: NodePackageManagerId) => {
  if (nodeStrategy === NODE_STRATEGY_IDS.NONE) {
    return "";
  }

  if (packageManager === NODE_PACKAGE_MANAGER_IDS.NPM) {
    return "# Use npm bundled with Node";
  }

  const corepackCommand =
    packageManager === NODE_PACKAGE_MANAGER_IDS.PNPM
      ? "corepack enable pnpm && corepack prepare pnpm@latest --activate"
      : "corepack enable yarn && corepack prepare yarn@stable --activate";

  return nodeStrategy === NODE_STRATEGY_IDS.MISE
    ? `mise exec node@lts -- sh -lc ${shellQuote(corepackCommand)}`
    : corepackCommand;
};

const agentToolsPreviewLine = (nodeStrategy: NodeStrategyId, selectedAgentToolIds: AgentToolId[]) => {
  const packages = selectedAgentToolIds.map((toolId) => AGENT_TOOL_PACKAGES[toolId]).filter(Boolean);
  if (packages.length === 0) {
    return "# Agent CLI install skipped";
  }

  if (nodeStrategy === NODE_STRATEGY_IDS.NONE) {
    return "# Agent CLI install needs Node";
  }

  const installArgs = packages.map(shellQuote).join(" ");
  return nodeStrategy === NODE_STRATEGY_IDS.MISE
    ? `mise exec node@lts -- npm install -g ${installArgs}`
    : `npm install -g ${installArgs}`;
};

const developerToolsPreviewLine = (osId: CommandOsId, selectedDeveloperToolIds: DeveloperToolId[]) => {
  if (selectedDeveloperToolIds.length === 0) {
    return "# Developer tool install skipped";
  }

  const lines = selectedDeveloperToolIds.map((toolId) => {
    if (toolId === DEVELOPER_TOOL_IDS.RUST) {
      return "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile default";
    }
    if (toolId === DEVELOPER_TOOL_IDS.GITHUB_CLI) {
      return osId === OS_IDS.MACOS
        ? "brew install gh"
        : osId === OS_IDS.UBUNTU
          ? "# GitHub CLI: add official repository, then sudo apt install -y gh"
          : "sudo dnf install -y gh";
    }
    return `mise use -g ${MISE_DEVELOPER_TOOLS[toolId] ?? `${toolId}@latest`}`;
  });

  return lines.join("\n");
};

const pythonPreviewLine = (strategy: PythonStrategyId) => {
  if (strategy === PYTHON_STRATEGY_IDS.NONE) {
    return "# Extra Python runtime setup skipped";
  }
  if (strategy === PYTHON_STRATEGY_IDS.MISE) {
    return "curl -fsSL https://mise.run | sh && mise use -g python@latest && mise settings add idiomatic_version_file_enable_tools python";
  }
  return "curl -LsSf https://astral.sh/uv/install.sh | sh";
};

const javaPreviewLine = (osId: CommandOsId, strategy: JavaStrategyId) => {
  if (strategy === JAVA_STRATEGY_IDS.NONE) {
    return "# Java setup skipped";
  }
  if (strategy === JAVA_STRATEGY_IDS.MISE_TEMURIN_21) {
    return "curl -fsSL https://mise.run | sh && mise use -g java@temurin-21";
  }
  if (osId === OS_IDS.MACOS) {
    return "brew install openjdk@21";
  }
  return osId === OS_IDS.UBUNTU ? "sudo apt install -y openjdk-21-jdk" : "sudo dnf install -y java-21-openjdk-devel";
};

export const buildConfigWriteCommand = (definition: { path: string; mkdir?: string }, content: string) => {
  const mkdirLine = definition.mkdir ? `mkdir -p ${definition.mkdir}\n` : "";
  return `${mkdirLine}cat > ${definition.path} <<'EOF'\n${content.replace(/\n?$/, "\n")}EOF`;
};
