import {
  DEFAULT_REF,
  buildCommands,
  buildConfigWriteCommand,
  buildPackageCommand,
  shellDoubleQuote,
  shellQuote,
  type BuildCommandInput
} from "./commandBuilder.js";
import {
  AGENT_TOOL_IDS,
  DEVELOPER_TOOL_IDS,
  DOCKER_STRATEGY_IDS,
  JAVA_STRATEGY_IDS,
  NODE_STRATEGY_IDS,
  NODE_PACKAGE_MANAGER_IDS,
  OS_IDS,
  PYTHON_STRATEGY_IDS
} from "./ids.js";

const assertEqual = (actual: unknown, expected: unknown, label: string) => {
  if (actual !== expected) {
    throw new Error(`${label}\nExpected: ${String(expected)}\nActual: ${String(actual)}`);
  }
};

const assertIncludes = (actual: string, expected: string, label: string) => {
  if (!actual.includes(expected)) {
    throw new Error(`${label}\nMissing: ${expected}\nActual: ${actual}`);
  }
};

const assertNotIncludes = (actual: string, expected: string, label: string) => {
  if (actual.includes(expected)) {
    throw new Error(`${label}\nUnexpected: ${expected}\nActual: ${actual}`);
  }
};

const baseInput: BuildCommandInput = {
  activeOs: OS_IDS.UBUNTU,
  activeTarget: { commandTarget: OS_IDS.UBUNTU },
  targetVersion: "26.04",
  selectedPackageNames: ["git", "zsh"],
  proxmoxGuestAgent: false,
  createAdminUser: false,
  tmuxPrefix: "ctrl-a",
  saveSetupPreferences: true,
  loadSetupPreferences: false,
  stepSelection: {
    packages: true,
    shell: true,
    dotfiles: true,
    tools: true
  },
  assumeYes: true,
  installTpm: true,
  dockerEnabled: true,
  dockerStrategy: DOCKER_STRATEGY_IDS.OFFICIAL,
  nodeStrategy: NODE_STRATEGY_IDS.MISE,
  nodePackageManager: NODE_PACKAGE_MANAGER_IDS.PNPM,
  pythonStrategy: PYTHON_STRATEGY_IDS.SYSTEM_UV,
  javaEnabled: false,
  javaStrategy: JAVA_STRATEGY_IDS.MISE_TEMURIN_21,
  selectedAgentToolIds: [AGENT_TOOL_IDS.CLAUDE_CODE, AGENT_TOOL_IDS.OPENAI_CODEX],
  selectedDeveloperToolIds: [
    DEVELOPER_TOOL_IDS.RUST,
    DEVELOPER_TOOL_IDS.GO,
    DEVELOPER_TOOL_IDS.BUN,
    DEVELOPER_TOOL_IDS.DENO,
    DEVELOPER_TOOL_IDS.GITHUB_CLI
  ],
  adminUserEnabled: true,
  adminUserName: "",
  powerlevel10k: true,
  prepareSystem: true,
  runInTmux: true,
  repoRef: DEFAULT_REF
};

assertEqual(shellQuote("feature/test's"), "'feature/test'\\''s'", "shellQuote escapes single quotes");
assertEqual(
  shellDoubleQuote('echo "$HOME`test`!"'),
  '"echo \\"\\$HOME\\`test\\`\\!\\""',
  "shellDoubleQuote escapes interactive shell metacharacters"
);

const defaultCommands = buildCommands(baseInput);
assertIncludes(defaultCommands.primary, "sudo apt update", "primary command prepares apt metadata first");
assertIncludes(
  defaultCommands.primary,
  "sudo apt install -y 'ca-certificates' 'curl' 'git' 'tmux'",
  "primary command installs bootstrap tools"
);
assertIncludes(
  defaultCommands.primary,
  "tmux new-session -A -s dotfiles",
  "primary command runs inside tmux by default"
);
assertIncludes(defaultCommands.primary, "curl -fsSL", "primary command downloads installer");
assertNotIncludes(defaultCommands.primary, "DOTFILES_REPO_REF=", "default ref does not need env prefix");

