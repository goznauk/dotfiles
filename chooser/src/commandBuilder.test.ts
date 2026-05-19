import {
  DEFAULT_REF,
  buildCommands,
  buildConfigWriteCommand,
  buildPackageCommand,
  shellDoubleQuote,
  shellQuote,
  type BuildCommandInput
} from "./commandBuilder.js";
import { DOCKER_STRATEGY_IDS, JAVA_STRATEGY_IDS, NODE_STRATEGY_IDS, OS_IDS, PYTHON_STRATEGY_IDS } from "./ids.js";

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
  pythonStrategy: PYTHON_STRATEGY_IDS.SYSTEM_UV,
  javaEnabled: false,
  javaStrategy: JAVA_STRATEGY_IDS.MISE_TEMURIN_21,
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
assertIncludes(plainCommands.primary, "'--apt-packages' 'git,zsh'", "primary command includes selected packages");
assertIncludes(plainCommands.primary, "'--with-tpm'", "primary command includes TPM flag");

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

const skippedPackageStep = buildCommands({
  ...baseInput,
  stepSelection: {
    ...baseInput.stepSelection,
    packages: false
  }
});
assertIncludes(skippedPackageStep.primary, "'--skip-apt'", "disabled package step skips apt");
assertNotIncludes(skippedPackageStep.primary, "'--docker-strategy'", "disabled package step omits docker strategy");

assertIncludes(
  buildPackageCommand(
    OS_IDS.MACOS,
    "26.5",
    ["git", "node"],
    DOCKER_STRATEGY_IDS.NONE,
    NODE_STRATEGY_IDS.NVM,
    PYTHON_STRATEGY_IDS.MISE,
    JAVA_STRATEGY_IDS.NONE
  ),
  "brew install 'git' 'node'",
  "macOS preview uses brew"
);
assertIncludes(
  buildPackageCommand(
    OS_IDS.RHEL,
    "10.1",
    ["git"],
    DOCKER_STRATEGY_IDS.PODMAN,
    NODE_STRATEGY_IDS.MISE,
    PYTHON_STRATEGY_IDS.SYSTEM_UV,
    JAVA_STRATEGY_IDS.DISTRO_OPENJDK_21
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
