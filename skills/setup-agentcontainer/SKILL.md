---
name: setup-agentcontainer
description: Use when the user asks to set up agentcontainer, configure a dev container for AI agents, or initialize a containerized development environment for a project
---

# Setup Agentcontainer

Guided setup of agentcontainer for a project. Walks through detection, confirmation, and execution to produce a working container configuration.

## Preconditions

Before starting, verify:

1. **`agentcontainer` on PATH**: Run `which agentcontainer`. If missing, stop and tell the user to install it first.
2. **Existing `.agentcontainer/` directory**: If present, warn the user that `init --force` will overwrite `agentcontainer.conf` and `devcontainer.json` but preserve `local.conf`. Ask for confirmation before proceeding. If the user confirms, use `--force` on the init command.

## Phase 1: Detection

Scan the project silently before asking questions. Build a proposal from what you find.

### Scan for environment markers

Read @references/environment-detection.md for the full mapping tables. Use them to:

1. **Identify language/framework** from marker files at the project root
2. **Pick base image** from the markers-to-image table
3. **Pin version** by reading the version pinning source for the detected language
4. **Identify features** from the markers-to-features table
5. **Detect OS package needs** by scanning dependency files against the dependency-to-packages table
6. **Detect package manager** from the base-image-to-package-manager table

### Multi-language projects

If multiple markers found, use the primary language (the one with the most code or the main build system) for the base image. Add secondary languages as devcontainer features.

### Git identity

If `git` is available, read:
```bash
git config --global user.name
git config --global user.email
```
Use these as defaults to confirm with the user.

## Phase 2: Conversation

Present detected defaults for each topic. The user confirms or adjusts. Ask one topic at a time — do not dump all questions at once.

### Step 1: Environment summary and base image

Show what you detected (markers found, language, version). Propose the full base image with `mcr.microsoft.com/devcontainers/` prefix and pinned version tag. Ask the user to confirm or change.

### Step 2: Devcontainer features

Propose features based on detection (including `ghcr.io/anthropics/devcontainer-features/claude-code:1` for claude-code agent). Note that `--agent claude-code` auto-adds Node.js 20 — do not duplicate it. Offer to check the devcontainer registry online if the user needs features not in the detected set. Feature URIs must start with `ghcr.io/` or `docker.io/`.

### Step 3: Agent exec command

Default: `claude {}` (the `{}` is replaced with the task file path by agentcontainer). If Nix or another wrapper shell was detected, suggest the appropriate pattern, e.g. `nix-shell data.nix --run 'claude {}'`.

### Step 4: Remote control

Ask whether to enable Claude Code's remote control capability for all sessions:

- **Disabled (default)**: Remote control is not available. Standard interactive use.
- **Enabled by default**: Every session starts with remote control active
  (`enableRemoteControlByDefault: true` in settings.json). Allows external
  processes to send commands to the running Claude Code session.
- **Blocked entirely**: Remote control cannot be started even manually
  (`disableRemoteControl: true` in settings.json).

The chosen value is written into settings.json in Phase 3, Action 3.
This does NOT affect EXEC_AGENT — remote control is a session-level capability,
not a CLI flag.

### Step 5: Output style

Ask which output style the agent should use. This sets the `outputStyle` key
in settings.json, which modifies the system prompt behavior:

- **Default**: Standard Claude Code behavior (software engineering focused)
- **Proactive**: Executes immediately, makes assumptions, prefers action over planning
- **Explanatory**: Adds educational insights between code completions
- **Learning**: Collaborative learn-by-doing mode with `TODO(human)` markers

If the user has custom output style files in `.claude/output-styles/`, they can
specify the style name instead.

The chosen value is written into settings.json in Phase 3, Action 3.

### Step 6: Resource limits

Show the CLI defaults (`4g:2:500` = memory:CPUs:PIDs) as a starting point. Always ask — resource needs vary by project.

### Step 7: Git identity

Pre-fill from git config if available. Confirm name and email. These go into `local.conf` (gitignored, machine-specific).

### Step 8: Host directory mounts

Ask if any host directories should be mounted into the container. Help format mount strings: `type=bind,source=/host/path,target=/container/path[,readonly]`.

### Step 9: OS packages

Present detected candidates from dependency scanning. Confirm which to include. The user can add more.

### Step 10: Setup script

Ask if there is an existing repo script to run inside the container after creation (maps to `--setup` flag). Example: `./scripts/dev-setup.sh`.

### Step 11: Shell profile

Only ask if a non-standard shell was detected (Nix, etc.). If answered, check whether the EXEC_AGENT command from Step 3 needs updating to use the shell wrapper.

## Phase 3: Execution

After gathering all answers, execute these steps in order.

### Action 1: Write `local.conf`

**IMPORTANT: Write `local.conf` BEFORE running `agentcontainer init`.** Init only creates `local.conf` if it does not already exist (it preserves an existing one). By writing it first, init reads the populated values when generating `devcontainer.json`.

