#!/usr/bin/env sh
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
patch="$here/codex-swarm.patch"
tag=rust-v0.171.0-alpha.13.2
check=false
if [ "${1:-}" = "--check" ]; then
  check=true
  shift
fi
if [ "$#" -gt 1 ] || { "$check" && [ "$#" -ne 1 ]; }; then
  printf '%s\n' 'Usage: native/build.sh [CODEX_CHECKOUT] or native/build.sh --check CODEX_CHECKOUT' >&2
  exit 2
fi
checkout=${1:-"$here/.build/codex-source"}
if [ "$#" -eq 0 ] && [ ! -e "$checkout" ]; then
  mkdir -p "$here/.build"
  git clone --depth 1 --branch "$tag" https://github.com/openai/codex.git "$checkout"
fi
checkout=$(CDPATH= cd -- "$checkout" && pwd)

if git -C "$checkout" apply --check "$patch" 2>/dev/null; then
  if "$check"; then
    printf '%s\n' 'The Swarm patch applies cleanly.'
    exit 0
  fi
  git -C "$checkout" apply "$patch"
elif git -C "$checkout" apply --reverse --check "$patch" >/dev/null 2>&1; then
  if "$check"; then
    printf '%s\n' 'The Swarm patch is already applied.'
    exit 0
  fi
else
  printf '%s\n' 'The upstream TUI changed. Review the patch against this checkout before building.' >&2
  exit 1
fi

build="$here/.build"
mkdir -p "$build"
(
  cd "$checkout/codex-rs"
  export CARGO_TARGET_DIR="$build/target"
  cargo build --locked --profile dev-small -p codex-cli --bin codex
)
install -m 755 "$build/target/dev-small/codex" "$build/codex"
printf 'Launch with %s/launch.sh\n' "$here"
