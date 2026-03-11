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

### GAP-1: Functional Overview section contains implementation architecture rather than user-facing description
- **Source**: functional-critic
- **Severity**: medium
- **Description**: The Overview section of the functional spec includes implementation details that belong in design or technical artifacts, not a functional spec. Content such as line counts, directory structures, entry point responsibilities (argument parsing, dependency checking, command dispatch), and two-layer config internals describes how the system is built, not what users can do with it. A functional spec overview should describe user-observable behavior and stop after stating user impact. The implementation specifics — command module sourcing, platform layer organization, config file naming — should be removed or relocated to design artifacts.

### GAP-2: Two capabilities use system-centric framing instead of actor-outcome framing
- **Source**: functional-critic
- **Severity**: low
- **Description**: The functional spec's capability list is mostly framed around developer actors, but two capabilities use "System" as the subject rather than a human actor: the platform detection capability and the agent authentication persistence capability. Functional specs describe outcomes for human actors. These capabilities should be reframed as actor-outcome statements — for example, describing the developer not needing to manually configure a container runtime, or retaining auth across rebuilds without re-authenticating.

### GAP-3: Current Limitations section frames technical constraints rather than user-visible impacts
- **Source**: functional-critic
- **Severity**: medium
- **Description**: Several entries in the Current Limitations section describe internal technical mechanics rather than the user-visible consequence of those mechanics. Examples include limitations framed around the Apple Container builder daemon fallback mechanism, the containerd runtime's level of support relative to other runtimes, and shell profile resolution depending on a specific internal file. A functional spec's limitations section should state what the user cannot do or must do differently — not why the system has that constraint. These entries should be rewritten to describe user-facing impact.

### GAP-4: Why section includes implementation philosophy alongside user burden statement
- **Source**: functional-critic
- **Severity**: low
- **Description**: The Why section of the functional spec begins with appropriate user burden language but then includes a design principle about matching devcontainer CLI behavioral semantics, including failure handling, lifecycle hooks, and configuration model. These are implementation-level design decisions that explain how the tool is built, not why users need it. This principle belongs in a design artifact's decisions section. The Why section in a functional spec should stay focused on the user problem being solved.

### GAP-5: Architecture diagram places Apple Container shim in eager-load subgraph, contradicting lazy-load specification
- **Source**: design-critic
- **Severity**: medium
- **Description**: The system architecture diagram groups the Apple Container shim inside the platform library subgraph alongside eagerly loaded modules, connected to the entry point via an unlabeled eager edge. The lazy-loading objective and the lazy-command-loading decision both state that the shim is loaded on demand, not at startup. A developer reading the diagram would infer the shim is sourced eagerly during initialization alongside the platform detection module, leading to incorrect assumptions about initialization order and what is available at startup. The diagram and the prose directly contradict each other.

### GAP-6: build_mounts_json() call context and CONTAINER_HOME precondition are unspecified
- **Source**: technical-critic
- **Severity**: medium
- **Description**: The template engine component documents that `build_mounts_json()` requires `CONTAINER_HOME`, which is derived from `REMOTE_USER` inside the init command component's `generate_devcontainer_json()`. The spec does not state whether `build_mounts_json()` is only callable from within `generate_devcontainer_json()`, or whether callers from other contexts must establish `CONTAINER_HOME` themselves. The up command component describes reading mounts from the already-generated devcontainer.json but never explicitly states it does not call `build_mounts_json()` directly. A developer modifying the template engine or extending the startup path cannot determine from the spec alone whether `CONTAINER_HOME` is a caller precondition or always inherited from the init context.

### GAP-7: find_project_container duplication in stop.sh has no decision record
- **Source**: design-critic
- **Severity**: low
- **Description**: The technical spec acknowledges that the stop command module carries a duplicate definition of `find_project_container` guarded by a `declare -f` check to allow standalone sourcing, and characterizes this as shared infrastructure despite living in a command module. This is a deliberate architectural trade-off — code duplication to avoid cross-module sourcing dependencies — but the decisions section contains no entry explaining why this approach was chosen over alternatives such as extracting the function to a shared utility module. Future maintainers have no documented rationale for whether to continue this duplication pattern or refactor it.

