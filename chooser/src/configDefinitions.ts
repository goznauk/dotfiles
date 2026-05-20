import gitConfigRaw from "../../common/.gitconfig?raw";
import tmuxConfigRaw from "../../common/.tmux.conf?raw";
import vimConfigRaw from "../../common/.vimrc?raw";
import zshConfigRaw from "../../common/.zshrc?raw";
import { CONFIG_BLOCK_KINDS, CONFIG_KEYS, type ConfigBlockKind, type ConfigKey } from "./ids";

export type ConfigBlock = {
  id: string;
  title: string;
  description: string;
  kind: ConfigBlockKind;
  shortcuts: string[];
  risk?: string;
  enabled: boolean;
  content: string;
};

type ConfigBlockTemplate = Omit<ConfigBlock, "enabled" | "content" | "kind"> & {
  start: number;
  end: number;
  kind?: ConfigBlockKind;
  enabled?: boolean;
};

export type ConfigDefinition = {
  title: string;
  path: string;
  mkdir?: string;
  blocks: ConfigBlock[];
};

const htopConfigDefault = `# htop config
fields=0 48 17 18 38 39 2 46 47 49 1
sort_key=46
sort_direction=1
tree_sort_key=0
tree_sort_direction=1
hide_kernel_threads=1
hide_userland_threads=0
shadow_other_users=0
show_thread_names=0
show_program_path=1
highlight_base_name=1
highlight_megabytes=1
highlight_threads=1
highlight_changes=0
highlight_changes_delay_secs=5
find_comm_in_cmdline=1
strip_exe_from_cmdline=1
show_merged_command=0
header_margin=1
detailed_cpu_time=0
cpu_count_from_one=0
show_cpu_usage=1
show_cpu_frequency=1
show_cpu_temperature=0
degree_fahrenheit=0
update_process_names=0
account_guest_in_cpu_meter=0
color_scheme=0
enable_mouse=1
delay=15
left_meters=LeftCPUs2 Memory Swap
left_meter_modes=1 1 1
right_meters=RightCPUs2 Tasks LoadAverage Uptime
right_meter_modes=1 2 2 2
`;

const createConfigBlocks = (raw: string, templates: ConfigBlockTemplate[]): ConfigBlock[] => {
  const lines = raw.trimEnd().split(/\r?\n/);
  return templates.map((template) => ({
    id: template.id,
    title: template.title,
    description: template.description,
    kind: template.kind ?? CONFIG_BLOCK_KINDS.FREE,
    shortcuts: template.shortcuts,
    risk: template.risk,
    enabled: template.enabled ?? true,
    content: `${lines.slice(template.start - 1, template.end).join("\n")}\n`
  }));
};

export const blockKindLabels: Record<ConfigBlockKind, string> = {
  [CONFIG_BLOCK_KINDS.LOCKED]: "Locked order",
  [CONFIG_BLOCK_KINDS.ORDERED]: "Order matters",
  [CONFIG_BLOCK_KINDS.SIDE_EFFECT]: "Side effect",
  [CONFIG_BLOCK_KINDS.FREE]: "Safe to move"
};

export const blockKindDescriptions: Record<ConfigBlockKind, string> = {
  [CONFIG_BLOCK_KINDS.LOCKED]: "Keep this block in place unless you are deliberately changing startup order.",
  [CONFIG_BLOCK_KINDS.ORDERED]: "This block can be edited, but it depends on nearby setup happening first.",
  [CONFIG_BLOCK_KINDS.SIDE_EFFECT]: "This block can run external tools, create files, or load plugin managers.",
  [CONFIG_BLOCK_KINDS.FREE]: "This block is mostly aliases, display settings, or local preferences."
};

