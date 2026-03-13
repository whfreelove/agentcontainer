# Resolved Gaps

<!-- GAP TEMPLATE:
### GAP-XX: Title
- **Source**: <kebab-case with type suffix, e.g., functional-critic, implicit-detection>
- **Severity**: high|medium|low
- **Description**: ... (original concern, immutable)
- **Triage**: check-in|delegate|defer-release|defer-resolution (preserved from gaps.md)
- **Decision**: ... (immutable point-in-time decision)
- **Status**: resolved|superseded|deprecated (set on move to resolved.md)
- **Superseded by**: GAP-XX (only when Status is superseded)
- **Outcome**: ... (optional — records what actually changed in artifacts after Decision was applied)
- **Rationale**: ... (only when Status is deprecated — must cite specific evidence: artifact change, code evidence, or context shift)
- **Current approach**: ... (only when Status is superseded — points to up-to-date information)

See tokamak:managing-spec-gaps for triage and status semantics.
-->

### GAP-1: Functional Overview section contains implementation architecture rather than user-facing description
- **Source**: functional-critic
- **Severity**: medium
- **Description**: The Overview section of the functional spec includes implementation details that belong in design or technical artifacts, not a functional spec. Content such as line counts, directory structures, entry point responsibilities (argument parsing, dependency checking, command dispatch), and two-layer config internals describes how the system is built, not what users can do with it. A functional spec overview should describe user-observable behavior and stop after stating user impact. The implementation specifics — command module sourcing, platform layer organization, config file naming — should be removed or relocated to design artifacts.
- **Triage**: delegate
- **Decision**: Rewrite functional.md Overview as a user-facing workflow description covering available commands, user-visible configuration model, and automatic behaviors. Remove all implementation architecture (line counts, directory structures, module sourcing, internal entry point responsibilities). No relocation needed — technical.md already documents this architecture in components, interfaces, and decisions sections.
- **Primary-file**: functional.md
- **Status**: resolved
- **Outcome**: Replaced the Overview section (previously containing architecture details like line counts, directory structures, entry point responsibilities, module sourcing, and config internals) with a user-facing description organized into three subsections: Commands (listing all 8 commands with user-visible behavior), Configuration (two-level config model from user perspective), and Automatic behaviors (runtime detection and auth persistence). [diff: +18/-20 functional.md]

### GAP-2: Two capabilities use system-centric framing instead of actor-outcome framing
- **Source**: functional-critic
- **Severity**: low
- **Description**: The functional spec's capability list is mostly framed around developer actors, but two capabilities use "System" as the subject rather than a human actor: the platform detection capability and the agent authentication persistence capability. Functional specs describe outcomes for human actors. These capabilities should be reframed as actor-outcome statements — for example, describing the developer not needing to manually configure a container runtime, or retaining auth across rebuilds without re-authenticating.
- **Triage**: defer-release
- **Decision**: Defer to a future spec refinement round. Low-severity editorial concern — two capabilities use system-centric framing but are substantively correct. No artifact changes; gap resolution record serves as tracking.
- **Primary-file**: functional.md
- **Status**: resolved
- **Outcome**: No artifact changes. Gap deferred per decision — two capabilities (runtime-detects-platform, agent-auth-persists) use system-centric framing but are substantively correct. Tracked for future refinement. [diff: +0/-0 functional.md]

### GAP-3: Current Limitations section frames technical constraints rather than user-visible impacts
- **Source**: functional-critic
- **Severity**: medium
- **Description**: Several entries in the Current Limitations section describe internal technical mechanics rather than the user-visible consequence of those mechanics. Examples include limitations framed around the Apple Container builder daemon fallback mechanism, the containerd runtime's level of support relative to other runtimes, and shell profile resolution depending on a specific internal file. A functional spec's limitations section should state what the user cannot do or must do differently — not why the system has that constraint. These entries should be rewritten to describe user-facing impact.
- **Triage**: delegate
- **Decision**: Rewrite the three technically-framed Current Limitations entries (Apple Container build fallback, containerd support level, shell profile resolution) as user-impact statements. State what the developer cannot do or must do differently, not why the system has the constraint. Internal mechanisms are already documented in technical.md components.
- **Primary-file**: functional.md
- **Status**: resolved
- **Outcome**: Rewrote three Current Limitations entries: (1) Apple Container build fallback now describes slower builds from the developer's perspective, (2) containerd limitation now states developers may encounter unsupported operations, (3) shell profile resolution now states developers must define custom profiles for non-default shells. All three removed internal mechanism details. [diff: +3/-3 functional.md]

### GAP-4: Why section includes implementation philosophy alongside user burden statement
- **Source**: functional-critic
- **Severity**: low
- **Description**: The Why section of the functional spec begins with appropriate user burden language but then includes a design principle about matching devcontainer CLI behavioral semantics, including failure handling, lifecycle hooks, and configuration model. These are implementation-level design decisions that explain how the tool is built, not why users need it. This principle belongs in a design artifact's decisions section. The Why section in a functional spec should stay focused on the user problem being solved.
- **Triage**: defer-release
- **Decision**: Defer to a future spec refinement round. Low-severity editorial concern — design principle in Why section is already captured in technical.md DEC-devcontainer-foundation. No artifact changes; gap resolution record serves as tracking.
- **Primary-file**: functional.md
- **Status**: resolved
- **Outcome**: No artifact changes. Gap deferred per decision — the design principle about matching devcontainer CLI behavioral semantics in the Why section is already documented in technical.md DEC-devcontainer-foundation. Tracked for future refinement. [diff: +0/-0 functional.md]

### GAP-27: developer-views-status capability overclaims container state inspection
- **Source**: capability-accuracy-critic
- **Severity**: medium
- **Description**: The functional spec's developer-views-status capability description states the developer can inspect "platform, runtime, and container state." The actual status implementation calls only the runtime information display function and the config display function — it never queries whether a container exists, is running, or is stopped. The phrase "container state" is not reflected in the code. This mismatch also manifests in the requirements spec: no requirement rule covers displaying actual container state (running, stopped, or not created), despite the capability description including it. Either the capability description should be corrected to remove "container state," or both the requirements and code need to be updated to deliver it.
- **Triage**: delegate
- **Decision**: Correct the developer-views-status capability description in functional.md to remove 'container state' and reflect actual behavior: 'Developer can inspect the detected platform, runtime availability, and project configuration.' The requirements already match this scope. No new requirements needed.
- **Primary-file**: functional.md
- **Status**: resolved
- **Outcome**: Updated developer-views-status capability from 'Developer can inspect the detected platform, runtime, and container state' to 'Developer can inspect the detected platform, runtime availability, and project configuration' — matching actual code behavior and existing requirements. [diff: +1/-1 functional.md]

### GAP-5: Architecture diagram places Apple Container shim in eager-load subgraph, contradicting lazy-load specification
- **Source**: design-critic
- **Severity**: medium
- **Description**: The system architecture diagram groups the Apple Container shim inside the platform library subgraph alongside eagerly loaded modules, connected to the entry point via an unlabeled eager edge. The lazy-loading objective and the lazy-command-loading decision both state that the shim is loaded on demand, not at startup. A developer reading the diagram would infer the shim is sourced eagerly during initialization alongside the platform detection module, leading to incorrect assumptions about initialization order and what is available at startup. The diagram and the prose directly contradict each other.
- **Triage**: delegate
- **Decision**: Restructure the architecture diagram to show EP→DETECT as the only eager edge into the PLATFORM subgraph. Label BUILD→SHIM and UP→SHIM edges with 'lazy, path ref' to indicate the shim is not sourced at startup but referenced on demand by command modules, consistent with DEC-lazy-command-loading and OBJ-lazy-loading.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Moved SHIM node outside the PLATFORM subgraph to its own standalone node. Changed EP→PLATFORM edge to EP→DETECT. Labeled BUILD→SHIM and UP→SHIM edges as 'lazy, path ref'. PLATFORM subgraph now contains only DETECT. [diff: +10/-8 technical.md]

### GAP-6: build_mounts_json() call context and CONTAINER_HOME precondition are unspecified
- **Source**: technical-critic
- **Severity**: medium
- **Description**: The template engine component documents that `build_mounts_json()` requires `CONTAINER_HOME`, which is derived from `REMOTE_USER` inside the init command component's `generate_devcontainer_json()`. The spec does not state whether `build_mounts_json()` is only callable from within `generate_devcontainer_json()`, or whether callers from other contexts must establish `CONTAINER_HOME` themselves. The up command component describes reading mounts from the already-generated devcontainer.json but never explicitly states it does not call `build_mounts_json()` directly. A developer modifying the template engine or extending the startup path cannot determine from the spec alone whether `CONTAINER_HOME` is a caller precondition or always inherited from the init context.
- **Triage**: delegate
- **Decision**: Document build_mounts_json() in CMP-template-engine as an init-context-only helper called exclusively within generate_devcontainer_json(), where CONTAINER_HOME is inherited from the REMOTE_USER derivation. Add a clarifying note that CMP-up-command reads mount definitions from the already-generated devcontainer.json and does not call build_mounts_json() directly.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Updated CMP-template-engine responsibilities to describe build_mounts_json() as init-context-only and clarify that CMP-up-command reads mounts from devcontainer.json rather than calling the function. [diff: +2/-1 technical.md]

