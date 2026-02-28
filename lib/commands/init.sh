#!/usr/bin/env bash
# agentcontainer init command

cmd_init() {
    local features=""
    local agents=""
    local base_image=""
    local setup_script=""
    local default_shell=""
    local exec_agent=""
    local resources=""
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --image)
                base_image="$2"
                shift 2
                ;;
            --agent|--agents)
                agents="$2"
                shift 2
                ;;
            --features)
                features="$2"
                shift 2
                ;;
            --setup)
                setup_script="$2"
                shift 2
                ;;
            --shell)
                default_shell="$2"
                shift 2
                ;;
            --exec)
                exec_agent="$2"
                shift 2
                ;;
            --resources)
                resources="$2"
                shift 2
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -h|--help)
                show_init_help
                return 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_init_help
                return 1
                ;;
        esac
    done

    # Check if already initialized
    if [[ -d ".agentcontainer" && "$force" != "true" ]]; then
        log_error "Project already initialized. Use --force to overwrite."
        return 1
    fi

    log_info "Initializing agentcontainer..."

    # Detect project settings
    detect_project_settings

    # Apply CLI overrides
    [[ -n "$base_image" ]] && BASE_IMAGE="$base_image"
    [[ -n "$agents" ]] && AGENTS="$agents"
    [[ -n "$features" ]] && FEATURES="$features"
    [[ -n "$setup_script" ]] && SETUP_SCRIPT="$setup_script"
    [[ -n "$default_shell" ]] && DEFAULT_SHELL="$default_shell"
    [[ -n "$exec_agent" ]] && EXEC_AGENT="$exec_agent"

    # Parse resources (memory:cpu:pids format)
    if [[ -n "$resources" ]]; then
        IFS=':' read -r mem cpu pids <<< "$resources"
        [[ -n "$mem" ]] && MEMORY_LIMIT="$mem"
        [[ -n "$cpu" ]] && CPU_LIMIT="$cpu"
        [[ -n "$pids" ]] && PID_LIMIT="$pids"
    fi

    # Create directories
    mkdir -p .agentcontainer/.claude/plans
    mkdir -p .devcontainer

    # Generate project config (tracked)
    log_info "Generating agentcontainer.conf..."
    expand_template "$LIB_DIR/templates/agentcontainer.conf.tmpl" ".agentcontainer/agentcontainer.conf"

    # Generate local config (gitignored) - only if it doesn't exist
    if [[ ! -f ".agentcontainer/local.conf" ]]; then
        log_info "Generating local.conf..."
        expand_template "$LIB_DIR/templates/local.conf.tmpl" ".agentcontainer/local.conf"
    else
        log_info "Keeping existing local.conf"
    fi

    # Generate devcontainer.json with features and mounts
    log_info "Generating devcontainer.json..."
    generate_devcontainer_json

    # Generate setup script
    log_info "Generating setup.sh..."
    expand_template "$LIB_DIR/templates/setup.sh.tmpl" ".agentcontainer/setup.sh"
    chmod +x ".agentcontainer/setup.sh"

    # Generate Claude hook
    log_info "Generating SessionStart hook..."
    mkdir -p ".agentcontainer/.claude/hooks"
    cp "$LIB_DIR/templates/SessionStart.sh.tmpl" ".agentcontainer/.claude/hooks/SessionStart.sh"
    chmod +x ".agentcontainer/.claude/hooks/SessionStart.sh"

    # Create .gitignore for agentcontainer
    cat > .agentcontainer/.gitignore <<'EOF'
# Machine-specific config (resources, platform)
local.conf

