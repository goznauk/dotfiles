import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const rootDir = join(scriptDir, "..");
const zshrc = readFileSync(join(rootDir, "common/.zshrc"), "utf8");

const assert = (condition, message) => {
  if (!condition) {
    throw new Error(message);
  }
};

const assertIncludes = (expected, message) => {
  assert(zshrc.includes(expected), message);
};

assertIncludes(
  "_dotfiles_tmux_sessions()",
  ".zshrc must define a tmux session completion function."
);
assertIncludes(
  "compdef _dotfiles_tmux_sessions ta tk",
  ".zshrc must register tmux session completion for ta and tk."
);
assertIncludes(
  "tmux list-sessions -F '#S'",
  ".zshrc must complete current tmux session names."
);
assertIncludes(
  'tmux has-session -t "=$session"',
  "tmux helpers must use exact-name session lookup."
);
assertIncludes(
  'tmux attach-session -t "=$session"',
  "ta must attach to an exact existing session outside tmux."
);
assertIncludes(
  'tmux switch-client -t "=$session"',
  "ta must switch to an exact existing session inside tmux."
);
assertIncludes(
  'tmux new-session -d -s "$session"',
  "ta must create missing sessions detached when already inside tmux."
);
assertIncludes('[[ "$session" == -* ]]', "tmux helpers must reject option-like session names.");
assertIncludes("Usage: tk <session>", "tk must require an explicit session name.");
assertIncludes("tmain()", ".zshrc must keep the tmain shortcut.");

console.log("zsh tmux helper check passed.");
