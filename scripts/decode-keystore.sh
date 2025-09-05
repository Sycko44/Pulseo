#!/usr/bin/env bash
set -euo pipefail
MOBILE_DIR="${MOBILE_DIR:-apps/mobile}"
ANDROID_DIR="$MOBILE_DIR/android"
KS_DIR="$ANDROID_DIR/keystore"
mkdir -p "$KS_DIR"
if [ -z "${ANDROID_KEYSTORE_BASE64:-}" ]; then
  echo "ℹ️ Pas de keystore → APK debug uniquement"; exit 0
fi
echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > "$KS_DIR/pulseo-release.keystore"
cat > "$ANDROID_DIR/keystore.properties" <<EOF
storeFile=$KS_DIR/pulseo-release.keystore
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
keyPassword=${ANDROID_KEY_PASSWORD}
EOF
