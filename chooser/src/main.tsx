import { StrictMode, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import corePackagesRaw from "../../Ubuntu/packages/core.txt?raw";
import optionalPackagesRaw from "../../Ubuntu/packages/optional.txt?raw";
import "./styles.css";

const REPO_OWNER = "goznauk";
const REPO_NAME = "dotfiles";
const DEFAULT_REF = "main";

type StepKey = "apt" | "shell" | "dotfiles" | "tools";

type SetupStep = {
  key: StepKey;
  title: string;
  description: string;
  skipFlag: string;
};

const setupSteps: SetupStep[] = [
  {
    key: "apt",
    title: "Apt packages",
    description: "Compiler, shell, Python, tmux, Vim, Docker, and inspection tools.",
    skipFlag: "--skip-apt"
  },
  {
    key: "shell",
    title: "Shell setup",
    description: "oh-my-zsh, Powerlevel10k, highlighting, autosuggestions, completions.",
    skipFlag: "--skip-shell"
  },
  {
    key: "dotfiles",
    title: "Dotfile links",
    description: "Link zsh, Vim, tmux, Git config, and Git exclude files into home.",
    skipFlag: "--skip-dotfiles"
  },
  {
    key: "tools",
    title: "Language tools",
    description: "Install uv, Rust stable, rustfmt, clippy, mise, and Node LTS.",
    skipFlag: "--skip-tools"
  }
];

const shellQuote = (value: string) => `'${value.replaceAll("'", "'\\''")}'`;

const parsePackageList = (raw: string) =>
  raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0 && !line.startsWith("#"));

