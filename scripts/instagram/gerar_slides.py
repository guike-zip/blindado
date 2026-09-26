#!/usr/bin/env python3
"""
gerar_slides.py — gera os slides (1080x1350) de um post do @blindado.app a partir de um JSON.

Monta um HTML por slide com os tokens de design/design-tokens.md e tira print com o
chrome-headless-shell que o Playwright já deixou em ~/Library/Caches/ms-playwright.
Zero pip install, zero serviço externo, fontes do sistema (SF Pro / SF Mono — as mesmas
do app).

Uso:
  python3 gerar_slides.py post.json marketing/fila/2026-09-27_1200_acesso-antecipado

Grava slide1.png..slideN.png na pasta e, se o JSON tiver "legenda", o legenda.txt.

Formato do post.json:
  {
    "legenda": "texto do post...",
    "slides": [
      {"tipo": "capa",     "titulo": "...<em>...</em>", "sub": "...", "escudo": "protected"},
      {"tipo": "texto",    "rotulo": "o problema", "titulo": "...", "corpo": "..."},
      {"tipo": "dominios", "titulo": "...", "dominios": ["doubleclick.net", ...], "nota": "..."},
      {"tipo": "lista",    "titulo": "...", "itens": [{"ok": true, "texto": "...", "detalhe": "..."}]},
      {"tipo": "cta",      "titulo": "...", "palavra": "BETA", "sub": "..."}
    ]
  }

Regras de marca que o gerador aplica sozinho (design/brand-spec.md):
  - o escudo é o único elemento figurativo; cor só fala de estado
    (verde = protegido, âmbar = pendente, cinza = não configurado, vermelho = perigo);
  - <em> destaca em verde; <br> quebra linha;
  - o conteúdo fica no QUADRADO CENTRAL (a grade do perfil corta 135 px em cima e embaixo
    de um 4:5), então capa e CTA ainda leem certo na grade.
"""
import json
import subprocess
import sys
import tempfile
from html import escape
from pathlib import Path

LARGURA, ALTURA = 1080, 1350
REPO = Path(__file__).resolve().parents[2]

SHIELD = "M512 190L262 290V492c0 153 103 284 250 338c147-54 250-185 250-338V290L512 190Z"
CHECK = "M390 502L470 582L634 414"

ESTADO = {
    "protected": "#56DC85",
    "pending": "#F9B73F",
    "idle": "#8E939A",
    "danger": "#F75D59",
}

