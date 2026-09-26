"""
publish_instagram.py — Publicação automática no Instagram (@blindado.app)
Gerado pelo setup-instagram (Claude) em 2026-07-29.

Fluxo: Instagram API com Login do Instagram (token IGAA) → graph.instagram.com
Zero dependências: usa apenas a biblioteca padrão do Python 3.

Uso:
  python3 publish_instagram.py --images slide1.png slide2.png --caption "legenda"
  python3 publish_instagram.py --images foto.png --caption "post único"
  python3 publish_instagram.py --images slides/*.png --caption "..." --dry-run
"""
from __future__ import annotations

import argparse
import json
import mimetypes
import os
import sys
import time
import urllib.parse
import urllib.request
import sys as _sys
from pathlib import Path as _Path
_sys.path.insert(0, str(_Path(__file__).resolve().parent))
from ca_tls import CTX as _CTX   # CA no codigo, nao no ambiente (ver ca_tls.py)
import uuid
from pathlib import Path


# ---------------------------------------------------------------- .env loader
def load_env() -> None:
    """Procura um .env na pasta do script e até 3 níveis acima."""
    here = Path(__file__).resolve().parent
    for folder in [here, *list(here.parents)[:3]]:
        env_file = folder / ".env"
        if env_file.exists():
            for line in env_file.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                os.environ.setdefault(key.strip(), value.strip())
            return


load_env()
IG_ID   = os.getenv("INSTAGRAM_BUSINESS_ID")
TOKEN   = os.getenv("INSTAGRAM_ACCESS_TOKEN")
VERSION = os.getenv("META_API_VERSION", "v23.0")
BASE    = f"https://graph.instagram.com/{VERSION}"


# ---------------------------------------------------------------- HTTP helpers
def api(method: str, path: str, data: dict | None = None, params: dict | None = None) -> dict:
    url = f"{BASE}/{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    body = urllib.parse.urlencode(data).encode() if data else None
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header("Authorization", f"Bearer {TOKEN}")
    try:
        with urllib.request.urlopen(req, timeout=60, context=_CTX) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"Erro da API ({e.code}): {e.read().decode()}") from e


