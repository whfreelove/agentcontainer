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

### GAP-48: Auth credential file list not enumerated
- **Source**: implicit-gap-detection
- **Severity**: medium
- **Description**: Source: implicit-detection. Scenario @agent-auth-persists:3.1 says 'a credential file exists in the workspace (e.g. `.claude.json`)' — the 'e.g.' signals a non-exhaustive list without providing the actual list. CMP-setup-script in technical.md says 'Persists auth credential files by moving them into the named volume directory and creating symlinks' without enumerating which files. An implementor building setup.sh.tmpl cannot determine the complete set of credential files to iterate over. They could miss files (breaking auth persistence for some credentials) or include wrong files (moving non-credential data into the volume). Since auth persistence is the core mechanism of this capability, the file list is implementation-critical.
- **Triage**: delegate
- **Decision**: Enumerate the credential file set exhaustively in the specification. The auth credential files persisted by CMP-setup-script are: (1) `.claude.json` — the primary auth file, processed by name; (2) `.claude.json.backup.*` — timestamped backup files, discovered via glob pattern in both the workspace (`$HOME`) and volume (`$HOME/.claude`) directories. Remove 'e.g.' from @agent-auth-persists:3.1 and replace with direct `.claude.json` reference. Add a new Rule to agent-auth-persists covering backup file glob discovery. Update CMP-setup-script description and @integration:5.2 to reflect both patterns.
- **Primary-file**: requirements/agent-auth-persists/requirements.feature.md

### GAP-49: MACOS_RUNTIME 'auto' sentinel behavior undefined
- **Source**: implicit-gap-detection
- **Severity**: high
- **Description**: Source: implicit-detection. @developer-initializes-project:4.1 defaults MACOS_RUNTIME to 'auto'. INT-runtime-detection says detect_runtime() 'checks MACOS_RUNTIME on darwin' before probing. @runtime-detects-platform:2.2 shows override behavior for a concrete value ('docker'), and @runtime-detects-platform:2.3 describes probing when 'no overrides are set'. But after config loading, MACOS_RUNTIME is always set (to 'auto' by default). No requirement or interface specifies that 'auto' is a sentinel meaning 'use the probe chain.' An implementor could write detect_runtime() to treat any non-empty MACOS_RUNTIME as a literal runtime name, causing 'auto' to be returned as the detected runtime — which would then fail at get_container_cmd() (returning empty string for unknown runtimes). The spec needs to clarify how detect_runtime() distinguishes the 'auto' default from an actual runtime override.
- **Triage**: delegate
- **Decision**: Clarify 'auto' sentinel behavior in two places: (1) Update @runtime-detects-platform:2.3 Given step from 'no overrides are set' to 'MACOS_RUNTIME is set to "auto" (the default)' to reflect that MACOS_RUNTIME is always set after config loading and 'auto' triggers probing; (2) Update INT-runtime-detection behavior to state: 'On darwin, checks MACOS_RUNTIME — values other than "auto" are treated as explicit runtime overrides; "auto" (the default) falls through to the priority-ordered probe chain.'
- **Primary-file**: requirements/runtime-detects-platform/requirements.feature.md

### GAP-50: Shell command missing no-container error scenario
- **Source**: implicit-gap-detection
- **Severity**: medium
- **Description**: Source: implicit-detection. developer-opens-shell has no scenario for the case where no running container exists. developer-runs-agent (@developer-runs-agent:1.3), developer-stops-container (@developer-stops-container:1.2), and developer-stops-container (@developer-stops-container:2.3) all have explicit no-container scenarios with defined exit codes. Shell uses the same find_project_container() discovery mechanism (per CMP-shell-command) which exits with code 1 on no match. Without a requirement, an implementor could: let the raw error propagate (poor UX with no helpful message), add a message but return exit 0 like stop does (wrong — shell should fail), or crash silently. The analogous agent-exec scenario returns exit code 1 with an error log; shell should specify the same pattern for consistency, but currently doesn't.
- **Triage**: delegate
- **Decision**: Add Rule @developer-opens-shell:4 'Shell exec SHALL fail with an error when no running container exists' with scenario @developer-opens-shell:4.1 'No running container produces an error' specifying exit code 1 with error log. This mirrors @developer-runs-agent:1.3 and documents the existing shell.sh behavior.
- **Primary-file**: requirements/developer-opens-shell/requirements.feature.md

