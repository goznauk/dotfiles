#!/usr/bin/env node

import { readdir, readFile, stat } from "node:fs/promises";
import { join } from "node:path";

const allowed = new Set([9, 10, 13]);
const ignoredNames = new Set([".git", ".tmp", "dist", "node_modules"]);
const roots = process.argv.slice(2);
const errors = [];

if (roots.length === 0) {
  console.error("Usage: check-ascii.mjs <path> [path...]");
  process.exit(2);
}

async function walk(path) {
  const info = await stat(path);
  if (info.isDirectory()) {
    if (ignoredNames.has(path.split("/").pop() ?? "")) {
      return;
    }
    const entries = await readdir(path);
    await Promise.all(entries.map((entry) => walk(join(path, entry))));
    return;
  }

  if (!info.isFile()) {
    return;
  }

  await checkFile(path);
}

async function checkFile(path) {
  const content = await readFile(path, "utf8");
  const lines = content.split(/\r?\n/);
  for (let lineIndex = 0; lineIndex < lines.length; lineIndex += 1) {
    const line = lines[lineIndex];
    for (let columnIndex = 0; columnIndex < line.length; columnIndex += 1) {
      const code = line.charCodeAt(columnIndex);
      if (allowed.has(code) || (code >= 32 && code <= 126)) {
        continue;
      }
      errors.push(`${path}:${lineIndex + 1}:${columnIndex + 1}: non-ASCII character U+${code.toString(16).toUpperCase()}`);
    }
  }
}

for (const root of roots) {
  await walk(root);
}

if (errors.length > 0) {
  for (const error of errors) {
    console.error(error);
  }
  process.exit(1);
}

console.log("ASCII text check passed.");
