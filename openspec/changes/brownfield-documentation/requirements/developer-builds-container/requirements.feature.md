# Feature: Container image building (developer-builds-container)

## Requirements

`@developer-builds-container:1`
### Rule: Build SHALL delegate to devcontainer CLI with the runtime-appropriate docker-path

#### Background

- Given the project has been initialized with `agentcontainer init`

`@developer-builds-container:1.1`
#### Scenario Outline: Build uses correct docker-path per runtime

- Given the detected runtime is "<runtime>"
- When the developer runs `agentcontainer build`
- Then the system SHALL invoke `devcontainer build` with `--docker-path <docker_path>`

##### Examples

| runtime | docker_path |
|---------|-------------|
| docker | docker |
| podman | podman |
| lima | nerdctl.lima or wrapper |
| nerdctl | nerdctl |

`@developer-builds-container:1.2`
#### Scenario: Build passes --no-cache to devcontainer CLI

- Given the detected runtime is docker
- When the developer runs `agentcontainer build --no-cache`
- Then the system SHALL pass `--no-cache` to the `devcontainer build` command

---

`@developer-builds-container:2`
### Rule: Apple Container build SHALL attempt native builder before falling back

`@developer-builds-container:2.1`
#### Scenario: Native build when builder daemon is available

- Given the detected runtime is apple-container
- And `AC_BUILD_USE_SHIM` is not set or is "1"
- And the Apple Container builder daemon is running
- When the developer runs `agentcontainer build`
- Then the system SHALL use `apple-container-shim.sh` as `--docker-path`

`@developer-builds-container:2.2`
#### Scenario: Builder daemon started on demand

- Given the detected runtime is apple-container
- And the builder daemon is not running but can be started
- When the developer runs `agentcontainer build`
- Then the system SHALL attempt `container builder start`
- And SHALL use native build if start succeeds

`@developer-builds-container:2.3`
#### Scenario: Native build disabled by AC_BUILD_USE_SHIM=0

- Given the detected runtime is apple-container
- And `AC_BUILD_USE_SHIM` is set to "0"
- When the developer runs `agentcontainer build`
- Then the system SHALL skip native builder check and use a fallback runtime

---

`@developer-builds-container:3`
### Rule: Fallback build SHALL transfer images to Apple Container registry

`@developer-builds-container:3.1`
#### Scenario Outline: Fallback runtime selection priority

- Given the detected runtime is apple-container
- And the native builder is unavailable
- And "<available_runtime>" is installed
- When the system calls `find_build_runtime()`
- Then the system SHALL select "<available_runtime>" as the build runtime

##### Examples

| available_runtime |
|-------------------|
| lima |
| docker |
| nerdctl |
| podman |

`@developer-builds-container:3.2`
#### Scenario: Image transfer from fallback runtime to Apple Container

- Given the system built an image using docker as fallback runtime
- When the build completes
- Then the system SHALL pipe `docker save` into `container image load`
- And the image SHALL be available in the Apple Container registry

`@developer-builds-container:3.3`
#### Scenario: Image transfer skipped when image already exists

- Given the system built an image using a fallback runtime
- And the image already exists in the Apple Container registry
- When the transfer step runs
- Then the system SHALL skip the image transfer

`@developer-builds-container:3.4`
#### Scenario: No fallback runtime available

- Given the detected runtime is apple-container
- And the native builder is unavailable
- And no Docker-compatible runtime is installed
- When the developer runs `agentcontainer build`
- Then the system SHALL log an error and return exit code 1
