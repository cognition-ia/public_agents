#!/usr/bin/env bash
# agents/setup.sh
set -euo pipefail

log() { printf "[%s] %s\n" "$(date +'%F %T')" "$*"; }

cd "$(dirname "$0")"

# 1) .env
if [[ ! -f .env ]]; then
  log "Criando .env a partir de .env.example"
  cp .env.example .env
  # gera token jupyter se placeholder
  if grep -q 'JUPYTER_TOKEN=$(openssl' .env; then
    tok=$(openssl rand -hex 16)
    sed -i "s|JUPYTER_TOKEN=.*|JUPYTER_TOKEN=$tok|g" .env
  fi
else
  log ".env já existe, mantendo."
fi

# 2) Scripts executáveis
chmod +x scripts/*.sh || true

# 3) Pasta Supabase
mkdir -p supabase
[[ -f supabase/config.toml ]] || cat > supabase/config.toml <<'EOF'
# Gerenciado pelo Supabase CLI. Ajuste conforme necessário.
project_id = "agents-local"
[api]
port = 54321
[db]
port = 54322
EOF

log "Setup concluído."
log "Próximos passos: 'make build' e 'make up'"
