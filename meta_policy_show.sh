#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd ~/meta-spiratech
META="config/meta.json"; [ -f "$META" ] || { echo "meta.json introuvable"; exit 1; }
if command -v jq >/dev/null; then jq '{policy:.policy, directives:(.directives//[])}' "$META"; else cat "$META"; fi