### GAP-7: find_project_container duplication in stop.sh has no decision record
- **Source**: design-critic
- **Severity**: low
- **Description**: The technical spec acknowledges that the stop command module carries a duplicate definition of `find_project_container` guarded by a `declare -f` check to allow standalone sourcing, and characterizes this as shared infrastructure despite living in a command module. This is a deliberate architectural trade-off — code duplication to avoid cross-module sourcing dependencies — but the decisions section contains no entry explaining why this approach was chosen over alternatives such as extracting the function to a shared utility module. Future maintainers have no documented rationale for whether to continue this duplication pattern or refactor it.
- **Triage**: delegate
- **Decision**: Add DEC-command-local-container-finding as DEC-9 in technical.md Decisions: in the context of container discovery functions needed by shell, stop, down, and agent-exec paths, facing the constraint that lazy-loaded command modules must be independently sourceable, we decided to duplicate find_project_container with a declare-f guard in stop.sh and define find_project_container_all locally in down.sh, neglecting extraction to a shared lib/utils/ module, to achieve full command-module independence, accepting code duplication and the maintenance burden of keeping duplicated logic in sync.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Added DEC-9 documenting the decision to duplicate find_project_container with declare-f guard in stop.sh and define find_project_container_all locally in down.sh, neglecting extraction to a shared lib/utils/ module. [diff: +2/-0 technical.md]

### GAP-8: find_build_runtime() referenced in build component but has no interface specification
- **Source**: technical-critic
- **Severity**: medium
- **Description**: The build command component references `find_build_runtime()` as the mechanism for selecting a fallback Docker-compatible runtime when the Apple Container native builder is unavailable. This function has no interface definition in the spec — no signature, selection criteria, priority chain, or return contract. The interfaces section defines other platform and utility functions but omits `find_build_runtime`. An implementer working on the Apple Container fallback path cannot determine whether this function reuses the runtime detection logic, applies a different priority ordering, or has different error semantics. The function is implementation-critical because the entire Apple Container build fallback path depends on it.
- **Triage**: delegate
- **Decision**: Add INT-build-runtime interface for find_build_runtime(). Signature: find_build_runtime(platform) → runtime-name. Priority chain: lima → docker → nerdctl → podman. Returns empty string if no Docker-compatible build runtime is found. This priority chain is intentionally independent of detect_runtime() because build fallback requires Docker-compatible image building capability, not general container runtime suitability. Reference from CMP-build-command.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Added INT-build-runtime interface with signature, priority chain, error behavior, note about independence from detect_runtime(), and consumer reference to CMP-build-command. [diff: +7/-0 technical.md]

### GAP-9: find_project_container_all() absent from interfaces section
- **Source**: technical-critic
- **Severity**: low
- **Description**: The lifecycle commands component references `find_project_container_all()` as a distinct variant used by the down command to locate containers in any state. This function does not appear in the interfaces section. The container-finding interface note covers `find_project_container` and mentions the stop command's duplicate definition but says nothing about the down command variant. It is unclear whether `find_project_container_all` is a separate function, an argument-parameterized form of the same function, or requires duplication like the stop command variant. The spec leaves the number and location of this function's definitions ambiguous.
- **Triage**: delegate
- **Decision**: Extend INT-container-finding to document find_project_container_all() as a variant. Same two-pass search logic (name pattern matching, then label-based fallback) but searches containers in any state via -a flag. Primary definition in down.sh. Consumer: CMP-lifecycle-commands (down command). This completes the container-finding interface documentation alongside the base find_project_container() variant.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Updated INT-container-finding heading and signature to include find_project_container_all. Added description of -a flag behavior and primary definition location in down.sh. Updated consumers list. [diff: +6/-5 technical.md]

### GAP-10: jq dependency lacks justification despite minimal-dependencies objective
- **Source**: dependency-critic
- **Severity**: medium
- **Description**: The jq binary is listed as a dependency and is used across multiple critical components — the Apple Container shim for JSON translation, the template engine for JSON fragment construction and shell profile reading, and the shell command for reading container configuration. The minimal-dependencies objective explicitly calls out minimizing external dependencies, but no decision record justifies the choice of jq over alternatives such as pure-Bash pattern matching for simple reads, Python's built-in json module, or other approaches. A developer evaluating whether to add JSON handling cannot determine whether jq is a deliberate architectural choice or an incidental convenience.
- **Triage**: delegate
- **Decision**: Add DEC-jq-json-parsing decision record as a Y-statement justifying jq as a deliberate choice for structured JSON parsing across five components. Update OBJ-minimal-deps to include jq alongside Bash, devcontainer CLI, envsubst, and a container runtime. Resolves both the missing justification and the internal contradiction between the Context section and the objective enumeration.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Added jq to OBJ-minimal-deps enumeration. Added DEC-10 Y-statement documenting jq as a deliberate choice over pure-Bash or Python alternatives for five components. [diff: +3/-1 technical.md]

### GAP-11: All five documented interfaces omit error contracts
- **Source**: dependency-critic
- **Severity**: medium
- **Description**: The five documented interfaces — runtime detection, container command, config loading, template expansion, and container finding — describe happy-path behavior but none fully specify failure modes. The runtime detection interface mentions returning a sentinel value but does not specify what callers should do with it. The container command interface returns an empty string for unknown runtimes without clarifying whether that is an error the caller must check. The config loading and template expansion interfaces document no failure behavior at all — what happens if the config file is absent or the template references an undefined variable is unspecified. The container finding interface states it exits with error when no match is found but does not document the exit code or error message pattern. Note: the container finding interface's exit-on-error behavior also creates a direct logical contradiction with stop and down command requirements; see GAP-24 for that specific concern.
- **Triage**: delegate
- **Decision**: Add error behavior documentation to all five existing interfaces in technical.md, matching actual implementation semantics. INT-runtime-detection: returns 'none' string, callers must handle explicitly. INT-container-cmd: returns empty string for unknown runtimes, callers must check. INT-config-loading: skips missing files silently, no content validation. INT-template-expansion: returns 1 with stderr message on missing template file. INT-container-finding: returns exit code 1 on no match; callers requiring graceful handling suppress via || true.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Added 'Error behavior' field to INT-runtime-detection (returns 'none'), INT-container-cmd (returns empty string), INT-config-loading (skips missing files), INT-template-expansion (exit 1 on missing template), and INT-container-finding (exit 1 on no match, callers suppress via || true). [diff: +5/-0 technical.md]

### GAP-12: OBJ-runtime-abstraction overstates containerd support — containerd is detected but not operable
- **Source**: decision-plausibility-critic
- **Severity**: high
- **Description**: The runtime abstraction objective claims the CLI works across six container runtimes, including containerd. Runtime detection does probe for the `ctr` binary and map it to `"containerd"`, but no command module implements handling for the `ctr` runtime. Every command dispatches based on Docker-compatible, Lima, or Apple Container branches — none include a `ctr` case. The `ctr` CLI also uses fundamentally different syntax than Docker-compatible runtimes, so fallthrough would not produce correct behavior. The objective overstates actual runtime coverage: containerd can be detected but is not usable as a runtime. A developer assigned containerd-related work would have no component specification, no interface, and no guidance on whether it is fully supported, detection-only, or aspirational.
- **Triage**: delegate
- **Decision**: Downgrade OBJ-runtime-abstraction from six to five operable runtimes (Docker, Podman, nerdctl, Lima, Apple Container). Add DEC-containerd-detection-only explaining that containerd is detected for diagnostic purposes but not operable due to fundamentally different CLI semantics. Update functional.md Current Limitations to state containerd is detected but not operable as a runtime.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Changed OBJ-runtime-abstraction from '6 container runtimes' to '5 operable container runtimes', removed containerd from the list, added cross-reference to DEC-containerd-detection-only. Added DEC-11 explaining containerd is detection-only due to incompatible CLI semantics. functional.md already documents this limitation at line 35. [diff: +3/-1 technical.md]

### GAP-23: No component specification exists for the status command
- **Source**: logic-critic
- **Severity**: high
- **Description**: The status capability has requirement scenarios covering platform display, runtime display, and project configuration display, but no component entry exists in the technical spec for this command. The entry point component's dispatch responsibilities do not mention status. Every other CLI capability maps to a named component with described responsibilities and dependencies. A developer assigned to implement or document the status command has no component specification to work from — no description of what the command is responsible for, which modules it calls, or what its output contract is.
- **Triage**: delegate
- **Decision**: Add CMP-status-command component to technical.md documenting status as an inline entry point behavior that delegates to print_runtime_info() from CMP-platform-detector and conditionally to load_config() / print_config() from CMP-config-loader. Update CMP-entry-point dispatch responsibilities to include status alongside the other six commands. The component description SHALL note that status is implemented inline in the entry point rather than as a separate command module.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Added CMP-status-command documenting status as inline entry point behavior delegating to print_runtime_info() and conditionally to load_config()/print_config(). Updated CMP-entry-point responsibilities to list status in the dispatch enumeration with cross-reference to CMP-status-command. [diff: +6/-1 technical.md]

