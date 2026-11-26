# Match upstream's setup-rusty-v8 action using checksums from the target checkout.
prepare_codex_v8() {
  if [ -n "${RUSTY_V8_ARCHIVE:-}" ] && [ -n "${RUSTY_V8_SRC_BINDING_PATH:-}" ]; then
    return
  fi
  source_dir=$1
  version=$(awk '$0 == "name = \"v8\"" { getline; gsub(/"/, "", $3); print $3; exit }' "$source_dir/codex-rs/Cargo.lock")
  [ -n "$version" ] || return 0
  underscored=$(printf '%s' "$version" | tr . _)
  trusted="$source_dir/third_party/v8/rusty_v8_${underscored}_release_manifests.sha256"
  [ -f "$trusted" ] || return 0

  target=$(rustc -vV | sed -n 's/^host: //p')
  profile="ptrcomp_sandbox_release_$target"
  case "$target" in
    *-pc-windows-msvc) archive="rusty_v8_$profile.lib.gz" ;;
    *) archive="librusty_v8_$profile.a.gz" ;;
  esac
  binding="src_binding_$profile.rs"
  manifest="rusty_v8_$profile.sha256"
  expected=$(awk -v name="$manifest" '$2 == name { print $1; exit }' "$trusted")
  [ -n "$expected" ] || return 0

  artifact_dir="$2/v8/$version/$target"
  origin="https://github.com/openai/codex/releases/download/rusty-v8-v$version"
  mkdir -p "$artifact_dir"
  if command -v sha256sum >/dev/null 2>&1; then
    checksum() { sha256sum "$@"; }
  else
    checksum() { shasum -a 256 "$@"; }
  fi
  if ! printf '%s  %s\n' "$expected" "$manifest" | (cd "$artifact_dir" && checksum --check - >/dev/null 2>&1); then
    curl -fsSL "$origin/$manifest" -o "$artifact_dir/$manifest"
  fi
  printf '%s  %s\n' "$expected" "$manifest" | (cd "$artifact_dir" && checksum --check -)
  if ! (cd "$artifact_dir" && tr -d '\r' < "$manifest" | checksum --check - >/dev/null 2>&1); then
    curl -fsSL "$origin/$archive" -o "$artifact_dir/$archive"
    curl -fsSL "$origin/$binding" -o "$artifact_dir/$binding"
  fi
  (cd "$artifact_dir" && tr -d '\r' < "$manifest" | checksum --check -)
  export RUSTY_V8_ARCHIVE="$artifact_dir/$archive" RUSTY_V8_SRC_BINDING_PATH="$artifact_dir/$binding"
}
