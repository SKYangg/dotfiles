#!/usr/bin/env bash
# Exercise the real installer against a disposable, synthetic repository.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-tests.XXXXXX")"
TEST_ROOT="$(cd "$TEST_ROOT" && pwd -P)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT
REPO="$TEST_ROOT/repo with spaces"
mkdir -p "$REPO/scripts" "$REPO/vim/tests" "$REPO/vim/.vim" \
  "$REPO/ai/.claude" "$REPO/cli/.config/yazi/plugins/demo" \
  "$REPO/cli/.config/brewfile" "$REPO/aerospace" "$REPO/macos/Library/LaunchAgents"
cp "$ROOT/scripts/bootstrap.sh" "$REPO/scripts/bootstrap.sh"
for path in vim/.vimrc vim/.vim/writing.vim vim/maintenance.md vim/practical-guide.md \
  vim/CLAUDE.md vim/tests/case.vim vim/private.example ai/.claude/CLAUDE.md \
  cli/.config/yazi/plugins/demo/README.md cli/.config/brewfile/Brewfile \
  aerospace/.aerospace.toml macos/Library/LaunchAgents/demo.plist; do
  printf 'fixture %s\n' "$path" > "$REPO/$path"
done
fail() { printf 'FAIL %s\n' "$*" >&2; exit 1; }
linked() { [[ -L "$1" ]] && [[ "$(readlink "$1")" == "$2" ]] || fail "link: $1"; }
absent() { [[ ! -e "$1" && ! -L "$1" ]] || fail "unexpected: $1"; }
install() { bash "$REPO/scripts/bootstrap.sh" "$@"; }
for platform in macos linux; do
  target="$TEST_ROOT/home $platform"
  install --home "$target" --platform "$platform" --dry-run > "$TEST_ROOT/dry-$platform.log"
  absent "$target"
  mkdir -p "$target"
  printf 'original configuration\n' > "$target/.vimrc"
  install --home "$target" --backup "$TEST_ROOT/backup-$platform" --platform "$platform" > "$TEST_ROOT/install-$platform.log"
  linked "$target/.vimrc" "$REPO/vim/.vimrc"
  linked "$target/.vim/writing.vim" "$REPO/vim/.vim/writing.vim"
  linked "$target/.claude/CLAUDE.md" "$REPO/ai/.claude/CLAUDE.md"
  linked "$target/.config/yazi/plugins/demo/README.md" "$REPO/cli/.config/yazi/plugins/demo/README.md"
  [[ "$(cat "$TEST_ROOT/backup-$platform/.vimrc")" == 'original configuration' ]] || fail backup
  for path in tests maintenance.md practical-guide.md CLAUDE.md private.example; do absent "$target/$path"; done
  for path in .aerospace.toml Library/LaunchAgents/demo.plist .config/brewfile/Brewfile; do
    if [[ "$platform" == linux ]]; then absent "$target/$path"; else [[ -L "$target/$path" ]] || fail "macos: $path"; fi
  done
  install --home "$target" --backup "$TEST_ROOT/repeat-$platform" --platform "$platform" > "$TEST_ROOT/repeat-$platform.log"
  grep -qx 'linked: 0' "$TEST_ROOT/repeat-$platform.log" || fail idempotence-links
  grep -qx 'backed_up: 0' "$TEST_ROOT/repeat-$platform.log" || fail idempotence-backups
  printf 'PASS %s scope, platform, backup, idempotence, dry-run\n' "$platform"
done
# An existing ancestor link must never move the repository's own source.
target="$TEST_ROOT/ancestor home"
mkdir -p "$target"
ln -s "$REPO/vim/.vim" "$target/.vim"
cp "$REPO/vim/.vim/writing.vim" "$TEST_ROOT/original"
ln -s "$REPO" "$TEST_ROOT/repo alias"
bash "$TEST_ROOT/repo alias/scripts/bootstrap.sh" --home "$target" --backup "$TEST_ROOT/ancestor-backup" --platform linux > "$TEST_ROOT/ancestor.log"
[[ ! -L "$REPO/vim/.vim/writing.vim" ]] || fail source-replaced
cmp "$TEST_ROOT/original" "$REPO/vim/.vim/writing.vim" || fail source-content
absent "$TEST_ROOT/ancestor-backup/.vim/writing.vim"
linked "$target/.vim" "$REPO/vim/.vim"
printf 'PASS ancestor symlink preserves repository content\n'
