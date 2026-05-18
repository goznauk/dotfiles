export const REPO_OWNER = "goznauk";
export const REPO_NAME = "dotfiles";
export const DEFAULT_REF = "main";

export type CommandOsId = "ubuntu" | "macos" | "amazon" | "rhel";
export type InstallStepKey = "packages" | "shell" | "dotfiles" | "tools";
export type DockerStrategyId = "official" | "distro" | "podman" | "none";
export type NodeStrategyId = "mise" | "nvm" | "none";
export type PythonStrategyId = "system-uv" | "mise" | "none";
export type JavaStrategyId = "mise-temurin-21" | "distro-openjdk-21" | "none";

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
    key: "packages",
    title: "OS packages",
    description: "Install package-manager packages selected from the catalog.",
    skipFlag: "--skip-apt"
  },
  {
    key: "shell",
    title: "Shell setup",
    description: "oh-my-zsh, Powerlevel10k, syntax highlighting, autosuggestions.",
    skipFlag: "--skip-shell"
  },
  {
    key: "dotfiles",
    title: "Dotfile links",
    description: "Link zsh, Vim, tmux, Git config, and Git exclude files.",
    skipFlag: "--skip-dotfiles"
  },
  {
    key: "tools",
    title: "Runtime tools",
    description: "uv, Rust stable, rustfmt, clippy, and selected language runtimes.",
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
  pythonStrategy: PythonStrategyId;
  javaEnabled: boolean;
  javaStrategy: JavaStrategyId;
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

export function buildCommands(input: BuildCommandInput): CommandSet {
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

  if (input.stepSelection.shell && !input.powerlevel10k) {
    flags.push("--no-powerlevel10k");
  }

  if (input.stepSelection.packages) {
    if (input.selectedPackageNames.length > 0) {
      flags.push("--apt-packages", input.selectedPackageNames.join(","));
    } else {
      flags.push("--skip-apt");
    }
    flags.push("--docker-strategy", input.dockerEnabled ? input.dockerStrategy : "none");
  }

  if (input.stepSelection.tools) {
    flags.push("--node-strategy", input.nodeStrategy);
    flags.push("--python-strategy", input.pythonStrategy);
    flags.push("--java-strategy", input.javaEnabled ? input.javaStrategy : "none");
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
      input.dockerEnabled ? input.dockerStrategy : "none",
      input.nodeStrategy,
      input.pythonStrategy,
      input.javaEnabled ? input.javaStrategy : "none"
    )
  };
}

function wrapSetupCommand(
  osId: CommandOsId,
  command: string,
  prepareSystem: boolean,
  runInTmux: boolean,
  mode: "local" | "remote"
) {
  if (osId !== "ubuntu") {
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
}

export function buildPackageCommand(
  osId: CommandOsId,
  targetVersion: string,
  packages: string[],
  dockerStrategy: DockerStrategyId,
  nodeStrategy: NodeStrategyId,
  pythonStrategy: PythonStrategyId,
  javaStrategy: JavaStrategyId
) {
  const installLine =
    osId === "ubuntu"
      ? packages.length > 0
        ? `sudo apt install -y ${packages.map(shellQuote).join(" ")}`
        : "# No apt packages selected"
      : osId === "macos"
        ? packages.length > 0
          ? `brew install ${packages.map(shellQuote).join(" ")}`
          : "# No brew packages selected"
        : packages.length > 0
          ? `sudo dnf install -y ${packages.map(shellQuote).join(" ")}`
          : "# No dnf packages selected";
  const targetLine = targetVersion.trim() ? `# Target OS version: ${targetVersion.trim()}` : "";
  const dockerLine = dockerPreviewLine(osId, dockerStrategy);
  const nodeLine = nodePreviewLine(nodeStrategy);
  const pythonLine = pythonPreviewLine(pythonStrategy);
  const javaLine = javaPreviewLine(osId, javaStrategy);

  return [targetLine, installLine, dockerLine, nodeLine, pythonLine, javaLine].filter(Boolean).join("\n");
}

function dockerPreviewLine(osId: CommandOsId, strategy: DockerStrategyId) {
  if (strategy === "none") {
    return "# Container runtime skipped";
  }
  if (osId === "macos") {
    return strategy === "official" || strategy === "distro"
      ? "brew install --cask docker"
      : "# Podman on macOS usually needs podman machine setup";
  }
  if (strategy === "podman") {
    return "sudo dnf install -y podman podman-docker";
  }
  if (strategy === "distro") {
    return "sudo dnf install -y docker";
  }
  return "# Use Docker official repository instructions for this OS";
}

function nodePreviewLine(strategy: NodeStrategyId) {
  if (strategy === "none") {
    return "# Node setup skipped";
  }
  if (strategy === "nvm") {
    return "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash";
  }
  return "curl -fsSL https://mise.run | sh && mise use -g node@lts";
}

function pythonPreviewLine(strategy: PythonStrategyId) {
  if (strategy === "none") {
    return "# Extra Python runtime setup skipped";
  }
  if (strategy === "mise") {
    return "curl -fsSL https://mise.run | sh && mise use -g python@latest";
  }
  return "curl -LsSf https://astral.sh/uv/install.sh | sh";
}

function javaPreviewLine(osId: CommandOsId, strategy: JavaStrategyId) {
  if (strategy === "none") {
    return "# Java setup skipped";
  }
  if (strategy === "mise-temurin-21") {
    return "curl -fsSL https://mise.run | sh && mise use -g java@temurin-21";
  }
  if (osId === "macos") {
    return "brew install openjdk@21";
  }
  return osId === "ubuntu" ? "sudo apt install -y openjdk-21-jdk" : "sudo dnf install -y java-21-openjdk-devel";
}

export function buildConfigWriteCommand(definition: { path: string; mkdir?: string }, content: string) {
  const mkdirLine = definition.mkdir ? `mkdir -p ${definition.mkdir}\n` : "";
  return `${mkdirLine}cat > ${definition.path} <<'EOF'\n${content.replace(/\n?$/, "\n")}EOF`;
}
