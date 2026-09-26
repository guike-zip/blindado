#!/usr/bin/env python3
"""
auto_publish.py — Publicador automático da fila de posts do @blindado.app.
Gerado pelo Claude em 2026-07-31. Zero dependências (Python 3 padrão).

Como funciona:
  - Lê as pastas em  blindado/marketing/fila/  no formato  AAAA-MM-DD_HHMM_nome/
  - Quando a data/hora da pasta chega (horário local do Mac), publica:
      * video.mp4  → Reel
      * 1 imagem   → post único
      * 2+ imagens (slide*.png em ordem) → carrossel
    A legenda vem do arquivo legenda.txt dentro da pasta.
  - Depois de publicar, move a pasta para  blindado/marketing/publicados/
    e registra em  blindado/marketing/fila/log.txt
  - Pastas começando com "_" são ignoradas (use p/ pausar um post).

Uso manual:
  python3 auto_publish.py            # publica o que estiver vencido
  python3 auto_publish.py --dry-run  # só mostra a fila, não publica
  python3 auto_publish.py --folder marketing/fila/2026-08-05_1200_carrossel-ciencia
                                     # publica ESSA pasta agora, fora do horário

Agendamento: launchd roda este script às 7h, 12h e 18h (ver README-automacao.md).
Se o Mac estiver dormindo no horário, o launchd roda ao acordar e o script
publica o que ficou pendente (nunca perde um post, só atrasa).
"""
from __future__ import annotations

import argparse
import json
import mimetypes
import os
import re
import shutil
import socket
import ssl
import subprocess
import sys
import sys as _sys
import time
import urllib.parse
import urllib.request
import uuid
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent            # .../scripts/instagram
REPO = HERE.parent.parent                          # .../blindado
FILA = REPO / "marketing" / "fila"
PUBLICADOS = REPO / "marketing" / "publicados"
LOG = FILA / "log.txt"
LOCK = Path("/tmp/blindado_autopublish.lock")


_sys.path.insert(0, str(Path(__file__).resolve().parent))
from ca_tls import CTX as SSL_CTX   # a historia do conserto mora em ca_tls.py



# ---------------------------------------------------------------- .env loader
def load_env() -> None:
    for folder in [HERE, *list(HERE.parents)[:3]]:
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


def git_pull() -> None:
    """Puxa o remoto antes de olhar a fila (rodando em >1 maquina desde 20/09).

    `auto_publish.py` nao tinha NENHUMA nocao de git: cada maquina so olhava o
    disco local. Com duas maquinas no mesmo horario de cron, as duas podiam ler
    a mesma pasta pendente e publicar o MESMO post duas vezes, porque nenhuma
    sabia que a outra ja tinha ido. Isto reduz a janela de corrida de "ate 6h
    entre tiques" para "os segundos entre este pull e a chamada de publish" —
    nao elimina (as duas ainda podem rodar no mesmo segundo), so' torna raro.

    Falha aqui NAO bloqueia a publicacao — mesma filosofia do conferir_cano():
    rede instavel nao pode significar "nunca mais publica". Só fica registrado
    no log, pra quem olhar depois entender que a corrida nao foi checada nesse
    tique.
    """
    try:
        result = subprocess.run(
            ["git", "-C", str(REPO), "pull", "--rebase", "--autostash"],
            capture_output=True, text=True, timeout=60,
        )
        if result.returncode != 0:
            # Rebase pela metade travaria TODO git futuro neste disco (inclusive
            # o git_commit_push de daqui a pouco) ate alguem resolver a mao —
            # pior do que so' nao ter puxado. Volta pro estado de antes do pull.
            subprocess.run(["git", "-C", str(REPO), "rebase", "--abort"],
                            capture_output=True, text=True, timeout=30)
            log("  (aviso: git pull falhou — "
                + (result.stderr.strip() or result.stdout.strip())
                + " — publicando com o estado local mesmo assim, risco de corrida com outra maquina.)")
    except Exception as e:
        log(f"  (aviso: git pull falhou — {type(e).__name__}: {e} "
            "— publicando com o estado local mesmo assim.)")