const plainCommands = buildCommands({
  ...baseInput,
  prepareSystem: false,
  runInTmux: false
});
assertNotIncludes(plainCommands.primary, "sudo apt update", "prepare system can be disabled");
assertNotIncludes(plainCommands.primary, "tmux new-session", "tmux wrapper can be disabled");
assertIncludes(plainCommands.local, "./setup.sh 'ubuntu'", "local command uses setup dispatcher");
assertIncludes(plainCommands.primary, "'--target-version' '26.04'", "primary command includes target version");
assertIncludes(plainCommands.primary, "'--admin-user-current'", "primary command configures current admin user");
assertIncludes(plainCommands.primary, "'--apt-packages' 'git,zsh'", "primary command includes selected packages");
assertIncludes(plainCommands.primary, "'--tmux-prefix' 'ctrl-a'", "primary command includes tmux prefix preference");
assertIncludes(
  plainCommands.primary,
  "'--save-setup-preferences'",
  "primary command persists non-secret setup preferences"
);
assertIncludes(
  plainCommands.primary,
  "'--node-package-manager' 'pnpm'",
  "primary command includes Node package manager"
);
assertIncludes(
  plainCommands.primary,
  "'--developer-tools' 'rust,go,bun,deno,gh'",
  "primary command includes selected developer tools"
);
assertIncludes(
  plainCommands.primary,
  "'--agent-tools' 'claude-code,openai-codex'",
  "primary command includes selected agent tools"
);
assertIncludes(plainCommands.primary, "'--with-tpm'", "primary command includes TPM flag");

const ubuntuLtsCommands = buildCommands({
  ...baseInput,
  prepareSystem: false,
  runInTmux: false,
  targetVersion: "24.04"
});
assertIncludes(ubuntuLtsCommands.primary, "'--target-version' '24.04'", "Ubuntu 24.04 can be selected");
assertNotIncludes(ubuntuLtsCommands.primary, "'--target-version' '26.04'", "Ubuntu 24.04 replaces the default version");

const customAdminCommands = buildCommands({
  ...baseInput,
  adminUserName: "ozz"
});
assertIncludes(customAdminCommands.primary, "'--admin-user' 'ozz'", "custom admin user is passed to setup");
assertNotIncludes(
  customAdminCommands.primary,
  "'--admin-user-current'",
  "custom admin user replaces current-user flag"
);

const firstBootAdminCommands = buildCommands({
  ...baseInput,
  prepareSystem: false,
  runInTmux: false,
  createAdminUser: true,
  adminUserName: "john",
  tmuxPrefix: "ctrl-b",
  loadSetupPreferences: true
});
assertIncludes(
  firstBootAdminCommands.primary,
  "'--create-admin-user' '--admin-user' 'john'",
  "first-boot command creates the named admin user"
);
assertIncludes(firstBootAdminCommands.primary, "'--tmux-prefix' 'ctrl-b'", "tmux prefix can be changed to Ctrl-b");
assertIncludes(
  firstBootAdminCommands.primary,
  "'--load-setup-preferences'",
  "saved setup preferences can be loaded explicitly"
);
assertNotIncludes(firstBootAdminCommands.primary, "password", "generated command never includes a password field");

const noPowerlevelCommands = buildCommands({
  ...baseInput,
  powerlevel10k: false
});
assertIncludes(noPowerlevelCommands.primary, "'--no-powerlevel10k'", "Powerlevel10k can be disabled");

const customRefCommands = buildCommands({
  ...baseInput,
  prepareSystem: false,
  runInTmux: false,
  repoRef: "feature/test's"
});
assertIncludes(customRefCommands.primary, "DOTFILES_REPO_REF='feature/test'\\''s'", "custom ref is shell quoted");
assertIncludes(customRefCommands.primary, "feature/test'\\''s/install.sh", "custom ref is used in raw GitHub URL");

