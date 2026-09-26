# Publicação no Instagram — @blindado.app (sob demanda)

**Nada é publicado sozinho.** Não há rotina/launchd: um post só vai ao ar quando
você pede ("publica o acesso-antecipado"). Os posts prontos ficam em
`marketing/fila/`; a data no nome da pasta é só a sugestão de quando postar.
Depois de publicar, a pasta vai para `marketing/publicados/` (com `publicado.json`)
e tudo fica registrado em `marketing/fila/log.txt`.

## Ver o que está pronto

```bash
/opt/homebrew/bin/python3 scripts/instagram/auto_publish.py --dry-run
```

## Publicar um post

```bash
/opt/homebrew/bin/python3 scripts/instagram/auto_publish.py --folder marketing/fila/2026-09-28_1200_acesso-antecipado --dry-run
```

Confere a mídia que vai sair (e a ordem dos slides). Se estiver certo, rode de
novo **sem** o `--dry-run`: publica na hora, move para `publicados/` e faz
commit + push do registro.

> Não rode `auto_publish.py` sem `--folder` e sem `--dry-run`: nesse modo ele
> publica TODAS as pastas com data vencida de uma vez.

## Como funciona a fila

Cada pasta em `marketing/fila/` segue o formato `AAAA-MM-DD_HHMM_nome/`:

- `video.mp4` + `legenda.txt` → publica como **Reel**
- `slide1.png ... slideN.png` + `legenda.txt` → publica como **carrossel**
- 1 imagem só + `legenda.txt` → post único

Para **adicionar** um post: crie uma pasta nova no mesmo formato.

## Detalhes importantes

- **Falha de rede/API?** A pasta continua na fila; é só pedir de novo. Erros ficam
  em `marketing/fila/log.txt`.
- **Token expirou?** (dura ~60 dias; gerado em 26/09/2026 no app Meta "guikeZip Publisher"
  → Casos de uso → API do Instagram → Configuração da API com login do Instagram → Gerar token
  na linha do blindado.app) Atualize `scripts/instagram/.env`. O log mostrará erro 190 quando isso acontecer.
- **Reels automáticos saem sem áudio em tendência** (a API não permite adicionar
  música). Para usar áudio em alta, publique pelo app e apague a pasta da fila.


## Criar um post novo (slides com a marca do Blindado)

O texto de cada post fica em `marketing/posts/<nome>.json` (fonte). O gerador desenha os
slides 1080x1350 com os tokens de `design/design-tokens.md` e já grava a `legenda.txt`:

```bash
python3 scripts/instagram/gerar_slides.py marketing/posts/acesso-antecipado.json marketing/fila/2026-09-28_1200_acesso-antecipado
```

Tipos de slide: `capa`, `texto`, `dominios`, `lista`, `cta` (ver o docstring do script).

## Leads do beta (quem comentou BETA)

```bash
python3 scripts/instagram/listar_interessados.py --palavra BETA --posts 5 --csv marketing/leads.csv
```

Lista quem comentou a palavra-chave. O DM com o convite do TestFlight é manual (DM
automático exige App Review da Meta). O `marketing/leads*.csv` é gitignored — o repo é
público e ali tem @ de pessoas reais.

**Não conte o presente nos posts:** quem entrar no beta ganha o app de graça no lançamento
oficial. Os posts só dizem "uma surpresa".
