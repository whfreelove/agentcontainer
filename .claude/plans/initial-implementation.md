# Plan: Implement Agentcontainer CLI

## Overview

Build an open-source bash CLI tool that wraps `devcontainer` CLI with agent-specific features. This is a thin orchestration layer that generates config files and handles platform differences.

## Design Decisions

| Decision | Choice |
|----------|--------|
| Language | Pure Bash |
| Config format | Shell variables (`.agentcontainer/agentcontainer.conf`) |
| Platforms | macOS, Linux, WSL |
| Architecture | Thin wrapper around `devcontainer` CLI |

## CLI Commands

| Command | Purpose |
|---------|---------|
| `agentcontainer init` | Generate `.agentcontainer/` and `.devcontainer/` from templates |
| `agentcontainer build` | Build container image (platform-aware) |
| `agentcontainer start` | Create and start container with mounts |
| `agentcontainer shell` | Exec into running container |

## Platform & Runtime Support

| Platform | Runtimes (detection order) |
|----------|---------------------------|
| macOS | Apple Container → Lima (nerdctl) → Docker Desktop |
| Linux | nerdctl → podman → containerd → docker |
| WSL | nerdctl → docker |

## Target Structure

```
agentcontainer/
├── bin/agentcontainer                    # Main CLI entry point
├── lib/
│   ├── commands/
│   │   ├── init.sh                       # agentcontainer init
│   │   ├── build.sh                      # agentcontainer build
│   │   ├── start.sh                      # agentcontainer start
│   │   └── shell.sh                      # agentcontainer shell
│   ├── platform/
│   │   ├── detect.sh                     # Detect macOS/Linux/WSL
│   │   ├── darwin.sh                     # macOS runtime handling
│   │   ├── linux.sh                      # Linux runtime handling
│   │   └── wsl.sh                        # WSL runtime handling
│   ├── utils/
│   │   ├── config.sh                     # Load agentcontainer.conf
│   │   ├── hash.sh                       # Lockfile hash checking
│   │   └── template.sh                   # envsubst-based templating
│   └── templates/
│       ├── agentcontainer.conf.tmpl      # Default config template
│       ├── devcontainer.json.tmpl        # Container definition
│       ├── setup.sh.tmpl                 # Setup script
│       └── SessionStart.sh.tmpl          # Claude hook
├── install.sh                            # curl-pipe installer
└── README.md                             # Documentation
```

## Configuration Format

Projects using agentcontainer will have `.agentcontainer/agentcontainer.conf`:

```bash
# Project identity
PROJECT_NAME="myproject"
WORKSPACE_FOLDER="/workspaces/myproject"

# Language runtimes (empty = skip)
PYTHON_VERSION="3.11"
NODE_VERSION="20"

# Package managers
PACKAGE_MANAGER="uv"          # uv, pip, poetry, none
NODE_PACKAGE_MANAGER="npm"    # npm, pnpm, yarn, none

# Lockfiles for hash-based setup skipping (space-separated)
LOCKFILES="uv.lock package-lock.json"

# Optional features (space-separated)
FEATURES="jujutsu playwright claude-code"

# Resource limits
MEMORY_LIMIT="8g"
CPU_LIMIT="4"
PID_LIMIT="500"

# Platform-specific
MACOS_RUNTIME=""              # auto, apple-container, lima, docker
CONTAINER_RUNTIME=""          # Override auto-detection

# Custom setup command (runs after standard setup)
CUSTOM_SETUP_CMD=""
```

## Implementation Tasks

### Group 1: Core Infrastructure

#### Task 1.1: CLI Entry Point
Create `bin/agentcontainer` - main dispatcher that:
- Sources lib files
- Parses command and options
- Dispatches to command modules

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source utilities
source "$LIB_DIR/utils/config.sh"
source "$LIB_DIR/platform/detect.sh"

# Dispatch command
case "${1:-help}" in
    init)   source "$LIB_DIR/commands/init.sh"; cmd_init "${@:2}" ;;
    build)  source "$LIB_DIR/commands/build.sh"; cmd_build "${@:2}" ;;
    start)  source "$LIB_DIR/commands/start.sh"; cmd_start "${@:2}" ;;
    shell)  source "$LIB_DIR/commands/shell.sh"; cmd_shell "${@:2}" ;;
    help|-h|--help) show_help ;;
    *)      echo "Unknown command: $1"; exit 1 ;;
