#!/usr/bin/env bash
set -euo pipefail
# Public source, pinned revision and recursive submodule commits. No draft binary.
project_dir=$(cd "$(dirname "$0")/../.." && pwd)
core_dir=${1:-"$project_dir/hiddify-core/source"}
core_lock=()
while IFS= read -r line; do core_lock+=("$line"); done < <(python3 - "$project_dir/tool/native/core.lock.json" <<'PY'
import json,sys
lock=json.load(open(sys.argv[1]))
for key in ['repository','revision','amneziawg']: print(lock[key])
PY
)
if [[ ! -d "$core_dir/.git" ]]; then
  git init "$core_dir"
  git -C "$core_dir" remote add origin "${core_lock[0]}"
fi
git -C "$core_dir" fetch --depth=1 origin "${core_lock[1]}"
git -C "$core_dir" checkout --detach FETCH_HEAD
[[ $(git -C "$core_dir" rev-parse HEAD) == "${core_lock[1]}" ]]
git -C "$core_dir" submodule init
git -C "$core_dir" config submodule.ray2sing.url https://github.com/hiddify/ray2sing.git
git -C "$core_dir" submodule update --init --recursive --depth=1
python3 "$project_dir/tool/native/patch-core.py" "$core_dir"
(cd "$core_dir" && go mod edit -dropreplace=github.com/amnezia-vpn/amneziawg-go -droprequire=github.com/amnezia-vpn/amneziawg-go "-require=github.com/amnezia-vpn/amneziawg-go/v3@${core_lock[2]}" && go mod tidy)