# Claude local files
.claude/*.local.md
EOF

    log_ok "Initialization complete!"
    echo
    echo "Created:"
    echo "  .agentcontainer/"
    echo "    agentcontainer.conf    # Project config (commit this)"
    echo "    local.conf             # Machine config (gitignored)"
    echo "    setup.sh               # Container setup script"
    echo "    .claude/               # Claude Code configuration"
    echo "  .devcontainer/"
    echo "    devcontainer.json      # Container definition"
    echo
    echo "IMPORTANT: Verify 'remoteUser' in devcontainer.json matches your base image"
    echo "           (default: vscode, change to 'root' for root-based images)"
    echo
    echo "Next steps:"
    echo "  1. Review .agentcontainer/agentcontainer.conf"
    echo "  2. Adjust .agentcontainer/local.conf for your machine"
    echo "  3. Run: agentcontainer build"
    echo "  4. Run: agentcontainer up"
}

show_init_help() {
    cat <<EOF
Usage: agentcontainer init [options]

Initialize a new agentcontainer project.

Options:
    --image IMAGE       Base container image (default: devcontainers/base:ubuntu)
    --agent LIST        AI agents to install: claude-code, opencode
    --exec CMD          Command to run the agent (for 'agentcontainer' with no args)
    --features LIST     Devcontainer feature URIs
    --setup SCRIPT      Repo script to run for setup (e.g., ./scripts/dev-setup.sh)
    --shell PROFILE     Shell profile name for 'agentcontainer shell' (default: bash)
    --resources MEM:CPU:PIDS  Resource limits (default: 4g:2:500)
    -f, --force         Overwrite existing configuration
    -h, --help          Show this help

Shell Profiles:
    --shell selects a profile NAME, not a path. Built-in: bash, zsh, sh

    For custom shells, create .agentcontainer/shell-profiles.json:
    {
      "nix-data": { "path": "/nix/var/nix/profiles/default/bin/nix-shell", "args": ["data.nix"] }
    }

    Then: agentcontainer init --shell nix-data

Examples:
    agentcontainer init --agent claude-code --exec claude
    agentcontainer init --exec "nix-shell --run 'claude {}'"
    agentcontainer init --resources 8g:4:1000
    agentcontainer init --setup ./scripts/dev-setup.sh
    agentcontainer init --features "ghcr.io/devcontainers/features/python:1"
EOF
}

# Auto-detect project settings from existing files
detect_project_settings() {
    # Load existing configs first (preserves customizations on --force)
    # shellcheck source=/dev/null
    [[ -f ".agentcontainer/agentcontainer.conf" ]] && source ".agentcontainer/agentcontainer.conf"
    # shellcheck source=/dev/null
    [[ -f ".agentcontainer/local.conf" ]] && source ".agentcontainer/local.conf"

    # Set defaults for anything still unset
    : "${PROJECT_NAME:=$(basename "$(pwd)")}"
    : "${WORKSPACE_FOLDER:=/workspaces/$PROJECT_NAME}"
    : "${BASE_IMAGE:=mcr.microsoft.com/devcontainers/base:ubuntu}"
    : "${MEMORY_LIMIT:=4g}"
    : "${CPU_LIMIT:=2}"
    : "${PID_LIMIT:=500}"
    : "${MACOS_RUNTIME:=auto}"
    : "${CONTAINER_RUNTIME:=}"
    : "${CUSTOM_SETUP_CMD:=}"

    : "${AGENTS:=}"
    : "${FEATURES:=}"
    : "${SETUP_SCRIPT:=}"
    : "${DEFAULT_SHELL:=bash}"
    : "${EXEC_AGENT:=}"

    # Export all variables
    export PROJECT_NAME WORKSPACE_FOLDER BASE_IMAGE AGENTS FEATURES SETUP_SCRIPT DEFAULT_SHELL EXEC_AGENT
    export MEMORY_LIMIT CPU_LIMIT PID_LIMIT MACOS_RUNTIME CONTAINER_RUNTIME
}

# Generate devcontainer.json with computed features and mounts
generate_devcontainer_json() {
    local features_json mounts_json shell_profiles_json

    # Set remote user (template default)
    # Users should verify this matches their base image
    REMOTE_USER="${REMOTE_USER:-vscode}"

    # Derive container home directory from remote user
    if [[ "$REMOTE_USER" == "root" ]]; then
        CONTAINER_HOME="/root"
    else
        CONTAINER_HOME="/home/$REMOTE_USER"
    fi
    export REMOTE_USER CONTAINER_HOME

    features_json="$(build_features_json "        ")"
    mounts_json="$(build_mounts_json "        ")"
    shell_profiles_json="$(build_shell_profiles_json)"

    export FEATURES_JSON="$features_json"
    export MOUNTS_JSON="$mounts_json"
    export SHELL_PROFILES_JSON="$shell_profiles_json"

    expand_template "$LIB_DIR/templates/devcontainer.json.tmpl" ".devcontainer/devcontainer.json"
}
