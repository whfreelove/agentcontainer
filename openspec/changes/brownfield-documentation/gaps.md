# Gaps

<!-- GAP TEMPLATE:
### GAP-XX: Title
- **Source**: <kebab-case with type suffix, e.g., functional-critic, implicit-detection>
- **Severity**: high|medium|low
- **Description**: ...
- **Triage**: check-in|delegate|defer-release|defer-resolution (added by resolve workflow)
- **Decision**: ... (added by resolve workflow)

CRITIQUE adds: ID, Source, Severity, Description
RESOLVE adds: Triage, Decision

New gaps from critique should NOT have Triage or Decision fields.

See tokamak:managing-spec-gaps for triage and status semantics.
-->

### GAP-54: GAP-47 Risk entry approved for technical.md was not applied
- **Source**: placement-drift-detection
- **Severity**: medium
- **Description**: Resolution of GAP-47 correctly removed a design recommendation from infra.md but did not apply the corresponding Risk entry to technical.md. The GAP-47 Decision explicitly mandated adding a Risk entry: 'detect_platform() hardcodes /proc/version, limiting WSL detection unit testing to environments with a real /proc/version file → Making the version file path an injectable parameter would enable mock-based testing on plain Linux CI runners without requiring a WSL environment.' The Outcome acknowledges the omission ('The removed design recommendation belongs in technical.md as a Risk entry (not modified here per single-file constraint)'). technical.md Risks currently has 3 entries; the /proc/version hardcoding risk is absent. An approved Decision that mandates a specific artifact change was only half-executed — the removal from infra.md was applied, but the placement in technical.md was not.
- **Triage**: delegate
- **Decision**: Apply the Risk entry approved in GAP-47's Decision to technical.md Risks section, completing the half-executed resolution. Add as fourth bullet: '**`detect_platform()` hardcodes `/proc/version`, limiting WSL detection unit testing to environments with a real `/proc/version` file** → Making the version file path an injectable parameter would enable mock-based testing on plain Linux CI runners without requiring a WSL environment.'
- **Primary-file**: technical.md

### GAP-55: setup.sh location contradicts between requirements and technical spec
- **Source**: implicit-gap-detection
- **Severity**: medium
- **Description**: Source: implicit-detection. @developer-initializes-project:1.1 states 'the system SHALL create `.agentcontainer/` with `agentcontainer.conf`, `local.conf`, `setup.sh`, and `.gitignore`' — placing setup.sh inside `.agentcontainer/`. This is reinforced by scenario 2.2's Given clause which lists setup.sh alongside agentcontainer.conf and local.conf under `.agentcontainer/`. However, CMP-setup-script in technical.md explicitly states 'lib/templates/setup.sh.tmpl → .devcontainer/setup.sh', placing the generated file in `.devcontainer/`. These are contradictory locations. An implementor following the requirements would generate setup.sh at `.agentcontainer/setup.sh`, but the devcontainer.json template (which references setup.sh for postCreateCommand) would reference `.devcontainer/setup.sh` per the technical spec, causing postCreateCommand to fail with a file-not-found error. The technical spec is internally consistent (CMP-setup-script path matches what the devcontainer.json template would reference), suggesting the requirements spec has the wrong directory.
- **Triage**: delegate
- **Decision**: Fix the documentation error in CMP-setup-script. The output path SHALL read 'lib/templates/setup.sh.tmpl → .agentcontainer/setup.sh' to match both the requirements (@developer-initializes-project:1.1) and the implementation (init.sh generates setup.sh to .agentcontainer/, devcontainer.json references 'bash .agentcontainer/setup.sh' in postCreateCommand). The .devcontainer/ path was a transcription error.
- **Primary-file**: technical.md

### GAP-56: Agent exec omits container user context
- **Source**: implicit-gap-detection
- **Severity**: medium
- **Description**: Source: implicit-detection. developer-runs-agent requirements specify TTY detection flags (Rule 3: -i, -t) and argument composition (Rule 2) for the container exec command, but include no rule specifying which user the agent runs as inside the container. The shell command (developer-opens-shell Rule 3, scenario 3.1) explicitly requires remoteUser from devcontainer.json as the default exec user via --user. The technical spec (CMP-entry-point) describes agent-exec as sourcing shell.sh 'for find_project_container()' and composing arguments, with no mention of user context. An implementor building agent-exec could reasonably omit --user from the exec command, defaulting to the container's root user. Running the agent as root instead of remoteUser would cause auth credential permission mismatches (setup.sh fixes ownership for remoteUser, not root) and workspace files created by the agent would be root-owned, inaccessible to the remoteUser in subsequent shell sessions.
- **Triage**: delegate
- **Decision**: Add Rule 4 to developer-runs-agent: 'Agent exec SHALL use remoteUser from devcontainer.json as default user' with a scenario mirroring developer-opens-shell:3.1 (Given devcontainer.json specifies remoteUser, Then --user SHALL be passed to container exec). Update CMP-entry-point description in technical.md to include 'Reads remoteUser from devcontainer.json' and 'sets --user' alongside the existing TTY detection and argument composition responsibilities. This makes both the capability requirements and technical component description self-consistent with the implementation and with the parallel shell command documentation.
- **Primary-file**: requirements/developer-runs-agent/requirements.feature.md

