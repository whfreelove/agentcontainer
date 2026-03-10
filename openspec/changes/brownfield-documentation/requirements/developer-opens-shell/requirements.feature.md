# Feature: Shell access (developer-opens-shell)

## Requirements

`@developer-opens-shell:1`
### Rule: Shell profile SHALL resolve from custom profiles then fall back to built-in names

`@developer-opens-shell:1.1`
#### Scenario: Shell resolved from shell-profiles.json

- Given `.agentcontainer/shell-profiles.json` contains `{"zsh-login": {"path": "/bin/zsh", "args": ["-l"]}}`
- When the developer runs `agentcontainer shell --shell zsh-login`
- Then the system SHALL exec into the container with `/bin/zsh -l`

`@developer-opens-shell:1.2`
#### Scenario: Unknown profile name used as shell executable

- Given `.agentcontainer/shell-profiles.json` does not contain a "fish" profile
- When the developer runs `agentcontainer shell --shell fish`
- Then the system SHALL exec into the container with `fish` as the shell command

`@developer-opens-shell:1.3`
#### Scenario: No --shell flag uses DEFAULT_SHELL from config

- Given `DEFAULT_SHELL` is set to `zsh` in `agentcontainer.conf`
- And no `--shell` flag is provided
- When the developer runs `agentcontainer shell`
- Then the system SHALL resolve the shell profile using `zsh`

---

`@developer-opens-shell:2`
### Rule: Shell flags SHALL control user, command, and profile selection

`@developer-opens-shell:2.1`
#### Scenario: --exec bypasses profile resolution

- When the developer runs `agentcontainer shell --exec /usr/bin/python3`
- Then the system SHALL exec `/usr/bin/python3` directly without shell profile lookup

`@developer-opens-shell:2.2`
#### Scenario: --root is shorthand for --user root

- When the developer runs `agentcontainer shell --root`
- Then the system SHALL exec into the container as user `root`

`@developer-opens-shell:2.3`
#### Scenario: Positional arguments treated as command

- When the developer runs `agentcontainer shell ls -la`
- Then the system SHALL exec `ls -la` inside the container

---

`@developer-opens-shell:3`
### Rule: Shell exec SHALL use remoteUser from devcontainer.json as default user

`@developer-opens-shell:3.1`
#### Scenario: remoteUser applied when no --user specified

- Given devcontainer.json specifies `"remoteUser": "vscode"`
- And no `--user` flag is provided
- When the developer runs `agentcontainer shell`
- Then the system SHALL pass `--user vscode` to the container exec command

`@developer-opens-shell:3.2`
#### Scenario: TTY detection controls interactive flags

- Given stdin is a TTY and stdout is a TTY
- When the developer runs `agentcontainer shell`
- Then the system SHALL pass `-i` and `-t` flags to the container exec command
