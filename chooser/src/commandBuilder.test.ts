import {
  DEFAULT_REF,
  buildCommands,
  buildConfigWriteCommand,
  buildPackageCommand,
  shellQuote,
  type BuildCommandInput
} from "./commandBuilder.js";

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
  activeOs: "ubuntu",
  activeTarget: { commandTarget: "ubuntu" },
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
  dockerStrategy: "official",
  nodeStrategy: "mise",
  pythonStrategy: "system-uv",
  javaEnabled: false,
  javaStrategy: "mise-temurin-21",
  repoRef: DEFAULT_REF
};

assertEqual(shellQuote("feature/test's"), "'feature/test'\\''s'", "shellQuote escapes single quotes");

const defaultCommands = buildCommands(baseInput);
assertIncludes(defaultCommands.primary, "curl -fsSL", "primary command downloads installer");
assertIncludes(defaultCommands.primary, "'--target-version' '26.04'", "primary command includes target version");
assertIncludes(defaultCommands.primary, "'--apt-packages' 'git,zsh'", "primary command includes selected packages");
assertIncludes(defaultCommands.primary, "'--with-tpm'", "primary command includes TPM flag");
assertNotIncludes(defaultCommands.primary, "DOTFILES_REPO_REF=", "default ref does not need env prefix");
assertIncludes(defaultCommands.local, "./setup.sh 'ubuntu'", "local command uses setup dispatcher");

const customRefCommands = buildCommands({
  ...baseInput,
  repoRef: "feature/test's"
});
assertIncludes(
  customRefCommands.primary,
  "DOTFILES_REPO_REF='feature/test'\\''s'",
  "custom ref is shell quoted"
);
assertIncludes(
  customRefCommands.primary,
  "feature/test'\\''s/install.sh",
  "custom ref is used in raw GitHub URL"
);

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
assertNotIncludes(
  skippedPackageStep.primary,
  "'--docker-strategy'",
  "disabled package step omits docker strategy"
);

assertIncludes(
  buildPackageCommand("macos", "26.5", ["git", "node"], "none", "nvm", "mise", "none"),
  "brew install 'git' 'node'",
  "macOS preview uses brew"
);
assertIncludes(
  buildPackageCommand("rhel", "10.1", ["git"], "podman", "mise", "system-uv", "distro-openjdk-21"),
  "sudo dnf install -y podman podman-docker",
  "RHEL podman preview uses dnf"
);

assertEqual(
  buildConfigWriteCommand({ path: "~/.config/htop/htoprc", mkdir: "~/.config/htop" }, "field=value"),
  "mkdir -p ~/.config/htop\ncat > ~/.config/htop/htoprc <<'EOF'\nfield=value\nEOF",
  "config write command creates parent directory and final newline"
);

console.log("Command builder tests passed.");
