#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const catalogPath = resolve(rootDir, "packages/catalog.json");
const ubuntuCorePath = resolve(rootDir, "Ubuntu/packages/core.txt");
const ubuntuOptionalPath = resolve(rootDir, "Ubuntu/packages/optional.txt");

const errors = [];

const readJson = async (path) => JSON.parse(await readFile(path, "utf8"));

const readPackageList = async (path) => {
  const content = await readFile(path, "utf8");
  return content
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith("#"));
};

const reportDuplicate = (label, values) => {
  const seen = new Set();
  const duplicates = new Set();

  for (const value of values) {
    if (seen.has(value)) {
      duplicates.add(value);
    }
    seen.add(value);
  }

  for (const value of duplicates) {
    errors.push(`${label} has duplicate value: ${value}`);
  }
};

const requireValue = (condition, message) => {
  if (!condition) {
    errors.push(message);
  }
};

const catalog = await readJson(catalogPath);
const ubuntuCore = await readPackageList(ubuntuCorePath);
const ubuntuOptional = await readPackageList(ubuntuOptionalPath);
const ubuntuKnownPackages = new Set([...ubuntuCore, ...ubuntuOptional]);

const osIds = catalog.osTargets.map((target) => target.id);
const groupIds = catalog.groups.map((group) => group.id);
const packageIds = catalog.packages.map((item) => item.id);

reportDuplicate("osTargets", osIds);
reportDuplicate("groups", groupIds);
reportDuplicate("packages", packageIds);
reportDuplicate("Ubuntu core packages", ubuntuCore);
reportDuplicate("Ubuntu optional packages", ubuntuOptional);
reportDuplicate("Ubuntu package lists", [...ubuntuCore, ...ubuntuOptional]);

for (const target of catalog.osTargets) {
  requireValue(target.id, "OS target is missing id");
  requireValue(target.label, `OS target ${target.id} is missing label`);
  requireValue(target.packageManager, `OS target ${target.id} is missing package manager`);
  requireValue(target.commandTarget, `OS target ${target.id} is missing command target`);
  requireValue(Array.isArray(target.versions), `OS target ${target.id} is missing versions`);
  requireValue(
    target.versions.some((version) => version.value === target.defaultVersion),
    `OS target ${target.id} defaultVersion is not listed in versions`
  );
}

for (const group of catalog.groups) {
  requireValue(group.id, "Group is missing id");
  requireValue(group.title, `Group ${group.id} is missing title`);
  requireValue(group.description, `Group ${group.id} is missing description`);
}

for (const item of catalog.packages) {
  requireValue(groupIds.includes(item.group), `Package ${item.id} references unknown group ${item.group}`);
  requireValue(item.label, `Package ${item.id} is missing label`);
  requireValue(item.note, `Package ${item.id} is missing note`);

  for (const osId of osIds) {
    const osPackages = item.packages[osId];
    requireValue(Array.isArray(osPackages), `Package ${item.id} is missing package list for ${osId}`);
    reportDuplicate(`${item.id} ${osId} packages`, osPackages ?? []);

    if (osId === "ubuntu" && item.defaultSelected) {
      for (const packageName of osPackages ?? []) {
        requireValue(
          ubuntuKnownPackages.has(packageName),
          `Selected Ubuntu package ${packageName} from ${item.id} is missing from Ubuntu package lists`
        );
      }
    }
  }
}

for (const [strategyGroup, strategies] of Object.entries(catalog.strategies)) {
  reportDuplicate(`${strategyGroup} strategy ids`, strategies.map((strategy) => strategy.id));
  requireValue(
    strategies.some((strategy) => strategy.id === "none"),
    `${strategyGroup} strategies must include none`
  );

  for (const strategy of strategies) {
    requireValue(strategy.label, `${strategyGroup} strategy ${strategy.id} is missing label`);
    requireValue(strategy.description, `${strategyGroup} strategy ${strategy.id} is missing description`);

    for (const osId of strategy.defaults ?? []) {
      requireValue(osIds.includes(osId), `${strategyGroup} strategy ${strategy.id} has invalid default ${osId}`);
    }
  }
}

if (errors.length > 0) {
  for (const error of errors) {
    console.error(`ERROR: ${error}`);
  }
  process.exit(1);
}

console.log("Catalog validation passed.");