export const configDefinitions: Record<ConfigKey, ConfigDefinition> = {
  [CONFIG_KEYS.ZSHRC]: {
    title: ".zshrc",
    path: "$HOME/.zshrc",
    blocks: createConfigBlocks(zshConfigRaw, [
      {
        id: "interactive-guard",
        title: "Interactive guard",
        description: "Stops non-interactive shells from loading prompt and alias setup, then loads the pre-hook.",
        kind: CONFIG_BLOCK_KINDS.LOCKED,
        risk: "Keep this first. Moving it can make scripts inherit interactive shell behavior.",
        shortcuts: [],
        start: 1,
        end: 3
      },
      {
        id: "prompt",
        title: "Prompt bootstrap",
        description: "Loads the Powerlevel10k instant prompt and selects the prompt theme.",
        kind: CONFIG_BLOCK_KINDS.LOCKED,
        risk: "Keep this near the top. Moving it below other shell output can break instant prompt startup.",
        shortcuts: [],
        start: 5,
        end: 16
      },
      {
        id: "history",
        title: "History settings",
        description: "Keeps a large shared history and avoids repeated duplicate commands.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: [],
        start: 18,
        end: 28
      },
      {
        id: "path",
        title: "PATH order",
        description: "Puts local user tools, Cargo tools, and home bin ahead of system paths.",
        kind: CONFIG_BLOCK_KINDS.ORDERED,
        risk: "Keep this before plugin and runtime setup so command checks resolve the expected tools.",
        shortcuts: [],
        start: 30,
        end: 41
      },
      {
        id: "plugins",
        title: "oh-my-zsh plugins",
        description:
          "Enables Git helpers, dotenv loading, completions, suggestions, and Docker helpers when Docker exists.",
        kind: CONFIG_BLOCK_KINDS.ORDERED,
        risk: "Keep this before oh-my-zsh loads. Plugins listed after the framework block will not load.",
        shortcuts: [],
        start: 43,
        end: 51
      },
      {
        id: "framework",
        title: "Shell framework",
        description: "Loads oh-my-zsh when available and falls back to plain completion setup.",
        kind: CONFIG_BLOCK_KINDS.LOCKED,
        risk: "Runtime hooks, aliases, and plugin arrays assume this framework block stays before them.",
        shortcuts: [],
        start: 53,
        end: 61
      },
      {
        id: "runtime-hooks",
        title: "mise and direnv hooks",
        description: "Activates mise shims and direnv in interactive zsh when those tools exist.",
        kind: CONFIG_BLOCK_KINDS.SIDE_EFFECT,
        risk: "Keep this after PATH setup so mise and direnv are discovered from the expected locations.",
        shortcuts: [],
        start: 63,
        end: 69
      },
      {
        id: "environment",
        title: "Environment",
        description: "Sets locale, editor, visual editor, and GPG tty defaults without overriding existing values.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: [],
        start: 71,
        end: 77
      },
      {
        id: "history-search",
        title: "History search keys",
        description: "Makes Up and Down search matching command history from the current prefix.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: ["Up", "Down"],
        start: 79,
        end: 83
      },
      {
        id: "safe-aliases",
        title: "Prompted aliases",
        description: "Keeps raw rm, cp, and mv untouched, and adds explicit prompted variants.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: ["rmi", "rmri", "cpi", "mvi"],
        start: 85,
        end: 90
      },
      {
        id: "navigation",
        title: "Navigation and listings",
        description: "Adds short directory and listing aliases used during terminal work.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: ["cd..", "l", "ll", "la"],
        start: 92,
        end: 97
      },
      {
        id: "tmux-docker",
        title: "tmux and Docker aliases",
        description: "Adds the session attach flow and common Docker Compose shortcuts.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: ["ta 0", "ta0", "tls", "tn"],
        start: 99,
        end: 105
      },
      {
        id: "editors",
        title: "Edit helpers",
        description: "Adds quick commands for editing and applying the shell configuration.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: ["zshrc", "zshrc_apply"],
        start: 107,
        end: 108
      },
      {
        id: "inspection",
        title: "Inspection helpers",
        description: "Adds compact helpers for listening ports, IP addresses, and PATH entries.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: ["ports", "ipb", "pathls"],
        start: 110,
        end: 124
      },
      {
        id: "local-prompt",
        title: "Local hooks and prompt file",
        description: "Loads local customizations and then the generated Powerlevel10k prompt file.",
        kind: CONFIG_BLOCK_KINDS.LOCKED,
        risk: "Keep this at the end so local overrides and prompt config apply after framework setup.",
        shortcuts: [],
        start: 126,
        end: 127
      }
    ])
  },
  [CONFIG_KEYS.VIMRC]: {
    title: ".vimrc",
    path: "$HOME/.vimrc",
    blocks: createConfigBlocks(vimConfigRaw, [
      {
        id: "core",
        title: "Core mode",
        description: "Starts Vim in modern mode with filetype plugins, indentation, syntax, and a space leader.",
        kind: CONFIG_BLOCK_KINDS.LOCKED,
        shortcuts: [],
        start: 1,
        end: 4
      },
      {
        id: "encoding",
        title: "Encoding and files",
        description: "Sets UTF-8 defaults, safer bells, autoread, hidden buffers, swap, undo, and cache directories.",
        kind: CONFIG_BLOCK_KINDS.SIDE_EFFECT,
        risk: "This creates ~/.vim cache directories during startup so project directories stay clean.",
        shortcuts: [],
        start: 6,
        end: 21
      },
      {
        id: "indent",
        title: "Indentation",
        description: "Uses two-space indentation by default with expanded tabs.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: [],
        start: 23,
        end: 29
      },
      {
        id: "search",
        title: "Search behavior",
        description: "Enables incremental smart-case search and a quick mapping to clear highlights.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: ["leader", "Space"],
        start: 31,
        end: 35
      },
      {
        id: "performance",
        title: "Completion and redraw",
        description: "Keeps completion local and avoids unnecessary redraw work.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: [],
        start: 37,
        end: 39
      },
      {
        id: "interface",
        title: "Interface",
        description: "Shows status, ruler, line numbers, command feedback, title, mouse, colors, and split direction.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: [],
        start: 41,
        end: 53
      },
      {
        id: "plugins",
        title: "vim-plug setup",
        description: "Uses vim-plug only when plug.vim exists, with vim-sensible and EditorConfig support.",
        kind: CONFIG_BLOCK_KINDS.SIDE_EFFECT,
        risk: "Keep plugin declarations after core Vim settings and before filetype-specific overrides.",
        shortcuts: [":PlugInstall"],
        start: 55,
        end: 61
      },
      {
        id: "filetypes",
        title: "Filetype indentation",
        description: "Overrides indentation for common web, Ruby, and Python files.",
        kind: CONFIG_BLOCK_KINDS.ORDERED,
        risk: "Keep the augroup together so sourcing .vimrc replaces old autocmds instead of duplicating them.",
        shortcuts: [],
        start: 63,
        end: 69
      }
    ])
  },
  [CONFIG_KEYS.TMUX]: {
    title: ".tmux.conf",
    path: "$HOME/.tmux.conf",
    blocks: createConfigBlocks(tmuxConfigRaw, [
      {
        id: "prefix",
        title: "Prefix and reload",
        description: "Uses Ctrl-A as the prefix and binds reload to prefix plus r.",
        kind: CONFIG_BLOCK_KINDS.LOCKED,
        risk: "Keep prefix bindings before later key bindings so the rest of the file uses the expected prefix.",
        shortcuts: ["C-a", "C-a r"],
        start: 1,
        end: 6
      },
      {
        id: "terminal",
        title: "Terminal capabilities",
        description: "Sets tmux-256color and truecolor capability hints for modern terminals.",
        kind: CONFIG_BLOCK_KINDS.ORDERED,
        risk: "Keep this before status and color styling so later color settings render correctly.",
        shortcuts: [],
        start: 8,
        end: 10
      },
      {
        id: "session",
        title: "Session behavior",
        description: "Enables mouse support, focus events, clipboard, renumbering, and deep history.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: [],
        start: 12,
        end: 19
      },
      {
        id: "indexes",
        title: "Indexes",
        description: "Starts windows and panes at 1 for easier keyboard targeting.",
        kind: CONFIG_BLOCK_KINDS.ORDERED,
        risk: "Move this only if every window and pane binding still expects one-based indexes.",
        shortcuts: ["1"],
        start: 21,
        end: 23
      },
      {
        id: "windows",
        title: "Windows and panes",
        description: "Adds pane splits, vim-style pane movement, window navigation, and resize keys.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: ["c", "|", "-", "h", "j", "k", "l", "Tab"],
        start: 25,
        end: 42
      },
      {
        id: "copy",
        title: "Copy mode",
        description: "Uses vi copy mode and tries macOS and Linux clipboard tools before falling back.",
        kind: CONFIG_BLOCK_KINDS.SIDE_EFFECT,
        risk: "Keep mode-keys before copy bindings. Clipboard commands run when text is copied.",
        shortcuts: ["v", "y", "Enter"],
        start: 44,
        end: 49
      },
      {
        id: "status",
        title: "Status line",
        description: "Sets a compact status line with host, session, date, time, window, and pane.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: [],
        start: 51,
        end: 63
      },
      {
        id: "tpm",
        title: "TPM block",
        description: "Keeps the tmux plugin manager block available but commented by default.",
        kind: CONFIG_BLOCK_KINDS.SIDE_EFFECT,
        risk: "Keep TPM plugin declarations near the bottom. TPM expects plugin lines before its run command.",
        shortcuts: ["prefix", "I"],
        start: 65,
        end: 69
      }
    ])
  },
  [CONFIG_KEYS.GITCONFIG]: {
    title: ".gitconfig",
    path: "$HOME/.gitconfig",
    blocks: createConfigBlocks(gitConfigRaw, [
      {
        id: "safe-defaults",
        title: "Safe defaults",
        description: "Keeps push simple, pull fast-forward only, and new repositories on main.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: [],
        start: 1,
        end: 6
      },
      {
        id: "aliases",
        title: "Git aliases",
        description: "Adds short status, graph log, difftool, and conflict listing commands.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: ["git st", "git lg", "git lga"],
        start: 7,
        end: 13
      },
      {
        id: "core",
        title: "Editor and excludes",
        description: "Sets the editor, pager, and shared global exclude file.",
        kind: CONFIG_BLOCK_KINDS.ORDERED,
        risk: "Keep excludesfile aligned with the linked ~/.gitexclude path.",
        shortcuts: [],
        start: 14,
        end: 17
      },
      {
        id: "merge-diff",
        title: "Diff and merge defaults",
        description: "Uses histogram diff, zdiff3 conflict markers, and rerere reuse.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        shortcuts: [],
        start: 18,
        end: 24
      },
      {
        id: "local-identity",
        title: "Local identity include",
        description: "Loads ~/.gitconfig.local for name, email, and machine-only Git settings.",
        kind: CONFIG_BLOCK_KINDS.LOCKED,
        risk: "Keep identity out of this shared file. Put user.name and user.email in ~/.gitconfig.local.",
        shortcuts: [],
        start: 25,
        end: 26
      },
      {
        id: "directory-includes",
        title: "Directory identity examples",
        description: "Shows commented includeIf blocks for separate work and personal Git accounts.",
        kind: CONFIG_BLOCK_KINDS.FREE,
        risk: "Only uncomment these after creating the target files, or Git can fail inside matching directories.",
        shortcuts: ["~/work", "~/personal"],
        start: 28,
        end: 33
      }
    ])
  },
  [CONFIG_KEYS.HTOP]: {
    title: "htoprc",
    path: "$HOME/.config/htop/htoprc",
    mkdir: "$HOME/.config/htop",
    blocks: createConfigBlocks(htopConfigDefault, [
      {
        id: "columns",
        title: "Columns and sorting",
        description: "Chooses the visible process columns and sorts by memory usage.",
        shortcuts: ["F6"],
        start: 1,
        end: 5
      },
      {
        id: "visibility",
        title: "Visibility",
        description: "Controls thread display, merged commands, highlighting, and path behavior.",
        shortcuts: ["H", "K"],
        start: 6,
        end: 24
      },
      {
        id: "runtime",
        title: "Runtime display",
        description: "Sets color scheme, mouse support, refresh delay, and CPU display behavior.",
        shortcuts: ["F2", "F9"],
        start: 25,
        end: 31
      },
      {
        id: "meters",
        title: "Header meters",
        description: "Shows CPU, memory, swap, task, load, and uptime meters.",
        shortcuts: [],
        start: 32,
        end: 35
      }
    ])
  }
};

