#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd ~/meta-spiratech
echo "🔍 Walk & verify"

need() { [ -f "$1" ] && echo "✅ $1" || { echo "❌ $1 manquant → création"; mkdir -p "$(dirname "$1")"; printf "%s\n" "$2" > "$1"; }; }

need "packages/meta-core/src/metaLoop.ts" "// metaLoop.ts (present)"
need "packages/meta-core/src/skills.ts"  "// skills.ts (present)"
need "packages/connectors/src/index.ts"  "// connectors (present)"
need "apps/pulseo-web/app/providers.tsx" "// providers (present)"
need "apps/pulseo-web/app/api/rss/route.ts" "// api rss (present)"
need "config/meta.json"                  "{}"
need "public/manifest.json"              "{}"
need "public/sw.js"                      "// sw"

# Nettoyage des fichiers temporaires
find . -type f \( -name "*~" -o -name "*.bak" -o -name "*.tmp" \) -print -delete
echo "✅ Walk terminé"