def git_commit_push(message: str) -> None:
    """Registra a publicacao no remoto assim que ela acontece, uma pasta por vez.

    Roda por post, nao em lote no fim do main(): quanto antes isso chegar no
    remoto, menor a janela em que OUTRA maquina, rodando `git_pull()` antes de
    ler a fila, ainda enxerga a pasta como pendente e tenta publicar de novo.

    Falha aqui NUNCA desfaz nada nem re-lanca — o post JA ESTA NO AR nesse
    ponto (publish_and_archive so' chama isto depois do publish() ter
    retornado com sucesso). Um push que falha so' atrasa a outra maquina saber;
    ela se recupera sozinha no proximo pull de qualquer sessao.
    """
    try:
        subprocess.run(["git", "-C", str(REPO), "add", "-A", "--", "marketing"],
                        check=True, capture_output=True, text=True, timeout=30)
        commit = subprocess.run(["git", "-C", str(REPO), "commit", "-m", message],
                                 capture_output=True, text=True, timeout=30)
        if commit.returncode != 0:
            if "nothing to commit" not in (commit.stdout + commit.stderr):
                log(f"  (aviso: git commit falhou — {commit.stderr.strip() or commit.stdout.strip()})")
            return
        push = subprocess.run(["git", "-C", str(REPO), "push"],
                               capture_output=True, text=True, timeout=60)
        if push.returncode != 0:
            log(f"  (aviso: git push falhou — {push.stderr.strip()}. "
                "O post ESTA no ar; sincronize a mao com git pull/push.)")
    except Exception as e:
        log(f"  (aviso: sincronizacao git falhou — {type(e).__name__}: {e}. O post ESTA no ar.)")


def log(msg: str) -> None:
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{stamp}] {msg}"
    print(line)
    try:
        LOG.parent.mkdir(parents=True, exist_ok=True)
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except OSError:
        pass


# ---------------------------------------------------------------- HTTP helpers
def api(method: str, path: str, data: dict | None = None, params: dict | None = None) -> dict:
    url = f"{BASE}/{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    body = urllib.parse.urlencode(data).encode() if data else None
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header("Authorization", f"Bearer {TOKEN}")
    try:
        with urllib.request.urlopen(req, timeout=60, context=SSL_CTX) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"Erro da API ({e.code}): {e.read().decode()}") from e


def _multipart_upload(endpoint: str, file_path: str, extra_fields: dict) -> str:
    p = Path(file_path)
    content_type = mimetypes.guess_type(p.name)[0] or "application/octet-stream"
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
    with urllib.request.urlopen(req, timeout=300, context=SSL_CTX) as resp:
        return resp.read().decode().strip()


def host_file(file_path: str) -> str:
    """Hospeda imagem/vídeo em URL pública (catbox; fallback litterbox 1h).

    O catbox leva DUAS tentativas antes do fallback, e isso foi medido: em
    03/09 ele devolveu `HTTP 200 com corpo VAZIO` nas 6 imagens de uma
    publicação, e o mesmo arquivo subiu de primeira na tentativa seguinte,
    segundos depois. A falha é intermitente e cresce com o tamanho — não é
    User-Agent (testado com e sem, os dois passam).

    Por que insistir em vez de aceitar o fallback: o litterbox apaga em 1 HORA.
    Ele serve de emergência, não de hospedagem — se o Instagram demorar para
    baixar a imagem, o post falha com o erro 9004 e o arquivo já não existe.
    """
    ultima = None
    for tentativa in (1, 2):
        try:
            url = _multipart_upload("https://catbox.moe/user/api.php", file_path,
                                    {"reqtype": "fileupload"})
            if not url.startswith("https://"):
                raise RuntimeError(f"resposta inesperada {url!r}")
            break
        except Exception as e:
            ultima = e
            if tentativa == 1:
                log(f"  catbox falhou ({e}); tentando de novo...")
    else:
        url = None
    if url is None or not url.startswith("https://"):
        e = ultima
        log(f"  catbox falhou 2x ({e}); usando litterbox (retencao de 1h)...")
        url = _multipart_upload("https://litterbox.catbox.moe/resources/internals/api.php",
                                file_path, {"reqtype": "fileupload", "time": "1h"})
        if not url.startswith("https://"):
            raise RuntimeError(f"Falha no upload: {url!r}")
    log(f"  Hospedado: {url}")
    return url