CSS = """
:root{
  --bg:#0B0F14; --surface:#181C22; --raised:#23282F; --fg:#F7F8FA; --muted:#ACB1B9;
  --tertiary:#8E939A; --sep:rgba(83,88,96,.62); --green:#56DC85; --onaccent:#021909;
  --amber:#F9B73F; --red:#F75D59;
  --sans:-apple-system,BlinkMacSystemFont,'SF Pro Display','SF Pro Text',system-ui,sans-serif;
  --mono:'SF Mono',ui-monospace,Menlo,monospace;
}
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1080px;height:1350px;background:var(--bg);color:var(--fg);font-family:var(--sans);
  -webkit-font-smoothing:antialiased;overflow:hidden}
.slide{position:relative;width:1080px;height:1350px;padding:135px 96px;display:flex;
  flex-direction:column;justify-content:center;
  background:radial-gradient(900px 700px at 50% 38%, rgba(86,220,133,.07), transparent 70%), var(--bg)}
em{font-style:normal;color:var(--green)}
.topo{position:absolute;top:56px;left:96px;right:96px;display:flex;justify-content:space-between;
  align-items:center;font:500 26px/1 var(--mono);color:var(--tertiary);letter-spacing:.02em}
.marca{display:flex;align-items:center;gap:14px;color:var(--fg);font:700 30px/1 var(--sans);letter-spacing:-.3px}
.marca svg{width:34px;height:34px}
.rodape{position:absolute;bottom:56px;left:96px;right:96px;display:flex;justify-content:space-between;
  font:500 26px/1 var(--mono);color:var(--tertiary)}
.rotulo{font:600 26px/1 var(--mono);color:var(--green);text-transform:uppercase;letter-spacing:.12em;
  margin-bottom:36px}
h1{font-weight:800;font-size:92px;line-height:1.02;letter-spacing:-3px}
h2{font-weight:750;font-size:72px;line-height:1.06;letter-spacing:-2.2px}
p.corpo{margin-top:40px;font-size:38px;line-height:1.38;color:var(--muted);max-width:860px}
.sub{margin-top:40px;font-size:40px;line-height:1.3;color:var(--muted)}
.escudo{width:300px;height:300px;margin:0 0 56px -28px}
.escudo.centro{margin:0 auto 56px}
.pill{display:inline-flex;align-items:center;gap:12px;padding:12px 22px;border-radius:999px;
  font:600 24px/1 var(--sans);text-transform:uppercase;letter-spacing:.06em}
.pill.ok{background:rgba(86,220,133,.16);color:var(--green)}
.pill.no{background:rgba(247,93,89,.16);color:var(--red)}
.cartao{margin-top:48px;background:var(--surface);border-radius:28px;overflow:hidden;
  box-shadow:0 1px 2px rgba(0,0,0,.4)}
.linha{display:flex;align-items:center;justify-content:space-between;gap:24px;padding:28px 36px;
  border-bottom:1px solid var(--sep)}
.linha:last-child{border-bottom:0}
.dom{font:400 36px/1.2 var(--mono);color:var(--fg)}
.item{display:flex;gap:28px;align-items:flex-start;padding:30px 36px;border-bottom:1px solid var(--sep)}
.item:last-child{border-bottom:0}
.ico{flex:0 0 52px;height:52px;border-radius:999px;display:grid;place-items:center}
.ico.ok{background:rgba(86,220,133,.16)} .ico.no{background:rgba(247,93,89,.16)}
.ico svg{width:30px;height:30px}
.item b{display:block;font-weight:650;font-size:38px;line-height:1.2;letter-spacing:-.4px}
.item span{display:block;margin-top:8px;font-size:30px;line-height:1.3;color:var(--muted)}
.nota{margin-top:32px;font-size:30px;line-height:1.35;color:var(--tertiary)}
.cta{text-align:center;align-items:center}
.cta h2{font-size:80px}
.botao{margin-top:60px;display:inline-flex;align-items:center;gap:22px;padding:34px 56px;border-radius:28px;
  background:var(--green);color:var(--onaccent);font:750 50px/1 var(--sans);letter-spacing:-.5px;
  box-shadow:0 6px 40px rgba(86,220,133,.28)}
.botao code{font:700 52px/1 var(--mono);background:rgba(2,25,9,.14);padding:10px 18px;border-radius:14px}
.cta .sub{max-width:820px}
.arrasta{margin-top:64px;font:500 28px/1 var(--mono);color:var(--tertiary)}
"""


def svg_escudo(cor: str, check: bool = True, classe: str = "escudo") -> str:
    visto = (f'<path d="{CHECK}" fill="none" stroke="#021909" stroke-width="56" '
             f'stroke-linecap="round" stroke-linejoin="round"/>') if check else ""
    halo = f' style="filter:drop-shadow(0 0 60px {cor}4D)"' if classe else ""   # elev.glow: 30% da cor do estado
    return (f'<svg class="{classe}"{halo} viewBox="150 150 724 724"><path d="{SHIELD}" fill="{cor}"/>'
            f'{visto}</svg>')


def icone(ok: bool) -> str:
    if ok:
        return ('<div class="ico ok"><svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" '
                'fill="none" stroke="#56DC85" stroke-width="2.6" stroke-linecap="round" '
                'stroke-linejoin="round"/></svg></div>')
    return ('<div class="ico no"><svg viewBox="0 0 24 24"><path d="M7 7l10 10M17 7L7 17" fill="none" '
            'stroke="#F75D59" stroke-width="2.6" stroke-linecap="round"/></svg></div>')


def moldura(conteudo: str, i: int, n: int, classe: str = "") -> str:
    marca = f'<div class="marca">{svg_escudo("#56DC85", check=False, classe="")}blindado</div>'
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{CSS}</style></head><body>'
            f'<div class="slide {classe}"><div class="topo">{marca}<span>@blindado.app</span></div>'
            f'{conteudo}<div class="rodape"><span>DNS privado · Safari</span>'
            f'<span>{i}/{n}</span></div></div></body></html>')