Write `.agentcontainer/local.conf` with the gathered values:

```
# Agentcontainer Local Configuration
# Machine-specific settings - DO NOT commit to version control

MEMORY_LIMIT="<memory>"
CPU_LIMIT="<cpus>"
PID_LIMIT="<pids>"

MACOS_RUNTIME="auto"
CONTAINER_RUNTIME=""

EXTRA_MOUNTS="<mount strings, newline-separated>"

GIT_USER_NAME="<name>"
GIT_USER_EMAIL="<email>"
```

### Action 2: Run `agentcontainer init`

Build the command from gathered answers. Show the full command to the user before running it:

```bash
agentcontainer init \
  --image "<base-image>" \
  --agent claude-code \
  --exec "<exec-command>" \
  --features "<feature1> <feature2>" \
  --setup "<setup-script>" \
  --resources <memory>:<cpus>:<pids>
```

Add `--force` if overwriting an existing configuration.

Omit flags for values that are empty or use defaults (e.g. omit `--setup` if no setup script, omit `--features` if no extra features beyond what `--agent` provides).

After init completes, surface the `remoteUser` warning: the default is `vscode`. If the base image is root-based, tell the user to change `remoteUser` to `root` in `.devcontainer/devcontainer.json`.

### Action 3: Write settings.json

Read the baseline template from @assets/settings.json. The baseline includes:
- Sandbox enabled with container prerequisites (`enableWeakerNestedSandbox`,
  `allowUnsandboxedCommands: false`, `deniedDomains`)
- Attribution disabled (empty commit and PR strings)
- Analytics disabled (`disableAnalytics: true`)
- Destructive operations deny list
- Plan mode as default permission mode

Then apply conversation answers:

1. Add project-specific `allow` rules based on the detected ecosystem:

   - **Python**: `"Bash(pip *)"`, `"Bash(python *)"`, `"Bash(pytest *)"`, `"Bash(uv *)"`
   - **Node.js**: `"Bash(npm *)"`, `"Bash(npx *)"`, `"Bash(node *)"`, `"Bash(yarn *)"`, `"Bash(pnpm *)"`
   - **Rust**: `"Bash(cargo *)"`, `"Bash(rustc *)"`
   - **Go**: `"Bash(go *)"`, `"Bash(go test *)"`
   - **Ruby**: `"Bash(bundle *)"`, `"Bash(gem *)"`, `"Bash(rake *)"`
   - **Java**: `"Bash(mvn *)"`, `"Bash(gradle *)"`, `"Bash(java *)"`
   - **C/C++**: `"Bash(make *)"`, `"Bash(cmake *)"`, `"Bash(gcc *)"`, `"Bash(g++ *)"`

2. If remote control was enabled (Step 4), add `"enableRemoteControlByDefault": true`.
   If blocked, add `"disableRemoteControl": true`. If disabled (default), omit both.

3. If output style is not "Default" (Step 5), add `"outputStyle": "<choice>"`.

Write the result to `.agentcontainer/.claude/settings.json`, merging with any
existing content (preserve user-added keys).

### Action 3b: Write CLAUDE.md

Write `.agentcontainer/.claude/CLAUDE.md` with container-environment context
for the agent. This file is mounted at `<workspace>/.claude/CLAUDE.md` inside
the container and is invisible to agents running on the host.

Use the template from @assets/CLAUDE.md, substituting the project name and
workspace path from gathered values.

### Action 4: Patch setup.sh

If OS packages were confirmed, add install lines to `.agentcontainer/setup.sh` below the `=== Add custom commands below ===` marker. Use the correct package manager for the base image:

**apt (Debian/Ubuntu — most devcontainer images):**
```bash
sudo apt-get update && sudo apt-get install -y <packages>
```

**apk (Alpine):**
```bash
sudo apk add --no-cache <packages>
```

**dnf (Fedora/RHEL):**
```bash
sudo dnf install -y <packages>
```

Do NOT add git identity lines — the setup.sh template already handles this by sourcing `local.conf`.

### Action 5: Update .gitignore

`.devcontainer/` is generated output that bakes in machine-specific values from `local.conf` (resource limits, extra mounts). It must not be committed.

Append `.devcontainer/` to the project's root `.gitignore`. If `.gitignore` does not exist, create it. If it already contains `.devcontainer`, skip this step.

### Action 6: Summary

Print what was created and the distinction between committed and gitignored files:

- `.agentcontainer/agentcontainer.conf` — project config (commit this)
- `.agentcontainer/setup.sh` — container setup script (commit this)
- `.agentcontainer/.claude/settings.json` — shared agent policy (commit this)
- `.agentcontainer/.claude/CLAUDE.md` — container-only agent context (commit this)
- `.agentcontainer/local.conf` — machine-specific config (**gitignored** by `.agentcontainer/.gitignore`)
- `.devcontainer/` — generated container definition (**gitignored** — regenerate with `agentcontainer init --force`)

Next steps:
```
agentcontainer build && agentcontainer up
```
