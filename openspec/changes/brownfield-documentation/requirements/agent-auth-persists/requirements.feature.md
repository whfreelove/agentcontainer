# Feature: Agent authentication persistence (agent-auth-persists)

## Requirements

`@agent-auth-persists:1`
### Rule: Auth volume mount SHALL use project-scoped named volumes targeting the container home

`@agent-auth-persists:1.1`
#### Scenario: Named volume generated with project name prefix

- Given `PROJECT_NAME` is set to "myproject"
- When `build_mounts_json()` generates mount definitions
- Then the system SHALL include a volume mount with source `myproject-claude-home`

`@agent-auth-persists:1.2`
#### Scenario Outline: Volume target derived from remote user

- Given `REMOTE_USER` is "<user>"
- When `build_mounts_json()` generates mount definitions
- Then the auth volume target SHALL be "<target>"

##### Examples

| user | target |
|------|--------|
| root | /root/.claude |
| vscode | /home/vscode/.claude |

`@agent-auth-persists:1.3`
#### Scenario: Volume mount type ensures persistence across container removal

- When `build_mounts_json()` generates the auth mount definition
- Then the mount type SHALL be "volume" not "bind"
- And the named volume SHALL persist after the container is removed

---

`@agent-auth-persists:2`
### Rule: Setup script SHALL fix auth directory ownership for non-root users

`@agent-auth-persists:2.1`
#### Scenario: Non-root user gets ownership of auth directory

- Given the container is running as a non-root user
- And `$HOME/.claude` exists inside the container
- When `setup.sh` executes as `postCreateCommand`
- Then the auth directory `$HOME/.claude` SHALL be owned by the current user

`@agent-auth-persists:2.2`
#### Scenario: Root user skips ownership fix

- Given the container is running as root
- When `setup.sh` executes as `postCreateCommand`
- Then the system SHALL skip the auth directory ownership fix

`@agent-auth-persists:2.3`
#### Scenario: Ownership fix failure is non-fatal

- Given the `chown` command fails inside the container
- When `setup.sh` attempts the ownership fix
- Then the failure SHALL be suppressed and setup SHALL continue

---

`@agent-auth-persists:3`
### Rule: Setup script SHALL symlink the primary auth file `.claude.json` into the persistent volume

`@agent-auth-persists:3.1`
#### Scenario: Existing workspace `.claude.json` is moved into volume and symlinked

- Given `.claude.json` exists in the workspace as a regular file
- And the file is not a symlink
- When setup.sh processes `.claude.json` during postCreateCommand
- Then the file SHALL be moved into the named volume directory `$HOME/.claude`
- And a symlink SHALL be created from `$HOME/.claude.json` to the volume copy

`@agent-auth-persists:3.2`
#### Scenario: `.claude.json` present in volume but missing from workspace gets symlinked

- Given `.claude.json` exists in the named volume directory `$HOME/.claude`
- And no `.claude.json` file or symlink exists at `$HOME/.claude.json`
- When setup.sh processes `.claude.json` during postCreateCommand
- Then a symlink SHALL be created from `$HOME/.claude.json` to the volume copy
- And the volume file SHALL not be moved or duplicated

`@agent-auth-persists:3.3`
#### Scenario: Already-symlinked `.claude.json` is a no-op

- Given a symlink already exists at `$HOME/.claude.json`
- And the symlink points to the named volume directory
- When setup.sh processes `.claude.json` during postCreateCommand
- Then the system SHALL take no action
- And the existing symlink SHALL remain unchanged

---

`@agent-auth-persists:4`
### Rule: Setup script SHALL discover and persist backup auth files via glob pattern

`@agent-auth-persists:4.1`
#### Scenario: Backup files in workspace are moved into volume and symlinked

- Given one or more files matching the glob `.claude.json.backup.*` exist in the workspace `$HOME`
- And the files are regular files, not symlinks
- When setup.sh discovers backup files during postCreateCommand
- Then each matching file SHALL be moved into the named volume directory `$HOME/.claude`
- And a symlink SHALL be created from the original workspace path to each volume copy

`@agent-auth-persists:4.2`
#### Scenario: Backup files in volume but missing from workspace get symlinked

- Given one or more files matching `.claude.json.backup.*` exist in the named volume directory `$HOME/.claude`
- And no corresponding file or symlink exists at the workspace path for each match
- When setup.sh discovers backup files during postCreateCommand
- Then a symlink SHALL be created from the workspace path to each volume copy

`@agent-auth-persists:4.3`
#### Scenario: Backup files discovered from both workspace and volume directories

- Given setup.sh scans for `.claude.json.backup.*` files
- When backup files exist in both `$HOME` and `$HOME/.claude`
- Then the system SHALL process backup files from both directories
- And the combined set of discovered files SHALL be deduplicated by filename before processing
