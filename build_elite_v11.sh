#!/bin/bash
set -e

echo "🚀 Iniciando compilación de ProPlayer Elite v11.0..."

# 1. Limpieza profunda
echo "🧹 Limpiando compilaciones previas..."
swift package clean
rm -rf .build

# 2. Compilación en modo Release con optimizaciones
echo "⚙️ Compilando en modo Release (Elite Optimization)..."
swift build -c release --product ProPlayer

VERSION="13.0-Elite"
BUILD_DIR=".build/release"
APP_NAME="Elysium Vanguard Pro Player.app"

echo "📦 Construyendo macOS App Bundle nativo..."
rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"

# Copiar Info.plist y binario
cp "Info.plist" "$APP_NAME/Contents/Info.plist"
cp "$BUILD_DIR/ProPlayer" "$APP_NAME/Contents/MacOS/ElysiumVanguardProPlayer"
chmod +x "$APP_NAME/Contents/MacOS/ElysiumVanguardProPlayer"

# Si existen recursos (assets, etc), copiarlos (opcional pero bueno)
if [ -d "$BUILD_DIR/ProPlayer_ProPlayerView.bundle" ]; then
    cp -r "$BUILD_DIR/ProPlayer_ProPlayerView.bundle" "$APP_NAME/Contents/Resources/"
fi

# Empaquetar
RELEASE_NAME="ProPlayer_v${VERSION}_$(date +%Y%m%d).zip"
echo "📦 Empaquetando la versión v${VERSION}..."
zip -r "$RELEASE_NAME" "$APP_NAME" PRO_USAGE_GUIDE.md README.md

echo "✅ Compilación y empaquetado completados: $RELEASE_NAME"

# 4. Iniciar la nueva versión para demostración como una App real (permite Spaces Full Screen)
echo "▶️ Iniciando la aplicación..."
open "$APP_NAME"