### GAP-24: INT-container-finding exit-on-error contract directly contradicts stop and down requirements
- **Source**: logic-critic
- **Severity**: high
- **Description**: The container finding interface specifies that it returns a container ID or exits with error when no match is found. However, the stop command requirements specify that when no running container exists, the system must log a warning and return exit code 0. The down command requirements similarly require an informational message and exit code 0 when no container exists in any state. The lifecycle commands component delegates directly to the container finding functions with no documented mechanism for intercepting or suppressing the error exit. A developer implementing stop or down by following the interface contract literally will produce behavior that violates both requirements.
- **Triage**: delegate
- **Decision**: Update INT-container-finding in technical.md to document that the function exits with error (code 1) when no container matches, and that callers requiring graceful no-match handling (such as stop and down) SHALL suppress the error exit and check for empty output. This documents the actual caller contract without changing the interface behavior.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Added error behavior field to INT-container-finding documenting exit code 1 on no match and the || true suppression pattern for stop and down commands. Co-resolved with GAP-9 in the same INT-container-finding rewrite. [diff: +1/-0 technical.md]

### GAP-25: EXEC_AGENT argument composition logic has no component or interface specification
- **Source**: logic-critic
- **Severity**: medium
- **Description**: The agent execution requirements define a three-way contract for how arguments are composed with the agent command template: replace a placeholder with user-provided arguments if the placeholder is present; append arguments if no placeholder exists; leave the command unchanged if no arguments are provided. The entry point component description says only that the system executes the agent directly when invoked without a subcommand. No interface documents the placeholder substitution versus appending logic, and no component describes where this composition occurs or what its inputs and outputs are. A developer reading the technical design has no artifact defining how to implement this behavior.
- **Triage**: delegate
- **Decision**: Expand CMP-entry-point responsibilities to document EXEC_AGENT argument composition: the entry point composes user-provided arguments with the EXEC_AGENT template using three-way logic — placeholder substitution (replacing {} with shell-quoted arguments), argument appending (when no placeholder exists), or pass-through (when no arguments provided). Arguments are shell-quoted via printf '%q' before composition.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Expanded the agent exec sentence in CMP-entry-point to describe placeholder substitution (replacing {} with printf '%q' quoted arguments), argument appending (no placeholder), and pass-through (no arguments). [diff: +1/-1 technical.md]

### GAP-26: setup.sh runtime behavior (auth ownership fix) is unspecified in the technical design
- **Source**: logic-critic
- **Severity**: medium
- **Description**: The agent authentication requirements define what setup.sh must do when it executes inside the container as a postCreateCommand: run ownership correction for non-root users, skip the correction for root, and suppress failures so container startup continues. The init command component describes how setup.sh is generated but covers only the generation step — not the script's runtime behavior. The ownership correction logic, the root/non-root branch, and the non-fatal failure semantics are defined in the requirements but have no corresponding component description or interface specification in the technical design. A developer working on the setup.sh template has no design artifact defining what the template must contain.
- **Triage**: delegate
- **Decision**: Add CMP-setup-script component to technical.md documenting setup.sh as a container-side component generated from lib/templates/setup.sh.tmpl. Responsibilities: (1) fix auth directory ownership for non-root users via sudo chown -R with failure suppression, (2) skip ownership fix when running as root, (3) persist auth credential files by moving them into the named volume directory and creating symlinks, (4) treat all operations as non-fatal per DEC-non-fatal-post-creation. Update CMP-init-command to cross-reference CMP-setup-script for the runtime behavior contract of the generated setup.sh.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Added CMP-setup-script documenting setup.sh as a container-side component with responsibilities for auth ownership fix (non-root), root skip, credential persistence via symlinks, and non-fatal semantics. Updated CMP-init-command's setup.sh reference to cross-link CMP-setup-script. [diff: +6/-1 technical.md]

### GAP-30: lib/templates/ directory is absent from the architecture diagram and component descriptions
- **Source**: architecture-accuracy-critic
- **Severity**: medium
- **Description**: The architecture diagram maps three subdirectories under the library directory — utils, platform, and commands — but omits a fourth: the templates directory, which contains the template files used by the init command. No component entry describes this directory or its contents. The init command component references template expansion calls but provides no information about where templates are stored or what they contain. A developer reading the technical spec to understand the project structure would not know the templates directory exists or that it is a dependency of the init path.
- **Triage**: delegate
- **Decision**: Add lib/templates/ to the architecture diagram as a TEMPLATES subgraph with a node listing the 5 template files. Add CMP-templates component entry describing the template source files and their role. Update CMP-init-command dependencies to include CMP-templates. Connect INIT→TEMPLATES in the diagram to show the dependency path.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Added TEMPLATES subgraph with 5 template file nodes to the system overview diagram. Added INIT→TEMPLATES edge. Added CMP-templates component entry listing all 5 template files. Updated CMP-init-command dependencies to include CMP-templates. [diff: +12/-1 technical.md]

### GAP-31: build_resource_args() is documented as an active component responsibility but has no callers
- **Source**: architecture-accuracy-critic
- **Severity**: medium
- **Description**: The template engine component lists resource argument construction as an active responsibility, documenting that it constructs memory, CPU, and process limit flags. The function exists in the codebase but has zero callers — it is dead code. Documenting it as a component responsibility implies it is part of the active architecture and wired into build or startup paths. A developer reading the component description would believe resource arguments are handled through this utility function, when actual resource limit handling lives elsewhere. The component description should either acknowledge this as a defined-but-unused function or remove it from the component's responsibilities.
- **Triage**: delegate
- **Decision**: Remove build_resource_args() from CMP-template-engine's active responsibilities. Add a note that the function is defined in template.sh but has no callers in the current codebase, so it is not part of the active architecture. This prevents developers from assuming resource argument construction flows through this utility.
- **Primary-file**: technical.md
- **Status**: resolved
- **Outcome**: Removed build_resource_args() from the responsibilities sentence. Added a Note field stating the function is defined in template.sh but has no callers and is not part of the active architecture. [diff: +2/-1 technical.md]

### GAP-13: Requirements scenarios assert command invocations rather than observable outcomes
- **Source**: requirements-critic
- **Severity**: medium
- **Description**: Two scenarios in the requirements spec assert specific internal command invocations as their verification target rather than the observable state those commands produce. One scenario asserts that the system shall run a specific ownership change command to set directory ownership — the verifiable outcome is that the directory is owned by the correct user, not that a particular command was invoked. Another scenario asserts that the system shall run specific user and group modification commands to match host UID/GID — the verifiable outcome is that the container user's UID/GID matches the host. Additionally, the second scenario bundles a separate ownership fix behavior alongside the UID/GID matching concern, combining two distinct behaviors with different preconditions in one scenario. For the broader pattern of internal function name references appearing as Then-clause assertions across seven integration scenarios, see GAP-36.
- **Triage**: delegate
- **Decision**: Rewrite @agent-auth-persists:2.1 to assert observable ownership state ('the auth directory SHALL be owned by the current user') instead of the chown command invocation. Split @developer-starts-container:3.1 into two scenarios: one asserting the container user's UID/GID matches the host, another asserting the home directory is owned by the container user. Remove all shell command names (chown, groupmod, usermod) from Then clauses. Renumber subsequent scenarios in developer-starts-container Rule 3 accordingly.
- **Primary-file**: requirements/developer-starts-container/requirements.feature.md
- **Status**: resolved
- **Outcome**: Split scenario 3.1 into two scenarios: 3.1 asserts container user UID/GID matches host, 3.2 asserts home directory ownership by container user. Removed all shell command names (groupmod, usermod, chown) from Then clauses. Renumbered former 3.2 to 3.3 and former 3.3 to 3.4. Also removed internal function name references from When clauses in the new scenarios. [diff: +11/-7 requirements/developer-starts-container/requirements.feature.md]

### GAP-17: up --rebuild silent-ignore behavior is absent from requirements and contradicted by code
- **Source**: validation-critic
- **Severity**: high
- **Description**: The functional spec documents a known limitation: running `up --rebuild` when a container already exists is silently ignored — the user must remove the container first. However, the corresponding requirement scenario only states that the system shall invoke the build step before checking image existence, with no precondition constraining container state. The natural reading of the requirement — that `--rebuild` always triggers a rebuild — directly contradicts the documented limitation. Code examination confirms the mismatch: the up command checks for an existing container before reaching the rebuild path and returns immediately if a container is found in any state. The `--rebuild` flag is only reachable when no container exists at all. Scenarios covering the container-already-exists case when `--rebuild` is specified are missing from the requirements, leaving the discrepancy unresolvable by a developer reading either artifact.
- **Triage**: delegate
- **Decision**: Document actual --rebuild behavior: add a 'no container exists' precondition to @developer-starts-container:1.4 and add a new scenario @developer-starts-container:1.5 specifying that --rebuild with an existing container is silently ignored. This aligns requirements with the functional spec's documented limitation and the actual code behavior.
- **Primary-file**: requirements/developer-starts-container/requirements.feature.md
- **Status**: resolved
- **Outcome**: Added 'Given no container for the project exists' precondition to scenario 1.4. Rewrote Then clause to assert observable behavior ('build a new image before starting') instead of internal function call. Added new scenario 1.5 documenting that --rebuild with an existing container is handled as if --rebuild was not specified, aligning with functional spec's Current Limitations. [diff: +9/-2 requirements/developer-starts-container/requirements.feature.md]