# ---------------------------------------------------------------- IG publishing
def create_image_container(image_path: str, *, carousel_item: bool, caption: str | None = None) -> str:
    last_error = None
    for attempt in range(3):
        if attempt:
            log(f"  IG nao baixou a imagem; re-hospedando ({attempt + 1}/3)...")
            time.sleep(8)
        data = {"image_url": host_file(image_path)}
        if carousel_item:
            data["is_carousel_item"] = "true"
        if caption is not None:
            data["caption"] = caption
        try:
            result = api("POST", f"{IG_ID}/media", data=data)
        except RuntimeError as e:
            if '"code":9004' in str(e):
                last_error = e
                continue
            raise
        if "id" not in result:
            raise RuntimeError(f"Erro ao criar container: {result}")
        return result["id"]
    raise RuntimeError(f"Falha apos 3 tentativas: {last_error}")


def create_reel_container(video_path: str, caption: str) -> str:
    last_error = None
    for attempt in range(3):
        if attempt:
            log(f"  IG nao baixou o video; re-hospedando ({attempt + 1}/3)...")
            time.sleep(10)
        data = {"media_type": "REELS", "video_url": host_file(video_path), "caption": caption}
        try:
            result = api("POST", f"{IG_ID}/media", data=data)
        except RuntimeError as e:
            if '"code":9004' in str(e):
                last_error = e
                continue
            raise
        if "id" not in result:
            raise RuntimeError(f"Erro ao criar container de reel: {result}")
        return result["id"]
    raise RuntimeError(f"Falha apos 3 tentativas: {last_error}")


def wait_ready(container_id: str, *, tries: int = 40, interval: int = 15) -> bool:
    """Videos demoram a processar; espera ate ~10 min."""
    for i in range(tries):
        status = api("GET", container_id, params={"fields": "status_code"}).get("status_code", "")
        if status == "FINISHED":
            return True
        if status == "ERROR":
            raise RuntimeError(f"Container com erro: {container_id}")
        if i % 4 == 0:
            log(f"  Processando... {i * interval}s")
        time.sleep(interval)
    return False


def publish(container_id: str) -> str:
    result = api("POST", f"{IG_ID}/media_publish", data={"creation_id": container_id})
    if "id" not in result:
        raise RuntimeError(f"Erro ao publicar: {result}")
    return result["id"]


# ---------------------------------------------------------------- fila
def parse_due(folder: Path) -> datetime | None:
    """Nome AAAA-MM-DD_HHMM_slug → datetime local, ou None se formato invalido."""
    parts = folder.name.split("_")
    if len(parts) < 2:
        return None
    try:
        return datetime.strptime(parts[0] + parts[1], "%Y-%m-%d%H%M")
    except ValueError:
        return None


SLIDE_RE = re.compile(r"slide(\d+)", re.IGNORECASE)


def ordered_images(folder: Path) -> list[Path]:
    """Imagens da pasta na ordem em que devem sair no carrossel.

    slideN e ordenado por NUMERO, nao por texto: sorted() puro colocaria
    slide10 entre slide1 e slide2 e quebraria a narrativa do carrossel.
    Aborta se a sequencia tiver buraco ou se houver imagem fora do padrao,
    porque publicar um carrossel torto e pior do que nao publicar.
    """
    files = [p for p in folder.iterdir()
             if p.suffix.lower() in (".png", ".jpg", ".jpeg") and not p.name.startswith(".")]
    slides = [(int(m.group(1)), p) for p in files if (m := SLIDE_RE.fullmatch(p.stem))]
    if not slides:
        return sorted(files)
    if len(slides) != len(files):
        extras = ", ".join(sorted(p.name for p in files if not SLIDE_RE.fullmatch(p.stem)))
        raise RuntimeError(f"Pasta mistura slideN com outras imagens ({extras}).")
    numeros = sorted(n for n, _ in slides)
    if numeros != list(range(1, len(numeros) + 1)):
        raise RuntimeError(f"Slides fora de sequencia: achei {numeros}, esperava 1..{len(numeros)}.")
    return [p for _, p in sorted(slides)]


