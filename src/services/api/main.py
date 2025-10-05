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
