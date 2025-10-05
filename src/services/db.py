# agents/src/services/db.py
from typing import Optional
from src.common.config import settings

def get_supabase_client() -> Optional[object]:
    """
    Retorna cliente Supabase se SUPABASE_URL e chave estiverem configurados.
    Para Supabase local via CLI:
      - SUPABASE_URL=http://localhost:54321 (no host)
      - Dentro do contêiner, use http://host.docker.internal:54321 (em Linux, prefira usar a porta exposta no host e chamar pela máquina host)
    """
    if not settings.SUPABASE_URL:
        return None
    try:
        from supabase import create_client, Client
        key = settings.SUPABASE_SERVICE_ROLE_KEY or settings.SUPABASE_ANON_KEY
        if not key:
            return None
        return create_client(settings.SUPABASE_URL, key)
    except Exception as e:
        print(f"[WARN] Supabase indisponível: {e}")
        return None