### GAP-14: {uid} placeholder in Podman socket path assertion is undefined
- **Source**: requirements-critic
- **Severity**: medium
- **Description**: The platform detection requirements include a table of socket paths used to detect each runtime. The Podman entry on Linux specifies a socket path containing a `{uid}` placeholder, but the placeholder is not defined anywhere in the spec — it is unclear whether this represents a literal string to match, a variable reference, or a stand-in for the actual numeric user ID. Every other entry in the same table provides a concrete literal path. A test cannot assert an exact socket path without knowing the resolution rule for this placeholder, making the Podman/Linux assertion non-deterministic and impossible to verify.
- **Triage**: delegate
- **Decision**: Add an inline note after the scenario 3.2 Examples table defining {uid} as the numeric user ID of the invoking user (as returned by `id -u`). The placeholder is necessary because the Podman socket path is inherently user-specific and cannot be expressed as a single concrete literal.
- **Primary-file**: requirements/runtime-detects-platform/requirements.feature.md
- **Status**: resolved
- **Outcome**: Added a blockquote note after the scenario 3.2 Examples table clarifying that {uid} represents the numeric user ID returned by `id -u` and explaining why a placeholder is necessary for the Podman socket path. [diff: +2/-0 requirements/runtime-detects-platform/requirements.feature.md]

### GAP-15: Lima runtime docker_path value is ambiguous — "or" introduces two alternatives without a selection rule
- **Source**: requirements-critic
- **Severity**: medium
- **Description**: The build requirements table specifying the `--docker-path` value per runtime lists two alternative values for the Lima runtime, connected by "or," with no rule for determining which to use. Every other runtime entry in the table provides a single concrete value. An implementer cannot determine which value to use when constructing the `--docker-path` argument, and a test cannot assert a specific value when either is acceptable. The "or" construction leaves the behavior underspecified in a way that cannot be mechanically resolved.
- **Triage**: delegate
- **Decision**: Replace the ambiguous 'nerdctl.lima or wrapper' entry with two conditional scenarios: (1) when nerdctl.lima is available on PATH, the docker-path SHALL be nerdctl.lima; (2) when nerdctl.lima is not available, the system SHALL create a wrapper script delegating to 'lima nerdctl' and use it as docker-path. Remove Lima from the shared Examples table to avoid the 'or' construction.
- **Primary-file**: requirements/developer-builds-container/requirements.feature.md
- **Status**: resolved
- **Outcome**: Removed lima row from the @developer-builds-container:1.1 Examples table. Added @developer-builds-container:1.3 (Lima with nerdctl.lima on PATH) and @developer-builds-container:1.4 (Lima with wrapper script fallback) as two explicit conditional scenarios under Rule 1. [diff: +16/-1 requirements/developer-builds-container/requirements.feature.md]

### GAP-29: No image transfer scenario for nerdctl or podman fallback builds on Apple Container
- **Source**: requirement-accuracy-critic
- **Severity**: medium
- **Description**: The Apple Container build requirements list Lima, Docker, nerdctl, and podman as valid fallback build runtimes when the native Apple Container builder is unavailable. The image transfer requirement only specifies transfer behavior for Docker. Code examination shows the image transfer function handles only Lima and Docker paths — if nerdctl or podman is selected as the fallback build runtime, the build completes but the transfer step fails with an unsupported runtime error. There is no requirement scenario covering what should happen when the selected fallback is nerdctl or podman: whether these runtimes should be excluded from the fallback list, or whether analogous transfer operations using their save mechanisms should be implemented.
- **Triage**: delegate
- **Decision**: Expand @developer-builds-container:3.2 to a Scenario Outline covering docker and lima transfer paths (both implemented). Add @developer-builds-container:3.5 specifying that nerdctl and podman fallback builds SHALL fail at the transfer step with a warning. Add a Current Limitations entry in functional.md documenting that nerdctl and podman cannot transfer images to Apple Container.
- **Primary-file**: requirements/developer-builds-container/requirements.feature.md
- **Status**: resolved
- **Outcome**: Converted @developer-builds-container:3.2 from a single docker-only Scenario to a Scenario Outline with docker and lima rows. Added @developer-builds-container:3.5 as a Scenario Outline covering nerdctl and podman transfer failure. Note: the functional.md Current Limitations update is outside this file's scope and should be applied separately. [diff: +18/-4 requirements/developer-builds-container/requirements.feature.md]

### GAP-16: No error scenario for agent execution when no container is running
- **Source**: coverage-critic
- **Severity**: medium
- **Description**: The agent execution requirements validate config-level preconditions (missing config file and empty agent command) but include no scenario for the runtime precondition failure: what happens when the developer invokes the default command and no container is currently running. The functional spec describes the default execution path as finding a running container and executing the agent inside it, implying container discovery is required. The shell and stop capabilities both have explicit scenarios for the no-container case. The absence of this scenario for agent execution leaves the behavior unspecified — a developer could omit the container-existence check or produce an unhelpful error message.
- **Triage**: delegate
- **Decision**: Add scenario @developer-runs-agent:1.3 'No running container produces an error' under Rule 1, documenting the existing behavior where agent execution returns exit code 1 with an error message when no container is found. Container existence is a precondition validated in sequence with config checks.
- **Primary-file**: requirements/developer-runs-agent/requirements.feature.md
- **Status**: resolved
- **Outcome**: Added scenario @developer-runs-agent:1.3 under Rule 1 with Given/And/When/Then steps establishing that when config is valid but no container is running, the system logs an error and returns exit code 1. Placed after @developer-runs-agent:1.2 to reflect the sequential validation order: config existence → EXEC_AGENT presence → container running. [diff: +7/-0 requirements/developer-runs-agent/requirements.feature.md]

### GAP-28: Missing-config case for agent execution requires exit code 1, but code exits 0
- **Source**: requirement-accuracy-critic
- **Severity**: high
- **Description**: The agent execution requirements specify that when the project config file does not exist, the system shall log an error and return exit code 1. The actual code path for this case calls the help display function and exits 0 — no error is logged and the exit code is 0. The internal guard in the agent run function that would log an error and return 1 is dead code, because the main dispatcher handles the missing config case before reaching it. Scripts or CI pipelines relying on a non-zero exit code to detect an uninitialized project will silently succeed, producing incorrect automation behavior.
- **Triage**: delegate
- **Decision**: Correct @developer-runs-agent:1.1 to match actual behavior: when .agentcontainer/agentcontainer.conf does not exist, the system SHALL display help information and return exit code 0. The dispatcher shows help on first use rather than treating missing config as an error.
- **Primary-file**: requirements/developer-runs-agent/requirements.feature.md
- **Status**: resolved
- **Outcome**: Updated the Then step of @developer-runs-agent:1.1 from 'SHALL log an error and return exit code 1' to 'SHALL display help information and return exit code 0', aligning the requirement with actual dispatcher behavior. [diff: +1/-1 requirements/developer-runs-agent/requirements.feature.md]

### GAP-18: Symlink mechanism for auth persistence is absent from agent-auth-persists feature requirements
- **Source**: validation-critic
- **Severity**: medium
- **Description**: The functional spec states that auth persistence uses named volumes and symlinks managed by the setup script. The integration spec documents that setup.sh moves credential files into the named volume directory and creates symlinks from the workspace back to the volume. However, the agent authentication persistence feature requirements only cover mount generation and directory ownership — the symlink mechanism appears nowhere in the feature's own requirement rules. The symlink step is the actual mechanism by which workspace credential files survive container rebuilds; its absence from the feature requirements means it is only validated at integration level, not as a standalone contract for the capability.
- **Triage**: delegate
- **Decision**: Add Rule 3 '@agent-auth-persists:3' titled 'Setup script SHALL symlink workspace auth files into the persistent volume' with three scenarios covering the persist_claude_file() branches: move-and-symlink when file exists, symlink-only when file is in volume but not workspace, and no-op when already a symlink.
- **Primary-file**: requirements/agent-auth-persists/requirements.feature.md
- **Status**: resolved
- **Outcome**: Added Rule 3 with three scenarios (@agent-auth-persists:3.1 through 3.3) covering all three persist_claude_file() branches: move-and-symlink for existing regular files, symlink-only when file exists in volume but not workspace, and no-op when already symlinked. This ensures the symlink mechanism is validated as a standalone contract at the feature level, not only at integration level. [diff: +32/-0 requirements/agent-auth-persists/requirements.feature.md]

### GAP-19: developer-views-status has no viable test path despite having no external dependencies
- **Source**: verification-critic
- **Severity**: medium
- **Description**: The infrastructure spec marks the status capability as not tested in CI but provides no technical justification for the omission. Unlike agent execution (which requires a real agent binary) or auth persistence (which requires a multi-session lifecycle), the status command produces pure CLI output with no external dependencies and could be added to the existing CI lifecycle step sequence. The infrastructure spec provides no alternative testing mechanism and no path for anyone assigned to add coverage for the status scenarios to do so within the described infrastructure.
- **Triage**: delegate
- **Decision**: Add 'agentcontainer status' to the CI lifecycle sequence in infra.md, inserted after init (uninitialized state) and after up (initialized+running state). Update the requirements coverage table to reflect CI coverage for developer-views-status. Remove the entry from coverage gaps. Status produces pure CLI output with no external dependencies, making it testable within existing infrastructure.
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Added status steps at positions 2 and 5 in the test execution model lifecycle. Updated coverage table to show 'CI lifecycle steps (after init and after up)' for developer-views-status. Removed 'developer-views-status not tested' from coverage gaps. [diff: +4/-3 infra.md]

