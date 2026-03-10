# Feature: Container startup (developer-starts-container)

## Requirements

`@developer-starts-container:1`
### Rule: Up SHALL handle existing container states before creating new containers

#### Background

- Given the project has been initialized and an image has been built

`@developer-starts-container:1.1`
#### Scenario: Already running container returns success

- Given a container for the project is already running
- When the developer runs `agentcontainer up`
- Then the system SHALL log that the container is already running and return exit code 0

`@developer-starts-container:1.2`
#### Scenario: Stopped container is restarted

- Given a container for the project exists but is stopped
- When the developer runs `agentcontainer up`
- Then the system SHALL start the existing container

`@developer-starts-container:1.3`
#### Scenario: Missing image produces an error

- Given no container image exists for the project
- When the developer runs `agentcontainer up`
- Then the system SHALL log an error about missing image and return exit code 1

`@developer-starts-container:1.4`
#### Scenario: --rebuild triggers a fresh build before starting

- When the developer runs `agentcontainer up --rebuild`
- Then the system SHALL call `cmd_build()` before checking image existence

---

`@developer-starts-container:2`
### Rule: Apple Container startup SHALL use custom mount and resource handling

`@developer-starts-container:2.1`
#### Scenario: Apple Container uses custom startup instead of devcontainer up

- Given the detected runtime is apple-container
- When the developer runs `agentcontainer up`
- Then the system SHALL call `start_apple_container()` instead of `devcontainer up`

`@developer-starts-container:2.2`
#### Scenario: Mount parsing from devcontainer.json

- Given devcontainer.json contains bind and volume mount definitions
- When `start_apple_container()` parses mounts
- Then the system SHALL substitute `${localWorkspaceFolder}` with the current directory
- And the system SHALL create named volumes before mounting them

`@developer-starts-container:2.3`
#### Scenario: Memory below 200 MiB rejected on Apple Container

- Given devcontainer.json specifies `--memory=100m` in runArgs
- When `start_apple_container()` validates resource limits
- Then the system SHALL log an error about the 200 MiB minimum and return exit code 1

`@developer-starts-container:2.4`
#### Scenario Outline: Memory value parsing accepts multiple units

- Given devcontainer.json specifies `--memory=<value>` in runArgs
- When `start_apple_container()` validates the memory value
- Then the system SHALL interpret the value as `<mib>` MiB

##### Examples

| value | mib |
|-------|-----|
| 4g | 4096 |
| 512m | 512 |
| 1073741824 | 1024 |

---

`@developer-starts-container:3`
### Rule: Apple Container startup SHALL sync UID/GID for non-root users

`@developer-starts-container:3.1`
#### Scenario: UID/GID sync for non-root remoteUser

- Given devcontainer.json specifies `remoteUser` as "vscode" and `updateRemoteUserUID` as true
- When `start_apple_container()` creates the container
- Then the system SHALL run `groupmod` and `usermod` inside the container to match host UID/GID
- And the system SHALL fix home directory ownership with `chown`

`@developer-starts-container:3.2`
#### Scenario: UID/GID sync skipped for root user

- Given devcontainer.json specifies `remoteUser` as "root"
- When `start_apple_container()` creates the container
- Then the system SHALL skip the UID/GID sync step

`@developer-starts-container:3.3`
#### Scenario: UID/GID sync failure is non-fatal

- Given the `usermod` command fails inside the container
- When `start_apple_container()` attempts UID/GID sync
- Then the system SHALL log a warning but continue startup

---

`@developer-starts-container:4`
### Rule: Post-creation setup SHALL execute entrypoints and commands non-fatally

`@developer-starts-container:4.1`
#### Scenario: Feature entrypoints executed after container creation

- Given the container image contains scripts at `/usr/local/share/*-entrypoint.sh`
- When `start_apple_container()` completes container creation
- Then the system SHALL execute each entrypoint script
- And entrypoint failures SHALL NOT prevent container startup

`@developer-starts-container:4.2`
#### Scenario: postCreateCommand executed from devcontainer.json

- Given devcontainer.json specifies a `postCreateCommand`
- When `start_apple_container()` completes container creation
- Then the system SHALL execute the `postCreateCommand` inside the container
- And command failure SHALL NOT prevent container startup