const noPackageCommands = buildCommands({
  ...baseInput,
  selectedPackageNames: []
});
assertIncludes(noPackageCommands.primary, "'--skip-apt'", "empty selected package list skips apt");
assertIncludes(noPackageCommands.packageCommand, "# No apt packages selected", "empty package preview is explicit");
assertIncludes(
  noPackageCommands.packageCommand,
  "# Admin user: current login user gets sudo access",
  "package preview includes admin user note"
);
assertIncludes(
  noPackageCommands.packageCommand,
  "mise settings add idiomatic_version_file_enable_tools node",
  "mise node preview enables idiomatic version files"
);
assertIncludes(
  noPackageCommands.packageCommand,
  "mise exec node@lts -- npm install -g '@anthropic-ai/claude-code' '@openai/codex'",
  "package preview includes selected agent CLIs"
);
assertIncludes(
  noPackageCommands.packageCommand,
  "mise exec node@lts -- sh -lc 'corepack enable pnpm && corepack prepare pnpm@latest --activate'",
  "package preview enables pnpm through corepack"
);
assertIncludes(noPackageCommands.packageCommand, "mise use -g go@latest", "package preview includes Go through mise");
assertIncludes(noPackageCommands.packageCommand, "mise use -g bun@latest", "package preview includes Bun through mise");
assertIncludes(
  noPackageCommands.packageCommand,
  "mise use -g deno@latest",
  "package preview includes Deno through mise"
);
assertIncludes(
  noPackageCommands.packageCommand,
  "https://sh.rustup.rs",
  "package preview includes Rust through rustup"
);
assertIncludes(noPackageCommands.packageCommand, "GitHub CLI", "package preview includes GitHub CLI note");

const proxmoxGuestAgentCommands = buildCommands({
  ...baseInput,
  prepareSystem: false,
  runInTmux: false,
  selectedPackageNames: ["git", "qemu-guest-agent"],
  proxmoxGuestAgent: true
});
assertIncludes(
  proxmoxGuestAgentCommands.primary,
  "'--proxmox-guest-agent'",
  "primary command enables Proxmox guest-agent setup"
);
assertIncludes(
  proxmoxGuestAgentCommands.packageCommand,
  "sudo apt install -y 'git' 'qemu-guest-agent'",
  "package preview installs qemu guest agent"
);
assertIncludes(
  proxmoxGuestAgentCommands.packageCommand,
  "sudo systemctl enable --now qemu-guest-agent",
  "package preview enables qemu guest agent service"
);

const skippedPackageStep = buildCommands({
  ...baseInput,
  stepSelection: {
    ...baseInput.stepSelection,
    packages: false
  }
});
assertIncludes(skippedPackageStep.primary, "'--skip-apt'", "disabled package step skips apt");
assertNotIncludes(skippedPackageStep.primary, "'--docker-strategy'", "disabled package step omits docker strategy");

const skippedProxmoxPackageStep = buildCommands({
  ...baseInput,
  selectedPackageNames: ["qemu-guest-agent"],
  proxmoxGuestAgent: true,
  stepSelection: {
    ...baseInput.stepSelection,
    packages: false
  }
});
assertIncludes(skippedProxmoxPackageStep.primary, "'--skip-apt'", "disabled package step skips apt");
assertNotIncludes(
  skippedProxmoxPackageStep.primary,
  "'--proxmox-guest-agent'",
  "disabled package step omits Proxmox service flag"
);

assertIncludes(
  buildPackageCommand(
    OS_IDS.MACOS,
    "26.5",
    true,
    "",
    ["git", "node"],
    false,
    DOCKER_STRATEGY_IDS.NONE,
    NODE_STRATEGY_IDS.NVM,
    NODE_PACKAGE_MANAGER_IDS.YARN,
    PYTHON_STRATEGY_IDS.MISE,
    JAVA_STRATEGY_IDS.NONE,
    [],
    [DEVELOPER_TOOL_IDS.GITHUB_CLI]
  ),
  "brew install 'git' 'node'",
  "macOS preview uses brew"
);
assertIncludes(
  buildPackageCommand(
    OS_IDS.RHEL,
    "10.1",
    true,
    "builder",
    ["git"],
    false,
    DOCKER_STRATEGY_IDS.PODMAN,
    NODE_STRATEGY_IDS.MISE,
    NODE_PACKAGE_MANAGER_IDS.NPM,
    PYTHON_STRATEGY_IDS.SYSTEM_UV,
    JAVA_STRATEGY_IDS.DISTRO_OPENJDK_21,
    [],
    [DEVELOPER_TOOL_IDS.GITHUB_CLI]
  ),
  "sudo dnf install -y podman podman-docker",
  "RHEL podman preview uses dnf"
);

assertEqual(
  buildConfigWriteCommand({ path: "~/.config/htop/htoprc", mkdir: "~/.config/htop" }, "field=value"),
  "mkdir -p ~/.config/htop\ncat > ~/.config/htop/htoprc <<'EOF'\nfield=value\nEOF",
  "config write command creates parent directory and final newline"
);

console.log("Command builder tests passed.");
