#!/usr/bin/env bash
#
# Claude Code SessionStart hook
# Runs when Claude Code starts a new session
#

# Ensure PATH includes common tool locations
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Source project-specific environment if it exists
if [[ -f ".agentcontainer/env.sh" ]]; then
    source ".agentcontainer/env.sh"
fi
