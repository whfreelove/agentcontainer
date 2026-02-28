#!/usr/bin/env bash
# agentcontainer shell command

cmd_shell() {
    local user=""
    local shell_profile=""
    local -a shell_cmd=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --shell)
                shell_profile="$2"
                shift 2
                ;;
            --exec)
                shell_cmd=("$2")
                shift 2
                ;;
            --user|-u)
                user="$2"
                shift 2
                ;;
            --root)
                user="root"
                shift
                ;;
            -h|--help)
                show_shell_help
                return 0
                ;;
            *)
                # Treat remaining args as command to run
                shell_cmd=("$@")
                break
                ;;
        esac
    done

    # Verify initialization
    if [[ ! -f ".agentcontainer/agentcontainer.conf" ]]; then
        log_error "Project not initialized. Run 'agentcontainer init' first."
        return 1
    fi

    # Load config
    load_config

    # If no --exec given, resolve shell from profile
    if [[ ${#shell_cmd[@]} -eq 0 ]]; then
        local profile_name="${shell_profile:-$DEFAULT_SHELL}"
        local shell_profiles=".agentcontainer/shell-profiles.json"
        local shell_path="" shell_args=""

        # Look up profile in shell-profiles.json
        if [[ -f "$shell_profiles" ]]; then
            shell_path=$(jq -r --arg name "$profile_name" '.[$name].path // empty' "$shell_profiles" 2>/dev/null)
            shell_args=$(jq -r --arg name "$profile_name" '.[$name].args // [] | join(" ")' "$shell_profiles" 2>/dev/null)
        fi

        # If no profile found, use profile name as shell (built-in: bash, zsh, sh)
        if [[ -z "$shell_path" ]]; then
            shell_path="$profile_name"
        fi

        # Build shell command with args
        shell_cmd=("$shell_path")
        if [[ -n "$shell_args" ]]; then
            read -ra args_array <<< "$shell_args"
            shell_cmd+=("${args_array[@]}")
        fi
    fi

    # Get remoteUser from devcontainer.json (default user for VSCode-like experience)
    if [[ -z "$user" && -f ".devcontainer/devcontainer.json" ]]; then
        user=$(jq -r '.remoteUser // empty' .devcontainer/devcontainer.json 2>/dev/null)
    fi

    # Detect runtime
    local detected_runtime container_cmd
    detected_runtime="$(detect_runtime)"
    container_cmd="$(get_container_cmd "$detected_runtime")"

    if [[ -z "$container_cmd" ]]; then
        log_error "No container runtime found."
        return 1
    fi

    # Find the running container
    local container_id
    container_id="$(find_project_container "$PROJECT_NAME" "$container_cmd")"

    if [[ -z "$container_id" ]]; then
        log_error "No running container found for project: $PROJECT_NAME"
        echo "Run 'agentcontainer start' first."
        return 1
    fi

    log_info "Connecting to container..."

    # Build exec arguments
    local exec_args=()

    # Use -i if stdin is a TTY, -t if stdout is a TTY
    [[ -t 0 ]] && exec_args+=(-i)
    [[ -t 1 ]] && exec_args+=(-t)

    # User override
    if [[ -n "$user" ]]; then
        exec_args+=(--user "$user")
    fi

    # Working directory
    exec_args+=(-w "$WORKSPACE_FOLDER")

    # Execute shell
    case "$container_cmd" in
        docker|podman|nerdctl)
            exec $container_cmd exec "${exec_args[@]}" "$container_id" "${shell_cmd[@]}"
            ;;
        "lima nerdctl")
            exec lima nerdctl exec "${exec_args[@]}" "$container_id" "${shell_cmd[@]}"
            ;;
        container)
            exec container exec "${exec_args[@]}" "$container_id" "${shell_cmd[@]}"
            ;;
        *)
            log_error "Don't know how to exec with: $container_cmd"
            return 1
            ;;
    esac
}

show_shell_help() {
    cat <<EOF
Usage: agentcontainer shell [options] [command]

Get a shell in the running container, or run a command.

Options:
    --shell PROFILE Select shell profile (default: DEFAULT_SHELL from config)
    --exec PATH     Run specific executable (bypasses profile lookup)
    -u, --user USER Run as specific user (default: remoteUser)
    --root          Run as root
    -h, --help      Show this help

Profiles:
    Built-in: bash, zsh, sh (profile name = executable)
    Custom:   Define in .agentcontainer/shell-profiles.json

Examples:
    agentcontainer shell                    # Use DEFAULT_SHELL profile
    agentcontainer shell --shell nix-data   # Use specific profile
    agentcontainer shell --exec /bin/zsh    # Run executable directly
    agentcontainer shell ls -la             # Run a command
EOF
}

# Find the container for this project
find_project_container() {
    local project="$1"
    local cmd="$2"

    # devcontainer creates containers with names like:
    # vsc-projectname-hash or projectname_devcontainer-1
    local patterns=(
        "vsc-${project}-"
        "${project}_devcontainer"
        "agentcontainer-${project}"
    )

    for pattern in "${patterns[@]}"; do
        local container_id
        case "$cmd" in
            docker|podman|nerdctl)
                container_id=$($cmd ps --format '{{.ID}} {{.Names}}' 2>/dev/null | grep "$pattern" | head -1 | awk '{print $1}')
                ;;
            "lima nerdctl")
                container_id=$(lima nerdctl ps --format '{{.ID}} {{.Names}}' 2>/dev/null | grep "$pattern" | head -1 | awk '{print $1}')
                ;;
            container)
                container_id=$(container list 2>/dev/null | grep "$pattern" | head -1 | awk '{print $1}')
                ;;
        esac

        if [[ -n "$container_id" ]]; then
            echo "$container_id"
            return 0
        fi
    done

    return 1
}
