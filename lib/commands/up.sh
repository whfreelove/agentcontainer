#!/usr/bin/env bash
# agentcontainer up command

cmd_up() {
    local rebuild=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --rebuild)
                rebuild=true
                shift
                ;;
            -h|--help)
                show_up_help
                return 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_up_help
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
    local detected_platform detected_runtime container_cmd
    detected_platform="$(detect_platform)"
    detected_runtime="$(detect_runtime "$detected_platform")"
    container_cmd="$(get_container_cmd "$detected_runtime")"

    if [[ -z "$container_cmd" ]]; then
        log_error "No container runtime found."
        return 1
    fi

    log_info "Starting container..."
    log_info "  Project: $PROJECT_NAME"
    log_info "  Workspace: $WORKSPACE_FOLDER"
    log_info "  Runtime: $detected_runtime"

    # Check if container already exists
    local container_name="agentcontainer-${PROJECT_NAME}"

    if container_exists "$container_name" "$container_cmd"; then
        if container_running "$container_name" "$container_cmd"; then
            log_ok "Container already running: $container_name"
            return 0
        else
            log_info "Starting existing container..."
            start_existing_container "$container_name" "$container_cmd"
            return $?
        fi
    fi

    # Rebuild if requested
    if [[ "$rebuild" == "true" ]]; then
        log_info "Rebuilding container..."
        source "$LIB_DIR/commands/build.sh"
        cmd_build
    fi

    # Check if image has been built
    if ! image_exists "$detected_runtime"; then
        log_error "No container image found. Run 'agentcontainer build' first."
        return 1
    fi

    # Apple Container uses native `container` CLI directly
    if [[ "$detected_runtime" == "apple-container" ]]; then
        start_apple_container "$container_name"
        return $?
    fi

    # Other runtimes use devcontainer up
    local up_args=()
    up_args+=(--workspace-folder "$(pwd)")

    # Set docker path based on runtime
    case "$detected_runtime" in
        docker)
            up_args+=(--docker-path docker)
            ;;
        podman)
            up_args+=(--docker-path podman)
            ;;
        lima)
            up_args+=(--docker-path nerdctl.lima)
            ;;
        nerdctl)
            up_args+=(--docker-path nerdctl)
            ;;
    esac

    # Run devcontainer up
    log_info "Running: devcontainer up ${up_args[*]}"

    if devcontainer up "${up_args[@]}"; then
        log_ok "Container started!"
        echo
        echo "To connect:"
        echo "  agentcontainer shell"
        echo
        echo "To stop:"
        echo "  $detected_runtime stop <container>"
    else
        log_error "Failed to start container"
        return 1
    fi
}