### GAP-57: FEATURES config variable exported but unconsumed
- **Source**: implicit-gap-detection
- **Severity**: medium
- **Description**: Source: implicit-detection. CMP-config-loader exports FEATURES as one of 13 configuration variables (project-tier). CMP-init-command parses a --features flag. But no component describes how FEATURES is consumed: build_features_json() in CMP-template-engine 'converts AGENTS shorthand names (e.g., claude-code) to devcontainer feature URIs' — it operates on AGENTS, not FEATURES. No other component's responsibilities reference FEATURES. An implementor building the template engine or devcontainer.json generation cannot determine whether FEATURES provides additional raw devcontainer feature URIs that augment build_features_json() output, replaces AGENTS as the feature source, or is dead config. Getting this wrong produces an incorrect features array in devcontainer.json — either missing user-specified features (if FEATURES is ignored) or duplicating/conflicting with agent features (if FEATURES is misused).
- **Triage**: delegate
- **Decision**: Update CMP-template-engine responsibilities to document that build_features_json() processes both AGENTS (shorthand-to-URI conversion) and FEATURES (raw URI pass-through for ghcr.io/* and docker.io/* patterns; non-URI values silently ignored). Add a Known Risk in functional.md noting the README incorrectly documents FEATURES as accepting agent shorthand names alongside URIs, while the implementation only passes through URI-shaped values.
- **Primary-file**: technical.md

### GAP-59: GAP-48 Rule 4 missing from infra.md coverage
- **Source**: cross-artifact-propagation-detection
- **Severity**: medium
- **Description**: Resolution of GAP-48 added Rule 4 (@agent-auth-persists:4) with three backup-file glob discovery scenarios (4.1–4.3), but infra.md coverage table and coverage gaps still only reference Rules 1–3. Rule 4 has the same testability profile as Rule 3 (testable within a single container lifecycle) and should be acknowledged in both the coverage table entry ('Partially testable: Rule 3 symlink scenarios...') and the coverage gaps bullet.
- **Triage**: delegate
- **Decision**: Update infra.md coverage table entry and coverage gaps bullet to reference Rules 3–4 (not just Rule 3) as testable within a single container lifecycle. Rule 4 (backup file glob discovery) has the same testability profile as Rule 3 (primary auth file symlink creation) — both involve file moves and symlink verification that can be validated within init → build → up → verify. Change 'Rule 3 symlink scenarios' to 'Rules 3–4 symlink scenarios' in the table, and expand the coverage gaps prose to include Rule 4's backup file scenarios alongside Rule 3's primary file scenarios.
- **Primary-file**: infra.md

### GAP-60: GAP-15 introduced wrapper-script mechanism Then clause in builds-container:1.4
- **Source**: resolution-normative-detection
- **Severity**: medium
- **Description**: Resolution of GAP-15 added scenario @developer-builds-container:1.4 whose first Then clause reads 'the system SHALL create a wrapper script that delegates to `lima nerdctl`'. This specifies the implementation mechanism (how the lima nerdctl docker-path is produced) rather than an observable outcome. GAP-52 identified and removed the identical anti-pattern from scenario 3.2 ('the system SHALL pipe `<save_command>` into `container image load`') for the same reason: mechanism Then clauses couple the spec to implementation details and are not independently testable. The And clause 'SHALL invoke `devcontainer build` with `--docker-path` set to the wrapper script path' also imports this coupling — 'the wrapper script path' is only meaningful relative to the first clause. Both should be replaced by a single observable assertion, e.g. 'Then the system SHALL invoke `devcontainer build` with `--docker-path` set to a path that executes `lima nerdctl`'. File: requirements/developer-builds-container/requirements.feature.md, scenario 1.4.
- **Triage**: delegate
- **Decision**: Replace the two mechanism-specifying Then clauses in @developer-builds-container:1.4 with a single observable assertion: 'Then the system SHALL invoke `devcontainer build` with `--docker-path` set to a path that executes `lima nerdctl`'. Update the scenario title to 'Lima build delegates to lima nerdctl when nerdctl.lima is not on PATH'. This follows the GAP-52 precedent: mechanism details (wrapper script creation) belong in technical.md CMP-build-command, not in behavioral requirements.
- **Primary-file**: requirements/developer-builds-container/requirements.feature.md

### GAP-61: GAP-48 introduced process-sequencing language in agent-auth-persists:4.3 Then clause
- **Source**: resolution-normative-detection
- **Severity**: medium
- **Description**: Resolution of GAP-48 added scenario @agent-auth-persists:4.3 whose second Then clause reads 'the combined set of discovered files SHALL be deduplicated by filename before processing'. The phrase 'before processing' is implementation-sequencing language — it describes the order of internal steps rather than an observable final state. A test cannot verify 'before processing' without white-box access to the deduplication step; it can only verify that no filename appears twice in the volume after setup.sh runs. The clause should assert the observable outcome, e.g. 'each unique backup filename SHALL appear exactly once in the named volume directory'. The first Then clause 'the system SHALL process backup files from both directories' is also vague — 'process' is an internal verb with no defined observable meaning; the testable outcome is the resulting symlink or volume-copy state. File: requirements/agent-auth-persists/requirements.feature.md, scenario 4.3.
- **Triage**: delegate
- **Decision**: Replace the two non-observable Then clauses in @agent-auth-persists:4.3 with observable filesystem-state assertions: 'Then each unique backup filename SHALL appear exactly once in the named volume directory `$HOME/.claude`' / 'And a symlink SHALL exist from `$HOME/<filename>` to the corresponding volume copy for each discovered backup file'. This replaces the internal verb 'process' and the sequencing language 'before processing' with verifiable final state. Deduplication is asserted by the uniqueness requirement on volume contents.
- **Primary-file**: requirements/agent-auth-persists/requirements.feature.md
