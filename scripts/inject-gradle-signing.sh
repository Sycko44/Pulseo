#!/usr/bin/env bash
set -euo pipefail
APP_GRADLE="${1:-apps/mobile/android/app/build.gradle}"
if [ ! -f "$APP_GRADLE" ]; then echo "Gradle not found: $APP_GRADLE"; exit 1; fi
if grep -q "keystorePropertiesFile" "$APP_GRADLE"; then echo "Signing block present."; exit 0; fi
cat >> "$APP_GRADLE" <<'EOF'

// === Pulseo: signing via keystore.properties ===
def keystorePropertiesFile = rootProject.file("keystore.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) { keystoreProperties.load(new FileInputStream(keystorePropertiesFile)) }

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            shrinkResources true
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug { debuggable true }
    }
}
EOF
echo "Gradle signing injected."
