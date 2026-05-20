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

console.log("Ubuntu apt setup check passed.");
