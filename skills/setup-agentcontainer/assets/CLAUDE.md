# Container Environment

You are running inside an agentcontainer for **{{PROJECT_NAME}}**.

Workspace: `{{WORKSPACE_FOLDER}}`

## Key facts

- The workspace is a bind mount from the host. File changes are reflected immediately.
- Resource limits (memory, CPU, PIDs) are enforced by the container runtime.
- Network access may be restricted — see `.claude/settings.json` for denied domains.
- `.claude/` is managed by agentcontainer. Do not modify `settings.json` or `hooks/`.
- To add OS packages permanently, edit `.agentcontainer/setup.sh` and tell the user to rebuild. Do not `sudo apt-get install` ad-hoc — it won't survive container restarts.
