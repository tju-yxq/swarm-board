#!/usr/bin/env sh
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
binary=${CODEX_SWARM_CLI:-"$here/.build/codex"}
if [ ! -x "$binary" ]; then
  printf 'Patched Codex CLI not found. Build it with %s/build.sh.\n' "$here" >&2
  exit 1
fi
export CODEX_SWARM_RUNNER="$here/../skills/swarm/codex/run.mjs"
exec "$binary" "$@"