def _multipart_upload(endpoint: str, image_path: str, extra_fields: dict) -> str:
    p = Path(image_path)
    content_type = mimetypes.guess_type(p.name)[0] or "image/png"
    boundary = uuid.uuid4().hex
    parts = []
    for name, value in extra_fields.items():
        parts.append(f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{value}\r\n".encode())
    parts.append(
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"fileToUpload\"; "
        f"filename=\"{p.name}\"\r\nContent-Type: {content_type}\r\n\r\n".encode()
        + p.read_bytes() + b"\r\n"
    )
    parts.append(f"--{boundary}--\r\n".encode())
    body = b"".join(parts)
    req = urllib.request.Request(endpoint, data=body, method="POST")
    req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")
    with urllib.request.urlopen(req, timeout=120, context=_CTX) as resp:
        return resp.read().decode().strip()


def host_image(image_path: str) -> str:
    """Hospeda a imagem em URL pública (a API do IG exige image_url).

    Tenta catbox.moe (permanente); se falhar, cai para litterbox (expira em 1h,
    suficiente para o Instagram baixar a imagem durante a publicação).
    """
    try:
        url = _multipart_upload("https://catbox.moe/user/api.php", image_path,
                                {"reqtype": "fileupload"})
        if not url.startswith("https://"):
            raise RuntimeError(f"Resposta inesperada do catbox: {url!r}")
    except Exception as e:
        print(f"  catbox falhou ({e}); usando litterbox...")
        url = _multipart_upload("https://litterbox.catbox.moe/resources/internals/api.php",
                                image_path, {"reqtype": "fileupload", "time": "1h"})
        if not url.startswith("https://"):
            raise RuntimeError(f"Falha no upload da imagem: {url!r}")
    print(f"  Hospedada: {url}")
    return url


# ---------------------------------------------------------------- IG publishing
def create_container(image_path: str, *, carousel_item: bool, caption: str | None = None) -> str:
    last_error = None
    for attempt in range(3):
        if attempt:
            print(f"  IG nao conseguiu baixar a imagem; re-hospedando (tentativa {attempt + 1}/3)...")
            time.sleep(8)
        data = {"image_url": host_image(image_path)}
        if carousel_item:
            data["is_carousel_item"] = "true"
        if caption is not None:
            data["caption"] = caption
        try:
            result = api("POST", f"{IG_ID}/media", data=data)
        except RuntimeError as e:
            # 9004 = falha do IG ao baixar a midia da URL; vale re-hospedar e tentar de novo
            if '"code":9004' in str(e):
                last_error = e
                continue
            raise
        if "id" not in result:
            raise RuntimeError(f"Erro ao criar container: {result}")
        print(f"  Container: {result['id']}")
        return result["id"]
    raise RuntimeError(f"Falha apos 3 tentativas: {last_error}")


def create_carousel(media_ids: list, caption: str) -> str:
    result = api("POST", f"{IG_ID}/media", data={
        "media_type": "CAROUSEL",
        "children": ",".join(media_ids),
        "caption": caption,
    })
    if "id" not in result:
        raise RuntimeError(f"Erro ao criar carrossel: {result}")
    print(f"  Carrossel: {result['id']}")
    return result["id"]


def wait_ready(container_id: str) -> bool:
    for i in range(12):
        status = api("GET", container_id, params={"fields": "status_code"}).get("status_code", "")
        if status == "FINISHED":
            return True
        if status == "ERROR":
            raise RuntimeError(f"Container com erro: {container_id}")
        print(f"  Processando... {i * 5}s")
        time.sleep(5)
    return False


def publish(container_id: str) -> str:
    result = api("POST", f"{IG_ID}/media_publish", data={"creation_id": container_id})
    if "id" not in result:
        raise RuntimeError(f"Erro ao publicar: {result}")
    return result["id"]


def run(images: list, caption: str, dry_run: bool = False) -> None:
    if not IG_ID or not TOKEN:
        print("ERRO: Credenciais nao encontradas. Confira o .env ao lado deste script.")
        sys.exit(1)
    missing = [i for i in images if not Path(i).exists()]
    if missing:
        print(f"ERRO: Imagens nao encontradas: {missing}")
        sys.exit(1)
    if len(images) > 10:
        print("ERRO: Maximo 10 imagens por carrossel.")
        sys.exit(1)

    kind = "1 imagem" if len(images) == 1 else f"carrossel de {len(images)} slides"
    print(f"\nPublicando {kind} em @{os.getenv('INSTAGRAM_USERNAME', 'instagram')}...")
    if dry_run:
        print("[DRY RUN] Tudo OK. Remova --dry-run para publicar de verdade.")
        return

    if len(images) == 1:
        print("\nPasso 1/2 - Criando container...")
        container_id = create_container(images[0], carousel_item=False, caption=caption)
    else:
        print("\nPasso 1/2 - Criando containers dos slides...")
        ids = [create_container(img, carousel_item=True) for img in images]
        print("\nMontando carrossel...")
        container_id = create_carousel(ids, caption)

    print("\nPasso 2/2 - Publicando...")
    if not wait_ready(container_id):
        print("ERRO: Timeout no processamento. Tente novamente em alguns minutos.")
        sys.exit(1)

    post_id = publish(container_id)
    print("\nPublicado com sucesso!")
    print(f"Post ID: {post_id}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Publica foto ou carrossel no Instagram.")
    parser.add_argument("--images", nargs="+", required=True, help="1 a 10 imagens (jpg/png)")
    parser.add_argument("--caption", required=True, help="Legenda do post")
    parser.add_argument("--dry-run", action="store_true", help="Valida tudo sem publicar")
    args = parser.parse_args()
    run(args.images, args.caption, args.dry_run)
