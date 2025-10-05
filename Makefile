# agents/Makefile

SHELL := /bin/bash
PROJECT := agents

# Carrega variáveis de ambiente se .env existir
ifneq ("$(wildcard .env)","")
include .env
export
endif

.PHONY: help build up down ps logs bash reset agent jupyter api supabase-up supabase-down new-agent fmt

help:
	@echo "Comandos:"
	@echo "  make build         - Build da imagem app"
	@echo "  make up            - Sobe app, db, pgadmin (detached)"
	@echo "  make down          - Derruba serviços"
	@echo "  make ps            - Lista serviços"
	@echo "  make logs          - Logs do app"
	@echo "  make bash          - Shell no app"
	@echo "  make agent         - Executa agente de exemplo"
	@echo "  make jupyter       - Abre JupyterLab no app"
	@echo "  make api           - Sobe FastAPI (reload)"
	@echo "  make supabase-up   - Inicia Supabase local via CLI"
	@echo "  make supabase-down - Para Supabase local"
	@echo "  make new-agent AGENT=name - Gera agente boilerplate"
	@echo "  make reset         - down + volumes (cuidado)"

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

ps:
	docker compose ps

logs:
	docker compose logs -f app

bash:
	docker compose exec app bash

reset:
	docker compose down -v

agent:
	docker compose exec app python src/agents/agente01_secretaria.py

jupyter:
	docker compose exec -e JUPYTER_TOKEN="$(JUPYTER_TOKEN)" app \
	  bash -lc 'jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token=$$JUPYTER_TOKEN'

api:
	docker compose exec app \
	  bash -lc 'uvicorn src.services.api.main:app --host $${API_HOST:-0.0.0.0} --port $${API_PORT:-8000} --reload'

supabase-up:
	bash scripts/supabase_local.sh up

supabase-down:
	bash scripts/supabase_local.sh down

new-agent:
	@if [ -z "$(AGENT)" ]; then echo "Use: make new-agent AGENT=agente02_novo"; exit 1; fi
	@f="src/agents/$(AGENT).py"; \
	if [ -f "$$f" ]; then echo "Arquivo $$f já existe"; exit 1; fi; \
	echo "Criando $$f"; \
	cat > "$$f" <<'PY'
#!/usr/bin/env python
import os
from src.common.config import settings
from src.services.db import get_supabase_client

def run():
    print("[INFO] Novo agente: $(AGENT)")
    sb = get_supabase_client()
    print("[INFO] Supabase:", "OK" if sb else "DESABILITADO")
    # TODO: implementar lógica do agente
    print("[OK] Agente finalizado.")

if __name__ == "__main__":
    run()
PY
	chmod +x "src/agents/$(AGENT).py"

fmt:
	docker compose exec app bash -lc "python -m pip install ruff black && ruff check --fix . && black ."
