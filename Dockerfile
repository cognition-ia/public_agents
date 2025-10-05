# agents/Dockerfile
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Dependências do sistema (ajuste se necessário)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl git ca-certificates tini \
  && rm -rf /var/lib/apt/lists/*

# Usuário sem privilégios
RUN useradd -ms /bin/bash appuser
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copia código (pode usar bind-mount no compose para dev)
COPY src /app/src
COPY .env.example /app/.env.example

# Exponha portas usadas no container (mapeadas no host via compose)
EXPOSE 8000 8888

# Entrypoint neutro para dev; comandos reais via `docker compose exec`
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bash", "-lc", "sleep infinity"]
