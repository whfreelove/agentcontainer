# Feature: Project initialization (developer-initializes-project)

## Requirements

`@developer-initializes-project:1`
### Rule: Init SHALL scaffold all required project files

#### Background

- Given the developer is in a project directory without `.agentcontainer/`

`@developer-initializes-project:1.1`
#### Scenario: Init creates configuration directories and files

- When the developer runs `agentcontainer init`
- Then the system SHALL create `.agentcontainer/` with `agentcontainer.conf`, `local.conf`, `setup.sh`, and `.gitignore`
- And the system SHALL create `.agentcontainer/.claude/plans/` directory
- And the system SHALL create `.devcontainer/devcontainer.json`

`@developer-initializes-project:1.2`
#### Scenario: Init generates executable scripts

- When the developer runs `agentcontainer init`
- Then `setup.sh` SHALL have executable permission
- And `.agentcontainer/.claude/hooks/SessionStart.sh` SHALL have executable permission

---

`@developer-initializes-project:2`
### Rule: Init SHALL block on existing configuration unless forced

`@developer-initializes-project:2.1`
#### Scenario: Init rejects re-initialization without --force

- Given `.agentcontainer/` already exists in the project directory
- When the developer runs `agentcontainer init` without `--force`
- Then the system SHALL log an error and return exit code 1

`@developer-initializes-project:2.2`
#### Scenario: Init with --force overwrites all template-derived files but preserves user-owned files

- Given `.agentcontainer/` already exists with `agentcontainer.conf`, `local.conf`, `setup.sh`, `.claude/hooks/SessionStart.sh`, and `.devcontainer/devcontainer.json`
- When the developer runs `agentcontainer init --force`
- Then the system SHALL overwrite `agentcontainer.conf`
- And the system SHALL overwrite `devcontainer.json`
- And the system SHALL overwrite `setup.sh`
- And the system SHALL overwrite `SessionStart.sh`
- But the system SHALL preserve the existing `local.conf`

---

`@developer-initializes-project:3`
### Rule: CLI flags SHALL override detected defaults

`@developer-initializes-project:3.1`
#### Scenario Outline: Init applies CLI overrides to configuration

- Given the developer is in a project directory
- When the developer runs `agentcontainer init <flag> <value>`
- Then `agentcontainer.conf` SHALL contain the overridden `<variable>` set to `<value>`

##### Examples

| flag | value | variable |
|------|-------|----------|
| --image | ubuntu:24.04 | BASE_IMAGE |
| --agent | claude-code | AGENTS |
| --shell | zsh | DEFAULT_SHELL |
| --exec | claude | EXEC_AGENT |

`@developer-initializes-project:3.2`
#### Scenario: Init parses colon-separated --resources format

- Given the developer is in a project directory
- When the developer runs `agentcontainer init --resources 8g:4:1000`
- Then `local.conf` SHALL set `MEMORY_LIMIT=8g`, `CPU_LIMIT=4`, and `PID_LIMIT=1000`

`@developer-initializes-project:3.3`
#### Scenario: Partial --resources sets only specified fields

- Given the developer is in a project directory
- When the developer runs `agentcontainer init --resources :4:`
- Then `local.conf` SHALL set `CPU_LIMIT=4`
- And `MEMORY_LIMIT` and `PID_LIMIT` SHALL retain their default values

---

`@developer-initializes-project:4`
### Rule: Unset configuration values SHALL receive sensible defaults

`@developer-initializes-project:4.1`
#### Scenario Outline: Default configuration values

- Given the developer is in a project directory named "myproject"
- When the developer runs `agentcontainer init` with no overrides
- Then `<variable>` SHALL default to `<default>`

##### Examples

| variable | default |
|----------|---------|
| PROJECT_NAME | myproject |
| WORKSPACE_FOLDER | /workspaces/myproject |
| BASE_IMAGE | mcr.microsoft.com/devcontainers/base:ubuntu |
| DEFAULT_SHELL | bash |
| MEMORY_LIMIT | 4g |
| CPU_LIMIT | 2 |
| PID_LIMIT | 500 |
| MACOS_RUNTIME | auto |
