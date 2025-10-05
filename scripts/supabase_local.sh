#!/usr/bin/env bash
# agents/scripts/supabase_local.sh
set -euo pipefail
cd "$(dirname "$0")/.."

CMD="${1:-up}"

CLI_IMAGE="supabase/cli:latest"
WORKDIR="/workspace"

run_cli() {
  docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD/supabase":"$WORKDIR" \
    -w "$WORKDIR" \
    -p 54321:54321 -p 54322:54322 \
    --name supabase_cli \
    "$CLI_IMAGE" "$@"
}

case "$CMD" in
  up|start)
    echo "[INFO] Iniciando Supabase local (API:54321, DB:54322)..."
    run_cli start -x studio -x imgproxy -x vector -x analytics -x edge-runtime
    ;;
  down|stop)
    echo "[INFO] Parando Supabase local..."
    run_cli stop
    ;;
  status)
    echo "[INFO] Status:"
    run_cli status || true
    ;;
  *)
    echo "Uso: $0 {up|down|status}"
    exit 1
    ;;
esac
