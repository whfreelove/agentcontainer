#!/usr/bin/env bash
# Reproducer: Apple Container 0.10.0 drops nested files from build context
#
# Bug: `container build` silently drops files inside subdirectories when
# any component of the build context path is a symlink. On macOS, /tmp
# and /var are symlinks to /private/tmp and /private/var respectively,
# so any path through them (including mktemp -d) triggers the bug.
#
# Impact: devcontainer CLI stores feature temp files under /var/folders/,
# so `devcontainer build --docker-path <shim>` fails because feature
# install scripts inside subdirectories are never transferred.
#
# Workaround: copy the build context to a symlink-free path (e.g. under
# the project directory) before passing it to `container build`.
#
# Prerequisites:
#   - Apple Container CLI (`container`) 0.10.0
#   - Run from a directory under /Users (no symlinks in path)
#
# Usage: ./repro-container-build-context-bug.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_CTX="$SCRIPT_DIR/.repro-tmp-$$"

cleanup() { rm -rf "$LOCAL_CTX"; }
trap cleanup EXIT

setup_context() {
    local dir="$1"
    mkdir -p "$dir/sub"
    echo "root-file"  > "$dir/root.txt"
    echo "nested-file" > "$dir/sub/nested.txt"
    cat <<'DOCKERFILE' > "$dir/Dockerfile"
FROM ubuntu:latest
COPY . /tmp/out/
RUN find /tmp/out -type f | sort
DOCKERFILE
}

build_and_report() {
    local ctx="$1"
    local output
    output=$(container build --no-cache -t "repro-ctx-$$" "$ctx" 2>&1) || true
    local files
    files=$(echo "$output" \
        | grep -E '^#[0-9]+ [0-9.]+ /tmp/out/' \
        | sed 's/^#[0-9]* [0-9.]* //' \
        | sort)
    local count
    count=$(echo "$files" | grep -c '/tmp/out/' || true)
    echo "$files"
    # return count on last line
    echo "COUNT:$count"
}

echo "=== Apple Container build context symlink bug ==="
echo "container: $(container --version 2>&1 | head -1)"
echo ""

# --- Test 1: /var/folders path (from mktemp, has /var symlink) ---
TMPDIR_CTX="$(mktemp -d)/ctx"
setup_context "$TMPDIR_CTX"

run_test() {
    local label="$1" path="$2"
    echo "$label"
    echo "  path: $path"
    local result
    result=$(build_and_report "$path")
    local count
    count=$(echo "$result" | grep '^COUNT:' | cut -d: -f2)
    echo "$result" | grep -v '^COUNT:' | grep -v '^$' | sed 's/^/  /'
    echo "  result: $count/3 files"
    echo ""
    echo "$count"
}

files1=$(run_test "Test 1: symlink in path (/var/folders via mktemp)" "$TMPDIR_CTX")
files1=$(echo "$files1" | tail -1)

RESOLVED_CTX="$(cd "$TMPDIR_CTX" && pwd -P)"
files2=$(run_test "Test 2: resolved path (/private/var/folders)" "$RESOLVED_CTX")
files2=$(echo "$files2" | tail -1)

cp -a "$TMPDIR_CTX" "$LOCAL_CTX"
files3=$(run_test "Test 3: symlink-free path (local copy)" "$LOCAL_CTX")
files3=$(echo "$files3" | tail -1)

rm -rf "$(dirname "$TMPDIR_CTX")"

# --- Verdict ---
echo "=== Verdict ==="
if [[ "$files1" -eq 3 ]]; then
    echo "PASS: Bug may be fixed in this version"
elif [[ "$files1" -lt 3 && "$files3" -eq 3 ]]; then
    echo "CONFIRMED: container build drops nested files when path contains symlinks"
    echo ""
    echo "  /var/folders (symlink):   $files1/3 — BROKEN (nested files lost)"
    echo "  /private/var (resolved):  $files2/3 — WORSE (all files lost)"
    echo "  local copy (no symlinks): $files3/3 — OK"
    echo ""
    echo "  On macOS, /var and /tmp are symlinks to /private/var and /private/tmp."
    echo "  devcontainer CLI uses \$TMPDIR (/var/folders) for build context,"
    echo "  triggering this bug during every feature-enabled build."
    echo ""
    echo "  Workaround: copy build context to a symlink-free path before building."
else
    echo "UNEXPECTED: symlink=$files1, resolved=$files2, local=$files3"
fi