### GAP-8: find_build_runtime() referenced in build component but has no interface specification
- **Source**: technical-critic
- **Severity**: medium
- **Description**: The build command component references `find_build_runtime()` as the mechanism for selecting a fallback Docker-compatible runtime when the Apple Container native builder is unavailable. This function has no interface definition in the spec — no signature, selection criteria, priority chain, or return contract. The interfaces section defines other platform and utility functions but omits `find_build_runtime`. An implementer working on the Apple Container fallback path cannot determine whether this function reuses the runtime detection logic, applies a different priority ordering, or has different error semantics. The function is implementation-critical because the entire Apple Container build fallback path depends on it.

### GAP-9: find_project_container_all() absent from interfaces section
- **Source**: technical-critic
- **Severity**: low
- **Description**: The lifecycle commands component references `find_project_container_all()` as a distinct variant used by the down command to locate containers in any state. This function does not appear in the interfaces section. The container-finding interface note covers `find_project_container` and mentions the stop command's duplicate definition but says nothing about the down command variant. It is unclear whether `find_project_container_all` is a separate function, an argument-parameterized form of the same function, or requires duplication like the stop command variant. The spec leaves the number and location of this function's definitions ambiguous.

### GAP-10: jq dependency lacks justification despite minimal-dependencies objective
- **Source**: dependency-critic
- **Severity**: medium
- **Description**: The jq binary is listed as a dependency and is used across multiple critical components — the Apple Container shim for JSON translation, the template engine for JSON fragment construction and shell profile reading, and the shell command for reading container configuration. The minimal-dependencies objective explicitly calls out minimizing external dependencies, but no decision record justifies the choice of jq over alternatives such as pure-Bash pattern matching for simple reads, Python's built-in json module, or other approaches. A developer evaluating whether to add JSON handling cannot determine whether jq is a deliberate architectural choice or an incidental convenience.

### GAP-11: All five documented interfaces omit error contracts
- **Source**: dependency-critic
- **Severity**: medium
- **Description**: The five documented interfaces — runtime detection, container command, config loading, template expansion, and container finding — describe happy-path behavior but none fully specify failure modes. The runtime detection interface mentions returning a sentinel value but does not specify what callers should do with it. The container command interface returns an empty string for unknown runtimes without clarifying whether that is an error the caller must check. The config loading and template expansion interfaces document no failure behavior at all — what happens if the config file is absent or the template references an undefined variable is unspecified. The container finding interface states it exits with error when no match is found but does not document the exit code or error message pattern. Note: the container finding interface's exit-on-error behavior also creates a direct logical contradiction with stop and down command requirements; see GAP-24 for that specific concern.

### GAP-12: OBJ-runtime-abstraction overstates containerd support — containerd is detected but not operable
- **Source**: decision-plausibility-critic
- **Severity**: high
- **Description**: The runtime abstraction objective claims the CLI works across six container runtimes, including containerd. Runtime detection does probe for the `ctr` binary and map it to `"containerd"`, but no command module implements handling for the `ctr` runtime. Every command dispatches based on Docker-compatible, Lima, or Apple Container branches — none include a `ctr` case. The `ctr` CLI also uses fundamentally different syntax than Docker-compatible runtimes, so fallthrough would not produce correct behavior. The objective overstates actual runtime coverage: containerd can be detected but is not usable as a runtime. A developer assigned containerd-related work would have no component specification, no interface, and no guidance on whether it is fully supported, detection-only, or aspirational.

### GAP-13: Requirements scenarios assert command invocations rather than observable outcomes
- **Source**: requirements-critic
- **Severity**: medium
- **Description**: Two scenarios in the requirements spec assert specific internal command invocations as their verification target rather than the observable state those commands produce. One scenario asserts that the system shall run a specific ownership change command to set directory ownership — the verifiable outcome is that the directory is owned by the correct user, not that a particular command was invoked. Another scenario asserts that the system shall run specific user and group modification commands to match host UID/GID — the verifiable outcome is that the container user's UID/GID matches the host. Additionally, the second scenario bundles a separate ownership fix behavior alongside the UID/GID matching concern, combining two distinct behaviors with different preconditions in one scenario. For the broader pattern of internal function name references appearing as Then-clause assertions across seven integration scenarios, see GAP-36.

