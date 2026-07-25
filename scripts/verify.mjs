import fs from "node:fs";
import path from "node:path";

const projectRoot = process.cwd();
const html = fs.readFileSync(path.join(projectRoot, "index.html"), "utf8");
const markup = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, "");
const errors = [];

const scripts = [...html.matchAll(/<script(?![^>]*src)[^>]*>([\s\S]*?)<\/script>/gi)]
  .map(match => match[1]);
for (let index = 0; index < scripts.length; index += 1) {
  try {
    new Function(scripts[index]);
  } catch (error) {
    errors.push(`Script ${index + 1}: ${error.message}`);
  }
}

const localRefs = [...markup.matchAll(/(?:src|href)=["']([^"'?#]+)["']/g)]
  .map(match => match[1])
  .filter(ref => !/^(?:https?:|#|mailto:|javascript:|\/)/.test(ref));
for (const ref of new Set(localRefs)) {
  if (!fs.existsSync(path.resolve(projectRoot, ref))) {
    errors.push(`Eksik yerel dosya: ${ref}`);
  }
}

const i18nStart = html.indexOf("const I18N = ");
const i18nEnd = html.indexOf("\n};", i18nStart);
if (i18nStart < 0 || i18nEnd < 0) {
  errors.push("I18N sözlüğü bulunamadı");
} else {
  const expression = html.slice(i18nStart + "const I18N = ".length, i18nEnd + 2);
  const i18n = new Function(`return (${expression})`)();
  const usedKeys = new Set(
    [...markup.matchAll(/data-i18n(?:-html|-title|-placeholder)?=["']([^"']+)["']/g)]
      .map(match => match[1])
  );
  for (const lang of ["tr", "en", "ru"]) {
    for (const key of usedKeys) {
      if (!(key in i18n[lang])) errors.push(`Eksik ${lang.toUpperCase()} çevirisi: ${key}`);
    }
  }
}

const networkI18nStart = html.indexOf("const NETWORK_I18N = ");
const networkI18nEnd = html.indexOf("\n};", networkI18nStart);
if (networkI18nStart < 0 || networkI18nEnd < 0) {
  errors.push("Ağ çevirileri bulunamadı");
} else {
  const expression = html.slice(
    networkI18nStart + "const NETWORK_I18N = ".length,
    networkI18nEnd + 2
  );
  const networkI18n = new Function(`return (${expression})`)();
  for (const network of ["mainnet", "testnet"]) {
    for (const lang of ["tr", "en", "ru"]) {
      for (const key of ["welcome.subtitle", "welcome.warning", "help.testnet"]) {
        if (!networkI18n[network]?.[lang]?.[key]) {
          errors.push(`Eksik ağ çevirisi: ${network}.${lang}.${key}`);
        }
      }
    }
  }
}

const ids = [...markup.matchAll(/\bid=["']([^"']+)["']/g)].map(match => match[1]);
for (const id of new Set(ids.filter((value, index) => ids.indexOf(value) !== index))) {
  errors.push(`Tekrarlanan element id: ${id}`);
}

const manifest = JSON.parse(
  fs.readFileSync(path.join(projectRoot, "public", "manifest.webmanifest"), "utf8")
);
const manifestIcons = [
  ...(manifest.icons || []),
  ...(manifest.shortcuts || []).flatMap(shortcut => shortcut.icons || [])
];
for (const icon of manifestIcons) {
  const iconPath = path.join(projectRoot, "public", String(icon.src || "").replace(/^\//, ""));
  if (!fs.existsSync(iconPath)) errors.push(`Eksik PWA ikonu: ${icon.src}`);
}

const sw = fs.readFileSync(path.join(projectRoot, "public", "sw.js"), "utf8");
const staticBlock = sw.match(/const STATIC_ASSETS = \[([\s\S]*?)\];/)?.[1] || "";
for (const [, asset] of staticBlock.matchAll(/['"]([^'"]+)['"]/g)) {
  if (asset === "/") continue;
  const assetPath = path.join(projectRoot, "public", asset.replace(/^\//, ""));
  if (!fs.existsSync(assetPath)) errors.push(`Service worker dosyası eksik: ${asset}`);
}

if (!/<html\s+lang=["']tr["']/i.test(html)) errors.push("HTML lang=tr eksik");
if (!/<meta\s+charset=["']?utf-8/i.test(html)) errors.push("UTF-8 meta etiketi eksik");
if (!/rel=["']canonical["']/i.test(html)) errors.push("Canonical link eksik");
if (/abswar\.xyz/i.test(html)) errors.push("Eski abswar.xyz alan adı hâlâ index.html içinde");

if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}

console.log(
  `Centradar doğrulaması geçti: ${scripts.length} script, ${ids.length} element, ` +
  `${new Set(localRefs).size} yerel referans.`
);
