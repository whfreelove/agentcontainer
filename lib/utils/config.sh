#!/usr/bin/env bash
# shellcheck disable=SC1090  # dynamic config paths resolved at runtime
# Configuration loading and defaults

# Config file locations
AGENTCONTAINER_CONFIG=".agentcontainer/agentcontainer.conf"
AGENTCONTAINER_LOCAL_CONFIG=".agentcontainer/local.conf"

load_config() {
    local config_file="${1:-$AGENTCONTAINER_CONFIG}"

    # Load project config
    if [[ -f "$config_file" ]]; then
        # shellcheck source=/dev/null
        source "$config_file"
    fi

    # Load local/machine config (overrides project config)
    if [[ -f "$AGENTCONTAINER_LOCAL_CONFIG" ]]; then
        # shellcheck source=/dev/null
        source "$AGENTCONTAINER_LOCAL_CONFIG"
    fi

    # Set defaults for unset variables
    : "${PROJECT_NAME:=$(basename "$(pwd)")}"
    : "${WORKSPACE_FOLDER:=/workspaces/$PROJECT_NAME}"
    : "${BASE_IMAGE:=mcr.microsoft.com/devcontainers/base:ubuntu}"
    : "${MEMORY_LIMIT:=4g}"
    : "${CPU_LIMIT:=2}"
    : "${PID_LIMIT:=500}"
    : "${AGENTS:=}"
    : "${FEATURES:=}"
    : "${SETUP_SCRIPT:=}"
    : "${DEFAULT_SHELL:=bash}"
    : "${EXEC_AGENT:=}"
    : "${MACOS_RUNTIME:=auto}"
    : "${CONTAINER_RUNTIME:=}"

    # Export for subprocesses
    export PROJECT_NAME WORKSPACE_FOLDER BASE_IMAGE MEMORY_LIMIT CPU_LIMIT PID_LIMIT
    export AGENTS FEATURES SETUP_SCRIPT DEFAULT_SHELL EXEC_AGENT MACOS_RUNTIME CONTAINER_RUNTIME
}

# Validate required config
validate_config() {
    local errors=()

    if [[ -z "$PROJECT_NAME" ]]; then
        errors+=("PROJECT_NAME is required")
    fi

    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "Configuration errors:" >&2
        for err in "${errors[@]}"; do
            echo "  - $err" >&2
        done
        return 1
    fi

    return 0
}

# Print current config for debugging
print_config() {
    echo "=== Project Config (agentcontainer.conf) ==="
    echo "PROJECT_NAME=$PROJECT_NAME"
    echo "WORKSPACE_FOLDER=$WORKSPACE_FOLDER"
    echo "BASE_IMAGE=$BASE_IMAGE"
    echo "AGENTS=${AGENTS:-<none>}"
    echo "FEATURES=${FEATURES:-<none>}"
    echo "SETUP_SCRIPT=${SETUP_SCRIPT:-<none>}"
    echo "DEFAULT_SHELL=$DEFAULT_SHELL"
    echo "EXEC_AGENT=${EXEC_AGENT:-<none>}"
    echo
    echo "=== Local Config (local.conf) ==="
    echo "MEMORY_LIMIT=$MEMORY_LIMIT"
    echo "CPU_LIMIT=$CPU_LIMIT"
    echo "PID_LIMIT=$PID_LIMIT"
    echo "MACOS_RUNTIME=$MACOS_RUNTIME"
    echo "CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-<auto>}"
    echo "========================================"
}

# Get config value with default
get_config() {
    local key="$1"
    local default="${2:-}"
    local value

    value="${!key:-$default}"
    echo "$value"
}
