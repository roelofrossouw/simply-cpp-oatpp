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

overall=0
for server in "${servers[@]}"; do
    echo "==> $server"
    rsync -av "$dirpath/" "root@$server:/var/www/build/$module/" --exclude=".git" --exclude="work" --exclude="pkg" --delete || {
        overall=1
        continue
    }
    if ! ssh "root@$server" "cd /var/www/build/$module && bash scripts/publish.sh"; then
        echo "$server FAILED" >&2
        overall=1
    fi
done

exit "$overall"