### GAP-14: {uid} placeholder in Podman socket path assertion is undefined
- **Source**: requirements-critic
- **Severity**: medium
- **Description**: The platform detection requirements include a table of socket paths used to detect each runtime. The Podman entry on Linux specifies a socket path containing a `{uid}` placeholder, but the placeholder is not defined anywhere in the spec — it is unclear whether this represents a literal string to match, a variable reference, or a stand-in for the actual numeric user ID. Every other entry in the same table provides a concrete literal path. A test cannot assert an exact socket path without knowing the resolution rule for this placeholder, making the Podman/Linux assertion non-deterministic and impossible to verify.

### GAP-15: Lima runtime docker_path value is ambiguous — "or" introduces two alternatives without a selection rule
- **Source**: requirements-critic
- **Severity**: medium
- **Description**: The build requirements table specifying the `--docker-path` value per runtime lists two alternative values for the Lima runtime, connected by "or," with no rule for determining which to use. Every other runtime entry in the table provides a single concrete value. An implementer cannot determine which value to use when constructing the `--docker-path` argument, and a test cannot assert a specific value when either is acceptable. The "or" construction leaves the behavior underspecified in a way that cannot be mechanically resolved.

### GAP-16: No error scenario for agent execution when no container is running
- **Source**: coverage-critic
- **Severity**: medium
- **Description**: The agent execution requirements validate config-level preconditions (missing config file and empty agent command) but include no scenario for the runtime precondition failure: what happens when the developer invokes the default command and no container is currently running. The functional spec describes the default execution path as finding a running container and executing the agent inside it, implying container discovery is required. The shell and stop capabilities both have explicit scenarios for the no-container case. The absence of this scenario for agent execution leaves the behavior unspecified — a developer could omit the container-existence check or produce an unhelpful error message.

### GAP-17: up --rebuild silent-ignore behavior is absent from requirements and contradicted by code
- **Source**: validation-critic
- **Severity**: high
- **Description**: The functional spec documents a known limitation: running `up --rebuild` when a container already exists is silently ignored — the user must remove the container first. However, the corresponding requirement scenario only states that the system shall invoke the build step before checking image existence, with no precondition constraining container state. The natural reading of the requirement — that `--rebuild` always triggers a rebuild — directly contradicts the documented limitation. Code examination confirms the mismatch: the up command checks for an existing container before reaching the rebuild path and returns immediately if a container is found in any state. The `--rebuild` flag is only reachable when no container exists at all. Scenarios covering the container-already-exists case when `--rebuild` is specified are missing from the requirements, leaving the discrepancy unresolvable by a developer reading either artifact.

### GAP-18: Symlink mechanism for auth persistence is absent from agent-auth-persists feature requirements
- **Source**: validation-critic
- **Severity**: medium
- **Description**: The functional spec states that auth persistence uses named volumes and symlinks managed by the setup script. The integration spec documents that setup.sh moves credential files into the named volume directory and creates symlinks from the workspace back to the volume. However, the agent authentication persistence feature requirements only cover mount generation and directory ownership — the symlink mechanism appears nowhere in the feature's own requirement rules. The symlink step is the actual mechanism by which workspace credential files survive container rebuilds; its absence from the feature requirements means it is only validated at integration level, not as a standalone contract for the capability.

### GAP-19: developer-views-status has no viable test path despite having no external dependencies
- **Source**: verification-critic
- **Severity**: medium
- **Description**: The infrastructure spec marks the status capability as not tested in CI but provides no technical justification for the omission. Unlike agent execution (which requires a real agent binary) or auth persistence (which requires a multi-session lifecycle), the status command produces pure CLI output with no external dependencies and could be added to the existing CI lifecycle step sequence. The infrastructure spec provides no alternative testing mechanism and no path for anyone assigned to add coverage for the status scenarios to do so within the described infrastructure.