def render_slide(s: dict, i: int, n: int) -> str:
    t = s["tipo"]
    if t == "capa":
        cor = ESTADO.get(s.get("escudo", "protected"), ESTADO["protected"])
        html = svg_escudo(cor, check=s.get("escudo", "protected") == "protected")
        html += f'<h1>{s["titulo"]}</h1>'
        if s.get("sub"):
            html += f'<div class="sub">{s["sub"]}</div>'
        if s.get("arrasta", True) and n > 1:
            html += '<div class="arrasta">arrasta →</div>'
        return moldura(html, i, n)
    if t == "texto":
        html = f'<div class="rotulo">{s["rotulo"]}</div>' if s.get("rotulo") else ""
        html += f'<h2>{s["titulo"]}</h2>'
        if s.get("corpo"):
            html += f'<p class="corpo">{s["corpo"]}</p>'
        return moldura(html, i, n)
    if t == "dominios":
        html = f'<div class="rotulo">{s["rotulo"]}</div>' if s.get("rotulo") else ""
        html += f'<h2>{s["titulo"]}</h2><div class="cartao">'
        for d in s["dominios"]:
            html += (f'<div class="linha"><span class="dom">{escape(d)}</span>'
                     f'<span class="pill ok">Bloqueado</span></div>')
        html += "</div>"
        if s.get("nota"):
            html += f'<div class="nota">{s["nota"]}</div>'
        return moldura(html, i, n)
    if t == "lista":
        html = f'<div class="rotulo">{s["rotulo"]}</div>' if s.get("rotulo") else ""
        html += f'<h2>{s["titulo"]}</h2><div class="cartao">'
        for it in s["itens"]:
            det = f'<span>{it["detalhe"]}</span>' if it.get("detalhe") else ""
            html += f'<div class="item">{icone(it.get("ok", True))}<div><b>{it["texto"]}</b>{det}</div></div>'
        html += "</div>"
        return moldura(html, i, n)
    if t == "cta":
        html = svg_escudo(ESTADO["protected"], classe="escudo centro")
        html += f'<h2>{s["titulo"]}</h2>'
        html += f'<div><div class="botao">Comenta <code>{escape(s.get("palavra", "BETA"))}</code></div></div>'
        if s.get("sub"):
            html += f'<div class="sub">{s["sub"]}</div>'
        return moldura(html, i, n, classe="cta")
    raise SystemExit(f"tipo de slide desconhecido: {t!r}")


def chrome() -> str:
    base = Path.home() / "Library/Caches/ms-playwright"
    achados = sorted(base.glob("chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell"))
    if not achados:
        raise SystemExit("Não achei o chrome-headless-shell. Rode: npx playwright install chromium-headless-shell")
    return str(achados[-1])


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    post = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    destino = Path(sys.argv[2])
    if not destino.is_absolute():
        destino = REPO / destino
    destino.mkdir(parents=True, exist_ok=True)
    for velho in destino.glob("slide*.png"):
        velho.unlink()

    slides = post["slides"]
    if not 1 <= len(slides) <= 10:
        raise SystemExit("O Instagram aceita de 1 a 10 slides.")
    exe = chrome()
    with tempfile.TemporaryDirectory() as tmp:
        for i, s in enumerate(slides, 1):
            html = Path(tmp) / f"s{i}.html"
            html.write_text(render_slide(s, i, len(slides)), encoding="utf-8")
            png = destino / f"slide{i}.png"
            subprocess.run([exe, "--headless", "--hide-scrollbars", "--force-device-scale-factor=1",
                            f"--window-size={LARGURA},{ALTURA}", f"--screenshot={png}", html.as_uri()],
                           check=True, capture_output=True)
            if not png.exists():
                raise SystemExit(f"Falhou ao gerar {png.name}")
            print(f"  {png.relative_to(REPO)}")

    if post.get("legenda"):
        (destino / "legenda.txt").write_text(post["legenda"].strip() + "\n", encoding="utf-8")
        print(f"  {(destino / 'legenda.txt').relative_to(REPO)}")


if __name__ == "__main__":
    main()