function App() {
  const corePackages = useMemo(() => parsePackageList(corePackagesRaw), []);
  const optionalPackages = useMemo(() => parsePackageList(optionalPackagesRaw), []);
  const [selectedSteps, setSelectedSteps] = useState<Record<StepKey, boolean>>({
    apt: true,
    shell: true,
    dotfiles: true,
    tools: true
  });
  const [selectedOptional, setSelectedOptional] = useState<string[]>(optionalPackages);
  const [installTpm, setInstallTpm] = useState(false);
  const [assumeYes, setAssumeYes] = useState(true);
  const [repoRef, setRepoRef] = useState(DEFAULT_REF);
  const [copied, setCopied] = useState<"bootstrap" | "local" | null>(null);

  const generatedFlags = useMemo(() => {
    const flags: string[] = [];

    if (assumeYes) {
      flags.push("--yes");
    }

    for (const step of setupSteps) {
      if (!selectedSteps[step.key]) {
        flags.push(step.skipFlag);
      }
    }

    if (installTpm) {
      flags.push("--with-tpm");
    }

    if (selectedSteps.apt) {
      if (selectedOptional.length === 0) {
        flags.push("--no-optional-packages");
      } else if (selectedOptional.length < optionalPackages.length) {
        flags.push("--optional-packages", selectedOptional.join(","));
      }
    }

    return flags;
  }, [assumeYes, installTpm, optionalPackages.length, selectedOptional, selectedSteps]);

  const bootstrapCommand = useMemo(() => {
    const activeRef = repoRef.trim() || DEFAULT_REF;
    const envPrefix =
      activeRef === DEFAULT_REF ? "" : `DOTFILES_REPO_REF=${shellQuote(activeRef)} `;
    const url = `https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${activeRef}/install.sh`;
    const args = ["ubuntu", ...generatedFlags].map(shellQuote).join(" ");
    return `curl -fsSL ${shellQuote(url)} | ${envPrefix}bash -s -- ${args}`;
  }, [generatedFlags, repoRef]);

  const localCommand = useMemo(() => {
    const args = ["ubuntu", ...generatedFlags].map(shellQuote).join(" ");
    return `./setup.sh ${args}`;
  }, [generatedFlags]);

  const selectedSummary = useMemo(() => {
    const activeSteps = setupSteps.filter((step) => selectedSteps[step.key]).length;
    return {
      steps: activeSteps,
      optional: selectedSteps.apt ? selectedOptional.length : 0,
      totalOptional: optionalPackages.length
    };
  }, [optionalPackages.length, selectedOptional.length, selectedSteps]);

  const toggleStep = (key: StepKey) => {
    setSelectedSteps((current) => ({ ...current, [key]: !current[key] }));
  };

  const toggleOptionalPackage = (packageName: string) => {
    setSelectedOptional((current) =>
      current.includes(packageName)
        ? current.filter((item) => item !== packageName)
        : [...current, packageName].sort((a, b) => optionalPackages.indexOf(a) - optionalPackages.indexOf(b))
    );
  };

  const copyCommand = async (kind: "bootstrap" | "local", command: string) => {
    await navigator.clipboard.writeText(command);
    setCopied(kind);
    window.setTimeout(() => setCopied(null), 1600);
  };

  return (
    <main className="app-shell">
      <section className="hero">
        <div className="hero-copy">
          <p className="section-label">Ubuntu dotfiles</p>
          <h1>Choose the setup, copy one command.</h1>
          <p>
            Build an Ubuntu install command for this dotfiles repo. The page is static:
            it generates commands, and your terminal runs them.
          </p>
        </div>
        <div className="summary-panel" aria-label="Selected setup summary">
          <span>{selectedSummary.steps} setup groups</span>
          <strong>
            {selectedSummary.optional}/{selectedSummary.totalOptional}
          </strong>
          <span>optional packages</span>
        </div>
      </section>

      <section className="layout-grid">
        <div className="config-column">
          <section className="panel">
            <div className="panel-heading">
              <p className="section-label">Setup</p>
              <h2>Install groups</h2>
            </div>
            <div className="step-list">
              {setupSteps.map((step) => (
                <label className="option-row" key={step.key}>
                  <input
                    type="checkbox"
                    checked={selectedSteps[step.key]}
                    onChange={() => toggleStep(step.key)}
                  />
                  <span>
                    <strong>{step.title}</strong>
                    <small>{step.description}</small>
                  </span>
                </label>
              ))}
            </div>
          </section>

          <section className="panel">
            <div className="panel-heading">
              <p className="section-label">Packages</p>
              <h2>Optional apt packages</h2>
            </div>
            <div className="package-actions">
              <button type="button" onClick={() => setSelectedOptional(optionalPackages)}>
                Select all
              </button>
              <button type="button" onClick={() => setSelectedOptional([])}>
                Clear
              </button>
            </div>
            <div className="package-grid" aria-disabled={!selectedSteps.apt}>
              {optionalPackages.map((packageName) => (
                <label className="package-pill" key={packageName}>
                  <input
                    type="checkbox"
                    disabled={!selectedSteps.apt}
                    checked={selectedOptional.includes(packageName)}
                    onChange={() => toggleOptionalPackage(packageName)}
                  />
                  <span>{packageName}</span>
                </label>
              ))}
            </div>
            <details className="core-packages">
              <summary>Core package list ({corePackages.length})</summary>
              <ul>
                {corePackages.map((packageName) => (
                  <li key={packageName}>{packageName}</li>
                ))}
              </ul>
            </details>
          </section>
        </div>

        <aside className="command-column">
          <section className="panel sticky-panel">
            <div className="panel-heading">
              <p className="section-label">Command</p>
              <h2>Run from terminal</h2>
            </div>
            <label className="field">
              <span>Repository ref</span>
              <input
                value={repoRef}
                onChange={(event) => setRepoRef(event.target.value)}
                spellCheck={false}
              />
            </label>
            <label className="switch-row">
              <input
                type="checkbox"
                checked={assumeYes}
                onChange={() => setAssumeYes((value) => !value)}
              />
              <span>Use --yes</span>
            </label>
            <label className="switch-row">
              <input
                type="checkbox"
                checked={installTpm}
                onChange={() => setInstallTpm((value) => !value)}
              />
              <span>Install TPM</span>
            </label>

            <CommandBlock
              title="Bootstrap command"
              command={bootstrapCommand}
              copied={copied === "bootstrap"}
              onCopy={() => copyCommand("bootstrap", bootstrapCommand)}
            />
            <CommandBlock
              title="Already cloned"
              command={localCommand}
              copied={copied === "local"}
              onCopy={() => copyCommand("local", localCommand)}
            />
          </section>
        </aside>
      </section>
    </main>
  );
}

type CommandBlockProps = {
  title: string;
  command: string;
  copied: boolean;
  onCopy: () => void;
};

function CommandBlock({ title, command, copied, onCopy }: CommandBlockProps) {
  return (
    <div className="command-block">
      <div className="command-header">
        <h3>{title}</h3>
        <button type="button" onClick={onCopy}>
          {copied ? "Copied" : "Copy"}
        </button>
      </div>
      <pre>
        <code>{command}</code>
      </pre>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