export const createInitialConfigBlocks = () =>
  Object.fromEntries(
    (Object.keys(configDefinitions) as ConfigKey[]).map((key) => [
      key,
      configDefinitions[key].blocks.map((block) => ({ ...block }))
    ])
  ) as Record<ConfigKey, ConfigBlock[]>;

export const createInitialActiveBlocks = () =>
  Object.fromEntries(
    (Object.keys(configDefinitions) as ConfigKey[]).map((key) => [key, configDefinitions[key].blocks[0].id])
  ) as Record<ConfigKey, string>;

export const buildConfigContent = (blocks: ConfigBlock[]) =>
  blocks
    .filter((block) => block.enabled)
    .map((block) => block.content.trimEnd())
    .filter(Boolean)
    .join("\n\n")
    .concat("\n");

export const pluginNoteFor = (configKey: ConfigKey, blockId: string) => {
  if (configKey === CONFIG_KEYS.VIMRC && blockId === "plugins") {
    return "vim-plug is installed by the setup script. This rc block only uses it when plug.vim already exists.";
  }
  if (configKey === CONFIG_KEYS.TMUX && blockId === "tpm") {
    return "TPM stays commented by default. Install TPM, uncomment this block, then press prefix plus I to install plugins.";
  }
  if (configKey === CONFIG_KEYS.GITCONFIG && blockId === "directory-includes") {
    return "Use includeIf when one machine needs different Git accounts by directory. Keep the example commented until the extra files exist.";
  }
  return "";
};