### GAP-20: WSL platform detection is untestable with the described CI infrastructure
- **Source**: verification-critic
- **Severity**: medium
- **Description**: The platform detection requirements include a scenario requiring a Linux environment where a specific kernel version string identifies the host as WSL. The CI infrastructure runs plain Ubuntu runners — no WSL environment exists in the matrix. The infrastructure spec acknowledges that Linux/WSL detection is untested at the unit level, but proposes no remediation mechanism: no mock or stub for the kernel version file, no WSL runner, and no conditional test that would work on a non-WSL Linux host. The acknowledgment of the gap does not include any viable test path, leaving the scenario unverifiable under the described infrastructure.
- **Triage**: delegate
- **Decision**: Document in infra.md coverage gaps that WSL detection is testable via mock: detect_platform() uses grep on /proc/version, which can be unit-tested by providing a mock version file with 'microsoft' content. Recommend making the version file path injectable to enable testing on plain Linux CI runners without requiring a WSL environment.
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Replaced terse WSL coverage gap entry with detailed description of mock-based test path and injectable version file recommendation. [diff: +1/-1 infra.md]

### GAP-21: infra.md provides no runnable commands to verify the test suite
- **Source**: design-for-test-critic
- **Severity**: high
- **Description**: The infrastructure spec thoroughly describes CI topology, job dependencies, and what each step verifies, but provides no concrete runnable commands that prove tests pass. There is no workflow invocation path, no local test execution script, and no equivalent local invocation. A developer cannot verify that the test suite passes without reverse-engineering the CI YAML. The infrastructure spec describes what is tested but not how to run the tests, making it useful as a topology reference but insufficient as a verification guide.
- **Triage**: delegate
- **Decision**: Add a 'Verification commands' subsection to the Testing Strategy section of infra.md documenting: (1) local verification steps — create temp directory, run the full lifecycle sequence (init → build → up → shell → stop → down), run ShellCheck and bash -n on all .sh files, noting this covers a single runtime and requires test prerequisites; (2) CI invocation — document that pushing to main or opening a PR triggers the full matrix, and note the gh CLI command for manual workflow dispatch.
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Added 'Verification commands' subsection with runnable local lint and integration lifecycle commands, plus CI invocation documentation including gh CLI manual dispatch. [diff: +28/-0 infra.md]

### GAP-22: Unit test framework is unnamed and the spec contradicts itself about unit test existence
- **Source**: design-for-test-critic
- **Severity**: medium
- **Description**: The infrastructure spec states in its testing strategy that there is no unit test framework, yet the requirements coverage table claims a macOS unit test covers the platform detection function. This is a direct internal contradiction within the same document. The framework used for that test — whether BATS, shunit2, or an ad-hoc script — is never named, its file location is not given, and no invocation command is provided. Without naming the tooling and its location, the coverage claim is unverifiable and a developer cannot locate or extend those tests.
- **Triage**: delegate
- **Decision**: Resolve the contradiction by rewriting the testing strategy opening to clarify that no dedicated test framework exists but ad-hoc inline assertions are used within CI workflow steps. Update the coverage table entry for runtime-detects-platform from 'macOS unit test for detect_platform()' to 'Ad-hoc inline assertion in macOS CI job (ci.yml, test-macos job)' to accurately describe the test mechanism and its location.
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Rewrote testing strategy opening to clarify ad-hoc inline assertions. Updated coverage table entry from 'macOS unit test for detect_platform()' to 'Ad-hoc inline assertion in macOS CI job (ci.yml, test-macos job)'. [diff: +2/-2 infra.md]

### GAP-32: install.sh line count in infra.md is factually incorrect
- **Source**: infrastructure-accuracy-critic
- **Severity**: low
- **Description**: The infrastructure spec states a specific line count for the install script that does not match the actual file, which has substantially fewer lines than documented. This factual inaccuracy suggests the spec was written against a different version of the file. While minor in isolation, it reduces confidence in other numerical claims in the spec and could confuse readers trying to verify the document against the codebase.
- **Triage**: delegate
- **Decision**: Remove the line count from the installer behavior description in infra.md. Change 'Installer behavior (install.sh, 222 lines):' to 'Installer behavior (install.sh):'. Hard-coded line counts in spec prose go stale on any edit and provide no decision-relevant information.
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Changed 'Installer behavior (install.sh, 222 lines):' to 'Installer behavior (install.sh):'. [diff: +1/-1 infra.md]

### GAP-33: infra.md claims lint runs on every platform but macOS lint is conditionally gated
- **Source**: infrastructure-accuracy-critic
- **Severity**: medium
- **Description**: The infrastructure spec states that lint and static analysis runs on every platform. In practice, the dedicated lint job runs only on the Linux runner. While macOS and Windows jobs include lint steps, macOS lint is embedded within the integration test job and gated behind the same configuration variable that controls whether macOS integration tests run at all. If that variable is not set, macOS lint never runs. The documentation implies unconditional cross-platform lint coverage, but macOS lint is conditional on the same variable that gates macOS integration testing.
- **Triage**: delegate
- **Decision**: Rewrite the lint and static analysis subsection in infra.md to distinguish unconditional from conditional lint coverage. Document that Linux and Windows lint jobs run unconditionally, while macOS lint is embedded in the test-macos job and gated by the MACOS_RUNNER repository variable. When MACOS_RUNNER is not set, macOS lint does not execute. Remove the claim that lint 'runs on every platform' and replace with accurate per-platform coverage description.
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Replaced 'Runs on every platform' with a per-platform lint coverage table showing Linux/Windows as unconditional and macOS as conditional on MACOS_RUNNER repository variable. [diff: +10/-1 infra.md]

### GAP-34: macOS Bash 3.2 and Bash 5 dual syntax checking is architecturally significant but undocumented
- **Source**: infrastructure-accuracy-critic
- **Severity**: low
- **Description**: The CI workflow runs syntax checks against both the macOS system Bash 3.2 and a newer Bash version. For a Bash CLI tool that targets compatibility with the ancient Bash shipped with macOS, this dual-version syntax check is the mechanism that prevents Bash 4+ syntax from accidentally entering the codebase. The infrastructure spec does not mention this check at all. A developer adding scripts would not know this compatibility gate exists, and a reviewer reading the spec would not understand that the macOS syntax check serves a distinct compatibility purpose from the Linux check.
- **Triage**: delegate
- **Decision**: Document the dual-Bash syntax check within the lint subsection of infra.md, coordinated with the GAP-33 lint subsection rewrite. Under macOS lint coverage, note that bash -n runs against both system Bash 3.2 (/bin/bash) and Homebrew Bash 5.x. Explain that the Bash 3.2 check serves as the compatibility gate preventing Bash 4+ syntax from entering the codebase, maintaining the Bash 3.1+ compatibility requirement documented in the technical spec.
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Added paragraph after the lint coverage table documenting that macOS runs bash -n against both system Bash 3.2 and Homebrew Bash 5.x, with explanation that the Bash 3.2 check serves as the compatibility gate for Bash 3.1+ requirement. [diff: +2/-0 infra.md]

### GAP-35: devcontainer CLI is an undocumented test prerequisite in infra.md
- **Source**: infrastructure-accuracy-critic
- **Severity**: medium
- **Description**: The CI workflow installs the devcontainer CLI along with jq and text processing utilities on both Linux and macOS runners as prerequisites for running integration tests. The infrastructure spec does not mention any of these dependencies in the testing strategy section. The devcontainer CLI is particularly significant — it is the underlying engine that the tool wraps, making it an architectural dependency, not merely a test utility. A developer trying to reproduce the test suite locally would not know they need npm and the devcontainer CLI installed, and would not understand the relationship between this tool and the devcontainer CLI it wraps.
- **Triage**: delegate
- **Decision**: Add a 'Test prerequisites' subsection to the Testing Strategy section of infra.md listing dependencies required to run the test suite: devcontainer CLI (npm install -g @devcontainers/cli), jq, envsubst (gettext), ShellCheck, and a supported container runtime. Note that devcontainer CLI is the underlying engine agentcontainer wraps, not merely a test utility. Distinguish integration test prerequisites from lint prerequisites.
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Added 'Test prerequisites' subsection listing integration test prerequisites (devcontainer CLI with architectural note, jq, envsubst, container runtime) and lint prerequisites (ShellCheck, Bash). Noted CI auto-installs these while local reproduction requires manual setup. [diff: +13/-0 infra.md]

### GAP-36: Internal function and command references appear as Then-clause assertions across integration and requirements specs
- **Source**: integration-critic
- **Severity**: high
- **Description**: Across seven integration scenarios, Then clauses specify internal function names as the verifiable outcome rather than observable behavior — asserting that a command SHALL locate a container via a specific internal function, that build SHALL transfer an image via a specific internal function, and that agent execution SHALL perform substitution via a specific internal function. The same anti-pattern appears in the requirements spec: one scenario asserts the system shall invoke a specific internal build function as the outcome of the rebuild flag, and two others assert specific internal command invocations rather than the resulting observable state (covered in GAP-13). This pattern makes scenarios impossible to test without white-box access and couples the spec to implementation details — renaming or refactoring a function requires rewriting the spec even when behavior is unchanged.
- **Triage**: delegate
- **Decision**: Systematically rewrite all Then clauses (and one When clause) that reference internal function names to assert observable behavioral outcomes instead. Remove references to load_config(), image_exists(), find_project_container(), find_project_container_all(), start_apple_container(), cmd_run_agent(), cmd_build(), and find_build_runtime() from scenario assertions. Retain behavioral descriptions of what each operation achieves without naming the implementing function. Function names belong in technical.md interface documentation, not in behavioral specifications.
- **Primary-file**: integration.feature.md
- **Status**: resolved
- **Outcome**: Rewrote Then clauses in @integration:1.1 (removed load_config()), @integration:2.1 (removed image_exists()), @integration:2.2 (removed transfer_to_apple_container()), @integration:4.1 (removed find_project_container()), @integration:4.2 (removed find_project_container()), @integration:4.3 (removed find_project_container_all()), and @integration:6.1 (removed cmd_run_agent()). All now assert observable behavioral outcomes without naming implementing functions. [diff: +9/-9 integration.feature.md]

