# Feature: Platform and runtime detection (runtime-detects-platform)

## Requirements

`@runtime-detects-platform:1`
### Rule: Platform detection SHALL distinguish macOS, Linux, WSL, and unknown

`@runtime-detects-platform:1.1`
#### Scenario Outline: Platform identified from system markers

- Given the system reports `uname -s` as "<uname>" and /proc/version contains "<proc_content>"
- When `detect_platform()` runs
- Then the platform SHALL be identified as "<platform>"

##### Examples

| uname | proc_content | platform |
|-------|--------------|----------|
| Darwin | n/a | darwin |
| Linux | Ubuntu 24.04 | linux |
| Linux | microsoft-standard-WSL2 | wsl |

`@runtime-detects-platform:1.2`
#### Scenario: Unknown uname returns unknown platform

- Given the system reports an unrecognized `uname -s` value
- When `detect_platform()` runs
- Then the platform SHALL be identified as "unknown"

---

`@runtime-detects-platform:2`
### Rule: Runtime detection SHALL respect overrides then probe in priority order

`@runtime-detects-platform:2.1`
#### Scenario: CONTAINER_RUNTIME override takes precedence on any platform

- Given `CONTAINER_RUNTIME` is set to "podman" in configuration
- When `detect_runtime()` runs on any platform
- Then the runtime SHALL be "podman" regardless of what is installed

`@runtime-detects-platform:2.2`
#### Scenario: MACOS_RUNTIME override takes precedence on darwin

- Given the platform is "darwin" and `MACOS_RUNTIME` is set to "docker"
- When `detect_runtime()` runs
- Then the runtime SHALL be "docker" regardless of the probe chain

`@runtime-detects-platform:2.3`
#### Scenario Outline: macOS runtime probe priority

- Given the platform is "darwin" and `MACOS_RUNTIME` is set to "auto" (the default)
- And "<available>" is the first available runtime CLI
- When `detect_runtime()` runs
- Then the runtime SHALL be "<detected>"

##### Examples

| available | detected |
|-----------|----------|
| container | apple-container |
| lima nerdctl | lima |
| docker | docker |
| none | none |

`@runtime-detects-platform:2.4`
#### Scenario Outline: Linux/WSL runtime probe priority

- Given the platform is "linux" and no overrides are set
- And "<available>" is the first available runtime CLI
- When `detect_runtime()` runs
- Then the runtime SHALL be "<detected>"

##### Examples

| available | detected |
|-----------|----------|
| nerdctl | nerdctl |
| podman | podman |
| ctr | containerd |
| docker | docker |
| none | none |

---

`@runtime-detects-platform:3`
### Rule: Runtime utilities SHALL map names to commands and socket paths

`@runtime-detects-platform:3.1`
#### Scenario Outline: Runtime name mapped to CLI command

- Given the detected runtime is "<runtime>"
- When `get_container_cmd()` is called
- Then the command SHALL be "<command>"

##### Examples

| runtime | command |
|---------|---------|
| apple-container | container |
| lima | lima nerdctl |
| nerdctl | nerdctl |
| podman | podman |
| containerd | ctr |
| docker | docker |

`@runtime-detects-platform:3.2`
#### Scenario Outline: Docker socket path resolved per runtime and platform

- Given the runtime is "<runtime>" and the platform is "<platform>"
- When `get_docker_socket()` is called
- Then the socket path SHALL be "<socket>"

##### Examples

| runtime | platform | socket |
|---------|----------|--------|
| docker | darwin | ~/.docker/run/docker.sock |
| docker | linux | /var/run/docker.sock |
| docker | wsl | /var/run/docker.sock |
| podman | linux | /run/user/{uid}/podman/podman.sock |
| lima | darwin | ~/.lima/default/sock/nerdctl.sock |

> **Note:** `{uid}` is the numeric user ID of the invoking user, as returned by `id -u`. The Podman socket path is user-specific and cannot be expressed as a single concrete literal.

`@runtime-detects-platform:3.3`
#### Scenario: Runtime availability validated via version command

- Given the detected runtime command is available on PATH
- When `check_runtime()` is called
- Then the system SHALL execute the runtime's version command and return exit code 0
