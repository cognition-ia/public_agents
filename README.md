



-------------

agents/
├── docker/                       # Artefatos auxiliares de build/run (opcional)
├── scripts/                      # Automação (shell): supabase local, utilitários
│   └── supabase_local.sh
├── src/
│   ├── common/                   # Utilidades compartilhadas (config, logging, utils)
│   │   └── config.py
│   ├── agents/                   # Agentes (um arquivo por agente)
│   │   └── agente01_secretaria.py
│   └── services/                 # Serviços de infraestrutura (db, api, clientes)
│       ├── db.py
│       └── api/
│           └── main.py           # FastAPI opcional (ex.: /health, /agent/run)
├── supabase/                     # Pasta de trabalho do Supabase CLI (migr., seed)
│   └── config.toml               # Gerado/ajustado pelo CLI; versionável
├── .env.example                  # Variáveis mínimas (modelo)
├── docker-compose.yml            # Orquestração: app, db, pgadmin (+ supabase opcional)
├── Dockerfile                    # Imagem do app Python (3.11-slim)
├── requirements.txt              # Dependências do Python
├── Makefile                      # Alvos de automação (build/up/agent/jupyter/api/…)
├── README.md                     # Guia de uso (instalação, execução, troubleshooting)
└── setup.sh                      # Bootstrap idempotente (cria .env, pastas, permissões)

Função dos principais itens:

    src/common/config.py: centraliza carregamento de .env, valida chaves (OpenAI, Supabase…), helpers.

    src/services/db.py: cliente Supabase (via supabase-py) e/ou fallback psycopg para Postgres local.

    src/services/api/main.py: micro-API (FastAPI) para orquestrar/inspecionar agentes.

    scripts/supabase_local.sh: gerencia Supabase local via supabase/cli em contêiner (start/stop/status).

    supabase/: guarda migrações/seed do Supabase (para reprodutibilidade de schema/dados).

    Makefile: “façades” para Compose e comandos dentro do contêiner (Jupyter, Uvicorn, agentes).

    setup.sh: cria .env a partir de .env.example, gera segredos (tokens), marca scripts como executáveis.



Interação entre componentes:

Rede padrão do Compose isola app, db, pgadmin. O app acessa db por hostname db:5432.

pgadmin acessa db por hostname db.

Supabase local (opcional) roda em rede própria gerenciada pelo CLI; portas são publicadas em localhost (ex.: 54321 API, 54322 DB). O app então usa SUPABASE_URL=http://host.docker.internal:54321 (em Linux use localhost:54321 do host, pois a porta é publicada no host).





4.3 Agente exemplo src/agents/agente01_secretaria.py

# agents/src/agents/agente01_secretaria.py
#!/usr/bin/env python
import os
import sys
from src.common.config import settings
from src.services.db import get_supabase_client

def _run_with_agno(prompt: str) -> str:
    try:
        # Ajuste estas importações à API do Agno usada no seu projeto
        from agno import Agent
        # Exemplo genérico de agente; substitua conforme sua versão do Agno
        agent = Agent(
            name="agente01_secretaria",
            system_prompt="Você é uma secretária técnica, responda objetivamente.",
            openai_api_key=settings.OPENAI_API_KEY,
        )
        return agent.run(prompt)
    except Exception as e:
        return f"[ERRO/AGNO] {e}"

def _run_with_openai(prompt: str) -> str:
    from openai import OpenAI
    if not settings.OPENAI_API_KEY:
        return "[ERRO] OPENAI_API_KEY ausente."
    client = OpenAI(api_key=settings.OPENAI_API_KEY)
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "system", "content": "Você é uma secretária técnica."},
                  {"role": "user", "content": prompt}],
        temperature=0.2,
    )
    return resp.choices[0].message.content

def run():
    print("[INFO] Iniciando agente Secretaria (Agno -> OpenAI fallback)")
    sb = get_supabase_client()
    print("[INFO] Supabase:", "OK" if sb else "DESABILITADO")

    question = "Liste 3 próximos passos para organizar minha agenda da semana."
    out = _run_with_agno(question)
    if out.startswith("[ERRO/AGNO]"):
        print("[WARN] Agno indisponível, usando OpenAI direto.")
        out = _run_with_openai(question)

    print("[RESULTADO]")
    print(out)

if __name__ == "__main__":
    run()


4.4 API opcional src/services/api/main.py

# agents/src/services/api/main.py
from fastapi import FastAPI
from src.agents.agente01_secretaria import run as run_secretaria

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/agent/secretaria/run")
def exec_agent():
    run_secretaria()
    return {"status": "submitted"}



