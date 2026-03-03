# CI/CD

CI runs on every push and PR to `main` via GitHub Actions (`.github/workflows/ci.yml`).

## Jobs

| Job | Runner | What it does |
|-----|--------|--------------|
| **Lint** | `ubuntu-latest` | ShellCheck + `bash -n` syntax validation |
| **Linux** | `ubuntu-latest` | Integration tests across Docker, Podman, nerdctl (amd64 + arm64) |
| **Windows** | `windows-latest` | Lint and syntax checks (no container runtime available) |
| **macOS** | `self-hosted, macOS, ARM64` | Integration tests for Lima and Apple Container |

## macOS CI

The macOS jobs require a **self-hosted Apple Silicon runner** because both Lima (VZ driver) and Apple Container depend on Virtualization.framework, which is unavailable on GitHub-hosted macOS VMs (no nested virtualization).

### Enabling macOS CI

macOS CI is **disabled by default** and gated behind a repository variable. To enable it after registering a self-hosted runner:

1. Register a self-hosted runner with labels `self-hosted`, `macOS`, `ARM64`
2. Enable the jobs:

```bash
gh variable set MACOS_RUNNER --body true
```

### Disabling macOS CI

```bash
gh variable delete MACOS_RUNNER
```

When disabled, the macOS jobs are skipped entirely — they won't appear in the workflow run.

### Why not GitHub-hosted macOS runners?

GitHub's `macos-*` runners are ARM64 VMs, which means:

- **Lima/VZ** needs Virtualization.framework — unavailable (nested virt)
- **Lima/QEMU+HVF** needs Hypervisor.framework — unavailable ([actions/runner-images#9460](https://github.com/actions/runner-images/issues/9460))
- **Lima/QEMU+TCG** works but is prohibitively slow (full software emulation)
- **Apple Container** needs Virtualization.framework — same issue

A self-hosted runner on real Apple Silicon hardware has full access to these frameworks.

### Self-hosted runner cleanup

The macOS job includes a cleanup step that runs after every build (even on failure) to prevent state accumulation on the persistent self-hosted runner:

- Force-stops and deletes all Lima VMs
- Removes `/tmp/ci-test-project`
