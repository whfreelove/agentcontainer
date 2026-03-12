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
| nerdctl | nerdctl |

`@developer-builds-container:1.3`
#### Scenario: Lima build uses nerdctl.lima when available on PATH

- Given the detected runtime is lima
- And `nerdctl.lima` is available on PATH
- When the developer runs `agentcontainer build`
- Then the system SHALL invoke `devcontainer build` with `--docker-path nerdctl.lima`

`@developer-builds-container:1.4`
#### Scenario: Lima build uses a wrapper script when nerdctl.lima is not on PATH

- Given the detected runtime is lima
- And `nerdctl.lima` is not available on PATH
- When the developer runs `agentcontainer build`
- Then the system SHALL create a wrapper script that delegates to `lima nerdctl`
- And SHALL invoke `devcontainer build` with `--docker-path` set to the wrapper script path

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
- When the developer runs `agentcontainer build`
- Then the system SHALL select "<available_runtime>" as the build runtime

##### Examples

| available_runtime |
|-------------------|
| lima |
| docker |
| nerdctl |
| podman |

`@developer-builds-container:3.2`
#### Scenario Outline: Image transfer from fallback runtime to Apple Container

- Given the system built an image using "<fallback_runtime>" as fallback runtime
- When the build completes
- Then the system SHALL pipe `<save_command>` into `container image load`
- And the image SHALL be available in the Apple Container registry

##### Examples

| fallback_runtime | save_command |
|------------------|--------------|
| docker | docker save |
| lima | lima nerdctl save |

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

`@developer-builds-container:3.5`
#### Scenario Outline: Image transfer fails for unsupported fallback runtimes

- Given the system built an image using "<unsupported_runtime>" as fallback runtime
- When the transfer step runs
- Then the system SHALL log a warning that "<unsupported_runtime>" does not support image transfer to Apple Container and return exit code 1

##### Examples

| unsupported_runtime |
|---------------------|
| nerdctl |
| podman |
