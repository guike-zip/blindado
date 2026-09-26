# Publicação automática no Instagram — @blindado.app

Sistema de fila: os posts ficam em `marketing/fila/`, cada um numa pasta com a
data e hora de publicação no nome. O `auto_publish.py` roda às **7h, 12h e 18h**
(via launchd) e publica o que estiver vencido. Depois de publicar, a pasta vai
para `marketing/publicados/` e tudo fica registrado em `marketing/fila/log.txt`.

## Ativar (UMA VEZ — copie e cole no Terminal)

```bash
mkdir -p ~/Library/LaunchAgents && cp /Users/guike/Documents/GitHub/blindado/scripts/instagram/com.blindado.autopublish.plist ~/Library/LaunchAgents/ && launchctl load ~/Library/LaunchAgents/com.blindado.autopublish.plist && echo "✅ Automação ativada"
```

Pronto. Não precisa fazer mais nada — os posts da fila saem sozinhos nos dias certos.

## Conferir se está tudo certo (opcional)

```bash
python3 /Users/guike/Documents/GitHub/blindado/scripts/instagram/auto_publish.py --dry-run
```

Mostra a fila e o que está agendado, sem publicar nada.

## Publicar um post agora (fora do horário)

Quando você não quer esperar a janela das 7h/12h/18h:

```bash
python3 /Users/guike/Documents/GitHub/blindado/scripts/instagram/auto_publish.py --folder marketing/fila/2026-10-01_1200_meu-post --dry-run
```

Confere a mídia que vai sair (e a ordem dos slides). Se estiver certo, rode de
novo **sem** o `--dry-run`. Publica na hora, ignora a data da pasta, e move para
`publicados/` igual à automação.

## Como funciona a fila

Cada pasta em `marketing/fila/` segue o formato `AAAA-MM-DD_HHMM_nome/`:

- `video.mp4` + `legenda.txt` → publica como **Reel**
- `slide1.png ... slideN.png` + `legenda.txt` → publica como **carrossel**
- 1 imagem só + `legenda.txt` → post único

Para **adiar** um post: renomeie a pasta com a nova data.
Para **pausar** um post: adicione `_` no início do nome (ex.: `_2026-08-17_...`).
Para **adicionar** um post: crie uma pasta nova no mesmo formato.

## Detalhes importantes

- **Mac dormindo/desligado no horário?** O launchd roda o script quando o Mac
  acordar e ele publica o que ficou pendente. Nenhum post é perdido, só atrasa.
- **Falha de rede/API?** A pasta continua na fila e o script tenta de novo na
  próxima janela (7h/12h/18h). Erros ficam em `marketing/fila/log.txt`.
- **Token expirou?** Gere um novo no painel Meta e atualize
  `scripts/instagram/.env`. O log mostrará erro 190 quando isso acontecer.
- **Reels automáticos saem sem áudio em tendência** (a API não permite adicionar
  música). É o preço da automação total — quando quiser turbinar um Reel
  específico, publique manualmente pelo app com áudio em alta e apague a pasta
  da fila.

## Desativar

```bash
launchctl unload ~/Library/LaunchAgents/com.blindado.autopublish.plist
```
