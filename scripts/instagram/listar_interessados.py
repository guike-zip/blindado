#!/usr/bin/env python3
"""
listar_interessados.py — lista quem comentou uma palavra-chave nos seus posts.

Feito para os posts do beta do Blindado ("comenta BETA"): em vez de rolar o app atras dos
comentarios, roda isso e recebe a lista pronta pra mandar direct na mao.

NAO manda DM automatico. Responder comentario por DM via API exige a permissao
de mensagens com Advanced Access e aprovacao no App Review da Meta — semanas de
processo. Ler comentario do proprio post nao exige nada disso.

Uso:
  python3 listar_interessados.py --palavra BETA
  python3 listar_interessados.py --palavra BETA --posts 5 --csv ../../marketing/leads.csv

Le INSTAGRAM_BUSINESS_ID e o token do .env que ja esta em scripts/instagram/.
"""

import argparse
import csv
import json
import re
import sys
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
import sys as _sys
from pathlib import Path as _Path
_sys.path.insert(0, str(_Path(__file__).resolve().parent))
from ca_tls import CTX as _CTX   # CA no codigo, nao no ambiente (ver ca_tls.py)
from pathlib import Path

API = "https://graph.instagram.com/v21.0"


def load_env():
    here = Path(__file__).resolve().parent
    env = {}
    for folder in [here, *here.parents[:3]]:
        f = folder / ".env"
        if not f.exists():
            continue
        for raw in f.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env.setdefault(k.strip(), v.strip().strip("'\""))
        break
    token = env.get("INSTAGRAM_ACCESS_TOKEN") or env.get("IG_TOKEN") or env.get("TOKEN")
    ig_id = env.get("INSTAGRAM_BUSINESS_ID")
    if not token or not ig_id:
        sys.exit(
            "ERRO: nao achei INSTAGRAM_BUSINESS_ID e/ou o token no .env.\n"
            "  Rode este script de dentro de scripts/instagram/."
        )
    return ig_id, token


def get(path, token, **params):
    params["access_token"] = token
    url = f"{API}/{path}?{urllib.parse.urlencode(params)}"
    try:
        with urllib.request.urlopen(url, timeout=30, context=_CTX) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")[:300]
        if e.code == 400 and "permission" in body.lower():
            sys.exit(f"ERRO {e.code}: o token nao tem permissao de ler comentarios.\n  {body}")
        sys.exit(f"ERRO HTTP {e.code}: {body}")
    except urllib.error.URLError as e:
        sys.exit(
            f"ERRO de rede: {e.reason}\n"
            "  O sandbox na nuvem nao alcanca graph.instagram.com. "
            "Rode no terminal do seu Mac."
        )


def norm(s):
    s = unicodedata.normalize("NFKD", s.lower())
    return re.sub(r"[^a-z0-9 ]", " ", "".join(c for c in s if not unicodedata.combining(c)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--palavra", default="BETA", help="palavra-chave (padrao: BETA)")
    ap.add_argument("--posts", type=int, default=3, help="quantos posts recentes varrer")
    ap.add_argument("--csv", help="salva o resultado tambem em CSV")
    args = ap.parse_args()

    ig_id, token = load_env()
    alvo = norm(args.palavra)

    media = get(f"{ig_id}/media", token, fields="id,caption,permalink,timestamp",
                limit=args.posts).get("data", [])
    if not media:
        sys.exit("Nenhum post encontrado.")

    achados, vistos = [], set()
    for post in media:
        data = get(f"{post['id']}/comments", token,
                   fields="id,text,username,timestamp,like_count", limit=200)
        for c in data.get("data", []):
            if alvo not in norm(c.get("text", "")):
                continue
            user = c.get("username", "")
            if user in vistos:
                continue
            vistos.add(user)
            achados.append({
                "username": user,
                "comentario": c.get("text", "").strip(),
                "quando": c.get("timestamp", "")[:16].replace("T", " "),
                "post": post.get("permalink", ""),
            })

    if not achados:
        print(f'Ninguem comentou "{args.palavra}" nos ultimos {len(media)} posts (ainda).')
        return

    achados.sort(key=lambda a: a["quando"], reverse=True)
    print(f'\n{len(achados)} pessoa(s) comentaram "{args.palavra}":\n')
    for i, a in enumerate(achados, 1):
        print(f'{i:2}. @{a["username"]:<24} {a["quando"]}')
        print(f'    "{a["comentario"]}"')
        print(f'    {a["post"]}\n')

    print("Manda direct na mao pra cada um, citando o que a pessoa escreveu.")
    print("Nesse volume, DM escrito a mao converte muito mais que template.")

    if args.csv:
        out = Path(args.csv)
        with out.open("w", newline="", encoding="utf-8-sig") as fh:
            w = csv.DictWriter(fh, fieldnames=["username", "comentario", "quando", "post"])
            w.writeheader()
            w.writerows(achados)
        print(f"\nCSV salvo em {out}")


if __name__ == "__main__":
    main()