### GAP-20: WSL platform detection is untestable with the described CI infrastructure
- **Source**: verification-critic
- **Severity**: medium
- **Description**: The platform detection requirements include a scenario requiring a Linux environment where a specific kernel version string identifies the host as WSL. The CI infrastructure runs plain Ubuntu runners — no WSL environment exists in the matrix. The infrastructure spec acknowledges that Linux/WSL detection is untested at the unit level, but proposes no remediation mechanism: no mock or stub for the kernel version file, no WSL runner, and no conditional test that would work on a non-WSL Linux host. The acknowledgment of the gap does not include any viable test path, leaving the scenario unverifiable under the described infrastructure.

### GAP-21: infra.md provides no runnable commands to verify the test suite
- **Source**: design-for-test-critic
- **Severity**: high
- **Description**: The infrastructure spec thoroughly describes CI topology, job dependencies, and what each step verifies, but provides no concrete runnable commands that prove tests pass. There is no workflow invocation path, no local test execution script, and no equivalent local invocation. A developer cannot verify that the test suite passes without reverse-engineering the CI YAML. The infrastructure spec describes what is tested but not how to run the tests, making it useful as a topology reference but insufficient as a verification guide.

### GAP-22: Unit test framework is unnamed and the spec contradicts itself about unit test existence
- **Source**: design-for-test-critic
- **Severity**: medium
- **Description**: The infrastructure spec states in its testing strategy that there is no unit test framework, yet the requirements coverage table claims a macOS unit test covers the platform detection function. This is a direct internal contradiction within the same document. The framework used for that test — whether BATS, shunit2, or an ad-hoc script — is never named, its file location is not given, and no invocation command is provided. Without naming the tooling and its location, the coverage claim is unverifiable and a developer cannot locate or extend those tests.

### GAP-23: No component specification exists for the status command
- **Source**: logic-critic
- **Severity**: high
- **Description**: The status capability has requirement scenarios covering platform display, runtime display, and project configuration display, but no component entry exists in the technical spec for this command. The entry point component's dispatch responsibilities do not mention status. Every other CLI capability maps to a named component with described responsibilities and dependencies. A developer assigned to implement or document the status command has no component specification to work from — no description of what the command is responsible for, which modules it calls, or what its output contract is.

### GAP-24: INT-container-finding exit-on-error contract directly contradicts stop and down requirements
- **Source**: logic-critic
- **Severity**: high
- **Description**: The container finding interface specifies that it returns a container ID or exits with error when no match is found. However, the stop command requirements specify that when no running container exists, the system must log a warning and return exit code 0. The down command requirements similarly require an informational message and exit code 0 when no container exists in any state. The lifecycle commands component delegates directly to the container finding functions with no documented mechanism for intercepting or suppressing the error exit. A developer implementing stop or down by following the interface contract literally will produce behavior that violates both requirements.

### GAP-25: EXEC_AGENT argument composition logic has no component or interface specification
- **Source**: logic-critic
- **Severity**: medium
- **Description**: The agent execution requirements define a three-way contract for how arguments are composed with the agent command template: replace a placeholder with user-provided arguments if the placeholder is present; append arguments if no placeholder exists; leave the command unchanged if no arguments are provided. The entry point component description says only that the system executes the agent directly when invoked without a subcommand. No interface documents the placeholder substitution versus appending logic, and no component describes where this composition occurs or what its inputs and outputs are. A developer reading the technical design has no artifact defining how to implement this behavior.

### GAP-26: setup.sh runtime behavior (auth ownership fix) is unspecified in the technical design
- **Source**: logic-critic
- **Severity**: medium
- **Description**: The agent authentication requirements define what setup.sh must do when it executes inside the container as a postCreateCommand: run ownership correction for non-root users, skip the correction for root, and suppress failures so container startup continues. The init command component describes how setup.sh is generated but covers only the generation step — not the script's runtime behavior. The ownership correction logic, the root/non-root branch, and the non-fatal failure semantics are defined in the requirements but have no corresponding component description or interface specification in the technical design. A developer working on the setup.sh template has no design artifact defining what the template must contain.

