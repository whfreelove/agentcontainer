# Feature: Agent execution (developer-runs-agent)

## Requirements

`@developer-runs-agent:1`
### Rule: Agent execution SHALL validate configuration before running

`@developer-runs-agent:1.1`
#### Scenario: Missing config file produces an error

- Given `.agentcontainer/agentcontainer.conf` does not exist
- When the developer runs `agentcontainer` without a subcommand
- Then the system SHALL log an error and return exit code 1

`@developer-runs-agent:1.2`
#### Scenario: Empty EXEC_AGENT produces an error with usage examples

- Given `agentcontainer.conf` exists but `EXEC_AGENT` is empty
- When the developer runs `agentcontainer`
- Then the system SHALL log an error with example values and return exit code 1

---

`@developer-runs-agent:2`
### Rule: Agent arguments SHALL be handled via placeholder or append

`@developer-runs-agent:2.1`
#### Scenario: Placeholder substitution with {}

- Given `EXEC_AGENT` is set to `nix-shell --run 'claude {}'`
- When the developer runs `agentcontainer -- --resume`
- Then the system SHALL replace `{}` with `--resume` in the command

`@developer-runs-agent:2.2`
#### Scenario: Argument appending when no placeholder

- Given `EXEC_AGENT` is set to `claude`
- When the developer runs `agentcontainer -- --resume`
- Then the system SHALL append `--resume` to the command as `claude --resume`

`@developer-runs-agent:2.3`
#### Scenario: No arguments leaves command unchanged

- Given `EXEC_AGENT` is set to `claude`
- When the developer runs `agentcontainer` with no arguments after `--`
- Then the system SHALL execute `claude` without modification

---

`@developer-runs-agent:3`
### Rule: Agent exec SHALL detect TTY and set appropriate flags

`@developer-runs-agent:3.1`
#### Scenario: Interactive TTY adds -i and -t flags

- Given stdin is a TTY and stdout is a TTY
- When the developer runs `agentcontainer`
- Then the system SHALL pass `-i` and `-t` flags to the container exec command

`@developer-runs-agent:3.2`
#### Scenario: Non-TTY stdin omits interactive flags

- Given stdin is not a TTY
- When `agentcontainer` is invoked via a pipe
- Then the system SHALL omit the `-i` flag from the container exec command
