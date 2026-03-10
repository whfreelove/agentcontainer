## Why

Agentcontainer provides devcontainers' isolation and CI/production-matching experience to AI coding agents without burdening the user with container runtime and auth complexity. The design principle is to match devcontainer CLI's behavioral semantics — including its failure handling, lifecycle hooks, and configuration model — while adding agent-specific orchestration on top.

## Capabilities

- `developer-initializes-project`: Developer can scaffold container configuration for a project with agent, image, features, and resource settings
- `developer-builds-container`: Developer can build a container image with agent tooling using the host's detected or configured runtime
- `developer-starts-container`: Developer can start or resume a container environment from a previously built image
- `developer-runs-agent`: Developer can execute an AI agent inside the running container with optional arguments
- `developer-opens-shell`: Developer can open an interactive shell or run arbitrary commands inside the running container
- `developer-stops-container`: Developer can stop or stop-and-remove the running container
- `developer-views-status`: Developer can inspect the detected platform, runtime, and container state
- `runtime-detects-platform`: System auto-detects the best available container runtime for the host platform (macOS, Linux, WSL)
- `agent-auth-persists`: System persists AI agent authentication credentials across container rebuilds via named volumes and symlinks

## User Impact

### Scope

Individual developers running AI coding agents (Claude Code, OpenCode) on macOS, Linux, and WSL. The tool targets developers who want containerized, reproducible environments for AI-assisted coding without manually configuring devcontainers and runtime-specific plumbing.

### Out of Scope

- Multi-container orchestration (each project gets one container)
- Production deployment or hosting of AI agents
- Non-AI-agent container workflows (general devcontainer management is handled by the devcontainer CLI itself)
- GUI or web-based interfaces (CLI only)
- Windows native support (WSL is supported, but not native Windows)

### Current Limitations

- Apple Container runtime cannot build images natively without the builder daemon; falls back to Docker or Lima for building, then transfers the image
- Only two AI agents have official devcontainer features (Claude Code, OpenCode); other agents (Gemini CLI, Codex CLI, Amazon Q, Aider) require manual setup via `setup.sh`
- The `containerd` (ctr) runtime is detected on Linux but has limited support compared to Docker/Podman/nerdctl
- No built-in health checking or readiness probes for started containers
- Shell profile resolution depends on `.agentcontainer/shell-profiles.json` existing; built-in profiles are limited to bash, zsh, and sh
- `agentcontainer up --rebuild` is silently ignored when a container already exists (running or stopped); the user must run `down` before `up --rebuild` to trigger a fresh build

### Planned Future Work

No concrete plans at this time. Development is opportunistic.

### Known Risks

- Runtime auto-detection depends on CLI tools being on PATH; misconfigured environments may select an unintended runtime
- Apple Container support is newer and less battle-tested than Docker/Podman paths; edge cases in mount handling and UID/GID sync may surface
- The `EXEC_AGENT` command template uses shell expansion (`sh -c`) inside the container, which could behave unexpectedly with complex argument patterns containing special characters
- Auth persistence relies on named Docker volumes; volume lifecycle is not managed by agentcontainer (orphaned volumes from deleted projects persist)

## Overview

Agentcontainer is a pure Bash CLI (v0.1.0, ~2,100 lines across 12 shell scripts) that wraps the devcontainer CLI with agent-specific orchestration.

**Architecture:**
- **Entry point** (`bin/agentcontainer`) — argument parsing, dependency checking, command dispatch
- **Command modules** (`lib/commands/`) — `init`, `build`, `up`, `shell`, `stop`, `down`, each in a separate file sourced on demand
- **Platform layer** (`lib/platform/`) — runtime detection across 6 runtimes (Docker, Podman, nerdctl, Lima, Apple Container, containerd) and an Apple Container shim that translates Docker CLI calls for the devcontainer CLI; `detect.sh` is loaded eagerly at startup, the shim is loaded on demand by build/up
- **Utilities** (`lib/utils/`) — config loading (cascading `agentcontainer.conf` → `local.conf`), template expansion via `envsubst`; loaded eagerly at startup
- **Templates** (`lib/templates/`) — project config, local config, devcontainer.json, setup script, and Claude Code SessionStart hook

**Execution flow:**
1. `init` scaffolds `.agentcontainer/` and `.devcontainer/` from templates with user-supplied or default values
2. `build` detects the platform and runtime, then delegates to `devcontainer build` with the appropriate `--docker-path`; on Apple Container, it either uses a native shim or builds with Docker/Lima and transfers the image
3. `up` checks for an existing container (running or stopped) and either starts it or creates a new one via `devcontainer up`; Apple Container gets a custom startup path with mount parsing, volume creation, UID/GID sync, and feature entrypoint execution
4. The default command (no subcommand) finds the running container and execs `EXEC_AGENT` inside it, passing any `--` arguments
5. `shell` resolves a shell profile (built-in or from `shell-profiles.json`) and execs into the container
6. `stop` and `down` gracefully stop or force-remove the container

**Configuration model:** Two-layer config (`agentcontainer.conf` for shared project settings, `local.conf` for machine-specific overrides) plus a generated `devcontainer.json` that the devcontainer CLI consumes. Auth persistence uses a named volume (`${PROJECT_NAME}-claude-home`) mounted at `~/.claude` inside the container, with symlinks managed by `setup.sh`.
