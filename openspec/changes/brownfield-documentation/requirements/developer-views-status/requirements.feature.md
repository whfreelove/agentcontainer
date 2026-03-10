# Feature: Status display (developer-views-status)

## Requirements

`@developer-views-status:1`
### Rule: Status SHALL display runtime detection results

`@developer-views-status:1.1`
#### Scenario: Status prints platform and runtime information

- When the developer runs `agentcontainer status`
- Then the system SHALL display the detected platform, runtime name, container command, and availability status

`@developer-views-status:1.2`
#### Scenario: Status reports runtime as unavailable when check fails

- Given the detected runtime CLI is not functional
- When the developer runs `agentcontainer status`
- Then the system SHALL display the runtime status as "not available"

---

`@developer-views-status:2`
### Rule: Status SHALL display project configuration when initialized

`@developer-views-status:2.1`
#### Scenario: Status shows config when project is initialized

- Given `.agentcontainer/agentcontainer.conf` exists
- When the developer runs `agentcontainer status`
- Then the system SHALL display all project and local configuration values

`@developer-views-status:2.2`
#### Scenario: Status omits config section for uninitialized projects

- Given `.agentcontainer/agentcontainer.conf` does not exist
- When the developer runs `agentcontainer status`
- Then the system SHALL display only runtime information without configuration values