esac
```

#### Task 1.2: Platform Detection Module
Create `lib/platform/detect.sh`:

```bash
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
```

#### Task 1.3: Config Loading
Create `lib/utils/config.sh`:

```bash
load_config() {
    local config_file="${1:-.agentcontainer/agentcontainer.conf}"

    if [[ -f "$config_file" ]]; then
        # shellcheck source=/dev/null
        source "$config_file"
    fi

    # Set defaults for unset variables
    : "${PROJECT_NAME:=$(basename "$(pwd)")}"
    : "${WORKSPACE_FOLDER:=/workspaces/$PROJECT_NAME}"
    : "${MEMORY_LIMIT:=4g}"
    : "${CPU_LIMIT:=2}"
    : "${PID_LIMIT:=500}"
    : "${PACKAGE_MANAGER:=none}"
    : "${NODE_PACKAGE_MANAGER:=none}"
}
```

#### Task 1.4: Template Expansion
Create `lib/utils/template.sh`:

```bash
expand_template() {
    local template_file="$1"
    local output_file="$2"

    # Use envsubst for variable expansion
    envsubst < "$template_file" > "$output_file"
}

# Build features JSON for devcontainer.json
build_features_json() {
    local features=""

    if [[ -n "${PYTHON_VERSION:-}" ]]; then
        features+="\"ghcr.io/devcontainers/features/python:1\": {\"version\": \"$PYTHON_VERSION\", \"installTools\": true},"
    fi

    if [[ -n "${NODE_VERSION:-}" ]]; then
        features+="\"ghcr.io/devcontainers/features/node:1\": {\"version\": \"$NODE_VERSION\"},"
    fi

    # Add optional features
    for feature in ${FEATURES:-}; do
        case "$feature" in
            claude-code)
                features+="\"ghcr.io/anthropics/devcontainer-features/claude-code:1\": {},"
                ;;
            jujutsu)
                features+="\"ghcr.io/eitsupi/devcontainer-features/jujutsu-cli:1\": {},"
                ;;
            # Add more features as needed
        esac
    done

    # Remove trailing comma
    echo "${features%,}"
}
```

### Group 2: Commands

#### Task 2.1: Init Command
Create `lib/commands/init.sh` - generates `.agentcontainer/` and `.devcontainer/`

#### Task 2.2: Build Command
Create `lib/commands/build.sh` - wraps `devcontainer build` with platform handling

Reference implementation from FRCSim: `/Users/whfreelove/dev/frcsim/frcsim_cycle/scripts/devcontainer-build.sh`

Key logic to port:
- Image hash checking (skip rebuild if unchanged)
- Platform-specific docker path selection
- Image transfer for Apple Container runtime

#### Task 2.3: Start Command
Create `lib/commands/start.sh` - creates container with proper mounts

Key mounts:
- Project directory → workspace folder
- `.git` and `.jj` directories (VCS)
- `.agentcontainer/.claude` → container's `.claude` (readonly)
- `.agentcontainer/.claude/plans` → writable

#### Task 2.4: Shell Command
Create `lib/commands/shell.sh` - exec into running container

### Group 3: Templates

#### Task 3.1: Config Template
Create `lib/templates/agentcontainer.conf.tmpl`

#### Task 3.2: Devcontainer.json Template
Create `lib/templates/devcontainer.json.tmpl`

#### Task 3.3: Setup Script Template
Create `lib/templates/setup.sh.tmpl`

Reference: `/Users/whfreelove/dev/frcsim/frcsim_cycle/scripts/devcontainer-setup.sh`

#### Task 3.4: SessionStart Hook Template
Create `lib/templates/SessionStart.sh.tmpl`

Reference: `/Users/whfreelove/dev/frcsim/frcsim_cycle/.devcontainer/.claude/hooks/SessionStart.sh`

### Group 4: Distribution

#### Task 4.1: Installer Script
Create `install.sh` for curl-pipe installation

#### Task 4.2: README
Document usage, configuration, and platform notes

## Reference Files (from FRCSim)

These files in the FRCSim repo contain the original implementation to generalize:

| File | What to extract |
|------|-----------------|
| `scripts/devcontainer-build.sh` | Build orchestration, hash checking, image transfer |
| `scripts/devcontainer-setup.sh` | Hash-based setup skipping, package manager commands |
| `scripts/devcontainer-macos` | Lima wrapper pattern |
| `.devcontainer/devcontainer.json` | Feature structure, mount patterns |
| `.devcontainer/.claude/hooks/SessionStart.sh` | Verification logic (parameterize tool lists) |

## Verification

1. **Init test:**
   ```bash
   mkdir /tmp/test-project && cd /tmp/test-project
   agentcontainer init
   ls -la .agentcontainer/ .devcontainer/
   ```

2. **Build test (macOS):**
   ```bash
   agentcontainer build
   ```

3. **Full workflow:**
   ```bash
   agentcontainer init
   agentcontainer build
   agentcontainer start
   agentcontainer shell
   # Should drop into container shell
   ```
