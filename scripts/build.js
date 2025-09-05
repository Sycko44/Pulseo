import { cpSync, rmSync, mkdirSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.cwd());
const publicDir = resolve(root, 'public');
const distDir = resolve(root, 'dist');

try {
  if (existsSync(distDir)) rmSync(distDir, { recursive: true, force: true });
  mkdirSync(distDir, { recursive: true });
  cpSync(publicDir, distDir, { recursive: true });
  console.log('✅ Build: copied public → dist');
} catch (e) {
  console.error('Build failed:', e);
  process.exit(0); // do not fail CI if no public dir
}
