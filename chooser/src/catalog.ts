import catalogData from "../../packages/catalog.json";
import type { OsId } from "./ids";

export type OsVersion = {
  value: string;
  label: string;
  note: string;
};

export type OsTarget = {
  id: OsId;
  label: string;
  packageManager: string;
  commandTarget: string;
  implemented: boolean;
  note: string;
  defaultVersion: string;
  versions: OsVersion[];
};

export type PackageGroup = {
  id: string;
  title: string;
  description: string;
  defaultEnabled: boolean;
};

export type CatalogPackage = {
  id: string;
  group: string;
  label: string;
  defaultSelected: boolean;
  packages: Record<OsId, string[]>;
  note?: string;
};

export type Strategy = {
  id: string;
  label: string;
  description: string;
  defaults?: OsId[];
};

type Catalog = {
  osTargets: OsTarget[];
  groups: PackageGroup[];
  packages: CatalogPackage[];
  strategies: {
    docker: Strategy[];
    node: Strategy[];
    python: Strategy[];
    java: Strategy[];
  };
};

export const catalog = catalogData as Catalog;

export const defaultVersionForTarget = (target: OsTarget) => target.defaultVersion || target.versions[0]?.value || "";

export const packageNamesForOs = (item: CatalogPackage, osId: OsId) => item.packages[osId] ?? [];

export const packageDescriptionFor = (item: CatalogPackage, group: PackageGroup) => item.note ?? group.description;
