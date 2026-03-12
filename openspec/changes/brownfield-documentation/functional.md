## Why

Agentcontainer provides devcontainers' isolation and CI/production-matching experience to AI coding agents without burdening the user with container runtime and auth complexity. The design principle is to match devcontainer CLI's behavioral semantics — including its failure handling, lifecycle hooks, and configuration model — while adding agent-specific orchestration on top.

## Capabilities

- `developer-initializes-project`: Developer can scaffold container configuration for a project with agent, image, features, and resource settings
- `developer-builds-container`: Developer can build a container image with agent tooling using the host's detected or configured runtime
- `developer-starts-container`: Developer can start or resume a container environment from a previously built image
- `developer-runs-agent`: Developer can execute an AI agent inside the running container with optional arguments
- `developer-opens-shell`: Developer can open an interactive shell or run arbitrary commands inside the running container
- `developer-stops-container`: Developer can stop or stop-and-remove the running container
- `developer-views-status`: Developer can inspect the detected platform, runtime availability, and project configuration
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

- Apple Container users may experience slower builds when the native builder daemon is unavailable, as images must be built via an alternate runtime and transferred
- Only two AI agents have official devcontainer features (Claude Code, OpenCode); other agents (Gemini CLI, Codex CLI, Amazon Q, Aider) require manual setup via `setup.sh`
- Developers using the containerd runtime directly may encounter unsupported operations that work with Docker, Podman, or nerdctl
- No built-in health checking or readiness probes for started containers
- Developers who use shells other than bash, zsh, or sh must define custom shell profiles in `.agentcontainer/shell-profiles.json`; without this file, only the three built-in shells are available
- `agentcontainer up --rebuild` is silently ignored when a container already exists (running or stopped); the user must run `down` before `up --rebuild` to trigger a fresh build
- When building with nerdctl or Podman on Apple Container, the image cannot be transferred to Apple Container after the build; the developer must use Docker or Lima as the build runtime to complete the Apple Container workflow

### Planned Future Work

No concrete plans at this time. Development is opportunistic.

### Known Risks

- Runtime auto-detection depends on CLI tools being on PATH; misconfigured environments may select an unintended runtime
- Apple Container support is newer and less battle-tested than Docker/Podman paths; edge cases in mount handling and UID/GID sync may surface
- The `EXEC_AGENT` command template uses shell expansion (`sh -c`) inside the container, which could behave unexpectedly with complex argument patterns containing special characters
- Auth persistence relies on named volumes; volume lifecycle is not managed by agentcontainer (orphaned volumes from deleted projects persist)

## Overview

Agentcontainer is a CLI tool that manages the full lifecycle of containerized AI agent environments. The developer workflow follows a consistent sequence:

**Commands:**
- `agentcontainer init` — Scaffolds container configuration for a project, accepting options for base image, agent, features, shell, and resource limits. Generates project and local configuration files plus a devcontainer definition.
- `agentcontainer build` — Builds the container image using whichever container runtime is available on the host. The developer does not need to specify or configure the runtime.
- `agentcontainer up` — Starts the container environment. If the container already exists, it resumes it; otherwise it creates a new one. Resource limits and workspace mounts are applied automatically.
- `agentcontainer` (no subcommand) — Launches the configured AI agent inside the running container, forwarding any arguments after `--`.
- `agentcontainer shell` — Opens an interactive shell inside the container. Supports selecting a shell profile or running a one-off command.
- `agentcontainer stop` — Stops the running container, preserving its state for later resumption.
- `agentcontainer down` — Stops and removes the container entirely.
- `agentcontainer status` — Displays the detected platform, runtime availability, and project configuration.

**Configuration:** The developer manages two optional configuration files — a project-level file (intended to be committed and shared with the team) and a local-level file (for machine-specific overrides like resource limits and runtime preferences). Both are generated by `init` and can be edited directly.

**Automatic behaviors:** The tool automatically detects the host platform and selects the best available container runtime without manual configuration. AI agent authentication credentials persist across container rebuilds, so the developer does not need to re-authenticate after running `down` and rebuilding.
