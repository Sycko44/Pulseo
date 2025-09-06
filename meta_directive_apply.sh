#!/data/data/com.termux/files/usr/bin/bash
# Enregistre une directive texte ET applique immédiatement des politiques dérivées
set -euo pipefail
cd ~/meta-spiratech

DIR="config/directives"
META="config/meta.json"
mkdir -p "$DIR"
[ -f "$META" ] || echo '{}' > "$META"

if [ $# -eq 0 ]; then
  echo "Usage: bash meta_directive_apply.sh \"Ta directive en une ligne\""
  exit 1
fi

DIRECTIVE="$*"
STAMP=$(date +"%Y%m%d-%H%M%S")
FILE="$DIR/$STAMP.txt"
printf "%s\n" "$DIRECTIVE" > "$FILE"

# 1) Enregistrer la directive dans meta.json
if command -v jq >/dev/null; then
  jq --arg id "$STAMP" --arg path "$FILE" --argjson ts $(date +%s) \
     '.directives = ((.directives // []) + [{id:$id, path:$path, ts:$ts}])' \
     "$META" > "$META.tmp" && mv "$META.tmp" "$META"
else
  # Append minimal si jq absent (non destructif)
  printf '\n{"directives":[{"id":"%s","path":"%s","ts":%s}]}\n' "$STAMP" "$FILE" "$(date +%s)" >> "$META"
fi

# 2) Appliquer immédiatement une traduction simple de la directive → politiques
#    (parser ultra-léger basé sur des mots-clés courants)
apply_now() {
  local txt="$1"
  # Normaliser espaces/accents simples
  txt=$(printf "%s" "$txt" | tr '[:upper:]' '[:lower:]')
  # visuals=dimmed
  if printf "%s" "$txt" | grep -qiE 'visuals\s*=\s*dimmed|visuals:? *dimmed'; then
    if command -v jq >/dev/null; then
      jq '.policy.visuals="dimmed"' "$META" > "$META.tmp" && mv "$META.tmp" "$META"
    else
      printf '\n{"policy":{"visuals":"dimmed"}}\n' >> "$META"
    fi
    echo "→ policy.visuals = dimmed"
  fi
  # flushNow sur SOS
  if printf "%s" "$txt" | grep -qiE 'flushnow.*sos|sos.*flushnow|flushnow sur sos'; then
    if command -v jq >/dev/null; then
      jq '.policy."telemetry.flushOnSOS"=true | .policy."telemetry.flushNow"=true' "$META" > "$META.tmp" && mv "$META.tmp" "$META"
    else
      printf '\n{"policy":{"telemetry.flushOnSOS":true,"telemetry.flushNow":true}}\n' >> "$META"
    fi
    echo "→ policy.telemetry.flushOnSOS = true ; telemetry.flushNow = true"
  fi
  # seuil erreurs runtime > N / 5min  (extrait N si présent)
  if printf "%s" "$txt" | grep -qiE 'erreurs? *runtime.*>[ =]*[0-9]'; then
    N=$(printf "%s" "$txt" | sed -n 's/.*erreurs\? *runtime[^0-9]*>\? *\([0-9][0-9]*\).*/\1/p' | head -n1)
    [ -z "$N" ] && N=2
    if command -v jq >/dev/null; then
      jq --argjson n "$N" '.policy."errors.runtime.rate5m_threshold"=$n | .policy.visuals="dimmed"' "$META" > "$META.tmp" && mv "$META.tmp" "$META"
    else
      printf '\n{"policy":{"errors.runtime.rate5m_threshold":%s,"visuals":"dimmed"}}\n' "$N" >> "$META"
    fi
    echo "→ policy.errors.runtime.rate5m_threshold = $N ; visuals = dimmed"
  fi
  # priorité stabilité > performances → refreshFactor plus conservateur (>=1.25)
  if printf "%s" "$txt" | grep -qiE 'priorité.*stabilit|stabilité *>'; then
    if command -v jq >/dev/null; then
      jq '.policy.refreshFactor = ( ( .policy.refreshFactor // 1 ) | if . < 1.25 then 1.25 else . end )' "$META" > "$META.tmp" && mv "$META.tmp" "$META"
    else
      printf '\n{"policy":{"refreshFactor":1.25}}\n' >> "$META"
    fi
    echo "→ policy.refreshFactor ≥ 1.25"
  fi
}

apply_now "$DIRECTIVE"

echo "✅ Directive enregistrée et appliquée."
echo "   Fichier : $FILE"
echo "   Meta    : $META (policies mises à jour)"
