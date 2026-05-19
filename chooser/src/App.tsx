import { useEffect, useMemo, useState } from "react";
import {
  catalog,
  defaultVersionForTarget,
  packageDescriptionFor,
  packageNamesForOs,
  type AgentTool,
  type DeveloperTool,
  type NodePackageManager,
  type OsTarget,
  type PackageGroup,
  type Strategy
} from "./catalog";
import { DEFAULT_REF, buildCommands, buildConfigWriteCommand, installSteps, type CommandSet } from "./commandBuilder";
import {
  blockKindDescriptions,
  blockKindLabels,
  buildConfigContent,
  configDefinitions,
  createInitialActiveBlocks,
  createInitialConfigBlocks,
  pluginNoteFor,
  type ConfigBlock
} from "./configDefinitions";
import {
  CONFIG_KEYS,
  DOCKER_STRATEGY_IDS,
  INSTALL_STEP_KEYS,
  JAVA_STRATEGY_IDS,
  NODE_STRATEGY_IDS,
  NODE_PACKAGE_MANAGER_IDS,
  OS_IDS,
  PYTHON_STRATEGY_IDS,
  THEME_MODES,
  VIEW_IDS,
  type AgentToolId,
  type ConfigKey,
  type DeveloperToolId,
  type DockerStrategyId,
  type InstallStepKey,
  type JavaStrategyId,
  type NodePackageManagerId,
  type NodeStrategyId,
  type OsId,
  type PythonStrategyId,
  type ThemeMode,
  type ViewId
} from "./ids";

type DraggedBlock = { configKey: ConfigKey; blockId: string } | null;

const splitCustomPackages = (value: string) =>
  value
    .split(/[,\s]+/)
    .map((item) => item.trim())
    .filter(Boolean);

const unique = (items: string[]) => Array.from(new Set(items.filter(Boolean)));

const defaultAgentToolIds = () => catalog.agentTools.filter((tool) => tool.defaultSelected).map((tool) => tool.id);

const defaultDeveloperToolIds = () =>
  catalog.developerTools.filter((tool) => tool.defaultSelected).map((tool) => tool.id);

const defaultDockerStrategy = (osId: OsId): DockerStrategyId => {
  const strategy = catalog.strategies.docker.find((item) => item.defaults?.includes(osId));
  return (strategy?.id as DockerStrategyId | undefined) ?? DOCKER_STRATEGY_IDS.NONE;
};

const targetShortLabel = (target: OsTarget) => (target.id === OS_IDS.AMAZON ? "AL2023" : target.label);

const createInitialTargetVersions = () =>
  Object.fromEntries(catalog.osTargets.map((target) => [target.id, defaultVersionForTarget(target)])) as Record<
    OsId,
    string
  >;

const initialParams =
  typeof window === "undefined" ? new URLSearchParams() : new URLSearchParams(window.location.search);

const readInitialTheme = (): ThemeMode => {
  if (typeof window === "undefined") {
    return THEME_MODES.LIGHT;
  }
  const queryTheme = initialParams.get("theme");
  if (queryTheme === THEME_MODES.LIGHT || queryTheme === THEME_MODES.DARK) {
    return queryTheme;
  }
  try {
    const stored = window.localStorage.getItem("dotfiles-theme");
    if (stored === THEME_MODES.LIGHT || stored === THEME_MODES.DARK) {
      return stored;
    }
  } catch {
    return THEME_MODES.LIGHT;
  }
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? THEME_MODES.DARK : THEME_MODES.LIGHT;
};

const readInitialView = (): ViewId => {
  const view = initialParams.get("view");
  if (view === "install") {
    return VIEW_IDS.TARGET;
  }
  return view === VIEW_IDS.TARGET ||
    view === VIEW_IDS.PACKAGES ||
    view === VIEW_IDS.TOOLCHAINS ||
    view === VIEW_IDS.CONFIGS ||
    view === VIEW_IDS.SUMMARY
    ? view
    : VIEW_IDS.TARGET;
};

const readInitialOs = (): OsId => {
  const os = initialParams.get("os");
  return catalog.osTargets.some((target) => target.id === os) ? (os as OsId) : OS_IDS.UBUNTU;
};

const readInitialConfig = (): ConfigKey => {
  const config = initialParams.get("config");
  return config === CONFIG_KEYS.VIMRC ||
    config === CONFIG_KEYS.TMUX ||
    config === CONFIG_KEYS.GITCONFIG ||
    config === CONFIG_KEYS.HTOP ||
    config === CONFIG_KEYS.ZSHRC
    ? config
    : CONFIG_KEYS.ZSHRC;
};

const readInitialExpandedGroups = () => {
  const groups = new Set(
    initialParams
      .getAll("group")
      .flatMap((value) => value.split(","))
      .map((value) => value.trim())
      .filter(Boolean)
  );

  return Object.fromEntries(catalog.groups.map((group) => [group.id, groups.has(group.id)]));
};

const sectionAnchorId = (viewId: ViewId) => `${viewId}-section`;
const sectionNavItems: Array<{ id: ViewId; label: string }> = [
  { id: VIEW_IDS.TARGET, label: "Target" },
  { id: VIEW_IDS.PACKAGES, label: "Packages" },
  { id: VIEW_IDS.TOOLCHAINS, label: "Toolchains" },
  { id: VIEW_IDS.CONFIGS, label: "Config" },
  { id: VIEW_IDS.SUMMARY, label: "Run" }
];

const scrollSectionIntoView = (viewId: ViewId, behavior: ScrollBehavior = "smooth") => {
  const section = document.getElementById(sectionAnchorId(viewId));
  if (!section) {
    return false;
  }

  if (typeof section.scrollIntoView === "function") {
    section.scrollIntoView({ behavior, block: "start" });
    return true;
  }

  const anchor = `#${sectionAnchorId(viewId)}`;
  if (window.location.hash !== anchor) {
    window.location.hash = anchor;
  }
  return true;
};

