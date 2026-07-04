# StratoShell – Cloud‑Native Infrastructure Orchestrator

Accelerates provisioning of complex tooling stacks via modular Bash scripts and Git submodules.

## Architecture
- **Core (`main.sh`)**: interactive arrow‑key menu, discovers `modules/*/execute.sh` scripts and runs them.
- **Modules**: each lives in `modules/<name>/` and is a self‑contained Git submodule exposing a single `execute.sh` provisioner.

## Quick start
```bash
git clone --recurse-submodules https://github.com/DavoudTeimouri/StratoShell.git
cd StratoShell
./main.sh          # Arrow‑key menu – select a module to run
```

## Available Modules
| Module | Description |
|--------|-------------|
| `01-gitlab-setup` | Remote Docker‑Compose GitLab CE provisioner (hardware checks, port handling, cleanup). |

Add new modules as Git submodules under `modules/`.

---
© Davoud Teimouri – StratoShell project