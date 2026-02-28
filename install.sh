#!/usr/bin/env bash
#
# Agentcontainer installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/whfreelove/agentcontainer/main/install.sh | bash
#
# Or with a specific version:
#   curl -fsSL https://raw.githubusercontent.com/whfreelove/agentcontainer/main/install.sh | bash -s -- --version v0.1.0
#

set -euo pipefail

VERSION="${AGENTCONTAINER_VERSION:-latest}"
INSTALL_DIR="${AGENTCONTAINER_INSTALL_DIR:-$HOME/.local/bin}"
REPO="whfreelove/agentcontainer"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[info]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[ok]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[warn]${NC} $*" >&2; }
log_error() { echo -e "${RED}[error]${NC} $*" >&2; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version|-v)
            VERSION="$2"
            shift 2
            ;;
        --dir|-d)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --help|-h)
            cat <<EOF
Agentcontainer Installer

Usage: install.sh [options]

Options:
    -v, --version VERSION   Install specific version (default: latest)
    -d, --dir DIR           Installation directory (default: ~/.local/bin)
    -h, --help              Show this help

Environment variables:
    AGENTCONTAINER_VERSION     Version to install
    AGENTCONTAINER_INSTALL_DIR Installation directory
EOF
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Detect platform
detect_platform() {
    local os arch

    case "$(uname -s)" in
        Darwin) os="darwin" ;;
        Linux)  os="linux" ;;
        *)
            log_error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *)
            log_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac

    echo "${os}-${arch}"
}

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        missing+=("curl or wget")
    fi

    if ! command -v tar &>/dev/null; then
        missing+=("tar")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

# Download file
download() {
    local url="$1"
    local output="$2"

    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$output"
    else
        wget -q "$url" -O "$output"
    fi
}

# Get latest version from GitHub
get_latest_version() {
    local api_url="https://api.github.com/repos/${REPO}/releases/latest"
    local version

    if command -v curl &>/dev/null; then
        version=$(curl -fsSL "$api_url" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        version=$(wget -qO- "$api_url" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    fi

    if [[ -z "$version" ]]; then
        log_error "Failed to get latest version"
        exit 1
    fi

    echo "$version"
}

# Main installation
main() {
    log_info "Installing agentcontainer..."

    check_dependencies

    local platform
    platform="$(detect_platform)"
    log_info "Detected platform: $platform"

    # Get version
    if [[ "$VERSION" == "latest" ]]; then
        log_info "Fetching latest version..."
        VERSION="$(get_latest_version)"
    fi
    log_info "Version: $VERSION"

    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # For now, install from source (git clone)
    # In the future, this would download a release tarball
    local temp_dir
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' EXIT

    log_info "Downloading agentcontainer..."

    local tarball_url="https://github.com/${REPO}/archive/refs/tags/${VERSION}.tar.gz"
    local tarball="$temp_dir/agentcontainer.tar.gz"

    # Try to download release, fall back to main branch
    if ! download "$tarball_url" "$tarball" 2>/dev/null; then
        log_warn "Release $VERSION not found, downloading from main branch..."
        tarball_url="https://github.com/${REPO}/archive/refs/heads/main.tar.gz"
        download "$tarball_url" "$tarball"
    fi

    log_info "Extracting..."
    tar -xzf "$tarball" -C "$temp_dir"

    # Find extracted directory
    local src_dir
    src_dir="$(find "$temp_dir" -maxdepth 1 -type d -name 'agentcontainer*' | head -1)"

    if [[ -z "$src_dir" ]]; then
        log_error "Failed to find extracted directory"
        exit 1
    fi

    # Install files
    log_info "Installing to $INSTALL_DIR..."

    # Create lib directory structure
    local lib_dir="$INSTALL_DIR/../lib/agentcontainer"
    mkdir -p "$lib_dir"

    # Copy library files
    cp -r "$src_dir/lib/"* "$lib_dir/"

    # Copy and patch main script
    sed "s|LIB_DIR=\"\$SCRIPT_DIR/../lib\"|LIB_DIR=\"$lib_dir\"|" \
        "$src_dir/bin/agentcontainer" > "$INSTALL_DIR/agentcontainer"
    chmod +x "$INSTALL_DIR/agentcontainer"

    log_ok "Installation complete!"
    echo

    # Check if install dir is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warn "$INSTALL_DIR is not in your PATH"
        echo
        echo "Add it to your shell profile:"
        echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
        echo "  # or for zsh:"
        echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
        echo
    fi

    echo "Run 'agentcontainer --help' to get started"
}

main "$@"
