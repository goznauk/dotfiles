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

const assert = (condition, message) => {
  if (!condition) {
    throw new Error(message);
  }
};

if (optionalPackages.includes("eza")) {
  assert(
    setupScript.includes("enable_ubuntu_universe"),
    "Ubuntu installer must enable universe before installing eza."
  );

  const installFunctionMatch = setupScript.match(/install_apt_packages\(\) \{[\s\S]*?\n\}/);
  assert(installFunctionMatch, "Ubuntu installer must have install_apt_packages.");
  const installFunction = installFunctionMatch[0];
  const enableCallIndex = installFunction.indexOf("enable_ubuntu_universe");
  const packageInstallIndex = installFunction.indexOf('sudo apt install -y "${packages[@]}"');
  assert(enableCallIndex >= 0, "install_apt_packages must call enable_ubuntu_universe.");
  assert(packageInstallIndex > enableCallIndex, "Ubuntu universe setup must run before apt package install.");
}

console.log("Ubuntu apt setup check passed.");
