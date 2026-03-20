#!/usr/bin/env bash
# shellcheck disable=SC2016  # ${localWorkspaceFolder} is a devcontainer variable, not a shell expansion
# Template expansion utilities

# Expand template using envsubst
expand_template() {
    local template_file="$1"
    local output_file="$2"

    if [[ ! -f "$template_file" ]]; then
        echo "Error: Template file not found: $template_file" >&2
        return 1
    fi

    # Create output directory if needed
    mkdir -p "$(dirname "$output_file")"

    # Use envsubst with explicit variable list to avoid expanding shell variables like $HOME
    # Only expand variables actually used in templates
    local vars='${PROJECT_NAME} ${WORKSPACE_FOLDER} ${BASE_IMAGE}'
    vars+=' ${AGENTS} ${FEATURES} ${SETUP_SCRIPT} ${DEFAULT_SHELL} ${EXEC_AGENT}'
    vars+=' ${MEMORY_LIMIT} ${CPU_LIMIT} ${PID_LIMIT}'
    vars+=' ${MACOS_RUNTIME} ${CONTAINER_RUNTIME}'
    vars+=' ${EXTRA_MOUNTS}'
    vars+=' ${FEATURES_JSON} ${MOUNTS_JSON} ${SHELL_PROFILES_JSON}'

    envsubst "$vars" < "$template_file" > "$output_file"
}

# Build features JSON for devcontainer.json
build_features_json() {
    local output=""
    local indent="${1:-    }"

    # AI agents (shorthand names)
    for agent in ${AGENTS:-}; do
        case "$agent" in
            claude-code)
                output+="${indent}\"ghcr.io/anthropics/devcontainer-features/claude-code:1\": {},"$'\n'
                # Claude Code requires Node.js >= 20 (uses ES2023 Array.prototype.with)
                output+="${indent}\"ghcr.io/devcontainers/features/node:1\": { \"version\": \"20\" },"$'\n'
                ;;
            opencode)
                output+="${indent}\"ghcr.io/devcontainer-community/devcontainer-features/opencode.ai:1\": {},"$'\n'
                ;;
            *)
                log_warn "Unknown agent: $agent"
                ;;
        esac
    done

    # Devcontainer features (full URIs)
    for feature in ${FEATURES:-}; do
        if [[ "$feature" == ghcr.io/* || "$feature" == docker.io/* ]]; then
            output+="${indent}\"$feature\": {},"$'\n'
        fi
    done

    # Remove trailing comma and newline
    output="${output%,$'\n'}"

    echo "$output"
}

# Build mounts JSON for devcontainer.json
build_mounts_json() {
    local mounts=""
    local indent="${1:-    }"

    # Workspace mount
    mounts+="${indent}\"type=bind,source=\${localWorkspaceFolder},target=${WORKSPACE_FOLDER}\","$'\n'

    # Project Claude config at workspace root (hooks, plans, CLAUDE.md)
    mounts+="${indent}\"type=bind,source=\${localWorkspaceFolder}/.agentcontainer/.claude,target=${WORKSPACE_FOLDER}/.claude\","$'\n'

    # Git worktree overlay — keeps .claude/worktrees/ at the same depth
    # on host and in container so relative gitdir paths work in both
    mounts+="${indent}\"type=bind,source=\${localWorkspaceFolder}/.claude/worktrees,target=${WORKSPACE_FOLDER}/.claude/worktrees\","$'\n'

    # Claude auth volume at $HOME/.claude (persistent across up/down cycles)
    # Uses named volume: ${PROJECT_NAME}-claude-home
    mounts+="${indent}\"type=volume,source=${PROJECT_NAME}-claude-home,target=${CONTAINER_HOME}/.claude\""

    # Nix store volume (persistent across up/down cycles)
    # Without this, every container restart re-fetches and rebuilds all Nix packages
    if [[ " ${FEATURES:-} " == *" ghcr.io/devcontainers/features/nix:"* ]]; then
        mounts+=","$'\n'
        mounts+="${indent}\"type=volume,source=${PROJECT_NAME}-nix-store,target=/nix\""
    fi

    # Extra mounts from EXTRA_MOUNTS (newline-separated mount strings)
    # Each entry is a full devcontainer mount string, e.g.:
    #   "type=bind,source=/host/path,target=/container/path,readonly"
    if [[ -n "${EXTRA_MOUNTS:-}" ]]; then
        while IFS= read -r mount_entry; do
            mount_entry="$(echo "$mount_entry" | xargs)"  # trim whitespace
            [[ -z "$mount_entry" || "$mount_entry" == \#* ]] && continue
            mounts+=","$'\n'
            mounts+="${indent}\"${mount_entry}\""
        done <<< "$EXTRA_MOUNTS"
    fi

    echo "$mounts"
}

# Build shell profiles JSON from .agentcontainer/shell-profiles.json
build_shell_profiles_json() {
    local profiles_file=".agentcontainer/shell-profiles.json"

    if [[ ! -f "$profiles_file" ]]; then
        echo ""
        return
    fi

    # Validate JSON
    if ! jq empty "$profiles_file" 2>/dev/null; then
        log_warn "Invalid JSON in $profiles_file, skipping"
        echo ""
        return
    fi

    # Convert to terminal.integrated.profiles.linux format
    # Input:  { "zsh-login": { "path": "/bin/zsh", "args": ["-l"] } }
    # Output: ,"terminal.integrated.profiles.linux": { ... }
    local profiles
    profiles=$(jq -c '.' "$profiles_file" 2>/dev/null)

    if [[ -n "$profiles" && "$profiles" != "{}" ]]; then
        echo ","
        echo "                \"terminal.integrated.profiles.linux\": $profiles"
    fi
}

# Build resource limits for container
build_resource_args() {
    local args=""

    if [[ -n "${MEMORY_LIMIT:-}" ]]; then
        args+="--memory=$MEMORY_LIMIT "
    fi

    if [[ -n "${CPU_LIMIT:-}" ]]; then
        args+="--cpus=$CPU_LIMIT "
    fi

    if [[ -n "${PID_LIMIT:-}" ]]; then
        args+="--pids-limit=$PID_LIMIT "
    fi

    echo "$args"
}

