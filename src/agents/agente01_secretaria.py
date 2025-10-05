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