### GAP-51: GAP-3 retained 'native builder daemon' in limitation
- **Source**: resolution-leakage-detection
- **Severity**: low
- **Description**: Resolution of GAP-3 was supposed to rewrite Apple Container limitations as user-impact statements, removing internal mechanism details. The rewritten text in functional.md Current Limitations (line 33) still references 'the native builder daemon' — an internal implementation component that the user does not interact with. The user-facing consequence (slower builds in some configurations) should stand without naming the internal daemon, consistent with GAP-3's own decision: 'State what the developer cannot do or must do differently, not why the system has the constraint.'
- **Triage**: defer-release
- **Decision**: Acknowledge gap as acceptable for now, defer to future release.
- **Primary-file**: gap-lifecycle

### GAP-52: GAP-29 introduced pipe mechanism language in builds-container:3.2 Then clause
- **Source**: resolution-normative-detection
- **Severity**: medium
- **Description**: Resolution of GAP-29 added scenario @developer-builds-container:3.2 whose first Then clause reads 'the system SHALL pipe `<save_command>` into `container image load`'. This specifies the implementation mechanism (a shell pipeline between two commands) rather than an observable outcome. The adjacent And clause already states the observable outcome ('the image SHALL be available in the Apple Container registry'). A test cannot verify a piping mechanism without white-box access to the implementation; it can only verify image availability. The first Then assertion is untestable as a behavioral spec and couples the requirement to the specific transfer command. It should be replaced with an observable state assertion, or removed as redundant given the And clause. File: requirements/developer-builds-container/requirements.feature.md, scenario 3.2.
- **Triage**: delegate
- **Decision**: Remove the mechanism-specifying Then clause ('the system SHALL pipe `<save_command>` into `container image load`') from scenario @developer-builds-container:3.2. Promote the And clause to become the sole Then clause: 'Then the image SHALL be available in the Apple Container registry'. Remove the `save_command` column from the Examples table. The transfer mechanism is already documented in technical.md (CMP-build-command, INT-build-runtime) where implementation details belong.
- **Primary-file**: requirements/developer-builds-container/requirements.feature.md

### GAP-53: GAP-17 introduced non-observable 'handle as if' Then clause in starts-container:1.5
- **Source**: resolution-normative-detection
- **Severity**: medium
- **Description**: Resolution of GAP-17 added scenario @developer-starts-container:1.5 whose Then clause reads 'the system SHALL handle the existing container as if `--rebuild` was not specified'. The phrase 'handle...as if' names internal logic rather than a verifiable observable state — a test cannot observe 'handling'; it can only observe outcomes such as a logged message, exit code, or container state. The scenario provides no observable result: it does not state whether the container is started, restarted, or already running, nor what message or exit code is produced. The correct form would restate the applicable Rule 1 outcome for an already-existing container (e.g., 'the system SHALL start, restart, or report the existing container per its current state, and return exit code 0'). File: requirements/developer-starts-container/requirements.feature.md, scenario 1.5.
- **Triage**: delegate
- **Decision**: Replace scenario @developer-starts-container:1.5 with two scenarios that state observable outcomes: (1.5) Given a running container, When `agentcontainer up --rebuild`, Then log already running and return exit code 0; (1.6) Given a stopped container, When `agentcontainer up --rebuild`, Then start the existing container. This replaces the non-observable 'handle as if' language with the same observable outcomes specified in scenarios 1.1 and 1.2, applied to the --rebuild case.
- **Primary-file**: requirements/developer-starts-container/requirements.feature.md

### GAP-54: GAP-47 Risk entry approved for technical.md was not applied
- **Source**: placement-drift-detection
- **Severity**: medium
- **Description**: Resolution of GAP-47 correctly removed a design recommendation from infra.md but did not apply the corresponding Risk entry to technical.md. The GAP-47 Decision explicitly mandated adding a Risk entry: 'detect_platform() hardcodes /proc/version, limiting WSL detection unit testing to environments with a real /proc/version file → Making the version file path an injectable parameter would enable mock-based testing on plain Linux CI runners without requiring a WSL environment.' The Outcome acknowledges the omission ('The removed design recommendation belongs in technical.md as a Risk entry (not modified here per single-file constraint)'). technical.md Risks currently has 3 entries; the /proc/version hardcoding risk is absent. An approved Decision that mandates a specific artifact change was only half-executed — the removal from infra.md was applied, but the placement in technical.md was not.
- **Triage**: delegate
- **Decision**: Apply the Risk entry approved in GAP-47's Decision to technical.md Risks section, completing the half-executed resolution. Add as fourth bullet: '**`detect_platform()` hardcodes `/proc/version`, limiting WSL detection unit testing to environments with a real `/proc/version` file** → Making the version file path an injectable parameter would enable mock-based testing on plain Linux CI runners without requiring a WSL environment.'
- **Primary-file**: technical.md