def publish_folder(folder: Path) -> str:
    caption_file = folder / "legenda.txt"
    caption = caption_file.read_text(encoding="utf-8").strip() if caption_file.exists() else ""
    video = folder / "video.mp4"
    images = ordered_images(folder)

    if video.exists():
        log(f"  Reel: {video.name}")
        cid = create_reel_container(str(video), caption)
    elif len(images) == 1:
        log(f"  Post unico: {images[0].name}")
        cid = create_image_container(str(images[0]), carousel_item=False, caption=caption)
    elif len(images) >= 2:
        log(f"  Carrossel de {len(images)} slides")
        ids = [create_image_container(str(img), carousel_item=True) for img in images]
        result = api("POST", f"{IG_ID}/media", data={
            "media_type": "CAROUSEL", "children": ",".join(ids), "caption": caption})
        if "id" not in result:
            raise RuntimeError(f"Erro ao criar carrossel: {result}")
        cid = result["id"]
    else:
        raise RuntimeError("Pasta sem video.mp4 nem imagens.")

    if not wait_ready(cid):
        raise RuntimeError("Timeout no processamento do container.")
    return publish(cid)


PREFIXO_DATA = re.compile(r"^_?\d{4}-\d{2}-\d{2}(?:_\d{4})?_")


def nome_arquivado(nome_pasta: str, quando: datetime) -> str:
    """Nome da pasta no arquivo: hora REAL da publicacao + apelido da peca.

    Existe separada para ser testavel sem publicar nada — o caminho que a usa
    so' roda depois de um post ir ao ar, entao exercita-lo de verdade custaria
    um post.

    Tira o prefixo de data agendada (com ou sem `_` de desativada, com ou sem
    hora, porque o arquivo tem os tres formatos) e recarimba com a hora de
    agora. Se nao houver prefixo reconhecivel, o nome inteiro vira apelido —
    melhor um nome redundante que um nome perdido.
    """
    apelido = PREFIXO_DATA.sub("", nome_pasta) or nome_pasta.lstrip("_")
    return f"{quando:%Y-%m-%d_%H%M}_{apelido}"


