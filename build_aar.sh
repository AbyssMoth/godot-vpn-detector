#!/usr/bin/env bash
# Пересборка vpn-detector-release.aar из обёртки + ядра (submodule).
# Требует: Android SDK, JDK 17-22 (Gradle 8.14.x не поддерживает JDK 25), gradle.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# Ядро подключено submodule'ом в android_plugin/core; подтянуть, если пусто.
if [[ ! -e "android_plugin/core/vpndetectorcore/build.gradle" ]]; then
	echo "Инициализирую submodule ядра..."
	git submodule update --init --recursive
fi

export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
if [[ -z "${JAVA_HOME:-}" ]] && command -v /usr/libexec/java_home >/dev/null 2>&1; then
	export JAVA_HOME="$(/usr/libexec/java_home -v 22 2>/dev/null || /usr/libexec/java_home 2>/dev/null || true)"
fi

BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/godot-vpn-detector-build.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT
mkdir -p "$BUILD_DIR/android_plugin"
rsync -a --delete \
	--exclude='.gradle/' \
	--exclude='build/' \
	--exclude='.git' \
	android_plugin/ "$BUILD_DIR/android_plugin/"

cd "$BUILD_DIR/android_plugin"
./gradlew clean :plugin:assembleRelease --no-daemon
mkdir -p ../bin
cp plugin/build/outputs/aar/plugin-release.aar "$ROOT/bin/vpn-detector-release.aar"
echo "Готово: $ROOT/bin/vpn-detector-release.aar"
