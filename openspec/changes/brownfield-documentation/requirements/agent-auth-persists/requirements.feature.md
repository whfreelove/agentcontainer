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
- Then the system SHALL run `sudo chown -R` to set ownership to the current user

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
### Rule: Setup script SHALL symlink workspace auth files into the persistent volume

`@agent-auth-persists:3.1`
#### Scenario: Existing workspace auth file is moved into volume and symlinked

- Given a credential file exists in the workspace (e.g. `.claude.json`)
- And the file is a regular file, not a symlink
- When `persist_claude_file()` executes during `setup.sh`
- Then the file SHALL be moved into the named volume directory
- And a symlink SHALL be created from the original workspace path to the volume copy

`@agent-auth-persists:3.2`
#### Scenario: Auth file present in volume but missing from workspace gets symlinked

- Given a credential file exists in the named volume directory
- And no corresponding file or symlink exists at the workspace path
- When `persist_claude_file()` executes during `setup.sh`
- Then a symlink SHALL be created from the workspace path to the volume copy
- And the volume file SHALL not be moved or duplicated

`@agent-auth-persists:3.3`
#### Scenario: Already-symlinked auth file is a no-op

- Given a symlink already exists at the workspace credential path
- And the symlink points to the named volume directory
- When `persist_claude_file()` executes during `setup.sh`
- Then the function SHALL take no action
- And the existing symlink SHALL remain unchanged
