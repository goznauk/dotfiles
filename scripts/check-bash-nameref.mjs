#!/usr/bin/env node

import { readFile } from "node:fs/promises";

const files = process.argv.slice(2);
const errors = [];
const namerefPattern = /\blocal\s+-n\s+([A-Za-z_][A-Za-z0-9_]*)=/g;

if (files.length === 0) {
  console.error("Usage: check-bash-nameref.mjs <file> [file...]");
  process.exit(2);
}

const checkFile = async (file) => {
  const content = await readFile(file, "utf8");
  const lines = content.split(/\r?\n/);

  lines.forEach((line, index) => {
    for (const match of line.matchAll(namerefPattern)) {
      const name = match[1];
      if (!name.startsWith("__")) {
        errors.push(`${file}:${index + 1}: nameref local '${name}' must start with __`);
      }
    }
  });
};

await Promise.all(files.map((file) => checkFile(file)));

if (errors.length > 0) {
  errors.forEach((error) => console.error(error));
  process.exit(1);
}

console.log("Bash nameref check passed.");
