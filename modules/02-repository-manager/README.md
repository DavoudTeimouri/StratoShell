# 02‑repository‑manager

Remote **Sonatype Nexus 3** or **VMware Harbor** provisioner (Docker‑Compose).

## Disclaimer
Rapid Cloud‑Native setup. **Not** intended for high‑availability enterprise production.

## Default internal credentials
- **Nexus 3**: admin password `admin123` (stored in `sonatype-work/nexus3/admin.password`)
- **Harbor**: admin password `Harbor12345`

## Prerequisites on target host
- Docker Engine + Docker Compose installed
- Root (or sudo) SSH access
- Minimum resources: 4 CPU cores, 4 GiB RAM, 25 GiB free disk space

## Usage
```bash
cd modules/02-repository-manager
./execute.sh
```
The script will:
1. Prompt for target IP, SSH port, and authentication method.
2. Validate SSH connectivity.
3. Verify hardware specs and that no Nexus/Harbor container is already running.
4. Let you choose **Nexus 3** (port 8081) or **Harbor** (ports 80/443/4443).
5. Detect port conflicts and allow custom ports.
6. Generate an enterprise‑grade `docker-compose.yml` and transfer it to `/root/workspace/repository-manager/` on the remote host.
7. Run `docker compose up -d` remotely.
8. On success, print the remote URL(s).

## Monitoring & post‑install
- **Live logs (Nexus)**: `ssh -p <SSH_PORT> root@<TARGET_IP> "docker logs -f nexus"`
- **Live logs (Harbor)**: `ssh -p <SSH_PORT> root@<TARGET_IP> "docker logs -f harbor"`
- **Nexus initial admin password**: `ssh -p <SSH_PORT> root@<TARGET_IP> "cat /root/workspace/repository-manager/sonatype-work/nexus3/admin.password"`
- **Customisation**: edit the generated `docker-compose.yml` on the remote host (path `/root/workspace/repository-manager/`) to change resource limits, volume paths, or passwords, then run `docker compose up -d` again.

## Cleanup
If the script is interrupted (Ctrl+C) or any step fails, it automatically:
- Stops any partially started containers
- Removes `/root/workspace/repository-manager/` on the remote host
- Restores any altered host configuration

---
© Davoud Teimouri – StratoShell project