#!/usr/bin/env bash
# Platform and container runtime detection

detect_platform() {
    case "$(uname -s)" in
        Darwin) echo "darwin" ;;
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

detect_runtime() {
    local platform="${1:-$(detect_platform)}"

    # Allow override via config
    if [[ -n "${CONTAINER_RUNTIME:-}" ]]; then
        echo "$CONTAINER_RUNTIME"
        return
    fi

    # macOS-specific override
    if [[ "$platform" == "darwin" && -n "${MACOS_RUNTIME:-}" && "${MACOS_RUNTIME}" != "auto" ]]; then
        echo "$MACOS_RUNTIME"
        return
    fi

    case "$platform" in
        darwin)
            if command -v container &>/dev/null; then
                echo "apple-container"
            elif command -v lima &>/dev/null && lima nerdctl version &>/dev/null 2>&1; then
                echo "lima"
            elif command -v docker &>/dev/null; then
                echo "docker"
            else
                echo "none"
            fi
            ;;
        linux|wsl)
            if command -v nerdctl &>/dev/null; then
                echo "nerdctl"
            elif command -v podman &>/dev/null; then
                echo "podman"
            elif command -v ctr &>/dev/null; then
                echo "containerd"
            elif command -v docker &>/dev/null; then
                echo "docker"
            else
                echo "none"
            fi
            ;;
        *)
            echo "none"
            ;;
    esac
}

# Get the container command for the detected runtime
get_container_cmd() {
    local runtime="${1:-$(detect_runtime)}"

    case "$runtime" in
        apple-container) echo "container" ;;
        lima)            echo "lima nerdctl" ;;
        nerdctl)         echo "nerdctl" ;;
        podman)          echo "podman" ;;
        containerd)      echo "ctr" ;;
        docker)          echo "docker" ;;
        *)               echo "" ;;
    esac
}

# Get the docker socket path for devcontainer CLI
get_docker_socket() {
    local runtime="${1:-$(detect_runtime)}"
    local platform="${2:-$(detect_platform)}"

    case "$runtime" in
        docker)
            if [[ "$platform" == "darwin" ]]; then
                echo "$HOME/.docker/run/docker.sock"
            else
                echo "/var/run/docker.sock"
            fi
            ;;
        podman)
            echo "/run/user/$(id -u)/podman/podman.sock"
            ;;
        lima)
            echo "$HOME/.lima/default/sock/nerdctl.sock"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Check if runtime is available and working
check_runtime() {
    local runtime="${1:-$(detect_runtime)}"
    local cmd
    cmd="$(get_container_cmd "$runtime")"

    if [[ -z "$cmd" ]]; then
        return 1
    fi

    case "$runtime" in
        apple-container)
            $cmd --version &>/dev/null
            ;;
        lima)
            lima nerdctl version &>/dev/null
            ;;
        containerd)
            $cmd version &>/dev/null
            ;;
        *)
            $cmd version &>/dev/null
            ;;
    esac
}

# Print runtime info for debugging
print_runtime_info() {
    local platform runtime cmd
    platform="$(detect_platform)"
    runtime="$(detect_runtime "$platform")"
    cmd="$(get_container_cmd "$runtime")"

    echo "Platform: $platform"
    echo "Runtime: $runtime"
    echo "Command: $cmd"

    if check_runtime "$runtime"; then
        echo "Status: available"
    else
        echo "Status: not available"
    fi
}
