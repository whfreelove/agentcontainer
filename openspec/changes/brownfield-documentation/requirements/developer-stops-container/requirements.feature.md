# Feature: Container stop and removal (developer-stops-container)

## Requirements

`@developer-stops-container:1`
### Rule: Stop SHALL halt running containers and succeed silently when none exist

`@developer-stops-container:1.1`
#### Scenario: Stop halts a running container

- Given a container for the project is running
- When the developer runs `agentcontainer stop`
- Then the system SHALL issue a stop command to the container runtime
- And the container SHALL transition to stopped state

`@developer-stops-container:1.2`
#### Scenario: Stop with no running container returns success

- Given no running container exists for the project
- When the developer runs `agentcontainer stop`
- Then the system SHALL log a warning and return exit code 0

---

`@developer-stops-container:2`
### Rule: Down SHALL force-remove containers in any state and succeed when none exist

`@developer-stops-container:2.1`
#### Scenario: Down removes a running container

- Given a container for the project is running
- When the developer runs `agentcontainer down`
- Then the system SHALL force-remove the container with `rm -f`

`@developer-stops-container:2.2`
#### Scenario: Down removes a stopped container

- Given a container for the project exists but is stopped
- When the developer runs `agentcontainer down`
- Then the system SHALL find the stopped container using `-a` flag and force-remove it

`@developer-stops-container:2.3`
#### Scenario: Down with no container returns success

- Given no container exists for the project in any state
- When the developer runs `agentcontainer down`
- Then the system SHALL log an info message and return exit code 0
