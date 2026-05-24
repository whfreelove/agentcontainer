# Environment Detection Tables

## Markers to Base Image

| Marker files | Language | Base image |
|---|---|---|
| `pyproject.toml`, `requirements.txt`, `setup.py` | Python | `mcr.microsoft.com/devcontainers/python:<ver>` |
| `package.json`, `.nvmrc` | Node.js | `mcr.microsoft.com/devcontainers/javascript-node:<ver>` |
| `Cargo.toml`, `rust-toolchain.toml` | Rust | `mcr.microsoft.com/devcontainers/rust:1` |
| `go.mod` | Go | `mcr.microsoft.com/devcontainers/go:<ver>` |
| `Gemfile` | Ruby | `mcr.microsoft.com/devcontainers/ruby:<ver>` |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | Java/JVM | `mcr.microsoft.com/devcontainers/java:<ver>` |
| `CMakeLists.txt`, `Makefile`, `*.cpp`, `*.c`, `meson.build` | C/C++ | `mcr.microsoft.com/devcontainers/cpp:<ver>` |
| `*.nix`, `flake.nix` | Nix | `mcr.microsoft.com/devcontainers/base:ubuntu` |
| `Dockerfile`, `docker-compose.yml` | Containers | Note existing setup, ask user |
| None of the above | Unknown | `mcr.microsoft.com/devcontainers/base:ubuntu` |

For multi-language projects, use the primary language for the base image and add the secondary as a devcontainer feature.

## Markers to Features

| Marker | Feature URI |
|---|---|
| `*.nix`, `flake.nix` | `ghcr.io/devcontainers/features/nix:1` |
| `CMakeLists.txt` | `ghcr.io/devcontainers/features/cmake:1` |
| `--agent claude-code` | `ghcr.io/anthropics/devcontainer-features/claude-code:1` (auto-added by init) |

**Note:** `--agent claude-code` also auto-adds `ghcr.io/devcontainers/features/node:1` with version 20. Do not duplicate.

Prefer official features from `ghcr.io/devcontainers/features/` first. For tools not in the official set, offer to search the devcontainer registry online before suggesting community features. Do not hardcode community feature URIs — they go stale.

## Version Pinning Sources

| Language | Source | Field/directive |
|---|---|---|
| Python | `pyproject.toml` | `requires-python` |
| Node.js | `package.json` | `engines.node` |
| Node.js | `.nvmrc` | file content |
| Rust | `rust-toolchain.toml` | `[toolchain] channel` |
| Go | `go.mod` | `go` directive |
| Ruby | `.ruby-version` | file content |
| Java | `pom.xml` | `<maven.compiler.source>` or `<java.version>` |

Extract the major (or major.minor) version. Use it as the image tag: e.g. `python:3.12`, `javascript-node:20`.

## Dependency to OS Packages

| Dependency / pattern | OS packages (apt) |
|---|---|
| `psycopg2` (Python) | `libpq-dev` |
| `Pillow` (Python) | `libjpeg-dev zlib1g-dev libpng-dev` |
| `lxml` (Python) | `libxml2-dev libxslt1-dev` |
| `cryptography`, `pyOpenSSL` | `libssl-dev libffi-dev` |
| `bcrypt` | `libffi-dev` |
| `mysqlclient` (Python) | `default-libmysqlclient-dev` |
| `sharp` (Node.js) | `libvips-dev` |
| `canvas` (Node.js) | `libcairo2-dev libjpeg-dev libpango1.0-dev libgif-dev librsvg2-dev` |
| `sqlite3` / `better-sqlite3` | `libsqlite3-dev` |
| `pg` (Node.js) | `libpq-dev` |

This table covers common cases. For unlisted dependencies, check the library's documentation for system requirements.

## Base Image to Package Manager

| Base image pattern | Package manager | Install command |
|---|---|---|
| `*ubuntu*`, `*debian*`, `devcontainers/python`, `devcontainers/javascript-node`, `devcontainers/rust`, `devcontainers/go`, `devcontainers/ruby`, `devcontainers/java`, `devcontainers/cpp`, `devcontainers/base` | apt | `sudo apt-get update && sudo apt-get install -y <packages>` |
| `*alpine*` | apk | `sudo apk add --no-cache <packages>` |
| `*fedora*`, `*rhel*`, `*centos*` | dnf | `sudo dnf install -y <packages>` |

Most `mcr.microsoft.com/devcontainers/` images are Debian/Ubuntu-based and use apt.