### GAP-27: developer-views-status capability overclaims container state inspection
- **Source**: capability-accuracy-critic
- **Severity**: medium
- **Description**: The functional spec's developer-views-status capability description states the developer can inspect "platform, runtime, and container state." The actual status implementation calls only the runtime information display function and the config display function — it never queries whether a container exists, is running, or is stopped. The phrase "container state" is not reflected in the code. This mismatch also manifests in the requirements spec: no requirement rule covers displaying actual container state (running, stopped, or not created), despite the capability description including it. Either the capability description should be corrected to remove "container state," or both the requirements and code need to be updated to deliver it.

### GAP-28: Missing-config case for agent execution requires exit code 1, but code exits 0
- **Source**: requirement-accuracy-critic
- **Severity**: high
- **Description**: The agent execution requirements specify that when the project config file does not exist, the system shall log an error and return exit code 1. The actual code path for this case calls the help display function and exits 0 — no error is logged and the exit code is 0. The internal guard in the agent run function that would log an error and return 1 is dead code, because the main dispatcher handles the missing config case before reaching it. Scripts or CI pipelines relying on a non-zero exit code to detect an uninitialized project will silently succeed, producing incorrect automation behavior.

### GAP-29: No image transfer scenario for nerdctl or podman fallback builds on Apple Container
- **Source**: requirement-accuracy-critic
- **Severity**: medium
- **Description**: The Apple Container build requirements list Lima, Docker, nerdctl, and podman as valid fallback build runtimes when the native Apple Container builder is unavailable. The image transfer requirement only specifies transfer behavior for Docker. Code examination shows the image transfer function handles only Lima and Docker paths — if nerdctl or podman is selected as the fallback build runtime, the build completes but the transfer step fails with an unsupported runtime error. There is no requirement scenario covering what should happen when the selected fallback is nerdctl or podman: whether these runtimes should be excluded from the fallback list, or whether analogous transfer operations using their save mechanisms should be implemented.

### GAP-30: lib/templates/ directory is absent from the architecture diagram and component descriptions
- **Source**: architecture-accuracy-critic
- **Severity**: medium
- **Description**: The architecture diagram maps three subdirectories under the library directory — utils, platform, and commands — but omits a fourth: the templates directory, which contains the template files used by the init command. No component entry describes this directory or its contents. The init command component references template expansion calls but provides no information about where templates are stored or what they contain. A developer reading the technical spec to understand the project structure would not know the templates directory exists or that it is a dependency of the init path.

### GAP-31: build_resource_args() is documented as an active component responsibility but has no callers
- **Source**: architecture-accuracy-critic
- **Severity**: medium
- **Description**: The template engine component lists resource argument construction as an active responsibility, documenting that it constructs memory, CPU, and process limit flags. The function exists in the codebase but has zero callers — it is dead code. Documenting it as a component responsibility implies it is part of the active architecture and wired into build or startup paths. A developer reading the component description would believe resource arguments are handled through this utility function, when actual resource limit handling lives elsewhere. The component description should either acknowledge this as a defined-but-unused function or remove it from the component's responsibilities.

### GAP-32: install.sh line count in infra.md is factually incorrect
- **Source**: infrastructure-accuracy-critic
- **Severity**: low
- **Description**: The infrastructure spec states a specific line count for the install script that does not match the actual file, which has substantially fewer lines than documented. This factual inaccuracy suggests the spec was written against a different version of the file. While minor in isolation, it reduces confidence in other numerical claims in the spec and could confuse readers trying to verify the document against the codebase.

### GAP-33: infra.md claims lint runs on every platform but macOS lint is conditionally gated
- **Source**: infrastructure-accuracy-critic
- **Severity**: medium
- **Description**: The infrastructure spec states that lint and static analysis runs on every platform. In practice, the dedicated lint job runs only on the Linux runner. While macOS and Windows jobs include lint steps, macOS lint is embedded within the integration test job and gated behind the same configuration variable that controls whether macOS integration tests run at all. If that variable is not set, macOS lint never runs. The documentation implies unconditional cross-platform lint coverage, but macOS lint is conditional on the same variable that gates macOS integration testing.