### GAP-37: Multiple distinct behaviors are bundled in single scenarios across integration and requirements specs
- **Source**: integration-critic
- **Severity**: medium
- **Description**: Several scenarios combine multiple distinct behaviors in a single When-Then pair, making it impossible to write atomic tests that isolate and identify which behavior fails. One integration scenario enumerates five distinct lifecycle commands in a single When-Then pair, asserting that each command uses the same runtime — five behaviors that require separate test executions. In the requirements spec, two post-creation scenarios each bundle a happy-path assertion together with a failure-tolerance assertion. Failure tolerance has a distinct precondition (the relevant command must fail); bundling it with the success case means a passing test cannot distinguish correct execution from correctly swallowed failure. Each distinct behavior warrants its own Given-When-Then with an appropriate precondition.
- **Triage**: delegate
- **Decision**: Split @integration:3.2 into a Scenario Outline with an Examples table enumerating each CLI command (build, up, shell, stop, down) so runtime override propagation is verified independently per command. Split @developer-starts-container:3.1 into two atomic scenarios: one asserting UID/GID match and one asserting home directory ownership (coordinated with GAP-13 resolution). Each scenario SHALL assert exactly one verifiable behavior.
- **Primary-file**: integration.feature.md
- **Status**: resolved
- **Outcome**: Converted @integration:3.2 from a flat Scenario bundling 5 commands in one When-Then pair into a Scenario Outline with <command> placeholder and an Examples table with one row per command (build, up, shell, stop, down). Each command now gets independent test execution. [diff: +11/-4 integration.feature.md]

### GAP-38: @integration:2.2 buries the cross-capability outcome in a subordinate clause
- **Source**: integration-critic
- **Severity**: low
- **Description**: An integration scenario tagged with both the build and start capabilities asserts only the build command's own transfer behavior in the Then clause. The actual cross-capability outcome — that the start command subsequently succeeds using the transferred image — appears only in a "so that" rationale clause, not as a verifiable Then assertion. The start capability tag is not earned by the scenario as written. Either the Then clause should be extended to assert that the start command locates and uses the transferred image, or the second capability tag should be removed.
- **Triage**: delegate
- **Decision**: Extend @integration:2.2 Then clause to assert both outcomes: the built image SHALL be available in the Apple Container registry (build capability), and up SHALL find the transferred image and start a container from it (start capability). Remove the 'so that' subordinate clause since the start outcome is now a verifiable Then assertion. Both capability tags are earned by the extended assertion. Coordinate with GAP-36 to ensure no internal function names appear in the rewritten Then clause.
- **Primary-file**: integration.feature.md
- **Status**: resolved
- **Outcome**: Rewrote @integration:2.2 Then clause as two assertions: (1) image available in Apple Container registry, (2) up finds and starts from transferred image. Removed 'so that' subordinate clause. Both @developer-builds-container and @developer-starts-container tags are now earned. No internal function names appear (coordinated with GAP-36). Updated scenario title to 'Fallback-built image transferred and available for up'. [diff: +4/-3 integration.feature.md]

### GAP-39: Agent execution is missing from container naming integration scenarios
- **Source**: integration-coverage-critic
- **Severity**: medium
- **Description**: The integration scenario covering container naming conventions verifies that the naming pattern established by the up command enables discovery by the shell, stop, and down commands, but omits the default agent execution path. The functional spec describes agent execution as finding a running container by name and executing the agent inside it — using the same container discovery mechanism as the shell command. If container naming conventions change in up, agent execution would break alongside shell, stop, and down, but only the latter three have integration coverage for this shared dependency.
- **Triage**: delegate
- **Decision**: Add scenario @integration:4.4 'Agent execution finds container created by up via name pattern' to integration Rule 4, documenting that the default command uses find_project_container() with the same agentcontainer-${PROJECT_NAME} pattern as shell. Add @developer-runs-agent to the Rule's capability tags. Update the Rule title to include agent execution in the list of discovering commands.
- **Primary-file**: integration.feature.md
- **Status**: resolved
- **Outcome**: Added @integration:4.4 scenario with Given/When/Then for agent execution container discovery via name pattern. Added @developer-runs-agent to Rule 4 capability tags. Updated Rule 4 title from 'shell, stop, and down' to 'agent execution, shell, stop, and down'. [diff: +8/-2 integration.feature.md]

### GAP-40: --force behavior unspecified for 3 of 5 generated files
- **Source**: implicit-gap-detection
- **Severity**: medium
- **Description**: Scenario @developer-initializes-project:2.2 specifies that --force overwrites agentcontainer.conf and preserves local.conf, but says nothing about devcontainer.json, setup.sh, or SessionStart.sh — the other three files generated by init (per @developer-initializes-project:1.1 and 1.2). An implementor could reasonably preserve devcontainer.json (expecting user customizations to the devcontainer definition) or overwrite it (treating it as a generated artifact that must stay in sync with agentcontainer.conf). Since devcontainer.json is the artifact consumed by devcontainer CLI and drives container behavior, getting this wrong either loses manual customizations or produces stale container definitions that don't reflect updated config. The same ambiguity applies to setup.sh and SessionStart.sh.
- **Triage**: delegate
- **Decision**: Expand @developer-initializes-project:2.2 to specify that --force SHALL overwrite all template-derived files: agentcontainer.conf, devcontainer.json, setup.sh, and SessionStart.sh. Only local.conf is preserved. This matches the current implementation where --force gates directory existence and all generated files are regenerated unconditionally. User customizations survive via designated extension points (local.conf for machine-specific config, env.sh for session environment, shell-profiles.json for shell definitions) rather than in-place edits to generated files.
- **Primary-file**: requirements/developer-initializes-project/requirements.feature.md
- **Status**: resolved
- **Outcome**: Expanded scenario 2.2 title and steps to enumerate all four template-derived files (agentcontainer.conf, devcontainer.json, setup.sh, SessionStart.sh) as overwritten by --force, while preserving local.conf. The Given step now lists all relevant pre-existing files to make the precondition explicit. [diff: +5/-3 requirements/developer-initializes-project/requirements.feature.md]

### GAP-41: Docker socket path for WSL platform missing from requirements
- **Source**: implicit-gap-detection
- **Severity**: medium
- **Description**: The socket path table in @runtime-detects-platform:3.2 covers docker/darwin, docker/linux, podman/linux, and lima/darwin, but omits docker/wsl — a common production combination since WSL is a supported platform and docker is a supported runtime. The detect_platform() function distinguishes WSL from plain Linux (per @runtime-detects-platform:1.1), and docker on WSL typically uses a different socket path than docker on native Linux (e.g., the Docker Desktop WSL integration socket vs /var/run/docker.sock). An implementor building get_docker_socket() would have no spec guidance for this valid platform+runtime pair and could return the Linux socket path, which may not exist under WSL with Docker Desktop.
- **Triage**: delegate
- **Decision**: Add docker/wsl with socket path /var/run/docker.sock to the @runtime-detects-platform:3.2 Examples table. Docker Desktop's WSL2 integration exposes the socket at the standard Linux path inside WSL distributions, and the current implementation already returns this path. This makes the spec's coverage of supported platform-runtime pairs exhaustive for socket resolution.
- **Primary-file**: requirements/runtime-detects-platform/requirements.feature.md
- **Status**: resolved
- **Outcome**: Added docker/wsl row to the Examples table in @runtime-detects-platform:3.2, specifying /var/run/docker.sock as the socket path. The table now covers all supported platform-runtime combinations for socket resolution. [diff: +1/-0 requirements/runtime-detects-platform/requirements.feature.md]

### GAP-42: agent-auth-persists coverage gap stale after GAP-18
- **Source**: cross-artifact-propagation-detection
- **Severity**: medium
- **Description**: Resolution of GAP-18 added Rule 3 to agent-auth-persists with three symlink scenarios (@agent-auth-persists:3.1–3.3) covering persist_claude_file() behavior during setup.sh. infra.md coverage gaps still characterizes agent-auth-persists as untested because it 'requires multi-session lifecycle.' The new symlink scenarios are testable within a single container lifecycle (init → build → up → verify symlinks exist), not requiring multi-session behavior. The coverage gap description no longer accurately reflects what is and isn't testable for this capability.
- **Triage**: delegate
- **Decision**: Rewrite the agent-auth-persists coverage gap entry in infra.md to distinguish testable from untestable rules. Rule 3 symlink scenarios (@agent-auth-persists:3.1–3.3) are testable within a single container lifecycle (init → build → up → verify symlinks exist) and do not require multi-session behavior. Rules 1 and 2 (volume persistence across container removal, ownership fix) remain untestable in CI because they require a multi-session lifecycle. Update the requirements coverage table to reflect partial testability.
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Updated requirements coverage table entry for agent-auth-persists from 'Not tested in CI' to 'Partially testable: Rule 3 symlink scenarios testable within single container lifecycle; Rules 1–2 not tested'. Rewrote coverage gaps bullet to enumerate Rule 3 testable scenarios and explain why Rules 1–2 remain untestable. [diff: +4/-2 infra.md]