def publish_and_archive(folder: Path) -> bool:
    log(f"Publicando {folder.name}...")
    try:
        post_id = publish_folder(folder)
    except Exception as e:
        log(f"FALHOU ({e}). A pasta fica na fila; nova tentativa na proxima execucao.")
        return False
    PUBLICADOS.mkdir(parents=True, exist_ok=True)
    # O nome da pasta arquivada passa a ser a hora REAL da publicacao, nao a
    # agendada. Normalmente as duas coincidem (o cron publica na hora marcada) e
    # ninguem nota; publicacao manual quebra a coincidencia. Em 04/09 quatro
    # pecas agendadas para 05, 11, 13 e 16/09 sairam todas no dia 04, e o
    # arquivo passou a AFIRMAR datas que nunca aconteceram. Arquivo que mente e'
    # o fosil que este projeto passa o dia consertando.
    quando = datetime.now()
    destino = PUBLICADOS / nome_arquivado(folder.name, quando)
    shutil.move(str(folder), str(destino))
    # O rastro do post fica JUNTO da arte: sem isto, ligar desempenho a peca
    # depende de garimpar o log, e o `insights.py` so' devolve permalink.
    #
    # TUDO daqui pra baixo e' `try`, e a razao e' de ordem: neste ponto o post
    # JA ESTA NO AR. Deixar uma excecao subir aqui faria a funcao devolver
    # erro para um post publicado com sucesso — a pasta voltaria para a fila e
    # a proxima execucao PUBLICARIA DE NOVO. Registro que falha vira post
    # duplicado; por isso ele avisa e segue.
    try:
        link = ""
        try:
            link = api("GET", post_id, params={"fields": "permalink"}).get("permalink", "")
        except Exception:
            pass                      # permalink e' conveniencia; o id ja' resolve
        (destino / "publicado.json").write_text(json.dumps({
            "post_id": post_id,
            "permalink": link,
            "publicado_em": quando.isoformat(timespec="seconds"),
            "agendado_como": folder.name,
            "slides": len(list(destino.glob("slide*.*"))),
        }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    except Exception as e:
        log(f"  (aviso: nao gravei publicado.json — {e}. O post ESTA no ar.)")
    log(f"OK! Post ID {post_id} — movido para publicados/{destino.name}")
    git_commit_push(f"marketing: publicado {destino.name} (post {post_id})")
    return True


def conferir_cano() -> list[str]:
    """Confere o cano e devolve a lista de problemas (vazia = tudo bem).

    Existe por causa de uma quebra de 11 dias. O upload morreu em 21/08 e
    NINGUÉM viu, porque a fila estava vazia e o log dizia `Fila vazia.` três
    vezes por dia — que é **a mesma linha do sucesso e da quebra**. Quando a
    fila finalmente encheu, em 02/09, a falha apareceu de uma vez, com peça
    agendada e vencida.

    Por isso esta função roda em TODA execução, inclusive (principalmente) com
    a fila vazia: o que precisava de vigilância nunca foi a fila, foi o cano.

    Ela NÃO bloqueia a publicação. Um problema de rede passageiro não pode
    virar motivo para não tentar publicar — quem decide é a tentativa real.
    Isto aqui é instrumento, não portão.
    """
    problemas = []
    for host in ("catbox.moe", "graph.instagram.com"):
        try:
            with socket.create_connection((host, 443), timeout=15) as s:
                with SSL_CTX.wrap_socket(s, server_hostname=host):
                    pass
        except ssl.SSLCertVerificationError:
            problemas.append(f"{host}: certificado nao verifica (CA do python)")
        except Exception as e:
            problemas.append(f"{host}: {type(e).__name__}")

    if not IG_ID or not TOKEN:
        problemas.append(".env sem INSTAGRAM_BUSINESS_ID/ACCESS_TOKEN")
    else:
        try:
            api("GET", "me", params={"fields": "id"})
        except Exception as e:
            problemas.append(f"token recusado pelo Instagram ({type(e).__name__})")
    return problemas


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--folder", help="publica ESSA pasta agora, ignorando a data agendada")
    args = parser.parse_args()

    if not IG_ID or not TOKEN:
        log("ERRO: credenciais nao encontradas no .env")
        sys.exit(1)
    if not args.folder and not FILA.exists():
        log(f"Fila vazia (pasta {FILA} nao existe).")
        return

    # trava contra execucoes simultaneas (descarta trava > 2h = provavelmente morta)
    if LOCK.exists() and time.time() - LOCK.stat().st_mtime < 7200:
        log("Outra execucao em andamento; saindo.")
        return
    LOCK.write_text(str(os.getpid()))

    try:
        # Antes de tudo: puxa o remoto, pra nao publicar de novo o que outra
        # maquina ja publicou desde a ultima vez que este disco foi atualizado.
        git_pull()

        # Antes de olhar a fila: o cano. Ver conferir_cano() para o porquê.
        problemas = conferir_cano()
        if problemas:
            log("CANO QUEBRADO: " + "; ".join(problemas)
                + " — isso nao depende da fila; conserte antes do proximo tique.")
        else:
            log("cano OK (TLS + token)")

        if args.folder:
            folder = Path(args.folder).resolve()
            if not folder.is_dir():
                log(f"ERRO: pasta nao encontrada: {folder}")
                sys.exit(1)
            # valida a midia antes de sair publicando (ordem dos slides, buracos, etc.)
            midia = "video.mp4 (Reel)" if (folder / "video.mp4").exists() else \
                    ", ".join(p.name for p in ordered_images(folder)) or "NADA"
            log(f"{folder.name}: publicacao manual — {midia}")
            if args.dry_run:
                return
            sys.exit(0 if publish_and_archive(folder) else 1)

        now = datetime.now()
        pending = []
        for folder in sorted(FILA.iterdir()):
            if not folder.is_dir() or folder.name.startswith("_"):
                continue
            due = parse_due(folder)
            if due is None:
                continue
            pending.append((due, folder))

        if not pending:
            log("Fila vazia.")
            return

        for due, folder in pending:
            status = "VENCIDO -> publicar" if due <= now else f"agendado p/ {due:%d/%m %H:%M}"
            log(f"{folder.name}: {status}")

        if args.dry_run:
            return

        for due, folder in pending:
            if due > now:
                continue
            publish_and_archive(folder)
    finally:
        LOCK.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
