#!/usr/bin/env python3
"""Contexto TLS com uma CA que EXISTE — compartilhado por todos os scripts.

Existe porque em 21/08/2026 o `/usr/local/bin/python3` passou de 3.9 para o
framework 3.14, que **não vem com as CAs instaladas**: qualquer HTTPS morre em
CERTIFICATE_VERIFY_FAILED. A fila de publicação ficou 11 dias quebrada sem
ninguém ver, e o conserto de 01/09 (um `SSL_CERT_FILE` no plist do launchd)
nunca chegou a rodar, porque o plist do REPOSITÓRIO foi editado e o INSTALADO
continuou o de 10/08.

Daí as duas decisões deste módulo:

1. **A CA vem do código, não do ambiente.** Conserto que depende de alguém
   lembrar de exportar uma variável — ou de reinstalar um arquivo — é conserto
   que volta a quebrar. Aqui roda igual pelo launchd, pelo terminal ou por
   outra sessão.
2. **Um arquivo só.** Em 03/09 o `auto_publish.py` foi consertado e os irmãos
   ficaram para trás: `publish_instagram.py` (o caminho manual documentado),
   `ig_story.py`, `apify_run.py` e `listar_interessados.py` seguiam com o
   defeito latente. Cinco cópias da mesma função seriam cinco chances de
   consertar quatro.

Uso:

    import sys; from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from ca_tls import CTX
    urllib.request.urlopen(req, timeout=60, context=CTX)

O `sys.path.insert` não é enfeite: estes scripts também são carregados por
`importlib.spec_from_file_location` (o `insights.py` faz isso), e nesse modo o
diretório do arquivo NÃO entra no `sys.path` sozinho.
"""
import ssl
from pathlib import Path


def contexto() -> ssl.SSLContext:
    try:
        import certifi                    # não existe no python 3.14 desta máquina
        return ssl.create_default_context(cafile=certifi.where())
    except Exception:
        pass
    for cand in ("/etc/ssl/cert.pem", "/usr/local/etc/openssl@3/cert.pem"):
        if Path(cand).exists():
            return ssl.create_default_context(cafile=cand)
    return ssl.create_default_context()   # último recurso: o padrão do python


CTX = contexto()
