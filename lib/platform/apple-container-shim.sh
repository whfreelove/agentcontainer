#!/usr/bin/env bash
# Shim translating Docker CLI commands to Apple Container CLI.
# Used as --docker-path for devcontainer build on Apple Container runtime.
#
# Why fail on buildx? devcontainer CLI runs `<docker-path> buildx version`
# on startup. If it succeeds, it uses `docker buildx build` with BuildKit
# extensions (--cache-to, --load, --push, --build-context) that container CLI
# doesn't expose. Failing here makes devcontainer fall back to plain
# `docker build`, whose args map cleanly to `container build`. Apple Container's
# builder is BuildKit-based internally, so Dockerfile compatibility is excellent —
# we only lose the external cache management flags, not build quality.

set -euo pipefail

# Guard: jq is required for inspect JSON transformation
if ! command -v jq &>/dev/null; then
    echo "apple-container-shim: jq is required but not found" >&2
    exit 1
fi

# Debug logging (set AC_SHIM_DEBUG=1 to enable)
if [[ "${AC_SHIM_DEBUG:-}" == "1" ]]; then
    echo "[ac-shim] $*" >&2
fi

inspect_to_docker_format() {
    # Transform Apple Container inspect JSON to Docker-compatible format.
    # AC:     [{ variants: [{ platform: {os, architecture}, config: { config: { Cmd, Env, User, Labels } } }], name, index: {digest} }]
    # Docker: [{ Config: { Cmd, Env, User, Labels }, RepoTags: [...], Id, Architecture, Os }]
    jq '[.[0] | {
        Id: (.index.digest // ""),
        RepoTags: [.name],
        Config: (.variants[0].config.config // {}),
        Architecture: (.variants[0].platform.architecture // "arm64"),
        Os: (.variants[0].platform.os // "linux")
    }]'
}

case "$1" in
    buildx)
        # Fail to trigger devcontainer's plain `docker build` fallback.
        echo "buildx not available" >&2
        exit 1
        ;;
    build)
        # docker build -f FILE -t TAG ... CONTEXT → container build ...
        # Most args are compatible; strip ones container CLI doesn't support.
        shift
        args=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
                # Flags with no value (or value joined by =)
                --load|--push)
                    shift ;;
                --iidfile=*|--progress=*|--cache-from=*|--cache-to=*|--output=*|--build-context=*)
                    shift ;;
                # Flags with separate value
                --iidfile|--progress|--cache-from|--cache-to|--output|--build-context)
                    shift 2 ;;
                *)
                    args+=("$1"); shift ;;
            esac
        done
        exec container build "${args[@]}"
        ;;
    tag)
        # docker tag SOURCE TARGET → container image tag SOURCE TARGET
        shift
        exec container image tag "$@"
        ;;
    image)
        shift
        case "$1" in
            inspect)
                shift
                container image inspect "$@" | inspect_to_docker_format
                ;;
            *)
                exec container image "$@"
                ;;
        esac
        ;;
    inspect)
        # docker inspect IMAGE (without "image" subcommand)
        shift
        container image inspect "$@" | inspect_to_docker_format
        ;;
    images)
        shift
        exec container image list "$@"
        ;;
    info)
        # devcontainer may check ServerVersion, OSType, GPU support
        cat <<'INFOJSON'
{"ServerVersion":"0.10.0","Runtimes":{},"OSType":"linux","Architecture":"aarch64"}
INFOJSON
        ;;
    version)
        # devcontainer runs: docker version --format '{{.Server.Version}}'
        # Apple Container doesn't support --format on version; parse it ourselves
        if [[ "${2:-}" == "--format" ]]; then
            container --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
        else
            container --version
        fi
        ;;
    *)
        # Pass through anything else
        exec container "$@"
        ;;
esac
