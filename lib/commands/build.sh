#!/usr/bin/env bash
# agentcontainer build command

# Find a docker-compatible runtime for building images
# (used when apple-container is detected, since devcontainer CLI needs docker-compatible CLI)
find_build_runtime() {
    local platform="$1"

    if command -v lima &>/dev/null && lima nerdctl version &>/dev/null 2>&1; then
        echo "lima"
    elif command -v docker &>/dev/null; then
        echo "docker"
    elif command -v nerdctl &>/dev/null; then
        echo "nerdctl"
    elif command -v podman &>/dev/null; then
        echo "podman"
    else
        echo ""
    fi
}

cmd_build() {
    local no_cache=false
    local platform=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-cache)
                no_cache=true
                shift
                ;;
            --platform)
                platform="$2"
                shift 2
                ;;
            -h|--help)
                show_build_help
                return 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_build_help
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

    # Detect platform and runtime
    local detected_platform detected_runtime container_cmd build_runtime
    detected_platform="${platform:-$(detect_platform)}"
    detected_runtime="$(detect_runtime "$detected_platform")"
    container_cmd="$(get_container_cmd "$detected_runtime")"

    if [[ -z "$container_cmd" ]]; then
        log_error "No container runtime found. Please install Docker, Podman, or nerdctl."
        return 1
    fi

    # For apple-container, prefer native build via shim (no image transfer needed).
    # Falls back to Docker/Lima build + transfer if builder unavailable or AC_BUILD_USE_SHIM=0.
    build_runtime="$detected_runtime"
    if [[ "$detected_runtime" == "apple-container" ]]; then
        local use_native=false

        if [[ "${AC_BUILD_USE_SHIM:-1}" == "1" ]]; then
            # Check builder daemon availability
            if container builder status &>/dev/null; then
                use_native=true
            else
                log_info "Starting Apple Container builder..."
                if container builder start &>/dev/null; then
                    use_native=true
                else
                    log_warn "Could not start Apple Container builder, falling back to Docker/Lima"
                fi
            fi
        fi

        if [[ "$use_native" == "true" ]]; then
            # Native build via shim — no separate build runtime or image transfer needed
            local shim_path="$LIB_DIR/platform/apple-container-shim.sh"
            if [[ ! -x "$shim_path" ]]; then
                chmod +x "$shim_path"
            fi
            log_info "Building natively with Apple Container"
            build_runtime="apple-container-native"
        else
            # Fallback: use Docker/Lima to build, then transfer image
            build_runtime="$(find_build_runtime "$detected_platform")"
            if [[ -z "$build_runtime" ]]; then
                log_error "Apple Container detected but no docker-compatible build runtime found."
                log_error "Please install Docker Desktop or Lima for building images."
                return 1
            fi
            log_info "Using $build_runtime to build (will transfer to Apple Container)"
        fi
    fi

    log_info "Building container..."
    log_info "  Platform: $detected_platform"
    log_info "  Runtime: $detected_runtime"
    log_info "  Project: $PROJECT_NAME"

    # Build devcontainer CLI arguments
    local build_args=()
    build_args+=(--workspace-folder "$(pwd)")

    # Set docker path based on build runtime
    case "$build_runtime" in
        apple-container-native)
            build_args+=(--docker-path "$LIB_DIR/platform/apple-container-shim.sh")
            ;;
        docker)
            build_args+=(--docker-path docker)
            ;;
        podman)
            build_args+=(--docker-path podman)
            ;;
        lima)
            # Lima creates nerdctl.lima wrapper
            if command -v nerdctl.lima &>/dev/null; then
                build_args+=(--docker-path nerdctl.lima)
            else
                # Fallback: create a wrapper script
                local wrapper="/tmp/agentcontainer-lima-nerdctl-$$"
                printf '#!/bin/sh\nexec lima nerdctl "$@"\n' > "$wrapper"
                chmod +x "$wrapper"
                build_args+=(--docker-path "$wrapper")
            fi
            ;;
        nerdctl)
            build_args+=(--docker-path nerdctl)
            ;;
    esac

    if [[ "$no_cache" == "true" ]]; then
        build_args+=(--no-cache)
    fi

    # Run devcontainer build (JSON result on stdout, progress on stderr)
    log_info "Running: devcontainer build ${build_args[*]}"
    local build_result
    if build_result=$(devcontainer build "${build_args[@]}"); then
        log_ok "Build complete!"

        # Handle Apple Container image transfer if needed
        # Skip transfer when built natively — image is already in Apple Container's store
        if [[ "$detected_runtime" == "apple-container" && "$build_runtime" != "apple-container-native" ]]; then
            # Extract image name from JSON output
            local image_name
            image_name=$(echo "$build_result" | grep -o '"imageName":\["[^"]*"' | sed 's/.*\["\([^"]*\)".*/\1/' | head -1)
            if [[ -n "$image_name" ]]; then
                transfer_to_apple_container "$build_runtime" "$image_name"
            else
                log_warn "Could not extract image name from build output"
            fi
        fi
    else
        log_error "Build failed"
        return 1
    fi
}

show_build_help() {
    cat <<EOF
Usage: agentcontainer build [options]

Build the container image.

Options:
    --no-cache      Build without using cache
    --platform      Override platform detection (darwin, linux, wsl)
    -h, --help      Show this help

Examples:
    agentcontainer build
    agentcontainer build --no-cache
EOF
}

# Transfer image to Apple Container runtime
transfer_to_apple_container() {
    local build_runtime="$1"
    local image_name="$2"

    # Skip if image already exists in Apple Container
    if container image list 2>/dev/null | grep -q "$image_name"; then
        log_info "Image already in Apple Container, skipping transfer"
        return 0
    fi

    log_info "Transferring image to Apple Container runtime..."

    # Pipe directly from build runtime to Apple Container
    case "$build_runtime" in
        lima)
            if limactl shell default nerdctl save "$image_name" | container image load; then
                log_ok "Image transferred to Apple Container"
            else
                log_warn "Failed to transfer image to Apple Container"
                return 1
            fi
            ;;
        docker)
            if docker save "$image_name" | container image load; then
                log_ok "Image transferred to Apple Container"
            else
                log_warn "Failed to transfer image to Apple Container"
                return 1
            fi
            ;;
        *)
            log_warn "Transfer to Apple Container not supported for runtime: $build_runtime"
            return 1
            ;;
    esac
}
