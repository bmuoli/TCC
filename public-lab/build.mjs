import { copyFile, mkdir, readFile, readdir, rm, stat, writeFile } from 'node:fs/promises';
import path from 'node:path';

const repoRoot = process.cwd();
const publicRoot = path.join(repoRoot, 'public-lab');
const labRoot = path.join(repoRoot, 'Lab Notebook - HTML');
const outputRoot = path.join(repoRoot, '_site');
const campaignPath = path.join(labRoot, 'campanha.json');

const campaign = JSON.parse(await readFile(campaignPath, 'utf8'));

await rm(outputRoot, { recursive: true, force: true });
await mkdir(path.join(outputRoot, 'data'), { recursive: true });
await copyFile(path.join(publicRoot, 'index.html'), path.join(outputRoot, 'index.html'));
await copyFile(campaignPath, path.join(outputRoot, 'data', 'campanha.json'));

const paths = new Set();

for (const test of campaign.tests || []) {
  for (const variant of ['Si', 'SiC']) {
    for (const direction of ['forward', 'reverse']) {
      const run = test?.switchVariants?.[variant]?.directions?.[direction];
      if (!run) continue;

      for (const item of run.evidence || []) {
        if (!item || item.reportInclude === false) continue;
        if (item.relativePath) paths.add(item.relativePath);
        if (item.annotatedRelativePath) paths.add(item.annotatedRelativePath);
      }

      for (const item of run.simulationImages || []) {
        if (item?.relativePath) paths.add(item.relativePath);
      }
    }
  }
}

let copied = 0;
const missing = [];
let fileIndex = null;

async function buildFileIndex(directory, index = new Map()) {
  const entries = await readdir(directory, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) await buildFileIndex(fullPath, index);
    else if (entry.isFile()) {
      const list = index.get(entry.name) || [];
      list.push(fullPath);
      index.set(entry.name, list);
    }
  }
  return index;
}

async function resolveSource(source) {
  try {
    const info = await stat(source);
    if (info.isFile()) return source;
  } catch {}

  fileIndex ||= await buildFileIndex(labRoot);
  const candidates = fileIndex.get(path.basename(source)) || [];
  return candidates.length === 1 ? candidates[0] : null;
}

for (const relativePath of [...paths].sort()) {
  const normalized = String(relativePath).replaceAll('\\', '/').replace(/^\/+/, '');
  const source = path.resolve(labRoot, ...normalized.split('/'));
  const insideLab = source.startsWith(path.resolve(labRoot) + path.sep);

  if (!insideLab) {
    missing.push(relativePath);
    continue;
  }

  try {
    const resolvedSource = await resolveSource(source);
    if (!resolvedSource) throw new Error('arquivo não localizado de forma inequívoca');
    const destination = path.resolve(outputRoot, 'assets', ...normalized.split('/'));
    await mkdir(path.dirname(destination), { recursive: true });
    await copyFile(resolvedSource, destination);
    copied += 1;
  } catch {
    missing.push(relativePath);
  }
}

const manifest = {
  generatedAt: new Date().toISOString(),
  campaignUpdatedAt: campaign.updatedAt || '',
  copiedAssets: copied,
  missingAssets: missing
};

await writeFile(path.join(outputRoot, 'data', 'build-manifest.json'), JSON.stringify(manifest, null, 2));
console.log(`Site público montado: ${copied} arquivo(s) de evidência copiado(s).`);
if (missing.length) console.warn(`Aviso: ${missing.length} arquivo(s) referenciado(s) não foram encontrados.`);
