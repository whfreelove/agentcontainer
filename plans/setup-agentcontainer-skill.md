# setup-agentcontainer skill

Skill for the agentcontainer Claude Code plugin that guides an agent
through setting up agentcontainer for a new project.

## Identity

- **Skill name:** `setup-agentcontainer`
- **Plugin:** agentcontainer (globally installed by `install.sh`)
- **Invocation:** `/setup-agentcontainer` or natural language ("set up
  agentcontainer for this project")
- **Trigger:** Explicit only — no proactive detection

## Preconditions

- `agentcontainer` CLI on PATH
- No existing `.agentcontainer/` directory (or warn + confirm overwrite
  via `init --force`; note that `--force` preserves `local.conf` but
  overwrites `agentcontainer.conf` and `devcontainer.json`)
- Git not required; if present, used for identity pre-fill

## Approach

Single sequential skill (one SKILL.md). The agent walks a linear
conversation to gather project info, populates `local.conf` first,
then delegates to `agentcontainer init` for scaffolding (so init reads
the populated `local.conf` when generating `devcontainer.json`), and
finally patches results with customizations init doesn't handle.

## Detection phase

Before asking questions, the agent scans the project and builds a
proposal for the user to confirm/adjust.

### Environment markers

| Marker | Infers | Image | Feature |
|--------|--------|-------|---------|
| `pyproject.toml`, `requirements.txt`, `setup.py` | Python | `mcr.microsoft.com/devcontainers/python:<ver>` | — |
| `package.json`, `.nvmrc` | Node.js | `mcr.microsoft.com/devcontainers/javascript-node:<ver>` | — |
| `Cargo.toml`, `rust-toolchain.toml` | Rust | `mcr.microsoft.com/devcontainers/rust:1` | — |
| `go.mod` | Go | `mcr.microsoft.com/devcontainers/go:<ver>` | — |
| `*.nix`, `flake.nix` | Nix | `mcr.microsoft.com/devcontainers/base:ubuntu` | `ghcr.io/devcontainers/features/nix:1` |
| `Gemfile` | Ruby | `mcr.microsoft.com/devcontainers/ruby:<ver>` | — |
| `pom.xml`, `build.gradle` | Java/JVM | `mcr.microsoft.com/devcontainers/java:<ver>` | — |
| `CMakeLists.txt`, `Makefile`, `*.cpp`/`*.c`, `meson.build` | C/C++ | `mcr.microsoft.com/devcontainers/cpp:<ver>` | `ghcr.io/devcontainers/features/cmake:1` if CMakeLists |
| `Dockerfile`, `docker-compose.yml` | Containers | note existing setup, ask | — |
| None | Unknown | `mcr.microsoft.com/devcontainers/base:ubuntu` | ask |

### Version pinning

Read versions from project files where possible:
`requires-python` in pyproject.toml, `engines.node` in package.json,
`.nvmrc`, `rust-toolchain.toml`, `go.mod` go directive.

### Feature sourcing

Prefer official `ghcr.io/devcontainers/features/` first. Fall back to
community registries for tools not in the official set. The agent
should offer to check the devcontainer registries online before
finalizing suggestions (web fetch requires user consent). Do not
hardcode community feature URIs — they go stale; prefer registry
lookup when available.

### Agent feature

When `--agent claude-code` is specified, the skill must also ensure
`ghcr.io/anthropics/devcontainer-features/claude-code:1` is included
in the features list. The `--agent` flag stores `AGENTS` in config but
does not auto-add the devcontainer feature.

### Multi-language projects

If multiple markers found, pick the primary language for the base image
and add the secondary as a devcontainer feature.

### OS package detection

Scan dependency files for libraries needing system packages (e.g.
`psycopg2` -> `libpq-dev`, `Pillow` -> `libjpeg-dev zlib1g-dev`,
crypto libs -> `libssl-dev`). Use the correct package manager for the
base image (apt for Debian/Ubuntu, dnf for Fedora, apk for Alpine).

### Git identity

If `git` available, read `git config --global user.name` and
`user.email` as defaults to confirm.

## Conversation flow

Each step presents detected defaults and asks user to confirm/adjust.

1. **Environment summary & base image** — show what was detected,
   propose image with full `mcr.microsoft.com/devcontainers/` prefix
2. **Devcontainer features** — propose features (including claude-code
   feature for `--agent claude-code`), offer to check registries online
3. **EXEC_AGENT** — how to launch the agent (default: `claude {}`).
   If Nix or other wrapper shell was detected, suggest the appropriate
   pattern (e.g. `nix-shell data.nix --run 'claude {}'`)
4. **Resource limits** — memory, CPUs, PID limit (always ask; show
   CLI defaults of `4g:2:500` as a starting point)
5. **Git identity** — pre-fill from git config if available, confirm
6. **Host directory mounts** — ask if any host directories to mount,
   help format the mount string
7. **OS packages** — present detected candidates, confirm which to
   include
8. **Setup script** — ask if there's an existing repo script to run
   inside the container (maps to `--setup`)
9. **Shell profile** — only ask if non-standard shell detected (Nix,
   etc.). If answered, connect back to EXEC_AGENT if it needs updating

## Execution phase

After gathering all answers:

### 1. Populate `local.conf`

Write `local.conf` first (before running init) so that init can read
it when generating `devcontainer.json`. Patch `GIT_USER_NAME`,
`GIT_USER_EMAIL`, `EXTRA_MOUNTS`, and resource limits (`MEMORY_LIMIT`,
`CPU_LIMIT`, `PID_LIMIT`) with gathered values.

### 2. Run `agentcontainer init`

Build and show the command before running:

```bash
agentcontainer init \
  --image "mcr.microsoft.com/devcontainers/python:3.12" \
  --agent claude-code \
  --exec "claude {}" \
  --features "ghcr.io/anthropics/devcontainer-features/claude-code:1" \
  --setup "./scripts/dev-setup.sh" \
  --resources 8g:4:500
```

Init reads the already-populated `local.conf` to pick up mounts and
git identity when generating `devcontainer.json`.

After init completes, surface the `remoteUser` warning: verify that
`remoteUser` in `devcontainer.json` matches the base image (default
`vscode`; change to `root` for root-based images).

### 3. Generate `settings.local.json`

Write `.agentcontainer/.claude/settings.local.json` from the bundled
baseline template. This file is committed (shared team policy). Add
any project-specific allow rules surfaced during the conversation. The
baseline includes:

- Deny list for destructive git ops (reset, rebase, push -f,
  commit --amend, filter-branch, stash, branch -f, checkout -B)
- Deny process killing (kill, pkill) and sed -i
- Deny directory traversal (ls /, ls ..)
- Sandbox enabled with autoAllowBashIfSandboxed
- Plan mode as defaultMode
- Telemetry/analytics disabled

### 4. Patch `setup.sh`

Below the `=== Add custom commands below ===` marker, add:

- OS package install lines (if confirmed), using the correct package
  manager for the base image

Note: git identity is already handled by the `setup.sh` template
(sources `local.conf` and applies `git config --global`). Do not
duplicate it.

### 5. Summary

Print what was created, which files to review, and next steps:

```
Next: agentcontainer build && agentcontainer up
```

Note: `settings.local.json` is committed and shared. `local.conf` is
gitignored and machine-specific. Remind the user which is which.

## File structure

```
skills/
  setup-agentcontainer/
    SKILL.md                    # Core workflow (~1,500-2,000 words)
    assets/
      settings.local.json       # Baseline template (committed)
    references/
      environment-detection.md  # Marker/image/feature/package tables
```

### SKILL.md

Core workflow: precondition checks, detection instructions, conversation
steps, execution steps. Kept lean; references the detection tables in
`references/` rather than inlining them.

### assets/settings.local.json

Static baseline for team-shared permissions policy. The agent reads
this and adds project-specific allow rules before writing it to the
target project.

### references/environment-detection.md

Full mapping tables: markers -> images, markers -> features,
dependency -> OS packages, base image -> package manager. Loaded when
the agent enters the detection phase. This file grows as new ecosystems
are supported.

## Installation dependency

The agentcontainer plugin must be registered globally by `install.sh`
under `~/.claude/plugins/` for this skill to be discoverable by Claude
Code. This registration mechanism does not exist yet and must be built
as part of shipping this skill.
