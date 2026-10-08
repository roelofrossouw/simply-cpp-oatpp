#!/bin/bash
#~~~~~~~~~~
# Builds and publishes oatpp independently on every Ubuntu build server.

set -euo pipefail

module="sc-oatpp"
servers=("$@")
if [ ${#servers[@]} -eq 0 ]; then
    servers=(build-jammy build-noble build-resolute)
fi

scriptfile=$(realpath "$0")
scriptpath="${scriptfile%/*}"
dirpath=$(realpath "$scriptpath"/..)

# Each server's output (rsync and the build server's) is also kept in a local log named after
# the server: <suite>/logs/<server>/ inside the simply-cpp suite, otherwise logs/<server>/ in
# /tmp. Skipped when the caller already logs the run (publish-apt.sh sets SC_LOGGING).
suite=$(git -C "$dirpath" rev-parse --show-superproject-working-tree 2>/dev/null)
logs="${suite:-${TMPDIR:-/tmp}/simply-cpp}/logs"
logged() {
    local server="$1"
    shift
    if [ -n "${SC_LOGGING:-}" ]; then
        "$@"
        return
    fi
    mkdir -p "$logs/$server"
    local log_file
    log_file="$logs/$server/$(date -u +%Y%m%dT%H%M%SZ)-$module.log"
    echo "Logging to $log_file"
    "$@" 2>&1 | tee "$log_file"
    return "${PIPESTATUS[0]}"
}

deploy_to() {
    local server="$1"
    rsync -av "$dirpath/" "root@$server:/var/www/build/$module/" --exclude=".git" --exclude="work" --exclude="pkg" --delete || return
    ssh "root@$server" "cd /var/www/build/$module && bash scripts/publish.sh"
}

overall=0
for server in "${servers[@]}"; do
    echo "==> $server"
    if ! logged "$server" deploy_to "$server"; then
        echo "$server FAILED" >&2
        overall=1
    fi
done

exit "$overall"