export const App = () => {
  const initialOs = readInitialOs();
  const initialView = readInitialView();
  const [activeView, setActiveView] = useState<ViewId>(initialView);
  const [themeMode, setThemeMode] = useState<ThemeMode>(readInitialTheme);
  const [activeOs, setActiveOs] = useState<OsId>(initialOs);
  const [targetSelected, setTargetSelected] = useState(
    () => initialParams.has("os") || initialView !== VIEW_IDS.TARGET
  );
  const [targetVersions, setTargetVersions] = useState<Record<OsId, string>>(createInitialTargetVersions);
  const [selectedPackageIds, setSelectedPackageIds] = useState<string[]>(
    catalog.packages.filter((item) => item.defaultSelected).map((item) => item.id)
  );
  const [expandedGroups, setExpandedGroups] = useState<Record<string, boolean>>(readInitialExpandedGroups);
  const [stepSelection, setStepSelection] = useState<Record<InstallStepKey, boolean>>({
    [INSTALL_STEP_KEYS.PACKAGES]: true,
    [INSTALL_STEP_KEYS.SHELL]: true,
    [INSTALL_STEP_KEYS.DOTFILES]: true,
    [INSTALL_STEP_KEYS.TOOLS]: true
  });
  const [query, setQuery] = useState("");
  const [customPackages, setCustomPackages] = useState("");
  const [dockerStrategy, setDockerStrategy] = useState<DockerStrategyId>(() => {
    const strategy = defaultDockerStrategy(initialOs);
    return strategy === DOCKER_STRATEGY_IDS.NONE ? DOCKER_STRATEGY_IDS.OFFICIAL : strategy;
  });
  const [dockerEnabled, setDockerEnabled] = useState(
    initialParams.get("docker") === "off" ? false : defaultDockerStrategy(initialOs) !== DOCKER_STRATEGY_IDS.NONE
  );
  const [nodeStrategy, setNodeStrategy] = useState<NodeStrategyId>(NODE_STRATEGY_IDS.MISE);
  const [nodeEnabled, setNodeEnabled] = useState(true);
  const [nodePackageManager, setNodePackageManager] = useState<NodePackageManagerId>(NODE_PACKAGE_MANAGER_IDS.PNPM);
  const [selectedAgentToolIds, setSelectedAgentToolIds] = useState<AgentToolId[]>(defaultAgentToolIds);
  const [selectedDeveloperToolIds, setSelectedDeveloperToolIds] = useState<DeveloperToolId[]>(defaultDeveloperToolIds);
  const [pythonStrategy, setPythonStrategy] = useState<PythonStrategyId>(PYTHON_STRATEGY_IDS.SYSTEM_UV);
  const [pythonEnabled, setPythonEnabled] = useState(true);
  const [javaStrategy, setJavaStrategy] = useState<JavaStrategyId>(JAVA_STRATEGY_IDS.MISE_TEMURIN_21);
  const [javaEnabled, setJavaEnabled] = useState(false);
  const [adminUserEnabled, setAdminUserEnabled] = useState(true);
  const [adminUserName, setAdminUserName] = useState("");
  const [installTpm, setInstallTpm] = useState(false);
  const [powerlevel10k, setPowerlevel10k] = useState(true);
  const [prepareSystem, setPrepareSystem] = useState(true);
  const [runInTmux, setRunInTmux] = useState(true);
  const [assumeYes, setAssumeYes] = useState(true);
  const [repoRef, setRepoRef] = useState(DEFAULT_REF);
  const [copied, setCopied] = useState<string | null>(null);
  const [copyError, setCopyError] = useState<string | null>(null);
  const [activeConfig, setActiveConfig] = useState<ConfigKey>(readInitialConfig);
  const [configBlocks, setConfigBlocks] = useState<Record<ConfigKey, ConfigBlock[]>>(createInitialConfigBlocks);
  const [activeConfigBlockIds, setActiveConfigBlockIds] =
    useState<Record<ConfigKey, string>>(createInitialActiveBlocks);
  const [draggedBlock, setDraggedBlock] = useState<DraggedBlock>(null);

  useEffect(() => {
    document.documentElement.dataset.theme = themeMode;
    document.documentElement.style.colorScheme = themeMode;
    try {
      window.localStorage.setItem("dotfiles-theme", themeMode);
    } catch {
      // Ignore private browsing or blocked storage.
    }
  }, [themeMode]);

  useEffect(() => {
    const sections = sectionNavItems.map((item) => item.id);
    const updateActiveView = () => {
      let currentView: ViewId = VIEW_IDS.TARGET;
      for (const viewId of sections) {
        const section = document.getElementById(sectionAnchorId(viewId));
        if (section && section.getBoundingClientRect().top <= 128) {
          currentView = viewId;
        }
      }
      setActiveView(currentView);
    };

    window.addEventListener("scroll", updateActiveView, { passive: true });
    window.setTimeout(() => {
      if (initialView !== VIEW_IDS.TARGET && scrollSectionIntoView(initialView, "auto")) {
        updateActiveView();
      } else {
        updateActiveView();
      }
    }, 0);

    return () => window.removeEventListener("scroll", updateActiveView);
  }, [initialView]);

  const activeTarget = catalog.osTargets.find((target) => target.id === activeOs) ?? catalog.osTargets[0];
  const activeTargetVersion = targetVersions[activeOs] ?? defaultVersionForTarget(activeTarget);
  const selectedPackageItems = useMemo(
    () => catalog.packages.filter((item) => selectedPackageIds.includes(item.id)),
    [selectedPackageIds]
  );
  const customPackageList = useMemo(() => splitCustomPackages(customPackages), [customPackages]);
  const selectedPackageNames = useMemo(
    () => unique([...selectedPackageItems.flatMap((item) => packageNamesForOs(item, activeOs)), ...customPackageList]),
    [activeOs, customPackageList, selectedPackageItems]
  );
  const commandSet = useMemo(
    () =>
      buildCommands({
        activeOs,
        activeTarget,
        targetVersion: activeTargetVersion,
        selectedPackageNames,
        stepSelection,
        assumeYes,
        installTpm,
        dockerEnabled,
        dockerStrategy,
        nodeStrategy: nodeEnabled ? nodeStrategy : NODE_STRATEGY_IDS.NONE,
        nodePackageManager,
        pythonStrategy: pythonEnabled ? pythonStrategy : PYTHON_STRATEGY_IDS.NONE,
        javaEnabled,
        javaStrategy,
        selectedAgentToolIds: nodeEnabled ? selectedAgentToolIds : [],
        selectedDeveloperToolIds,
        adminUserEnabled,
        adminUserName,
        powerlevel10k,
        prepareSystem,
        runInTmux,
        repoRef
      }),
    [
      activeOs,
      activeTarget,
      activeTargetVersion,
      adminUserEnabled,
      adminUserName,
      assumeYes,
      dockerEnabled,
      dockerStrategy,
      installTpm,
      javaEnabled,
      javaStrategy,
      nodeEnabled,
      nodePackageManager,
      nodeStrategy,
      powerlevel10k,
      prepareSystem,
      pythonEnabled,
      pythonStrategy,
      repoRef,
      runInTmux,
      selectedAgentToolIds,
      selectedDeveloperToolIds,
      selectedPackageNames,
      stepSelection
    ]
  );
  const configContents = useMemo(
    () =>
      Object.fromEntries(
        (Object.keys(configBlocks) as ConfigKey[]).map((key) => [key, buildConfigContent(configBlocks[key])])
      ) as Record<ConfigKey, string>,
    [configBlocks]
  );
  const dockerStrategies = useMemo(
    () => catalog.strategies.docker.filter((strategy) => strategy.id !== DOCKER_STRATEGY_IDS.NONE),
    []
  );
  const nodeStrategies = useMemo(
    () => catalog.strategies.node.filter((strategy) => strategy.id !== NODE_STRATEGY_IDS.NONE),
    []
  );
  const pythonStrategies = useMemo(
    () => catalog.strategies.python.filter((strategy) => strategy.id !== PYTHON_STRATEGY_IDS.NONE),
    []
  );
  const javaStrategies = useMemo(
    () => catalog.strategies.java.filter((strategy) => strategy.id !== JAVA_STRATEGY_IDS.NONE),
    []
  );
  const selectedGroups = useMemo(
    () =>
      catalog.groups
        .map((group) => {
          const groupPackages = catalog.packages.filter((item) => item.group === group.id);
          return {
            group,
            selectedCount: groupPackages.filter((item) => selectedPackageIds.includes(item.id)).length,
            totalCount: groupPackages.length
          };
        })
        .filter((item) => item.totalCount > 0),
    [selectedPackageIds]
  );
  const selectedAgentTools = useMemo(
    () => catalog.agentTools.filter((tool) => selectedAgentToolIds.includes(tool.id)),
    [selectedAgentToolIds]
  );
  const selectedDeveloperTools = useMemo(
    () => catalog.developerTools.filter((tool) => selectedDeveloperToolIds.includes(tool.id)),
    [selectedDeveloperToolIds]
  );

  const switchOs = (osId: OsId) => {
    const nextDockerStrategy = defaultDockerStrategy(osId);
    setActiveOs(osId);
    setDockerEnabled(nextDockerStrategy !== DOCKER_STRATEGY_IDS.NONE);
    setDockerStrategy(
      nextDockerStrategy === DOCKER_STRATEGY_IDS.NONE ? DOCKER_STRATEGY_IDS.OFFICIAL : nextDockerStrategy
    );
  };

  const togglePackage = (packageId: string) => {
    setSelectedPackageIds((current) =>
      current.includes(packageId) ? current.filter((item) => item !== packageId) : [...current, packageId]
    );
  };

  const setGroupSelection = (groupId: string, selected: boolean) => {
    const groupPackageIds = catalog.packages.filter((item) => item.group === groupId).map((item) => item.id);
    setSelectedPackageIds((current) => {
      if (selected) {
        return unique([...current, ...groupPackageIds]);
      }
      return current.filter((item) => !groupPackageIds.includes(item));
    });
  };
  const toggleAgentTool = (toolId: AgentToolId) => {
    setSelectedAgentToolIds((current) =>
      current.includes(toolId) ? current.filter((item) => item !== toolId) : [...current, toolId]
    );
  };
  const toggleDeveloperTool = (toolId: DeveloperToolId) => {
    setSelectedDeveloperToolIds((current) =>
      current.includes(toolId) ? current.filter((item) => item !== toolId) : [...current, toolId]
    );
  };

  const copyText = async (key: string, value: string) => {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(key);
      setCopyError(null);
      window.setTimeout(() => setCopied(null), 1400);
    } catch {
      setCopied(null);
      setCopyError("Copy failed. Select the command text and copy it manually.");
      window.setTimeout(() => setCopyError(null), 5000);
    }
  };

  const configCommand = buildConfigWriteCommand(configDefinitions[activeConfig], configContents[activeConfig]);
  const updateConfigBlock = (blockId: string, updater: (block: ConfigBlock) => ConfigBlock) => {
    setConfigBlocks((current) => ({
      ...current,
      [activeConfig]: current[activeConfig].map((block) => (block.id === blockId ? updater(block) : block))
    }));
  };
  const moveConfigBlock = (blockId: string, direction: -1 | 1) => {
    setConfigBlocks((current) => {
      const blocks = [...current[activeConfig]];
      const index = blocks.findIndex((block) => block.id === blockId);
      const nextIndex = index + direction;
      if (index < 0 || nextIndex < 0 || nextIndex >= blocks.length) {
        return current;
      }
      const [block] = blocks.splice(index, 1);
      blocks.splice(nextIndex, 0, block);
      return { ...current, [activeConfig]: blocks };
    });
  };
  const dropConfigBlock = (targetBlockId: string) => {
    if (!draggedBlock || draggedBlock.configKey !== activeConfig || draggedBlock.blockId === targetBlockId) {
      setDraggedBlock(null);
      return;
    }

    setConfigBlocks((current) => {
      const blocks = [...current[activeConfig]];
      const fromIndex = blocks.findIndex((block) => block.id === draggedBlock.blockId);
      const toIndex = blocks.findIndex((block) => block.id === targetBlockId);
      if (fromIndex < 0 || toIndex < 0) {
        return current;
      }
      const [block] = blocks.splice(fromIndex, 1);
      blocks.splice(toIndex, 0, block);
      return { ...current, [activeConfig]: blocks };
    });
    setDraggedBlock(null);
  };
  const resetConfigBlock = (blockId: string) => {
    const originalBlock = configDefinitions[activeConfig].blocks.find((block) => block.id === blockId);
    if (!originalBlock) {
      return;
    }
    updateConfigBlock(blockId, (block) => ({ ...block, content: originalBlock.content }));
  };

  return (
    <main className="app-shell">
      <header className="topbar">
        <div>
          <p className="section-label">goznauk/dotfiles</p>
          <h1>Build a setup plan.</h1>
        </div>
        <div className="topbar-actions">
          <ThemeToggle mode={themeMode} onChange={setThemeMode} />
        </div>
      </header>

      <nav className="view-tabs sticky-tabs" aria-label="Chooser sections">
        {sectionNavItems.map((item) => (
          <a
            className={activeView === item.id ? "active" : ""}
            href={`#${sectionAnchorId(item.id)}`}
            key={item.id}
            onClick={() => setActiveView(item.id)}
          >
            {item.label}
          </a>
        ))}
      </nav>

      <div className="page-sections">
        <section className="scroll-section target-section" id={sectionAnchorId(VIEW_IDS.TARGET)}>
          <TargetSelector
            activeOs={activeOs}
            activeTarget={activeTarget}
            targetSelected={targetSelected}
            targetVersion={activeTargetVersion}
            onChange={switchOs}
            onTargetSelected={() => setTargetSelected(true)}
            onVersionChange={(version) => setTargetVersions((current) => ({ ...current, [activeOs]: version }))}
          />
          <UserSettingsPanel
            adminUserEnabled={adminUserEnabled}
            adminUserName={adminUserName}
            onEnabledChange={setAdminUserEnabled}
            onNameChange={setAdminUserName}
          />
          {copyError && (
            <p className="copy-status" role="status">
              {copyError}
            </p>
          )}
        </section>

        <section className="scroll-section" id={sectionAnchorId(VIEW_IDS.PACKAGES)}>
          <div className="content-stack">
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <p className="section-label">Install groups</p>
                  <h2>Choose what the command does</h2>
                </div>
              </div>
              <div className="step-grid">
                {installSteps.map((step) => (
                  <label className="option-row" key={step.key}>
                    <input
                      type="checkbox"
                      checked={stepSelection[step.key]}
                      onChange={() =>
                        setStepSelection((current) => ({
                          ...current,
                          [step.key]: !current[step.key]
                        }))
                      }
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
              <div className="panel-heading package-heading">
                <div>
                  <p className="section-label">Package catalog</p>
                  <h2>{activeTarget.label} package names</h2>
                </div>
                <label className="search-field">
                  <span>Search</span>
                  <input
                    value={query}
                    onChange={(event) => setQuery(event.target.value)}
                    placeholder="package, group, or label"
                  />
                </label>
              </div>

              <div className="group-list">
                {selectedGroups.map(({ group, selectedCount, totalCount }) => (
                  <PackageGroupPanel
                    activeOs={activeOs}
                    expanded={expandedGroups[group.id] ?? false}
                    group={group}
                    key={group.id}
                    query={query}
                    selectedCount={selectedCount}
                    selectedPackageIds={selectedPackageIds}
                    totalCount={totalCount}
                    onExpand={(expanded) => setExpandedGroups((current) => ({ ...current, [group.id]: expanded }))}
                    onPackageToggle={togglePackage}
                    onSelectAll={() => setGroupSelection(group.id, true)}
                    onSelectNone={() => setGroupSelection(group.id, false)}
                  />
                ))}
              </div>

              <label className="field custom-packages">
                <span>Custom {activeTarget.packageManager} packages</span>
                <input
                  value={customPackages}
                  onChange={(event) => setCustomPackages(event.target.value)}
                  placeholder="space or comma separated"
                  spellCheck={false}
                />
              </label>
            </section>
          </div>
        </section>

        <section className="scroll-section" id={sectionAnchorId(VIEW_IDS.TOOLCHAINS)}>
          <div className="content-stack">
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <p className="section-label">Toolchains</p>
                  <h2>Containers and language runtimes</h2>
                </div>
              </div>
              <ToolchainControl
                activeId={dockerStrategy}
                enabled={dockerEnabled}
                label="Docker"
                onChange={(value) => setDockerStrategy(value as DockerStrategyId)}
                onEnabledChange={(enabled) => setDockerEnabled(enabled)}
                recommendedId={DOCKER_STRATEGY_IDS.OFFICIAL}
                strategies={dockerStrategies}
              />
              <ToolchainControl
                activeId={nodeStrategy}
                enabled={nodeEnabled}
                label="Node"
                onChange={(value) => setNodeStrategy(value as NodeStrategyId)}
                onEnabledChange={setNodeEnabled}
                recommendedId={NODE_STRATEGY_IDS.MISE}
                strategies={nodeStrategies}
              />
              <NodePackageManagerChooser
                activeId={nodePackageManager}
                enabled={nodeEnabled}
                managers={catalog.nodePackageManagers}
                onChange={setNodePackageManager}
              />
              <AgentToolChooser
                enabled={nodeEnabled}
                selectedIds={selectedAgentToolIds}
                tools={catalog.agentTools}
                onToggle={toggleAgentTool}
              />
              <DeveloperToolChooser
                selectedIds={selectedDeveloperToolIds}
                tools={catalog.developerTools}
                onToggle={toggleDeveloperTool}
              />
              <ToolchainControl
                activeId={pythonStrategy}
                enabled={pythonEnabled}
                label="Python"
                onChange={(value) => setPythonStrategy(value as PythonStrategyId)}
                onEnabledChange={setPythonEnabled}
                recommendedId={PYTHON_STRATEGY_IDS.SYSTEM_UV}
                strategies={pythonStrategies}
              />
              <ToolchainControl
                activeId={javaStrategy}
                enabled={javaEnabled}
                label="Java"
                onChange={(value) => setJavaStrategy(value as JavaStrategyId)}
                onEnabledChange={setJavaEnabled}
                recommendedId={JAVA_STRATEGY_IDS.MISE_TEMURIN_21}
                strategies={javaStrategies}
              />
            </section>
          </div>
        </section>

        <section className="main-grid scroll-section" id={sectionAnchorId(VIEW_IDS.CONFIGS)}>
          <div className="content-stack">
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <p className="section-label">Config files</p>
                  <h2>Edit generated config content</h2>
                </div>
              </div>
              <div className="config-tabs">
                {(Object.keys(configDefinitions) as ConfigKey[]).map((key) => (
                  <button
                    className={activeConfig === key ? "active" : ""}
                    key={key}
                    type="button"
                    onClick={() => setActiveConfig(key)}
                  >
                    {configDefinitions[key].title}
                  </button>
                ))}
              </div>
              <ConfigPreferencePanel
                activeConfig={activeConfig}
                installTpm={installTpm}
                powerlevel10k={powerlevel10k}
                setInstallTpm={setInstallTpm}
                setPowerlevel10k={setPowerlevel10k}
              />
              <ConfigBlockEditor
                activeBlockId={activeConfigBlockIds[activeConfig]}
                blocks={configBlocks[activeConfig]}
                configKey={activeConfig}
                draggedBlock={draggedBlock}
                generatedContent={configContents[activeConfig]}
                onActiveBlockChange={(blockId) =>
                  setActiveConfigBlockIds((current) => ({ ...current, [activeConfig]: blockId }))
                }
                onBlockContentChange={(blockId, content) =>
                  updateConfigBlock(blockId, (block) => ({ ...block, content }))
                }
                onBlockDrop={dropConfigBlock}
                onBlockMove={moveConfigBlock}
                onBlockReset={resetConfigBlock}
                onBlockToggle={(blockId) =>
                  updateConfigBlock(blockId, (block) => ({ ...block, enabled: !block.enabled }))
                }
                onDragStart={(blockId) => setDraggedBlock({ configKey: activeConfig, blockId })}
              />
            </section>
          </div>
          <aside className="panel sticky-panel">
            <p className="section-label">Config output</p>
            <h2>{configDefinitions[activeConfig].path}</h2>
            <CommandBlock
              title="Write command"
              command={configCommand}
              copied={copied === "config-command"}
              onCopy={() => copyText("config-command", configCommand)}
            />
            <button
              className="wide-button"
              type="button"
              onClick={() => copyText("config-content", configContents[activeConfig])}
            >
              {copied === "config-content" ? "Copied" : "Copy file content"}
            </button>
          </aside>
        </section>

        <section className="main-grid scroll-section" id={sectionAnchorId(VIEW_IDS.SUMMARY)}>
          <div className="content-stack">
            <SummaryView
              activeTarget={activeTarget}
              adminUserEnabled={adminUserEnabled}
              adminUserName={adminUserName}
              configContents={configContents}
              dockerEnabled={dockerEnabled}
              dockerStrategy={dockerStrategy}
              installTpm={installTpm}
              selectedAgentTools={nodeEnabled ? selectedAgentTools : []}
              javaEnabled={javaEnabled}
              javaStrategy={javaStrategy}
              nodeEnabled={nodeEnabled}
              nodePackageManager={nodePackageManager}
              nodeStrategy={nodeStrategy}
              powerlevel10k={powerlevel10k}
              prepareSystem={prepareSystem}
              pythonEnabled={pythonEnabled}
              pythonStrategy={pythonStrategy}
              runInTmux={runInTmux}
              selectedPackageNames={selectedPackageNames}
              selectedDeveloperTools={selectedDeveloperTools}
              stepSelection={stepSelection}
              targetVersion={activeTargetVersion}
            />
          </div>
          <CommandPanel
            activeTarget={activeTarget}
            adminUserEnabled={adminUserEnabled}
            adminUserName={adminUserName}
            assumeYes={assumeYes}
            commandSet={commandSet}
            copied={copied}
            dockerEnabled={dockerEnabled}
            javaEnabled={javaEnabled}
            javaStrategy={javaStrategy}
            nodeEnabled={nodeEnabled}
            nodePackageManager={nodePackageManager}
            nodeStrategy={nodeStrategy}
            prepareSystem={prepareSystem}
            pythonEnabled={pythonEnabled}
            pythonStrategy={pythonStrategy}
            repoRef={repoRef}
            runInTmux={runInTmux}
            selectedAgentTools={nodeEnabled ? selectedAgentTools : []}
            selectedDeveloperTools={selectedDeveloperTools}
            selectedPackageNames={selectedPackageNames}
            targetVersion={activeTargetVersion}
            setAssumeYes={setAssumeYes}
            setPrepareSystem={setPrepareSystem}
            setRepoRef={setRepoRef}
            setRunInTmux={setRunInTmux}
            onCopy={copyText}
          />
        </section>
      </div>
    </main>
  );
};

const TargetSelector = ({
  activeOs,
  activeTarget,
  targetSelected,
  targetVersion,
  onChange,
  onTargetSelected,
  onVersionChange
}: {
  activeOs: OsId;
  activeTarget: OsTarget;
  targetSelected: boolean;
  targetVersion: string;
  onChange: (osId: OsId) => void;
  onTargetSelected: () => void;
  onVersionChange: (version: string) => void;
}) => {
  const [isChanging, setIsChanging] = useState(false);
  const versionNote =
    (activeTarget.versions.find((version) => version.value === targetVersion) ?? activeTarget.versions[0])?.note ??
    "Custom version";

  if (!targetSelected) {
    return (
      <section className="target-bar target-picker" aria-label="Operating system">
        <div>
          <p className="section-label">Target OS</p>
          <strong>Choose target</strong>
        </div>
        <div className="target-options compact" role="group" aria-label="Target OS choices">
          {catalog.osTargets.map((target) => (
            <button
              className={activeOs === target.id ? "target-button active" : "target-button"}
              key={target.id}
              type="button"
              onClick={() => {
                onChange(target.id);
                onTargetSelected();
              }}
            >
              <strong>{targetShortLabel(target)}</strong>
              <span>
                {defaultVersionForTarget(target)}
                {!target.implemented ? " preview" : ""}
              </span>
            </button>
          ))}
        </div>
      </section>
    );
  }

  return (
    <>
      <section className="target-bar target-selected-row" aria-label="Operating system">
        <p className="section-label">Target OS</p>
        <button className="target-pill active" type="button" onClick={() => setIsChanging(true)}>
          <strong>{targetShortLabel(activeTarget)}</strong>
          <span>
            {activeTarget.packageManager}
            {!activeTarget.implemented ? " preview" : ""}
          </span>
        </button>
        <div className="version-field target-version-field" title={versionNote}>
          <span>Version</span>
          <div className="version-button-group" role="group" aria-label={`${targetShortLabel(activeTarget)} version`}>
            {activeTarget.versions.map((version) => (
              <button
                className={version.value === targetVersion ? "version-button active" : "version-button"}
                key={version.value}
                title={version.note}
                type="button"
                onClick={() => onVersionChange(version.value)}
              >
                {version.label}
              </button>
            ))}
          </div>
        </div>
        <button className="target-change-button" type="button" onClick={() => setIsChanging(true)}>
          Change target
        </button>
      </section>

      {isChanging && (
        <div className="modal-backdrop" role="presentation" onClick={() => setIsChanging(false)}>
          <section
            className="target-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="target-modal-title"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="modal-heading">
              <div>
                <p className="section-label">Target OS</p>
                <h2 id="target-modal-title">Change target OS</h2>
              </div>
              <button type="button" onClick={() => setIsChanging(false)}>
                Close
              </button>
            </div>
            <p className="target-warning">
              Changing target OS can reset command defaults and package names. Review the command after switching.
            </p>
            <div className="target-options compact" role="group" aria-label="Target OS choices">
              {catalog.osTargets.map((target) => (
                <button
                  className={activeOs === target.id ? "target-button active" : "target-button"}
                  key={target.id}
                  type="button"
                  onClick={() => {
                    onChange(target.id);
                    setIsChanging(false);
                  }}
                >
                  <strong>{targetShortLabel(target)}</strong>
                  <span>
                    {defaultVersionForTarget(target)}
                    {!target.implemented ? " preview" : ""}
                  </span>
                </button>
              ))}
            </div>
          </section>
        </div>
      )}
    </>
  );
};

const ThemeToggle = ({ mode, onChange }: { mode: ThemeMode; onChange: (mode: ThemeMode) => void }) => {
  const nextMode: ThemeMode = mode === THEME_MODES.DARK ? THEME_MODES.LIGHT : THEME_MODES.DARK;

  return (
    <button
      aria-label={`Switch to ${nextMode} theme`}
      className={`theme-icon-toggle ${mode}`}
      title={`Switch to ${nextMode} theme`}
      type="button"
      onClick={() => onChange(nextMode)}
    >
      <span className="theme-icon" aria-hidden="true" />
      <span className="visually-hidden">{mode} theme</span>
    </button>
  );
};

const UserSettingsPanel = ({
  adminUserEnabled,
  adminUserName,
  onEnabledChange,
  onNameChange
}: {
  adminUserEnabled: boolean;
  adminUserName: string;
  onEnabledChange: (value: boolean) => void;
  onNameChange: (value: string) => void;
}) => {
  return (
    <section className="target-bar user-settings-bar" aria-label="User settings">
      <div>
        <p className="section-label">User</p>
        <strong>Sudo user</strong>
        <span className="muted compact-note">Leave blank to use the login user that runs the setup command.</span>
      </div>
      <ToggleSwitch checked={adminUserEnabled} label={adminUserEnabled ? "On" : "Off"} onChange={onEnabledChange} />
      <label className="version-field user-name-field">
        <span>User name</span>
        <input
          value={adminUserName}
          onChange={(event) => onNameChange(event.target.value)}
          placeholder="current user"
          disabled={!adminUserEnabled}
          spellCheck={false}
        />
      </label>
      <p className="muted compact-note user-settings-note">
        The installer adds this user to sudo. If Docker is installed, it also adds the same user to docker.
      </p>
    </section>
  );
};

const ConfigPreferencePanel = ({
  activeConfig,
  installTpm,
  powerlevel10k,
  setInstallTpm,
  setPowerlevel10k
}: {
  activeConfig: ConfigKey;
  installTpm: boolean;
  powerlevel10k: boolean;
  setInstallTpm: (checked: boolean) => void;
  setPowerlevel10k: (checked: boolean) => void;
}) => {
  if (activeConfig !== CONFIG_KEYS.ZSHRC && activeConfig !== CONFIG_KEYS.TMUX) {
    return null;
  }

  return (
    <div className="config-preferences">
      {activeConfig === CONFIG_KEYS.ZSHRC && (
        <PreferenceToggle
          checked={powerlevel10k}
          description="Use Powerlevel10k as the generated zsh prompt theme."
          label="Powerlevel10k prompt"
          onChange={setPowerlevel10k}
        />
      )}
      {activeConfig === CONFIG_KEYS.TMUX && (
        <PreferenceToggle
          checked={installTpm}
          description="Install tmux plugin manager for the TPM block in .tmux.conf."
          label="Install TPM"
          onChange={setInstallTpm}
        />
      )}
    </div>
  );
};

const PackageGroupPanel = ({
  activeOs,
  expanded,
  group,
  query,
  selectedCount,
  selectedPackageIds,
  totalCount,
  onExpand,
  onPackageToggle,
  onSelectAll,
  onSelectNone
}: {
  activeOs: OsId;
  expanded: boolean;
  group: PackageGroup;
  query: string;
  selectedCount: number;
  selectedPackageIds: string[];
  totalCount: number;
  onExpand: (expanded: boolean) => void;
  onPackageToggle: (packageId: string) => void;
  onSelectAll: () => void;
  onSelectNone: () => void;
}) => {
  const normalizedQuery = query.trim().toLowerCase();
  const packages = catalog.packages
    .filter((item) => item.group === group.id)
    .filter((item) => {
      if (!normalizedQuery) {
        return true;
      }
      const packageNames = packageNamesForOs(item, activeOs).join(" ");
      return `${group.title} ${item.label} ${item.id} ${packageNames}`.toLowerCase().includes(normalizedQuery);
    });
  const shouldOpen = expanded || normalizedQuery.length > 0;

  if (normalizedQuery && packages.length === 0) {
    return null;
  }

  return (
    <details className="group-panel" open={shouldOpen} onToggle={(event) => onExpand(event.currentTarget.open)}>
      <summary>
        <span>
          <strong>{group.title}</strong>
          <small>{group.description}</small>
        </span>
        <em>
          {selectedCount}/{totalCount}
        </em>
      </summary>
      <div className="group-detail">
        <p>{group.description}</p>
        <div className="group-actions">
          <button type="button" onClick={onSelectAll}>
            Select group
          </button>
          <button type="button" onClick={onSelectNone}>
            Clear group
          </button>
        </div>
      </div>
      <div className="package-tree">
        {packages.map((item) => {
          const packageNames = packageNamesForOs(item, activeOs);
          const hasPackageForOs = packageNames.length > 0;
          return (
            <label className="package-tree-row" key={item.id}>
              <input
                type="checkbox"
                checked={selectedPackageIds.includes(item.id)}
                disabled={!hasPackageForOs}
                onChange={() => onPackageToggle(item.id)}
              />
              <span className="tree-branch" aria-hidden="true" />
              <span className="package-row-copy">
                <strong>{item.label}</strong>
                <small>{packageDescriptionFor(item, group)}</small>
                <code>{hasPackageForOs ? packageNames.join(", ") : "No package needed"}</code>
              </span>
            </label>
          );
        })}
      </div>
    </details>
  );
};

const ToggleSwitch = ({
  checked,
  label,
  onChange
}: {
  checked: boolean;
  label: string;
  onChange: (checked: boolean) => void;
}) => {
  return (
    <button
      className={checked ? "toggle-switch on" : "toggle-switch"}
      role="switch"
      aria-checked={checked}
      type="button"
      onClick={() => onChange(!checked)}
    >
      <span aria-hidden="true" />
      <strong>{label}</strong>
    </button>
  );
};

const PreferenceToggle = ({
  checked,
  description,
  label,
  onChange
}: {
  checked: boolean;
  description: string;
  label: string;
  onChange: (checked: boolean) => void;
}) => {
  return (
    <div className="preference-card">
      <div>
        <strong>{label}</strong>
        <small>{description}</small>
      </div>
      <ToggleSwitch checked={checked} label={checked ? "On" : "Off"} onChange={onChange} />
    </div>
  );
};

const ToolchainControl = ({
  activeId,
  enabled,
  label,
  onChange,
  onEnabledChange,
  recommendedId,
  strategies
}: {
  activeId: string;
  enabled: boolean;
  label: string;
  onChange: (value: string) => void;
  onEnabledChange: (enabled: boolean) => void;
  recommendedId?: string;
  strategies: Strategy[];
}) => {
  const [editing, setEditing] = useState(false);
  const activeStrategy = strategies.find((strategy) => strategy.id === activeId) ?? strategies[0];
  const setEnabled = (checked: boolean) => {
    if (!checked) {
      setEditing(false);
    }
    onEnabledChange(checked);
  };

  return (
    <div className="strategy-block">
      <div className="strategy-heading">
        <div>
          <h3>{label}</h3>
          {enabled && <p className="muted compact-note">{activeStrategy.description}</p>}
        </div>
        <ToggleSwitch checked={enabled} label={enabled ? "On" : "Off"} onChange={setEnabled} />
      </div>

      {enabled && (
        <div className="selected-strategy-card">
          <div>
            <strong>{activeStrategy.label}</strong>
            <small>{activeStrategy.description}</small>
          </div>
          <button type="button" onClick={() => setEditing((current) => !current)}>
            {editing ? "Close" : "Modify"}
          </button>
        </div>
      )}

      {enabled && editing && (
        <div className="strategy-grid">
          {strategies.map((strategy) => (
            <button
              className={activeId === strategy.id ? "strategy-card active" : "strategy-card"}
              key={strategy.id}
              type="button"
              onClick={() => onChange(strategy.id)}
            >
              <strong>
                {strategy.label}
                {strategy.id === recommendedId && <small>Recommended</small>}
              </strong>
              <span>{strategy.description}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

const NodePackageManagerChooser = ({
  activeId,
  enabled,
  managers,
  onChange
}: {
  activeId: NodePackageManagerId;
  enabled: boolean;
  managers: NodePackageManager[];
  onChange: (managerId: NodePackageManagerId) => void;
}) => {
  const [editing, setEditing] = useState(false);
  const activeManager = managers.find((manager) => manager.id === activeId) ?? managers[0];

  if (!enabled) {
    return null;
  }

  return (
    <div className="strategy-block">
      <div className="strategy-heading">
        <div>
          <h3>Node packages</h3>
          <p className="muted compact-note">Choose the package manager enabled after Node installs.</p>
        </div>
      </div>
      <div className="selected-strategy-card">
        <div>
          <strong>{activeManager.label}</strong>
          <small>{activeManager.description}</small>
        </div>
        <button type="button" onClick={() => setEditing((current) => !current)}>
          {editing ? "Close" : "Modify"}
        </button>
      </div>
      {editing && (
        <div className="strategy-grid">
          {managers.map((manager) => (
            <button
              className={activeId === manager.id ? "strategy-card active" : "strategy-card"}
              key={manager.id}
              type="button"
              onClick={() => onChange(manager.id)}
            >
              <strong>
                {manager.label}
                {manager.id === NODE_PACKAGE_MANAGER_IDS.PNPM && <small>Recommended</small>}
              </strong>
              <span>{manager.description}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

const AgentToolChooser = ({
  enabled,
  selectedIds,
  tools,
  onToggle
}: {
  enabled: boolean;
  selectedIds: AgentToolId[];
  tools: AgentTool[];
  onToggle: (toolId: AgentToolId) => void;
}) => {
  if (!enabled) {
    return null;
  }

  return (
    <div className="strategy-block agent-tools-block">
      <div className="strategy-heading">
        <div>
          <h3>Coding agents</h3>
          <p className="muted compact-note">Install npm-based coding CLIs after Node is ready.</p>
        </div>
      </div>
      <div className="agent-tool-list">
        {tools.map((tool) => (
          <div className="agent-tool-row" key={tool.id}>
            <div>
              <strong>{tool.label}</strong>
              <small>{tool.description}</small>
              <code>{tool.npmPackage}</code>
            </div>
            <ToggleSwitch
              checked={selectedIds.includes(tool.id)}
              label={selectedIds.includes(tool.id) ? "On" : "Off"}
              onChange={() => onToggle(tool.id)}
            />
          </div>
        ))}
      </div>
    </div>
  );
};

const DeveloperToolChooser = ({
  selectedIds,
  tools,
  onToggle
}: {
  selectedIds: DeveloperToolId[];
  tools: DeveloperTool[];
  onToggle: (toolId: DeveloperToolId) => void;
}) => {
  return (
    <div className="strategy-block agent-tools-block">
      <div className="strategy-heading">
        <div>
          <h3>Developer tools</h3>
          <p className="muted compact-note">Install extra runtimes and command line tools for common projects.</p>
        </div>
      </div>
      <div className="agent-tool-list">
        {tools.map((tool) => (
          <div className="agent-tool-row" key={tool.id}>
            <div>
              <strong>{tool.label}</strong>
              <small>{tool.description}</small>
              <code>{tool.command}</code>
            </div>
            <ToggleSwitch
              checked={selectedIds.includes(tool.id)}
              label={selectedIds.includes(tool.id) ? "On" : "Off"}
              onChange={() => onToggle(tool.id)}
            />
          </div>
        ))}
      </div>
    </div>
  );
};

const ConfigBlockEditor = ({
  activeBlockId,
  blocks,
  configKey,
  draggedBlock,
  generatedContent,
  onActiveBlockChange,
  onBlockContentChange,
  onBlockDrop,
  onBlockMove,
  onBlockReset,
  onBlockToggle,
  onDragStart
}: {
  activeBlockId: string;
  blocks: ConfigBlock[];
  configKey: ConfigKey;
  draggedBlock: DraggedBlock;
  generatedContent: string;
  onActiveBlockChange: (blockId: string) => void;
  onBlockContentChange: (blockId: string, content: string) => void;
  onBlockDrop: (blockId: string) => void;
  onBlockMove: (blockId: string, direction: -1 | 1) => void;
  onBlockReset: (blockId: string) => void;
  onBlockToggle: (blockId: string) => void;
  onDragStart: (blockId: string) => void;
}) => {
  const activeBlock = blocks.find((block) => block.id === activeBlockId) ?? blocks[0];
  const activeIndex = blocks.findIndex((block) => block.id === activeBlock.id);
  const [selectedLine, setSelectedLine] = useState<{ blockId: string; lineIndex: number } | null>(null);
  const lineStarts = new Map<string, number>();
  let nextLineNumber = 1;

  for (const block of blocks) {
    const lineCount = block.content.trimEnd().split(/\r?\n/).length || 1;
    lineStarts.set(block.id, nextLineNumber);
    nextLineNumber += lineCount + 1;
  }

  const selectedLineBlock = selectedLine ? blocks.find((block) => block.id === selectedLine.blockId) : undefined;
  const detailLineBlock = selectedLineBlock ?? activeBlock;
  const detailLineIndex = selectedLineBlock && selectedLine ? selectedLine.lineIndex : 0;
  const selectedLineText = detailLineBlock.content.trimEnd().split(/\r?\n/)[detailLineIndex] || "";
  const selectedLineNumber = (lineStarts.get(detailLineBlock.id) ?? 1) + detailLineIndex;
  const activePluginNote = pluginNoteFor(configKey, activeBlock.id);

  return (
    <div className="config-builder">
      <div className="config-code-pane" aria-label={`${configDefinitions[configKey].title} blocks`}>
        <div className="code-pane-header">
          <strong>{configDefinitions[configKey].title}</strong>
          <span>
            {blocks.filter((block) => block.enabled).length}/{blocks.length} blocks on
          </span>
        </div>
        {blocks.map((block, index) => (
          <div
            className={[
              "editor-block",
              block.id === activeBlock.id ? "active" : "",
              block.enabled ? "" : "disabled",
              `kind-${block.kind}`,
              draggedBlock?.blockId === block.id ? "dragging" : ""
            ]
              .filter(Boolean)
              .join(" ")}
            draggable
            key={block.id}
            onClick={() => onActiveBlockChange(block.id)}
            onDragOver={(event) => event.preventDefault()}
            onDragStart={() => onDragStart(block.id)}
            onDrop={() => onBlockDrop(block.id)}
          >
            <div className="editor-block-header">
              <button
                className="block-title-button"
                type="button"
                onClick={() => {
                  setSelectedLine(null);
                  onActiveBlockChange(block.id);
                }}
              >
                <span>{block.title}</span>
                <small>{block.description}</small>
                <span className={`block-kind-pill kind-${block.kind}`}>{blockKindLabels[block.kind]}</span>
              </button>
              <div className="editor-block-actions">
                <button
                  aria-label={`Move ${block.title} up`}
                  className="icon-button"
                  disabled={index === 0}
                  type="button"
                  onClick={(event) => {
                    event.stopPropagation();
                    onBlockMove(block.id, -1);
                  }}
                >
                  Up
                </button>
                <button
                  aria-label={`Move ${block.title} down`}
                  className="icon-button"
                  disabled={index === blocks.length - 1}
                  type="button"
                  onClick={(event) => {
                    event.stopPropagation();
                    onBlockMove(block.id, 1);
                  }}
                >
                  Down
                </button>
                <button
                  className={block.enabled ? "block-toggle on" : "block-toggle"}
                  role="switch"
                  aria-checked={block.enabled}
                  type="button"
                  onClick={(event) => {
                    event.stopPropagation();
                    onBlockToggle(block.id);
                  }}
                >
                  <span aria-hidden="true" />
                  <strong>{block.enabled ? "On" : "Off"}</strong>
                </button>
              </div>
            </div>
            <div className="editor-lines">
              {(block.content.trimEnd().split(/\r?\n/) || [""]).map((line, lineIndex) => {
                const lineNumber = (lineStarts.get(block.id) ?? 1) + lineIndex;
                const lineKey = `${block.id}-${lineIndex}`;
                const lineActive = selectedLine?.blockId === block.id && selectedLine.lineIndex === lineIndex;
                return (
                  <button
                    className={lineActive ? "code-line active" : "code-line"}
                    key={lineKey}
                    type="button"
                    onClick={(event) => {
                      event.stopPropagation();
                      setSelectedLine({ blockId: block.id, lineIndex });
                      onActiveBlockChange(block.id);
                    }}
                  >
                    <span className="line-number">{lineNumber}</span>
                    <code className="line-text">{line || " "}</code>
                  </button>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      <section className="block-detail" aria-label="Selected config block">
        <div className="block-detail-heading">
          <div>
            <p className="section-label">Selected block</p>
            <h3>{activeBlock.title}</h3>
          </div>
          <span className="block-position">
            {activeIndex + 1}/{blocks.length}
          </span>
        </div>
        <p className="muted">{activeBlock.description}</p>
        <div className="block-meta-row">
          <span className={`block-kind-pill kind-${activeBlock.kind}`}>{blockKindLabels[activeBlock.kind]}</span>
          <span className="meta-chip">{blockKindDescriptions[activeBlock.kind]}</span>
        </div>
        {activeBlock.risk && <p className="order-warning">{activeBlock.risk}</p>}
        {activePluginNote && <p className="plugin-note">{activePluginNote}</p>}
        {activeBlock.shortcuts.length > 0 && <KeycapList keys={activeBlock.shortcuts} />}
        <div className="selected-line-detail">
          <span>Line {selectedLineNumber}</span>
          <code>{selectedLineText || "blank line"}</code>
        </div>
        <textarea
          className="block-editor"
          spellCheck={false}
          value={activeBlock.content}
          onChange={(event) => onBlockContentChange(activeBlock.id, event.target.value)}
        />
        <div className="block-actions">
          <button type="button" onClick={() => onBlockMove(activeBlock.id, -1)} disabled={activeIndex === 0}>
            Move up
          </button>
          <button
            type="button"
            onClick={() => onBlockMove(activeBlock.id, 1)}
            disabled={activeIndex === blocks.length - 1}
          >
            Move down
          </button>
          <button type="button" onClick={() => onBlockReset(activeBlock.id)}>
            Reset block
          </button>
        </div>
        <details className="generated-config">
          <summary>Generated file text</summary>
          <textarea className="config-editor" readOnly spellCheck={false} value={generatedContent} />
        </details>
      </section>
    </div>
  );
};

const KeycapList = ({ keys }: { keys: string[] }) => {
  return (
    <div className="keycap-list" aria-label="Keyboard shortcuts">
      {keys.map((keyName) => (
        <kbd key={keyName}>{keyName}</kbd>
      ))}
    </div>
  );
};

const CommandPanel = ({
  activeTarget,
  adminUserEnabled,
  adminUserName,
  assumeYes,
  commandSet,
  copied,
  dockerEnabled,
  javaEnabled,
  javaStrategy,
  nodeEnabled,
  nodePackageManager,
  nodeStrategy,
  prepareSystem,
  pythonEnabled,
  pythonStrategy,
  repoRef,
  runInTmux,
  selectedAgentTools,
  selectedDeveloperTools,
  selectedPackageNames,
  targetVersion,
  setAssumeYes,
  setPrepareSystem,
  setRepoRef,
  setRunInTmux,
  onCopy
}: {
  activeTarget: OsTarget;
  adminUserEnabled: boolean;
  adminUserName: string;
  assumeYes: boolean;
  commandSet: CommandSet;
  copied: string | null;
  dockerEnabled: boolean;
  javaEnabled: boolean;
  javaStrategy: JavaStrategyId;
  nodeEnabled: boolean;
  nodePackageManager: NodePackageManagerId;
  nodeStrategy: NodeStrategyId;
  prepareSystem: boolean;
  pythonEnabled: boolean;
  pythonStrategy: PythonStrategyId;
  repoRef: string;
  runInTmux: boolean;
  selectedAgentTools: AgentTool[];
  selectedDeveloperTools: DeveloperTool[];
  selectedPackageNames: string[];
  targetVersion: string;
  setAssumeYes: (value: boolean) => void;
  setPrepareSystem: (value: boolean) => void;
  setRepoRef: (value: string) => void;
  setRunInTmux: (value: boolean) => void;
  onCopy: (key: string, value: string) => void;
}) => {
  return (
    <aside className="panel sticky-panel">
      <p className="section-label">Command</p>
      <h2>{activeTarget.implemented ? "Run from terminal" : "Preview command"}</h2>
      <p className="muted">{activeTarget.note}</p>
      <label className="field">
        <span>Repository ref</span>
        <input value={repoRef} onChange={(event) => setRepoRef(event.target.value)} spellCheck={false} />
      </label>
      <label className="switch-row">
        <input type="checkbox" checked={assumeYes} onChange={() => setAssumeYes(!assumeYes)} />
        <span>Use --yes</span>
      </label>
      <div className="command-run-options">
        <label>
          <input type="checkbox" checked={prepareSystem} onChange={() => setPrepareSystem(!prepareSystem)} />
          <span>Update first</span>
        </label>
        <label>
          <input type="checkbox" checked={runInTmux} onChange={() => setRunInTmux(!runInTmux)} />
          <span>Run in tmux</span>
        </label>
      </div>
      <p className="muted compact-note">Target version: {targetVersion || "not set"}</p>
      <p className="muted compact-note">
        Admin user: {adminUserEnabled ? adminUserName.trim() || "current user" : "off"}
      </p>
      <p className="muted compact-note">Docker install: {dockerEnabled ? "on" : "off"}</p>
      <p className="muted compact-note">Node setup: {nodeEnabled ? nodeStrategy : "off"}</p>
      <p className="muted compact-note">Node package manager: {nodeEnabled ? nodePackageManager : "off"}</p>
      <p className="muted compact-note">
        Agent CLIs:{" "}
        {nodeEnabled && selectedAgentTools.length > 0 ? selectedAgentTools.map((tool) => tool.label).join(", ") : "off"}
      </p>
      <p className="muted compact-note">
        Developer tools:{" "}
        {selectedDeveloperTools.length > 0 ? selectedDeveloperTools.map((tool) => tool.label).join(", ") : "off"}
      </p>
      <p className="muted compact-note">Python setup: {pythonEnabled ? pythonStrategy : "off"}</p>
      <p className="muted compact-note">Java install: {javaEnabled ? javaStrategy : "off"}</p>
      <div className="mini-summary">
        <strong>{selectedPackageNames.length}</strong>
        <span>{activeTarget.packageManager} packages selected</span>
      </div>
      <CommandBlock
        title={activeTarget.implemented ? "Bootstrap command" : "Package command"}
        command={activeTarget.implemented ? commandSet.primary : commandSet.packageCommand}
        copied={copied === "primary-command"}
        onCopy={() =>
          onCopy("primary-command", activeTarget.implemented ? commandSet.primary : commandSet.packageCommand)
        }
      />
      {activeTarget.implemented && (
        <CommandBlock
          title="Already cloned"
          command={commandSet.local}
          copied={copied === "local-command"}
          onCopy={() => onCopy("local-command", commandSet.local)}
        />
      )}
    </aside>
  );
};

const SummaryView = ({
  activeTarget,
  adminUserEnabled,
  adminUserName,
  configContents,
  dockerEnabled,
  dockerStrategy,
  installTpm,
  javaEnabled,
  javaStrategy,
  nodeEnabled,
  nodePackageManager,
  nodeStrategy,
  powerlevel10k,
  prepareSystem,
  pythonEnabled,
  pythonStrategy,
  runInTmux,
  selectedAgentTools,
  selectedDeveloperTools,
  selectedPackageNames,
  stepSelection,
  targetVersion
}: {
  activeTarget: OsTarget;
  adminUserEnabled: boolean;
  adminUserName: string;
  configContents: Record<ConfigKey, string>;
  dockerEnabled: boolean;
  dockerStrategy: DockerStrategyId;
  installTpm: boolean;
  javaEnabled: boolean;
  javaStrategy: JavaStrategyId;
  nodeEnabled: boolean;
  nodePackageManager: NodePackageManagerId;
  nodeStrategy: NodeStrategyId;
  powerlevel10k: boolean;
  prepareSystem: boolean;
  pythonEnabled: boolean;
  pythonStrategy: PythonStrategyId;
  runInTmux: boolean;
  selectedAgentTools: AgentTool[];
  selectedDeveloperTools: DeveloperTool[];
  selectedPackageNames: string[];
  stepSelection: Record<InstallStepKey, boolean>;
  targetVersion: string;
}) => {
  const configLineCounts = (Object.keys(configContents) as ConfigKey[]).map((key) => ({
    key,
    title: configDefinitions[key].title,
    lines: configContents[key].split(/\r?\n/).length
  }));

  return (
    <section className="summary-grid">
      <section className="panel">
        <p className="section-label">Summary</p>
        <h2>{activeTarget.label}</h2>
        <dl className="summary-list">
          <div>
            <dt>Package manager</dt>
            <dd>{activeTarget.packageManager}</dd>
          </div>
          <div>
            <dt>Target version</dt>
            <dd>{targetVersion || "not set"}</dd>
          </div>
          <div>
            <dt>Admin user</dt>
            <dd>{adminUserEnabled ? adminUserName.trim() || "current user" : "off"}</dd>
          </div>
          <div>
            <dt>Install steps</dt>
            <dd>
              {Object.entries(stepSelection)
                .filter(([, enabled]) => enabled)
                .map(([key]) => key)
                .join(", ")}
            </dd>
          </div>
          <div>
            <dt>Docker strategy</dt>
            <dd>{dockerEnabled ? dockerStrategy : "off"}</dd>
          </div>
          <div>
            <dt>Node strategy</dt>
            <dd>{nodeEnabled ? nodeStrategy : "off"}</dd>
          </div>
          <div>
            <dt>Node package manager</dt>
            <dd>{nodeEnabled ? nodePackageManager : "off"}</dd>
          </div>
          <div>
            <dt>Agent CLIs</dt>
            <dd>
              {nodeEnabled && selectedAgentTools.length > 0
                ? selectedAgentTools.map((tool) => tool.label).join(", ")
                : "off"}
            </dd>
          </div>
          <div>
            <dt>Python strategy</dt>
            <dd>{pythonEnabled ? pythonStrategy : "off"}</dd>
          </div>
          <div>
            <dt>Java strategy</dt>
            <dd>{javaEnabled ? javaStrategy : "off"}</dd>
          </div>
          <div>
            <dt>Developer tools</dt>
            <dd>
              {selectedDeveloperTools.length > 0 ? selectedDeveloperTools.map((tool) => tool.label).join(", ") : "off"}
            </dd>
          </div>
          <div>
            <dt>Powerlevel10k</dt>
            <dd>{powerlevel10k ? "on" : "off"}</dd>
          </div>
          <div>
            <dt>TPM</dt>
            <dd>{installTpm ? "install" : "off"}</dd>
          </div>
          <div>
            <dt>Run wrapper</dt>
            <dd>
              {[prepareSystem ? "update first" : "", runInTmux ? "tmux" : ""].filter(Boolean).join(", ") || "off"}
            </dd>
          </div>
          <div>
            <dt>Selected packages</dt>
            <dd>{selectedPackageNames.length}</dd>
          </div>
        </dl>
      </section>
      <section className="panel">
        <p className="section-label">Packages</p>
        <h2>Resolved names</h2>
        {selectedPackageNames.length > 0 ? (
          <div className="selected-package-list">
            {selectedPackageNames.map((name) => (
              <span key={name}>{name}</span>
            ))}
          </div>
        ) : (
          <p className="muted">No package-manager packages selected.</p>
        )}
      </section>
      <section className="panel">
        <p className="section-label">Configs</p>
        <h2>Editable files</h2>
        <ul className="plain-list">
          {configLineCounts.map((item) => (
            <li key={item.key}>
              {item.title}: {item.lines} lines
            </li>
          ))}
        </ul>
      </section>
    </section>
  );
};

type CommandBlockProps = {
  title: string;
  command: string;
  copied: boolean;
  onCopy: () => void;
};

const CommandBlock = ({ title, command, copied, onCopy }: CommandBlockProps) => {
  return (
    <div className="command-block">
      <div className="command-header">
        <h3>{title}</h3>
        <button type="button" aria-label={`Copy ${title}`} onClick={onCopy}>
          {copied ? "Copied" : "Copy"}
        </button>
      </div>
      <pre>
        <code>{command}</code>
      </pre>
    </div>
  );
};
