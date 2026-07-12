# StratoShell – Cloud‑Native Infrastructure Orchestrator

A modular, decoupled Bash‑based orchestrator that accelerates provisioning of complex Cloud‑Native tooling stacks via Git submodules. Each module is a self‑contained provisioner that runs entirely over SSH on a remote target, performing hardware validation, port collision resolution, Docker‑Compose generation, deployment, and automatic rollback on failure.

---

## Architecture Overview

| Layer | Responsibility |
|-------|----------------|
| **Core (`main.sh`)** | Discovers `modules/*/execute.sh`, presents an interactive ANSI arrow‑key menu, and hands off execution to the selected module. |
| **Modules** | Independent Git submodules under `modules/<name>/`. Each exposes a single `execute.sh` that implements a complete provisioning lifecycle (SSH connectivity → resource checks → compose generation → remote `docker compose up -d` → SIGINT cleanup). |
| **Submodule Design** | Users clone the entire project recursively so every module is fetched automatically: `git clone --recurse-submodules <SSH_GIT_URL>`. |

---

## Capability Matrix (Active Modules)

| Module | Description | Key Features |
|--------|-------------|--------------|
| **`01-gitlab-setup`** | Remote GitLab CE provisioner | Hardware checks (≥4 CPU / 4 GiB / 25 GiB), port‑collision loop (80/443/5050/22), enterprise `docker-compose.yml` with healthchecks & log rotation, SIGINT remote cleanup. |
| **`02-repository-manager`** | Dual‑tool: Sonatype Nexus 3 **or** VMware Harbor | Tool selection menu, per‑tool RAM minimums (Nexus 8 GiB / Harbor 4 GiB), disk ≥25 GiB, port resolution (Nexus 8081/8082, Harbor 80/443/4443), tuned compose with resource limits, SIGINT remote cleanup. |
| **`03-os-provisioner`** | Multi‑Distro OS provisioning via Ansible | Multi‑Distro Ansible Playbook Generator, NTP pools, DNS & Limits setup (Ubuntu/RHEL). |
| **`04-load-balancer`** | Active/Active HA Load Balancer Engine | HAProxy Enterprise Baseline / NGINX Advanced Reverse Proxy + Keepalived VRRP, strict IPv4 validation, path-isolated config generation, Docker Compose + Ansible deployment, SSL termination, zero-downtime VIP failover. [View Repo](https://github.com/davoudteimouri/04-load-balancer) |

---

## Quick Start & Execution

```bash
# 1. Clone recursively (fetches all submodules)
git clone --recurse-submodules git@github.com:DavoudTeimouri/StratoShell.git

# 2. Enter the project
cd StratoShell

# 3. Launch the interactive menu
./main.sh
```

The menu renders all discovered modules. Use **↑ / ↓** to navigate, **Enter** to run a module, **q** to quit. After a module finishes (or is interrupted), control returns cleanly to the menu.

---

## Cloning Requirements

**You must use the recursive flag** to pull the complete nested architecture:

```bash
git clone --recurse-submodules git@github.com:DavoudTeimouri/StratoShell.git
```

Without `--recurse-submodules`, the `modules/` directory will be empty and no provisioners will be available.

---

## Git Submodule Workflow

- **Adding a new module**
  ```bash
  cd modules
  git submodule add git@github.com:<owner>/<module-repo>.git <module-name>
  # ensure <module-name>/execute.sh exists and is executable
  git add .gitmodules <module-name>
  git commit -m "feat: add <module-name> submodule"
  git push
  ```

- **Updating a submodule to latest upstream**
  ```bash
  cd modules/<module-name>
  git pull origin main
  cd ../..
  git add modules/<module-name>
  git commit -m "chore: update <module-name> submodule"
  git push
  ```

---

## Requirements

- **Local**: Bash ≥ 4.0, `ssh`, `scp`, `sshpass` (for password auth), `git`.
- **Remote target**: Docker Engine + Docker Compose, root/sudo SSH access, resources per module matrix.

---

## License

MIT – © Davoud Teimouri – StratoShell project