### GAP-34: macOS Bash 3.2 and Bash 5 dual syntax checking is architecturally significant but undocumented
- **Source**: infrastructure-accuracy-critic
- **Severity**: low
- **Description**: The CI workflow runs syntax checks against both the macOS system Bash 3.2 and a newer Bash version. For a Bash CLI tool that targets compatibility with the ancient Bash shipped with macOS, this dual-version syntax check is the mechanism that prevents Bash 4+ syntax from accidentally entering the codebase. The infrastructure spec does not mention this check at all. A developer adding scripts would not know this compatibility gate exists, and a reviewer reading the spec would not understand that the macOS syntax check serves a distinct compatibility purpose from the Linux check.

### GAP-35: devcontainer CLI is an undocumented test prerequisite in infra.md
- **Source**: infrastructure-accuracy-critic
- **Severity**: medium
- **Description**: The CI workflow installs the devcontainer CLI along with jq and text processing utilities on both Linux and macOS runners as prerequisites for running integration tests. The infrastructure spec does not mention any of these dependencies in the testing strategy section. The devcontainer CLI is particularly significant — it is the underlying engine that the tool wraps, making it an architectural dependency, not merely a test utility. A developer trying to reproduce the test suite locally would not know they need npm and the devcontainer CLI installed, and would not understand the relationship between this tool and the devcontainer CLI it wraps.

### GAP-36: Internal function and command references appear as Then-clause assertions across integration and requirements specs
- **Source**: integration-critic
- **Severity**: high
- **Description**: Across seven integration scenarios, Then clauses specify internal function names as the verifiable outcome rather than observable behavior — asserting that a command SHALL locate a container via a specific internal function, that build SHALL transfer an image via a specific internal function, and that agent execution SHALL perform substitution via a specific internal function. The same anti-pattern appears in the requirements spec: one scenario asserts the system shall invoke a specific internal build function as the outcome of the rebuild flag, and two others assert specific internal command invocations rather than the resulting observable state (covered in GAP-13). This pattern makes scenarios impossible to test without white-box access and couples the spec to implementation details — renaming or refactoring a function requires rewriting the spec even when behavior is unchanged.

### GAP-37: Multiple distinct behaviors are bundled in single scenarios across integration and requirements specs
- **Source**: integration-critic
- **Severity**: medium
- **Description**: Several scenarios combine multiple distinct behaviors in a single When-Then pair, making it impossible to write atomic tests that isolate and identify which behavior fails. One integration scenario enumerates five distinct lifecycle commands in a single When-Then pair, asserting that each command uses the same runtime — five behaviors that require separate test executions. In the requirements spec, two post-creation scenarios each bundle a happy-path assertion together with a failure-tolerance assertion. Failure tolerance has a distinct precondition (the relevant command must fail); bundling it with the success case means a passing test cannot distinguish correct execution from correctly swallowed failure. Each distinct behavior warrants its own Given-When-Then with an appropriate precondition.

### GAP-38: @integration:2.2 buries the cross-capability outcome in a subordinate clause
- **Source**: integration-critic
- **Severity**: low
- **Description**: An integration scenario tagged with both the build and start capabilities asserts only the build command's own transfer behavior in the Then clause. The actual cross-capability outcome — that the start command subsequently succeeds using the transferred image — appears only in a "so that" rationale clause, not as a verifiable Then assertion. The start capability tag is not earned by the scenario as written. Either the Then clause should be extended to assert that the start command locates and uses the transferred image, or the second capability tag should be removed.

### GAP-39: Agent execution is missing from container naming integration scenarios
- **Source**: integration-coverage-critic
- **Severity**: medium
- **Description**: The integration scenario covering container naming conventions verifies that the naming pattern established by the up command enables discovery by the shell, stop, and down commands, but omits the default agent execution path. The functional spec describes agent execution as finding a running container by name and executing the agent inside it — using the same container discovery mechanism as the shell command. If container naming conventions change in up, agent execution would break alongside shell, stop, and down, but only the latter three have integration coverage for this shared dependency.

