#!/usr/bin/env bash
# agentcontainer stop command

cmd_stop() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_stop_help
                return 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_stop_help
                return 1
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
    container_id="$(find_project_container "$PROJECT_NAME" "$container_cmd")" || true

    if [[ -z "$container_id" ]]; then
        log_warn "No running container found for project: $PROJECT_NAME"
        return 0
    fi

    log_info "Stopping container..."

    case "$container_cmd" in
        docker|podman|nerdctl)
            $container_cmd stop "$container_id"
            ;;
        "lima nerdctl")
            lima nerdctl stop "$container_id"
            ;;
        container)
            container stop "$container_id"
            ;;
        *)
            log_error "Don't know how to stop with: $container_cmd"
            return 1
            ;;
    esac

    log_ok "Container stopped"
}

show_stop_help() {
    cat <<EOF
Usage: agentcontainer stop [options]

Stop the running container.

Options:
    -h, --help      Show this help

Examples:
    agentcontainer stop
EOF
}

# Find the container for this project (reuse from shell.sh if not already defined)
if ! declare -f find_project_container &>/dev/null; then
find_project_container() {
    local project="$1"
    local cmd="$2"

    local patterns=(
        "agentcontainer-${project}"
        "vsc-${project}-"
        "${project}_devcontainer"
    )

    for pattern in "${patterns[@]}"; do
        local container_id
        case "$cmd" in
            docker|podman|nerdctl)
                container_id=$($cmd ps --format '{{.ID}} {{.Names}}' 2>/dev/null | grep "$pattern" | head -1 | awk '{print $1}' || true)
                ;;
            "lima nerdctl")
                container_id=$(lima nerdctl ps --format '{{.ID}} {{.Names}}' 2>/dev/null | grep "$pattern" | head -1 | awk '{print $1}' || true)
                ;;
            container)
                container_id=$(container list 2>/dev/null | grep "$pattern" | head -1 | awk '{print $1}' || true)
                ;;
        esac

        if [[ -n "$container_id" ]]; then
            echo "$container_id"
            return 0
        fi
    done

    # Fallback: find by devcontainer label
    local label_id
    case "$cmd" in
        docker|podman|nerdctl)
            label_id=$($cmd ps --filter "label=devcontainer.local_folder=$(pwd)" --format '{{.ID}}' 2>/dev/null | head -1 || true)
            ;;
        "lima nerdctl")
            label_id=$(lima nerdctl ps --filter "label=devcontainer.local_folder=$(pwd)" --format '{{.ID}}' 2>/dev/null | head -1 || true)
            ;;
    esac

    if [[ -n "$label_id" ]]; then
        echo "$label_id"
        return 0
    fi

    return 1
}
fi