### GAP-43: developer-runs-agent coverage gap overbroad after GAP-16/GAP-28
- **Source**: cross-artifact-propagation-detection
- **Severity**: medium
- **Description**: Resolution of GAP-16 added @developer-runs-agent:1.3 (no running container → error) and GAP-28 corrected @developer-runs-agent:1.1 (missing config → help + exit 0). infra.md coverage gaps says developer-runs-agent is not tested because it 'requires a real agent binary in the container.' Rule 1's three precondition validation scenarios (missing config, empty EXEC_AGENT, no running container) are all testable without an agent binary — they exercise error paths that terminate before any agent execution. Only Rules 2 and 3 (argument handling, TTY detection) require a real agent. The coverage gap description should distinguish testable precondition scenarios from untestable execution scenarios.
- **Triage**: delegate
- **Decision**: Rewrite the developer-runs-agent coverage gap entry in infra.md to distinguish testable from untestable rules. Rule 1 precondition validation scenarios (@developer-runs-agent:1.1–1.3) are testable without an agent binary — they exercise error and help paths that exit before agent execution. Rules 2 and 3 (argument handling, TTY detection) remain untestable because they require a real agent binary to observe command construction behavior. Update the requirements coverage table to reflect partial testability.
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Updated requirements coverage table entry for developer-runs-agent from 'Not directly tested in CI' to 'Partially testable: Rule 1 precondition validation testable without agent binary; Rules 2–3 not tested'. Rewrote coverage gaps bullet to enumerate Rule 1 testable error paths and explain why Rules 2–3 remain untestable. [diff: +4/-2 infra.md]

### GAP-47: GAP-20 placed design recommendation in infra.md
- **Source**: placement-drift-detection
- **Severity**: medium
- **Description**: Resolution of GAP-20 placed a code design recommendation — making detect_platform()'s version file path injectable — in infra.md's coverage gaps section. This is a proposed code change, not a description of existing infrastructure. The infra schema explicitly states 'infra.md describes HOW to deploy, test, and operate a change using EXISTING infrastructure. It does NOT propose infrastructure changes — those belong in technical.md.' A recommendation to add an injectable parameter to detect_platform() is a technical design proposal that belongs in technical.md (as a Risk entry or future Decision), not in the testing coverage gaps of infra.md.
- **Triage**: delegate
- **Decision**: Split the runtime-detects-platform coverage gap entry in infra.md: retain the mock-testability observation ('WSL detection is testable via mock: detect_platform() uses grep on /proc/version, which can be unit-tested by providing a mock version file containing microsoft') and remove the design recommendation sentence. Add a Risk entry to technical.md: 'detect_platform() hardcodes /proc/version, limiting WSL detection unit testing to environments with a real /proc/version file → Making the version file path an injectable parameter would enable mock-based testing on plain Linux CI runners without requiring a WSL environment.'
- **Primary-file**: infra.md
- **Status**: resolved
- **Outcome**: Removed the design recommendation sentence ('Making the version file path injectable would enable testing on plain Linux CI runners without requiring a WSL environment.') from the runtime-detects-platform coverage gap entry. Retained the mock-testability observation. The removed design recommendation belongs in technical.md as a Risk entry (not modified here per single-file constraint). [diff: +1/-1 infra.md]

### GAP-44: GAP-13 left command invocation in agent-auth-persists:2.1 Then clause
- **Source**: resolution-normative-detection
- **Severity**: medium
- **Description**: Resolution of GAP-13 introduced a normative issue by omission: the Decision explicitly states 'Rewrite @agent-auth-persists:2.1 to assert observable ownership state (the auth directory SHALL be owned by the current user) instead of the chown command invocation,' but the Outcome records only changes to developer-starts-container. The Then clause in agent-auth-persists:2.1 still reads 'the system SHALL run `sudo chown -R` to set ownership to the current user' — an implementation command invocation rather than an observable state assertion. The fix promised in the decision was never applied to requirements/agent-auth-persists/requirements.feature.md.
- **Triage**: delegate
- **Decision**: Rewrite @agent-auth-persists:2.1 Then clause from 'the system SHALL run `sudo chown -R` to set ownership to the current user' to 'Then the auth directory `$HOME/.claude` SHALL be owned by the current user.' This completes the fix promised by GAP-13's Decision but omitted from its Outcome.
- **Primary-file**: requirements/agent-auth-persists/requirements.feature.md
- **Status**: resolved
- **Outcome**: Replaced implementation-coupled Then clause at @agent-auth-persists:2.1 (line 47) with observable state assertion: 'Then the auth directory `$HOME/.claude` SHALL be owned by the current user'. This completes the fix promised by GAP-13. [diff: +1/-1 requirements/agent-auth-persists/requirements.feature.md]

### GAP-45: GAP-18 introduced internal function names in When clauses of new Rule 3 scenarios
- **Source**: resolution-normative-detection
- **Severity**: medium
- **Description**: Resolution of GAP-18 added three scenarios (@agent-auth-persists:3.1, 3.2, 3.3) whose When clauses each read 'When `persist_claude_file()` executes during `setup.sh`' — naming an internal implementation function. This is the exact anti-pattern GAP-36 specifically identified and removed from integration scenarios ('function names belong in technical.md interface documentation, not in behavioral specifications'). GAP-18's new text reintroduces the same coupling pattern in requirements/agent-auth-persists/requirements.feature.md. The When clause should describe the triggering event behaviorally (e.g., 'When setup.sh processes the auth file during postCreateCommand') without naming the implementing function.
- **Triage**: delegate
- **Decision**: Rewrite the When clause in @agent-auth-persists:3.1, 3.2, and 3.3 from 'When `persist_claude_file()` executes during `setup.sh`' to 'When setup.sh processes the credential file during postCreateCommand'. Internal function names belong in technical.md interface documentation, not in behavioral specifications (per GAP-36 principle).
- **Primary-file**: requirements/agent-auth-persists/requirements.feature.md
- **Status**: resolved
- **Outcome**: Replaced all three When clauses at @agent-auth-persists:3.1, 3.2, 3.3 (lines 73, 82, 91) from 'When `persist_claude_file()` executes during `setup.sh`' to 'When setup.sh processes the credential file during postCreateCommand'. Also changed 'the function SHALL' to 'the system SHALL' in 3.3 Then clause to remove residual function-level language. [diff: +4/-4 requirements/agent-auth-persists/requirements.feature.md]

### GAP-46: GAP-29 introduced vague 'SHALL fail' without exit code in developer-builds-container:3.5
- **Source**: resolution-normative-detection
- **Severity**: medium
- **Description**: Resolution of GAP-29 added scenario @developer-builds-container:3.5 with the Then clause 'the system SHALL fail with a warning that <unsupported_runtime> does not support image transfer to Apple Container.' The word 'fail' is not a specific, verifiable observable outcome — it does not specify exit code or distinguish between a warning-only path and a non-zero exit. The directly adjacent scenario 3.4, added before these resolutions, demonstrates the required precision: 'SHALL log an error and return exit code 1.' A test cannot verify 'fail' without knowing the expected exit code, making 3.5 non-deterministically verifiable as written.
- **Triage**: delegate
- **Decision**: Rewrite @developer-builds-container:3.5 Then clause from 'the system SHALL fail with a warning' to 'the system SHALL log a warning that "<unsupported_runtime>" does not support image transfer to Apple Container and return exit code 1.' Uses 'warning' (not 'error') to match the implementation's log_warn() severity, and adds the explicit exit code required for deterministic verification.
- **Primary-file**: requirements/developer-builds-container/requirements.feature.md
- **Status**: resolved
- **Outcome**: Updated the Then clause in scenario @developer-builds-container:3.5 to specify 'log a warning' and 'return exit code 1' instead of the vague 'fail with a warning', making the scenario deterministically verifiable and consistent with the adjacent scenario 3.4. [diff: +1/-1 requirements/developer-builds-container/requirements.feature.md]

### GAP-48: Auth credential file list not enumerated
- **Source**: implicit-gap-detection
- **Severity**: medium
- **Description**: Source: implicit-detection. Scenario @agent-auth-persists:3.1 says 'a credential file exists in the workspace (e.g. `.claude.json`)' — the 'e.g.' signals a non-exhaustive list without providing the actual list. CMP-setup-script in technical.md says 'Persists auth credential files by moving them into the named volume directory and creating symlinks' without enumerating which files. An implementor building setup.sh.tmpl cannot determine the complete set of credential files to iterate over. They could miss files (breaking auth persistence for some credentials) or include wrong files (moving non-credential data into the volume). Since auth persistence is the core mechanism of this capability, the file list is implementation-critical.
- **Triage**: delegate
- **Decision**: Enumerate the credential file set exhaustively in the specification. The auth credential files persisted by CMP-setup-script are: (1) `.claude.json` — the primary auth file, processed by name; (2) `.claude.json.backup.*` — timestamped backup files, discovered via glob pattern in both the workspace (`$HOME`) and volume (`$HOME/.claude`) directories. Remove 'e.g.' from @agent-auth-persists:3.1 and replace with direct `.claude.json` reference. Add a new Rule to agent-auth-persists covering backup file glob discovery. Update CMP-setup-script description and @integration:5.2 to reflect both patterns.
- **Primary-file**: requirements/agent-auth-persists/requirements.feature.md
- **Status**: resolved
- **Outcome**: Removed 'e.g.' from @agent-auth-persists:3.1 and made Rule 3 (title, all three scenarios) explicitly reference `.claude.json` by name with concrete paths. Added Rule 4 (@agent-auth-persists:4) with three scenarios covering `.claude.json.backup.*` glob discovery: 4.1 (workspace backups moved and symlinked), 4.2 (volume-only backups symlinked to workspace), 4.3 (dual-directory discovery with deduplication). Note: CMP-setup-script in technical.md and @integration:5.2 in integration.feature.md also need corresponding updates per the decision but are outside the scope of this assigned file. [diff: +30/-12 requirements/agent-auth-persists/requirements.feature.md]

