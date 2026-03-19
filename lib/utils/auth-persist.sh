#!/usr/bin/env bash
# Auth persistence helpers
#
# Claude writes ~/.claude.json on the container's ephemeral root filesystem.
# The ~/.claude/ directory is a persistent named volume. These helpers copy
# auth files into the volume on stop/down and restore them on start/up.

# Save ~/.claude.json* from home directory into the persistent volume.
# Call before stopping or removing the container.
save_claude_auth() {
    local container_id="$1" container_cmd="$2" user="${3:-}"
    local script='
        for f in "$HOME"/.claude.json "$HOME"/.claude.json.backup.*; do
            [ -f "$f" ] && [ ! -L "$f" ] && cp "$f" "$HOME/.claude/$(basename "$f")"
        done
    '
    _exec_in_container "$container_id" "$container_cmd" "$script" "$user"
}

# Restore ~/.claude.json* from the persistent volume into home directory.
# Call after starting the container.
restore_claude_auth() {
    local container_id="$1" container_cmd="$2" user="${3:-}"
    local script='
        for f in "$HOME/.claude"/.claude.json "$HOME/.claude"/.claude.json.backup.*; do
            [ -f "$f" ] || continue
            cp "$f" "$HOME/$(basename "$f")"
        done
    '
    _exec_in_container "$container_id" "$container_cmd" "$script" "$user"
}

# Execute a shell snippet inside the container.
_exec_in_container() {
    local container_id="$1" container_cmd="$2" script="$3" user="${4:-}"
    local user_args=()
    [[ -n "$user" ]] && user_args=(-u "$user")
    case "$container_cmd" in
        docker|podman|nerdctl)
            $container_cmd exec ${user_args[@]+"${user_args[@]}"} "$container_id" sh -c "$script" 2>/dev/null || true ;;
        "lima nerdctl")
            lima nerdctl exec ${user_args[@]+"${user_args[@]}"} "$container_id" sh -c "$script" 2>/dev/null || true ;;
        container)
            container exec ${user_args[@]+"${user_args[@]}"} "$container_id" sh -c "$script" 2>/dev/null || true ;;
    esac
}