Execução típica (dev):
# 1) Shell no contêiner
make bash

# 2) Rodar agente
python src/agents/agente01_secretaria.py

# 3) Jupyter (em outra aba do host abrir http://127.0.0.1:8888)
make jupyter

# 4) FastAPI com reload (abrir http://127.0.0.1:8000/docs)
make api



5) Reprodutibilidade — passo a passo (Ubuntu 24.04 LTS + Docker)

5.1. Pré-requisitos no host: Docker Engine + Docker Compose v2 instalados e ativos.

5.2. Clonar o repositório:
git clone <seu-fork-ou-repo> agents
cd agents

5.3 Bootstrap:
bash setup.sh

5.4 Build e subida:
make build
make up

5.5 Teste do agente:
make agent

5.6 Jupyter opcional:
make jupyter
# abrir http://127.0.0.1:8888 com token definido em .env

5.7 FastAPI opcional:
make api
# abrir http://127.0.0.1:8000/docs


5.8 Supabase local (stack completa, opcional):
make supabase-up
# SUPABASE_URL=http://localhost:54321 no .env
# Para parar: make supabase-down


6) Segurança e versionamento (Git)

Commite:

Código (src/), scripts (scripts/), Dockerfile, docker-compose.yml, requirements.txt, Makefile, README.md, supabase/ (migrações/seed/config), setup.sh, .env.example.

Não commite:

.env (segredos), volumes (postgres-data), artefatos temporários (__pycache__, .ipynb_checkpoints), tokens, outputs.

Sugestão de .gitignore:

.env
__pycache__/
*.pyc
.ipynb_checkpoints/
.supabase/
*.sqlite
# Volumes/artefatos externos (se gerarem arquivos no tree)
data/


Gerenciamento de variáveis sensíveis:

.env apenas local; .env.example documenta chaves necessárias.

Em CI/CD (GitHub Actions/GitLab CI), use Secrets do repositório (NUNCA commit).

Para produção, prefira injetar env no runtime (Secrets do orquestrador, cofre, etc.).

CI/CD (boas práticas):

Job de lint/format (ruff/black), build de imagem, testes (unitários), scan (Trivy).

Build reprodutível com tag imutável (ex.: :sha-<git-short>).

Deploy automatizado com migrações de banco (se aplicável).

7) Extensibilidade — criando novos agentes

Criar esqueleto:

make new-agent AGENT=agente02_financeiro

Isso gera src/agents/agente02_financeiro.py pré-configurado usando config e db.

Reaproveitar módulos em src/common/ e src/services/:

Centralize log, tracing, schemas Pydantic, wrappers do Supabase, etc.

Padronize I/O do agente (ex.: protocolo run(input)->output).

Automação:

Adicione entradas no Makefile (targets por agente se necessário).

Se quiser templates mais ricos, crie scripts/new_agent.sh dedicado.

Como tudo se conecta (mental model)

Reprodutibilidade: Docker define SO + Python + libs; Compose define topologia (app, db, pgadmin).

Autocontido: .env e supabase/ (opcional) versionam os contratos de infra local; nenhuma dependência no host além de Docker.

Automação: Makefile e setup.sh removem diferenças entre estações; scripts/supabase_local.sh encapsula a stack Supabase.

Segurança: portas loopback (127.0.0.1), segredos fora do Git, usuário não-root no contêiner.

Extensibilidade: novos agentes = novos módulos em src/agents/ reutilizando common/ e services/.

Resumo técnico final (bullet points)

Stack base: Docker + Compose + .env + Makefile (decisão recomendada).

Serviços: app (Python 3.11 + Agno + OpenAI + FastAPI + Jupyter), db (Postgres 15), pgadmin (opcional).

Supabase local: opcional via supabase/cli em contêiner (make supabase-up), expondo 54321/54322.

Segurança: segredos apenas em .env local; portas limitadas a 127.0.0.1; usuário não-root; imagens slim.

Reprodutibilidade: build determinístico; migrações/seed versionáveis em supabase/; automação via setup.sh e Makefile.

DevX: make bash|agent|jupyter|api; make new-agent AGENT=... gera boilerplate.

Portabilidade: funciona em Ubuntu 24.04 LTS (host) e também em macOS/WSL2 com Docker.

Próximo passo: copie os arquivos acima para um repositório agents/, rode bash setup.sh, ajuste .env, e execute make build && make up && make agent.