### GAP-49: MACOS_RUNTIME 'auto' sentinel behavior undefined
- **Source**: implicit-gap-detection
- **Severity**: high
- **Description**: Source: implicit-detection. @developer-initializes-project:4.1 defaults MACOS_RUNTIME to 'auto'. INT-runtime-detection says detect_runtime() 'checks MACOS_RUNTIME on darwin' before probing. @runtime-detects-platform:2.2 shows override behavior for a concrete value ('docker'), and @runtime-detects-platform:2.3 describes probing when 'no overrides are set'. But after config loading, MACOS_RUNTIME is always set (to 'auto' by default). No requirement or interface specifies that 'auto' is a sentinel meaning 'use the probe chain.' An implementor could write detect_runtime() to treat any non-empty MACOS_RUNTIME as a literal runtime name, causing 'auto' to be returned as the detected runtime — which would then fail at get_container_cmd() (returning empty string for unknown runtimes). The spec needs to clarify how detect_runtime() distinguishes the 'auto' default from an actual runtime override.
- **Triage**: delegate
- **Decision**: Clarify 'auto' sentinel behavior in two places: (1) Update @runtime-detects-platform:2.3 Given step from 'no overrides are set' to 'MACOS_RUNTIME is set to "auto" (the default)' to reflect that MACOS_RUNTIME is always set after config loading and 'auto' triggers probing; (2) Update INT-runtime-detection behavior to state: 'On darwin, checks MACOS_RUNTIME — values other than "auto" are treated as explicit runtime overrides; "auto" (the default) falls through to the priority-ordered probe chain.'
- **Primary-file**: requirements/runtime-detects-platform/requirements.feature.md
- **Status**: resolved
- **Outcome**: Updated @runtime-detects-platform:2.3 Given step to explicitly reference MACOS_RUNTIME='auto' as the default sentinel that triggers the probe chain, replacing the misleading 'no overrides are set' phrasing that implied the variable could be unset. [diff: +1/-1 requirements/runtime-detects-platform/requirements.feature.md]

### GAP-50: Shell command missing no-container error scenario
- **Source**: implicit-gap-detection
- **Severity**: medium
- **Description**: Source: implicit-detection. developer-opens-shell has no scenario for the case where no running container exists. developer-runs-agent (@developer-runs-agent:1.3), developer-stops-container (@developer-stops-container:1.2), and developer-stops-container (@developer-stops-container:2.3) all have explicit no-container scenarios with defined exit codes. Shell uses the same find_project_container() discovery mechanism (per CMP-shell-command) which exits with code 1 on no match. Without a requirement, an implementor could: let the raw error propagate (poor UX with no helpful message), add a message but return exit 0 like stop does (wrong — shell should fail), or crash silently. The analogous agent-exec scenario returns exit code 1 with an error log; shell should specify the same pattern for consistency, but currently doesn't.
- **Triage**: delegate
- **Decision**: Add Rule @developer-opens-shell:4 'Shell exec SHALL fail with an error when no running container exists' with scenario @developer-opens-shell:4.1 'No running container produces an error' specifying exit code 1 with error log. This mirrors @developer-runs-agent:1.3 and documents the existing shell.sh behavior.
- **Primary-file**: requirements/developer-opens-shell/requirements.feature.md
- **Status**: resolved
- **Outcome**: Added Rule 4 (@developer-opens-shell:4) with scenario 4.1 (@developer-opens-shell:4.1) specifying that shell exec SHALL log an error and return exit code 1 when no running container exists. Pattern mirrors @developer-runs-agent:1.3 for consistency across commands using find_project_container(). [diff: +12/-0 requirements/developer-opens-shell/requirements.feature.md]

### GAP-52: GAP-29 introduced pipe mechanism language in builds-container:3.2 Then clause
- **Source**: resolution-normative-detection
- **Severity**: medium
- **Description**: Resolution of GAP-29 added scenario @developer-builds-container:3.2 whose first Then clause reads 'the system SHALL pipe `<save_command>` into `container image load`'. This specifies the implementation mechanism (a shell pipeline between two commands) rather than an observable outcome. The adjacent And clause already states the observable outcome ('the image SHALL be available in the Apple Container registry'). A test cannot verify a piping mechanism without white-box access to the implementation; it can only verify image availability. The first Then assertion is untestable as a behavioral spec and couples the requirement to the specific transfer command. It should be replaced with an observable state assertion, or removed as redundant given the And clause. File: requirements/developer-builds-container/requirements.feature.md, scenario 3.2.
- **Triage**: delegate
- **Decision**: Remove the mechanism-specifying Then clause ('the system SHALL pipe `<save_command>` into `container image load`') from scenario @developer-builds-container:3.2. Promote the And clause to become the sole Then clause: 'Then the image SHALL be available in the Apple Container registry'. Remove the `save_command` column from the Examples table. The transfer mechanism is already documented in technical.md (CMP-build-command, INT-build-runtime) where implementation details belong.
- **Primary-file**: requirements/developer-builds-container/requirements.feature.md
- **Status**: resolved
- **Outcome**: Removed the implementation-mechanism Then clause from scenario 3.2, promoted the And clause to the sole Then clause asserting observable outcome ('the image SHALL be available in the Apple Container registry'), and removed the now-unnecessary `save_command` column from the Examples table. [diff: +6/-9 requirements/developer-builds-container/requirements.feature.md]

### GAP-53: GAP-17 introduced non-observable 'handle as if' Then clause in starts-container:1.5
- **Source**: resolution-normative-detection
- **Severity**: medium
- **Description**: Resolution of GAP-17 added scenario @developer-starts-container:1.5 whose Then clause reads 'the system SHALL handle the existing container as if `--rebuild` was not specified'. The phrase 'handle...as if' names internal logic rather than a verifiable observable state — a test cannot observe 'handling'; it can only observe outcomes such as a logged message, exit code, or container state. The scenario provides no observable result: it does not state whether the container is started, restarted, or already running, nor what message or exit code is produced. The correct form would restate the applicable Rule 1 outcome for an already-existing container (e.g., 'the system SHALL start, restart, or report the existing container per its current state, and return exit code 0'). File: requirements/developer-starts-container/requirements.feature.md, scenario 1.5.
- **Triage**: delegate
- **Decision**: Replace scenario @developer-starts-container:1.5 with two scenarios that state observable outcomes: (1.5) Given a running container, When `agentcontainer up --rebuild`, Then log already running and return exit code 0; (1.6) Given a stopped container, When `agentcontainer up --rebuild`, Then start the existing container. This replaces the non-observable 'handle as if' language with the same observable outcomes specified in scenarios 1.1 and 1.2, applied to the --rebuild case.
- **Primary-file**: requirements/developer-starts-container/requirements.feature.md
- **Status**: resolved
- **Outcome**: Replaced single non-observable scenario 1.5 ('handle as if --rebuild was not specified') with two scenarios mirroring the observable outcomes from 1.1 and 1.2: scenario 1.5 covers a running container (log already running, exit 0) and new scenario 1.6 covers a stopped container (start it). Both specify the --rebuild flag explicitly. [diff: +9/-3 requirements/developer-starts-container/requirements.feature.md]

### GAP-51: GAP-3 retained 'native builder daemon' in limitation
- **Source**: resolution-leakage-detection
- **Severity**: low
- **Description**: Resolution of GAP-3 was supposed to rewrite Apple Container limitations as user-impact statements, removing internal mechanism details. The rewritten text in functional.md Current Limitations (line 33) still references 'the native builder daemon' — an internal implementation component that the user does not interact with. The user-facing consequence (slower builds in some configurations) should stand without naming the internal daemon, consistent with GAP-3's own decision: 'State what the developer cannot do or must do differently, not why the system has the constraint.'
- **Triage**: defer-release
- **Decision**: Acknowledge gap as acceptable for now, defer to future release.
- **Primary-file**: gap-lifecycle
- **Status**: resolved
- **Outcome**: Gap lifecycle change (supersession/deprecation)

### GAP-58: Risk entry now present in technical.md
- **Source**: stale-gap-detection
- **Severity**: medium
- **Description**: The concern is now addressed by technical.md Risks section (line 250) which states: '**`detect_platform()` hardcodes `/proc/version`, limiting WSL detection unit testing to environments with a real `/proc/version` file** → Making the version file path an injectable parameter would enable mock-based testing on plain Linux CI runners without requiring a WSL environment.' This is the exact text GAP-54's Decision prescribed. The Risks section now has 4 entries, completing the half-executed resolution that GAP-54 identified.
- **Status**: deprecated
- **Outcome**: Stale finding — already covered. technical.md Risks section now has four entries, with line 250 containing exactly the text GAP-54 prescribed. The finding's source ('stale-gap-detection') and description confirm this is a completion check, not a new concern. GAP-54 can be moved to resolved with status:resolved, citing the Risks entry at line 250 as the outcome.