# Start container using Apple Container runtime directly
start_apple_container() {
    local container_name="$1"
    local devcontainer_json=".devcontainer/devcontainer.json"

    # Find the image (built by devcontainer build, transferred to Apple Container)
    local image_name
    image_name=$(container image list 2>/dev/null | grep "vsc-${PROJECT_NAME}" | awk '{print $1}' | head -1)

    log_info "Using image: $image_name"

    # Remove existing container if present
    container rm -f "$container_name" 2>/dev/null || true

    # Parse mounts from devcontainer.json
    local mount_args=()
    if [[ -f "$devcontainer_json" ]]; then
        # shellcheck disable=SC2207
        mount_args=($(parse_devcontainer_mounts "$devcontainer_json"))
    else
        # Fallback if no devcontainer.json
        mount_args+=(-v "$(pwd):${WORKSPACE_FOLDER}")
    fi

    # Parse resource limits from runArgs in devcontainer.json
    # Note: Apple Container only supports --memory and --cpus, not --pids-limit
    local resource_args=()
    if [[ -f "$devcontainer_json" ]]; then
        local memory cpus
        memory=$(jq -r '.runArgs[]? | select(startswith("--memory="))' "$devcontainer_json" 2>/dev/null | head -1)
        cpus=$(jq -r '.runArgs[]? | select(startswith("--cpus="))' "$devcontainer_json" 2>/dev/null | head -1)

        # Apple Container 0.10+ enforces a minimum memory of 200 MiB
        if [[ -n "$memory" ]]; then
            local mem_value="${memory#--memory=}"
            if ! validate_apple_container_memory "$mem_value"; then
                log_error "Memory limit '$mem_value' is below Apple Container's minimum of 200m (200 MiB)."
                log_error "Increase MEMORY_LIMIT in .agentcontainer/local.conf (e.g. MEMORY_LIMIT=512m)"
                return 1
            fi
            resource_args+=("$memory")
        fi
        [[ -n "$cpus" ]] && resource_args+=("$cpus")
    fi

    # Create and start container (as container's default user)
    log_info "Creating container: $container_name"
    if container run -d --name "$container_name" \
        -w "$WORKSPACE_FOLDER" \
        ${mount_args[@]+"${mount_args[@]}"} \
        ${resource_args[@]+"${resource_args[@]}"} \
        "$image_name" sleep infinity; then

        sleep 1

        # Get remoteUser from devcontainer.json
        local remote_user update_uid
        remote_user=$(jq -r '.remoteUser // empty' "$devcontainer_json" 2>/dev/null)
        update_uid=$(jq -r '.updateRemoteUserUID // true' "$devcontainer_json" 2>/dev/null)

        # Update remoteUser's UID/GID to match host (like devcontainer does)
        # This preserves sudo access while fixing bind mount permissions
        if [[ "$update_uid" == "true" && -n "$remote_user" && "$remote_user" != "root" ]]; then
            local host_uid host_gid
            host_uid=$(id -u)
            host_gid=$(id -g)
            log_info "Updating $remote_user UID/GID to $host_uid:$host_gid..."
            container exec "$container_name" sh -c "
                # Update group GID
                if command -v groupmod >/dev/null 2>&1; then
                    groupmod -g $host_gid $remote_user 2>/dev/null || true
                fi
                # Update user UID and primary GID
                if command -v usermod >/dev/null 2>&1; then
                    usermod -u $host_uid -g $host_gid $remote_user 2>/dev/null || true
                fi
                # Fix ownership of home directory
                chown -R $host_uid:$host_gid /home/$remote_user 2>/dev/null || true
            " || log_warn "Could not update UID/GID"
        fi

        # Run devcontainer feature entrypoints (e.g., nix-daemon, docker-in-docker)
        # Run as remoteUser who has passwordless sudo configured
        log_info "Initializing features..."
        local exec_user_args=()
        [[ -n "$remote_user" ]] && exec_user_args+=(-u "$remote_user")
        container exec ${exec_user_args[@]+"${exec_user_args[@]}"} "$container_name" sh -c '
            for entrypoint in /usr/local/share/*-entrypoint.sh; do
                if [ -x "$entrypoint" ]; then
                    echo "Running $entrypoint..."
                    "$entrypoint" true || true
                fi
            done
        ' || true

        # Run postCreateCommand from devcontainer.json
        local post_create_cmd
        post_create_cmd=$(jq -r '.postCreateCommand // empty' "$devcontainer_json" 2>/dev/null)
        if [[ -n "$post_create_cmd" ]]; then
            log_info "Running setup..."
            container exec ${exec_user_args[@]+"${exec_user_args[@]}"} "$container_name" sh -c "$post_create_cmd" || true
        fi

        log_ok "Container started!"
        echo
        echo "To connect:"
        echo "  agentcontainer shell"
        echo
        echo "To stop:"
        echo "  container stop $container_name"
    else
        log_error "Failed to create container"
        return 1
    fi
}

# Parse mounts from devcontainer.json and convert to container CLI format
parse_devcontainer_mounts() {
    local devcontainer_json="$1"
    local local_workspace
    local_workspace="$(pwd)"
    local container_workspace="$WORKSPACE_FOLDER"

    # Read mounts array from devcontainer.json
    jq -r '.mounts[]?' "$devcontainer_json" 2>/dev/null | while read -r mount; do
        [[ -z "$mount" ]] && continue

        # Substitute devcontainer variables
        mount="${mount//\$\{localWorkspaceFolder\}/$local_workspace}"
        mount="${mount//\$\{containerWorkspaceFolder\}/$container_workspace}"

        # Parse mount string (format: type=bind|volume,source=...,target=...,readonly)
        local mount_type="bind" source="" target="" readonly=""

        # Extract fields from comma-separated key=value pairs
        IFS=',' read -ra parts <<< "$mount"
        for part in "${parts[@]}"; do
            case "$part" in
                type=volume) mount_type="volume" ;;
                type=bind)   mount_type="bind" ;;
                source=*)    source="${part#source=}" ;;
                target=*)    target="${part#target=}" ;;
                readonly)    readonly=":ro" ;;
            esac
        done

        # Output as -v argument
        if [[ "$mount_type" == "volume" && -n "$source" && -n "$target" ]]; then
            # Ensure volume exists for Apple Container
            container volume create "$source" 2>/dev/null || true
            echo "-v"
            echo "${source}:${target}"
        elif [[ -n "$source" && -n "$target" ]]; then
            # Bind mount
            echo "-v"
            echo "${source}:${target}${readonly}"
        fi
    done
}

# Validate memory value meets Apple Container 0.10+ minimum (200 MiB)
# Accepts values like "200m", "1g", "4G", "512M", "1024" (bytes)
# Note: fractional values (e.g. "0.5g") pass through unvalidated to Apple Container
validate_apple_container_memory() {
    local mem_str="$1"
    local value suffix mib

    # Extract numeric part and suffix
    if [[ "$mem_str" =~ ^([0-9]+)([kKmMgGtTpP])?[bB]?$ ]]; then
        value="${BASH_REMATCH[1]}"
        suffix="$(printf '%s' "${BASH_REMATCH[2]}" | tr '[:upper:]' '[:lower:]')"
    else
        # Can't parse — let Apple Container validate it
        return 0
    fi

    # Convert to MiB
    case "$suffix" in
        k) mib=$(( value / 1024 )) ;;
        m) mib=$value ;;
        g) mib=$(( value * 1024 )) ;;
        t) mib=$(( value * 1024 * 1024 )) ;;
        p) mib=$(( value * 1024 * 1024 * 1024 )) ;;
        *) mib=$(( value / 1048576 )) ;;  # raw bytes
    esac

    [[ $mib -ge 200 ]]
}

show_up_help() {
    cat <<EOF
Usage: agentcontainer up [options]

Start the container.

Options:
    --rebuild       Rebuild container before starting
    -h, --help      Show this help

Examples:
    agentcontainer up
    agentcontainer up --rebuild
EOF
}

# Check if container exists
container_exists() {
    local name="$1"
    local cmd="$2"

    case "$cmd" in
        docker|podman|nerdctl)
            $cmd ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${name}$"
            ;;
        "lima nerdctl")
            lima nerdctl ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${name}$"
            ;;
        container)
            container list --all 2>/dev/null | grep -q "$name"
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if container is running
container_running() {
    local name="$1"
    local cmd="$2"

    case "$cmd" in
        docker|podman|nerdctl)
            $cmd ps --format '{{.Names}}' 2>/dev/null | grep -q "^${name}$"
            ;;
        "lima nerdctl")
            lima nerdctl ps --format '{{.Names}}' 2>/dev/null | grep -q "^${name}$"
            ;;
        container)
            container list 2>/dev/null | grep -q "$name"
            ;;
        *)
            return 1
            ;;
    esac
}

# Start existing stopped container
start_existing_container() {
    local name="$1"
    local cmd="$2"

    case "$cmd" in
        docker|podman|nerdctl)
            $cmd start "$name"
            ;;
        "lima nerdctl")
            lima nerdctl start "$name"
            ;;
        container)
            container start "$name"
            ;;
        *)
            log_error "Don't know how to start container with: $cmd"
            return 1
            ;;
    esac
}

# Check if container image exists for project
image_exists() {
    local runtime="$1"

    case "$runtime" in
        apple-container)
            container image list 2>/dev/null | grep -q "vsc-${PROJECT_NAME}"
            ;;
        docker|podman|nerdctl)
            $runtime images 2>/dev/null | grep -q "vsc-${PROJECT_NAME}"
            ;;
        lima)
            lima nerdctl images 2>/dev/null | grep -q "vsc-${PROJECT_NAME}"
            ;;
        *)
            # For unknown runtimes, assume image exists and let devcontainer handle it
            return 0
            ;;
    esac
}
