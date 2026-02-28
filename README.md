# Agentcontainer

Agent-focused container orchestration for AI coding assistants.

Agentcontainer is a thin CLI wrapper around the [devcontainer CLI](https://github.com/devcontainers/cli) that adds agent-specific features like:

- **Agent execution** — run AI agents inside containers via `EXEC_AGENT`
- **Platform-aware runtime selection** (Docker, Podman, nerdctl, Lima, Apple Container)
- **Claude Code integration** with SessionStart hooks and plans directory

## Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/whfreelove/agentcontainer/main/install.sh | bash
```

### Manual Install

```bash
git clone https://github.com/whfreelove/agentcontainer.git
cd agentcontainer
ln -s "$(pwd)/bin/agentcontainer" ~/.local/bin/agentcontainer
```

### Prerequisites

- [devcontainer CLI](https://github.com/devcontainers/cli): `npm install -g @devcontainers/cli`
- A container runtime: Docker, Podman, nerdctl, or Lima
  - Or Apple container plus another runtime for builds (not fully Docker-compatible)
- `envsubst` (part of gettext)

## Quick Start

```bash
# Initialize a new project
cd my-project
agentcontainer init

# Build the container
agentcontainer build

# Start the container
agentcontainer up

# Get a shell
agentcontainer shell
```

## Commands

### `agentcontainer` (agent run mode)

When run without a command, executes the agent defined by `EXEC_AGENT` in config.
Arguments after `--` are passed to the agent.

```bash
agentcontainer                         # Run the agent
agentcontainer -- --resume             # Run agent with args
agentcontainer -- -p "fix the bug"     # Run agent with prompt
```

### `agentcontainer init`

Initialize a new project with agentcontainer configuration.

```bash
agentcontainer init                                    # Initialize with defaults
agentcontainer init --agent claude-code --exec claude  # Agent with exec command
agentcontainer init --features "claude-code opencode"  # Specify devcontainer features
agentcontainer init --image python:3.12                # Use custom base image
agentcontainer init --setup ./scripts/dev-setup.sh     # Repo setup script
agentcontainer init --shell zsh                        # Default shell profile
agentcontainer init --resources 8g:4:1000              # Memory:CPU:PIDs limits
agentcontainer init --force                            # Overwrite existing config
```

Creates:
- `.agentcontainer/agentcontainer.conf` - Project configuration (commit this)
- `.agentcontainer/local.conf` - Machine-specific configuration (gitignored)
- `.agentcontainer/setup.sh` - Container setup script
- `.agentcontainer/.claude/` - Claude Code configuration
- `.devcontainer/devcontainer.json` - Devcontainer definition

### `agentcontainer build`

Build the container image.

```bash
agentcontainer build                   # Build with cache
agentcontainer build --no-cache        # Build without cache
agentcontainer build --platform linux  # Override platform detection
```

### `agentcontainer up`

Start the container.

```bash
agentcontainer up                      # Start the container
agentcontainer up --rebuild            # Rebuild before starting
```

### `agentcontainer shell`

Get a shell in the running container.

```bash
agentcontainer shell                       # Use DEFAULT_SHELL profile
agentcontainer shell --shell nix-data      # Use a specific shell profile
agentcontainer shell --exec /bin/zsh       # Run a specific executable
agentcontainer shell --root                # Shell as root
agentcontainer shell --user someone        # Shell as specific user
agentcontainer shell ls -la                # Run a command
```

### `agentcontainer stop`

Stop the running container.

```bash
agentcontainer stop
```

### `agentcontainer down`

Stop and remove the container.

```bash
agentcontainer down
```

### `agentcontainer status`

Show container and runtime status.

```bash
agentcontainer status
```

## Configuration

Project configuration is stored in `.agentcontainer/agentcontainer.conf`:

```bash
# Project identity
PROJECT_NAME="myproject"
WORKSPACE_FOLDER="/workspaces/myproject"
BASE_IMAGE="mcr.microsoft.com/devcontainers/base:ubuntu"

# Agent execution (used by 'agentcontainer' with no command)
EXEC_AGENT="claude"           # Command to run the agent
AGENTS="claude-code"          # AI agents to install

# Optional devcontainer features (space-separated names or URIs)
FEATURES="jujutsu playwright"

# Setup
SETUP_SCRIPT=""               # Repo script to run during container setup
DEFAULT_SHELL="bash"          # Shell profile for 'agentcontainer shell'
```

Machine-specific configuration is stored in `.agentcontainer/local.conf` (gitignored):

```bash
# Resource limits
MEMORY_LIMIT="4g"
CPU_LIMIT="2"
PID_LIMIT="500"

# Platform-specific
MACOS_RUNTIME="auto"          # auto, apple-container, lima, docker
CONTAINER_RUNTIME=""          # Override auto-detection
```

`local.conf` values override `agentcontainer.conf`, so team members can tune resource limits and runtimes for their own machines without affecting the shared config.

## Platform Support

### macOS

Runtime detection order:
1. Apple Container (`container` CLI)
2. Lima with nerdctl
3. Docker Desktop

### Linux

Runtime detection order:
1. nerdctl
2. Podman
3. containerd (ctr)
4. Docker

### WSL

Runtime detection order:
1. nerdctl
2. Docker

### Override Detection

Set `CONTAINER_RUNTIME` in your config to force a specific runtime:

```bash
CONTAINER_RUNTIME="podman"
```

Or for macOS specifically:

```bash
MACOS_RUNTIME="lima"
```

## Features

The `FEATURES` config accepts space-separated feature names or full URIs.

### AI Coding Agents

| Feature | Description | Status |
|---------|-------------|--------|
| `claude-code` | [Claude Code](https://github.com/anthropics/claude-code) | Official feature |
| `opencode` | [OpenCode](https://opencode.ai) | Community feature |

**Not yet available as devcontainer features:**

| Agent | Status | Workaround |
|-------|--------|------------|
| Gemini CLI | [Requested](https://github.com/google-gemini/gemini-cli/issues/8176) | Add to `setup.sh` |
| Codex CLI | No official feature | Add to `setup.sh` |
| Amazon Q | VS Code extension only | Add to devcontainer extensions |
| Aider | No official feature | Add to `setup.sh` |

### Other Features

Any devcontainer feature can be used by specifying its full URI:

```bash
FEATURES="claude-code opencode ghcr.io/devcontainers/features/rust:1"
```

Browse available features at [containers.dev/features](https://containers.dev/features).

## Claude Code Integration

When initialized, agentcontainer sets up:

- `.agentcontainer/.claude/` - Claude configuration directory (mounted readonly)
- `.agentcontainer/.claude/plans/` - Plans directory (mounted writable)
- `.agentcontainer/.claude/hooks/SessionStart.sh` - Hook that runs on session start

The SessionStart hook:
- Sets up PATH for common tool locations (`~/.local/bin`, `~/.cargo/bin`)
- Sources `.agentcontainer/env.sh` if it exists (project-specific environment)

## Directory Structure

```
.agentcontainer/
├── agentcontainer.conf     # Project configuration (commit this)
├── local.conf              # Machine-specific config (gitignored)
├── setup.sh                # Container setup script
├── .gitignore
└── .claude/
    ├── hooks/
    │   └── SessionStart.sh # Claude session hook
    └── plans/              # Claude plans (writable mount)

.devcontainer/
└── devcontainer.json       # Generated devcontainer config
```

## Development

```bash
# Clone the repo
git clone https://github.com/whfreelove/agentcontainer.git
cd agentcontainer

# Run locally
./bin/agentcontainer --help

# Test init
mkdir /tmp/test-project && cd /tmp/test-project
/path/to/agentcontainer/bin/agentcontainer init
```

## License

MIT
