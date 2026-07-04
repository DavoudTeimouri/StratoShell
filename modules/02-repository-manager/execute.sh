#!/usr/bin/env bash
set -euo pipefail

# Disclaimer
echo "=== WARNING ==="
echo "Rapid Cloud‑Native setup for Nexus 3 / Harbor. NOT intended for high‑availability enterprise production."
echo ""
echo "Default internal credentials:"
echo "  Nexus 3 admin password: admin123 (stored in sonatype-work/nexus3/admin.password)"
echo "  Harbor admin password: Harbor12345"
echo ""

# Configuration
REQ_CPU=4
REQ_RAM_MB=4096
REQ_DISK_MB=25600
REMOTE_DIR="/root/workspace/repository-manager"

log() { printf "[%s] %s\n" "$(date +%T)" "$*"; }

prompt_ssh() {
  while true; do
    read -p "Target IP: " TARGET_IP
    read -p "SSH port [22]: " tmp; SSH_PORT=${tmp:-22}
    read -p "Auth method (password/key): " AUTH
    if [[ "$AUTH" == "key" ]]; then
      read -p "Private key path: " KEY_PATH
      SSH_OPTS=(-i "$KEY_PATH")
    else
      read -sp "SSH password: " SSH_PASS; echo
      SSH_OPTS=()
    fi
    if sshpass -p "${SSH_PASS-}" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "${SSH_OPTS[@]}" "root@$TARGET_IP" "echo ok" 2>/dev/null; then
      break
    else
      echo "Connection failed, retry."
    fi
  done
}

ssh_cmd() {
  if [[ -n "${SSH_PASS-}" ]]; then
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "${SSH_OPTS[@]}" "root@$TARGET_IP" "$@"
  else
    ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "${SSH_OPTS[@]}" "root@$TARGET_IP" "$@"
  fi
}

check_resources() {
  log "Checking hardware"
  CPU=$(ssh_cmd "nproc")
  RAM=$(ssh_cmd "free -m | awk '/Mem:/ {print \$2}'")
  DISK=$(ssh_cmd "df -BM \"$REMOTE_DIR\" 2>/dev/null || df -BM / | tail -1 | awk '{print \$4}'")
  DISK=${DISK%M}
  [[ $CPU -ge $REQ_CPU ]]   || { log "Insufficient CPU $CPU (<$REQ_CPU)"; exit 1; }
  [[ $RAM -ge $REQ_RAM_MB ]] || { log "Insufficient RAM ${RAM}MiB (<${REQ_RAM_MB}MiB)"; exit 1; }
  [[ $DISK -ge $REQ_DISK_MB ]] || { log "Insufficient Disk ${DISK}MiB (<${REQ_DISK_MB}MiB)"; exit 1; }
  log "Resources OK (CPU=$CPU RAM=${RAM}MiB Disk=${DISK}MiB)"
}

preexist_check() {
  log "Checking existing containers"
  if ssh_cmd "docker ps --filter name=nexus --filter name=harbor -q" | grep -q .; then
    log "Nexus or Harbor already running on target. Abort."
    exit 1
  fi
}

select_tool() {
  echo "Select repository manager to deploy:"
  echo "  1) Sonatype Nexus 3"
  echo "  2) VMware Harbor"
  read -p "Choice [1/2]: " choice
  case "$choice" in
    1) TOOL="nexus" ;;
    2) TOOL="harbor" ;;
    *) echo "Invalid"; exit 1 ;;
  esac
}

port_check() {
  if [[ "$TOOL" == "nexus" ]]; then
    PORTS=(8081)
  else
    PORTS=(80 443 4443)
  fi
  for i in "${!PORTS[@]}"; do
    p=${PORTS[$i]}
    while ssh_cmd "ss -tlnp | grep -w :$p" >/dev/null 2>&1; do
      echo "Port $p in use on remote."
      read -p "Enter alternative port for $p: " alt
      PORTS[$i]=$alt
    done
    echo "Port ${PORTS[$i]} free"
  done
}

generate_compose() {
  if [[ "$TOOL" == "nexus" ]]; then
    cat > compose.yml <<EOF
version: '3.8'
services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    restart: unless-stopped
    ports:
      - "${PORTS[0]}:8081"
    volumes:
      - ./sonatype-work:/nexus-data
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4g
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/"]
      interval: 30s
      timeout: 10s
      retries: 5
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
EOF
  else
    cat > compose.yml <<EOF
version: '3.8'
services:
  harbor:
    image: goharbor/harbor-core:latest
    container_name: harbor
    restart: unless-stopped
    environment:
      HARBOR_ADMIN_PASSWORD: Harbor12345
    ports:
      - "${PORTS[0]}:80"
      - "${PORTS[1]}:443"
      - "${PORTS[2]}:4443"
    volumes:
      - ./data:/data
      - ./config:/etc/harbor
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4g
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 5
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
EOF
  fi
  log "compose.yml generated for $TOOL"
}

upload_and_deploy() {
  ssh_cmd "mkdir -p $REMOTE_DIR && chmod 700 $REMOTE_DIR"
  scp -P "$SSH_PORT" "${SSH_OPTS[@]}" compose.yml "root@$TARGET_IP:$REMOTE_DIR/docker-compose.yml"
  ssh_cmd "cd $REMOTE_DIR && docker compose up -d"
  log "$TOOL deployed on $TARGET_IP"
}

cleanup() {
  log "Cleanup triggered"
  ssh_cmd "cd $REMOTE_DIR && docker compose down --volumes || true"
  ssh_cmd "rm -rf $REMOTE_DIR"
  exit 1
}
trap cleanup SIGINT SIGTERM ERR

# Execution flow
prompt_ssh
ssh_cmd "mkdir -p $REMOTE_DIR"
check_resources
preexist_check
select_tool
port_check
generate_compose
upload_and_deploy
log "Provisioning complete"
exit 0