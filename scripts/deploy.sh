#!/bin/bash
#~~~~~~~~~~
# Deploys this packaging project through the suite's shared packaging/deploy.sh
# (one script for every project in the suite's packaging/ folder since 2026-11-17).
#
# Usage: scripts/deploy.sh [server...]
#   builds on every server named (default: build-jammy build-noble build-resolute): oatpp is built from source per Ubuntu release

scriptfile=$(realpath "$0")
dirpath=$(realpath "${scriptfile%/*}"/..)
suite=$(git -C "$dirpath" rev-parse --show-superproject-working-tree 2>/dev/null)
if [ -z "$suite" ] || [ ! -x "$suite/packaging/deploy.sh" ]; then
    echo "$0: needs the simply-cpp suite checkout (its packaging/deploy.sh)" >&2
    exit 1
fi
exec "$suite/packaging/deploy.sh" --per-server "$dirpath" "$@"
