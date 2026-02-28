- [ ] Environment Variables
  - [ ] OPENSPEC_TELEMETRY=0
---
Claude Sandbox

 bubblewrap (bwrap): not installed
   · apt install bubblewrap

 socat: not installed
   · apt install socat

 seccomp filter: not installed (required to block unix domain sockets)
   · npm install -g @anthropic-ai/sandbox-runtime
   · or copy vendor/seccomp/* from sandbox-runtime and set
     sandbox.seccomp.bpfPath and applyPath in settings.json
