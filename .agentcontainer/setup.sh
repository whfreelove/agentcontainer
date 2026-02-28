#!/usr/bin/env bash
#
# Container setup script
# Runs once after container creation (postCreateCommand)
#

set -euo pipefail

echo "=== Setting up agentcontainer ==="

# Fix ownership of Claude auth volume for non-root users
if [[ "$(id -u)" != "0" && -d "$HOME/.claude" ]]; then
    sudo chown -R "$(id -u):$(id -g)" "$HOME/.claude" 2>/dev/null || true
fi

# Run project setup script if configured
_setup=""
if [[ -n "$_setup" ]]; then
    if [[ -x "$_setup" ]]; then
        echo "Running $_setup..."
        "$_setup"
    elif [[ -f "$_setup" ]]; then
        echo "Running $_setup..."
        bash "$_setup"
    else
        echo "Warning: Setup script not found: $_setup" >&2
    fi
fi

# === Add custom commands below ===

echo "=== Setup complete ==="
