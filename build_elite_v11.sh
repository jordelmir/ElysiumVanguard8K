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

# 3. Empaquetado de la nueva versión
VERSION="11.0.0-Elite"
BUILD_DIR=".build/release"
RELEASE_NAME="ProPlayer_v${VERSION}_$(date +%Y%m%d).zip"

echo "📦 Empaquetando la versión v${VERSION}..."
zip -r "$RELEASE_NAME" "$BUILD_DIR/ProPlayer" PRO_USAGE_GUIDE.md README.md

echo "✅ Compilación completada: $RELEASE_NAME"

# 4. Iniciar la nueva versión para demostración
echo "▶️ Iniciando la aplicación..."
./$BUILD_DIR/ProPlayer
