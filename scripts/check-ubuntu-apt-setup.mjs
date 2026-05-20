import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const rootDir = join(scriptDir, "..");
const optionalPackages = readFileSync(join(rootDir, "Ubuntu/packages/optional.txt"), "utf8")
  .split(/\r?\n/)
  .map((line) => line.trim())
  .filter((line) => line && !line.startsWith("#"));
const setupScript = readFileSync(join(rootDir, "Ubuntu/setup-ubuntu.sh"), "utf8");
const universePackages = ["chromium-browser", "eza"];
const proxmoxFlagIndex = setupScript.indexOf("--proxmox-guest-agent");
const proxmoxPackageIndex = setupScript.indexOf('"qemu-guest-agent"');
const proxmoxEnableFunctionIndex = setupScript.indexOf("enable_qemu_guest_agent()");
const installFunctionMatch = setupScript.match(/install_apt_packages\(\) \{[\s\S]*?\n\}/);
const resolveFunctionMatch = setupScript.match(/resolve_apt_packages\(\) \{[\s\S]*?\n\}/);
const preferenceFunctionMatch = setupScript.match(/save_setup_preferences\(\) \{[\s\S]*?\n\}/);
const tmuxFunctionMatch = setupScript.match(/write_tmux_prefix_override\(\) \{[\s\S]*?\n\}/);

const assert = (condition, message) => {
  if (!condition) {
    throw new Error(message);
  }
};

if (universePackages.some((packageName) => optionalPackages.includes(packageName))) {
  assert(
    setupScript.includes("enable_ubuntu_universe"),
    "Ubuntu installer must enable universe before installing universe packages."
  );

  assert(installFunctionMatch, "Ubuntu installer must have install_apt_packages.");
  const installFunction = installFunctionMatch[0];
  const enableCallIndex = installFunction.indexOf("enable_ubuntu_universe");
  const packageInstallIndex = installFunction.indexOf('sudo apt install -y "${packages[@]}"');
  assert(enableCallIndex >= 0, "install_apt_packages must call enable_ubuntu_universe.");
  assert(packageInstallIndex > enableCallIndex, "Ubuntu universe setup must run before apt package install.");
}

assert(installFunctionMatch, "Ubuntu installer must have install_apt_packages.");
assert(resolveFunctionMatch, "Ubuntu installer must have resolve_apt_packages.");
assert(proxmoxFlagIndex >= 0, "Ubuntu installer must expose --proxmox-guest-agent.");
assert(proxmoxPackageIndex >= 0, "Ubuntu installer must append qemu-guest-agent when Proxmox support is enabled.");
assert(
  resolveFunctionMatch[0].includes('"qemu-guest-agent"'),
  "resolve_apt_packages must append qemu-guest-agent for Proxmox support."
);
assert(proxmoxEnableFunctionIndex >= 0, "Ubuntu installer must define enable_qemu_guest_agent.");
assert(
  setupScript.includes("sudo systemctl enable --now qemu-guest-agent"),
  "Ubuntu installer must enable and start qemu-guest-agent."
);
const installFunction = installFunctionMatch[0];
const packageInstallIndex = installFunction.indexOf('sudo apt install -y "${packages[@]}"');
const proxmoxEnableCallIndex = installFunction.indexOf("enable_qemu_guest_agent");
assert(packageInstallIndex >= 0, "install_apt_packages must install resolved apt packages.");
assert(
  proxmoxEnableCallIndex > packageInstallIndex,
  "qemu-guest-agent service enablement must run after apt package install."
);

assert(setupScript.includes("--create-admin-user"), "Ubuntu installer must expose --create-admin-user.");
assert(
  setupScript.includes("prompt_admin_user_password"),
  "Ubuntu installer must prompt interactively for first-boot admin passwords."
);
assert(setupScript.includes("read -rs"), "Admin password prompts must use hidden input.");
assert(setupScript.includes("chpasswd"), "Admin password setup must use stdin, not command arguments.");
assert(!setupScript.includes("--admin-password"), "Ubuntu installer must not accept passwords as CLI arguments.");
assert(setupScript.includes("--tmux-prefix"), "Ubuntu installer must expose --tmux-prefix.");
assert(setupScript.includes("ctrl-a|ctrl-b"), "Ubuntu installer must only accept ctrl-a or ctrl-b tmux prefixes.");
assert(tmuxFunctionMatch, "Ubuntu installer must define write_tmux_prefix_override.");
assert(
  tmuxFunctionMatch[0].includes(".tmux.conf.local"),
  "Tmux prefix overrides must be written to ~/.tmux.conf.local."
);
assert(setupScript.includes("--save-setup-preferences"), "Ubuntu installer must expose --save-setup-preferences.");
assert(setupScript.includes("--load-setup-preferences"), "Ubuntu installer must expose --load-setup-preferences.");
assert(preferenceFunctionMatch, "Ubuntu installer must define save_setup_preferences.");
assert(
  preferenceFunctionMatch[0].includes("chmod 600"),
  "Saved setup preferences must be written with 0600 permissions."
);
assert(
  !preferenceFunctionMatch[0].toLowerCase().includes("password"),
  "Saved setup preferences must not write password values."
);

console.log("Ubuntu apt setup check passed.");
