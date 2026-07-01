#!/usr/bin/env bash
# Двойной клик в Finder (macOS): собрать vpn-detector-release.aar.
# Просто оборачивает build_aar.sh, чтобы работал запуск мышкой.
cd "$(dirname "$0")"
exec ./build_aar.sh
