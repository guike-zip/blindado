#!/usr/bin/env python3
"""
responder_beta.py — responde quem comentou a palavra-chave (padrão: BETA) nos posts do @blindado.app.

Para cada comentário novo com a palavra:
  1. tenta uma RESPOSTA PRIVADA (DM ligada ao comentário, endpoint /messages com
     recipient.comment_id) com o convite do beta;
  2. responde PUBLICAMENTE no comentário ("te chamei no direct" ou, se a DM
     não saiu, "chama a gente no direct").

Por que a DM pode falhar: com o app Meta em modo desenvolvimento (acesso padrão), a
API só manda mensagem para quem tem função no app. Mandar para qualquer pessoa exige
"Advanced Access" em instagram_business_manage_messages, que só sai pela Análise do App
da Meta. O script tenta mesmo assim e registra o erro; a resposta pública funciona.

Estado: marketing/leads-respondidos.json (gitignored — tem @ de pessoas reais) guarda os
ids de comentário já tratados, então rodar de novo nunca responde duas vezes.

Uso:
  python3 responder_beta.py --dry-run          # mostra quem seria respondido
  python3 responder_beta.py                    # responde de verdade
  python3 responder_beta.py --link <outro link>   # padrão: TESTFLIGHT abaixo
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import publish_instagram as ig   # reaproveita .env, token, host e o contexto TLS

REPO = Path(__file__).resolve().parents[2]
ESTADO = REPO / "marketing" / "leads-respondidos.json"
# Grupo externo "Beta público" (App Store Connect), build 1.0.0 (5), limite 10.000 testadores.
TESTFLIGHT = "https://testflight.apple.com/join/Evt1DGrb"

SITE_BETA = "https://guike-zip.github.io/blindado/"
DM_COM_LINK = ("Oi! Que bom que você quer testar o Blindado 🛡️\n\n"
               "📱 iPhone: instala o TestFlight (app de testes da Apple) e abre este convite:\n{link}\n\n"
               "🤖 Android: o teste do Google Play é por e-mail. Deixa o e-mail da sua conta Google "
               "aqui que a gente te adiciona e manda o link:\n" + SITE_BETA + "\n\n"
               "Qualquer dúvida é só responder aqui.")
DM_SEM_LINK = ("Oi! Que bom que você quer testar o Blindado 🛡️\n\n"
               "Deixa seu e-mail e a plataforma (iPhone ou Android) aqui que a gente te manda o convite:\n"
               + SITE_BETA)
PUBLICA_DM_OK = "Te chamei no direct, @{user}! 💚"
PUBLICA_DM_FALHOU = "Oba, @{user}! Chama a gente no direct que te mandamos o convite 💚"


def norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", s.lower())
    return re.sub(r"[^a-z0-9 ]", " ", "".join(c for c in s if not unicodedata.combining(c)))


def carregar_estado() -> dict:
    if ESTADO.exists():
        return json.loads(ESTADO.read_text(encoding="utf-8"))
    return {"respondidos": {}}


def salvar_estado(estado: dict) -> None:
    ESTADO.parent.mkdir(parents=True, exist_ok=True)
    ESTADO.write_text(json.dumps(estado, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--palavra", default="BETA")
    ap.add_argument("--posts", type=int, default=10, help="quantos posts recentes varrer")
    ap.add_argument("--link", default=TESTFLIGHT, help="link público do TestFlight (vai na DM)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not ig.IG_ID or not ig.TOKEN:
        sys.exit("ERRO: credenciais não encontradas em scripts/instagram/.env")

    alvo = norm(args.palavra)
    estado = carregar_estado()
    feitos = estado["respondidos"]

    posts = ig.api("GET", "me/media", params={"fields": "id,permalink", "limit": args.posts}).get("data", [])
    pendentes = []
    for post in posts:
        dados = ig.api("GET", f"{post['id']}/comments",
                       params={"fields": "id,text,username,timestamp", "limit": 100}).get("data", [])
        for c in dados:
            if c["id"] in feitos or c.get("username") == "blindado.app":
                continue
            if alvo in norm(c.get("text", "")):
                pendentes.append((post, c))

    if not pendentes:
        print(f'Nenhum comentário novo com "{args.palavra}" nos últimos {len(posts)} posts.')
        return

    print(f'{len(pendentes)} comentário(s) novo(s) com "{args.palavra}":')
    for post, c in pendentes:
        print(f'  @{c.get("username")}: "{c.get("text", "").strip()}"  ({post.get("permalink", "")})')
    if args.dry_run:
        print("[DRY RUN] nada foi respondido.")
        return

    texto_dm = DM_COM_LINK.format(link=args.link) if args.link else DM_SEM_LINK
    for post, c in pendentes:
        user = c.get("username", "")
        dm_ok, erro_dm = False, ""
        try:
            ig.api("POST", f"{ig.IG_ID}/messages", data={
                "recipient": json.dumps({"comment_id": c["id"]}),
                "message": json.dumps({"text": texto_dm}),
            })
            dm_ok = True
        except Exception as e:
            erro_dm = re.sub(r"(IGAA|EAA)[A-Za-z0-9_\-]{10,}", r"\1<oculto>", str(e))[:300]

        publica = (PUBLICA_DM_OK if dm_ok else PUBLICA_DM_FALHOU).format(user=user)
        try:
            ig.api("POST", f"{c['id']}/replies", data={"message": publica})
            pub_ok = True
        except Exception as e:
            pub_ok = False
            print(f"  @{user}: resposta pública falhou — {str(e)[:200]}")

        feitos[c["id"]] = {
            "username": user,
            "comentario": c.get("text", ""),
            "post": post.get("permalink", ""),
            "dm": dm_ok,
            "erro_dm": erro_dm,
            "resposta_publica": pub_ok,
            "quando": datetime.now().isoformat(timespec="seconds"),
        }
        salvar_estado(estado)
        print(f"  @{user}: DM {'enviada' if dm_ok else 'NÃO enviada'} · resposta pública "
              f"{'ok' if pub_ok else 'falhou'}")
        if erro_dm:
            print(f"    motivo da DM: {erro_dm}")

    sem_dm = [v["username"] for v in feitos.values() if not v["dm"]]
    if sem_dm:
        print(f"\nSem DM automática ({len(sem_dm)}): mande o convite à mão para "
              + ", ".join("@" + u for u in sem_dm))


if __name__ == "__main__":
    main()
