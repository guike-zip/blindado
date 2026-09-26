# Análise do app da Meta — "guikeZip Publisher" (ID 2838919379825166)

Objetivo: acesso avançado às permissões do Instagram para que o `responder_beta.py` mande a DM
com o convite do TestFlight para **qualquer** pessoa que comentar BETA (hoje só funciona com
contas que têm função no app).

## Checklist

| Item | Status |
|---|---|
| E-mail de contato, categoria "Negócio e Páginas" | ✅ 26/09 |
| Política de privacidade — https://guike-zip.github.io/blindado/design/instagram-privacidade.html | ✅ 26/09 |
| Instruções de exclusão de dados — https://guike-zip.github.io/blindado/design/instagram-exclusao-dados.html | ✅ 26/09 |
| Ícone do app (escudo) | ✅ 26/09 |
| Permissão `instagram_business_manage_comments` adicionada ao caso de uso | ✅ 26/09 |
| Token regerado depois de adicionar comentários | ⏳ |
| ≥1 chamada de teste por permissão (30 dias): `content_publish` | ✅ post de 26/09 |
| ≥1 chamada: `manage_comments` e `manage_messages` (rodar `responder_beta.py` com um comentário BETA da @guike.zip) | ⏳ |
| Verificação da empresa (portfólio "Guike") — business.facebook.com → Central de Segurança → Iniciar verificação | ⏳ **só o dono** (dados da empresa/documentos) |
| Vídeo de tela por permissão | ⏳ |
| Enviar para análise e publicar o app (modo Live) | ⏳ |

URL "Termos de Serviço" está com `https://www.facebook.com/` (valor que a Meta repõe sozinha);
é opcional — deixe vazio ou aponte para uma página de termos se a análise reclamar.

## Textos para o formulário (colar em "Como seu app usará esta permissão")

**instagram_business_basic**
> Our app is an internal publishing tool used only by the owner of the Instagram professional
> accounts @blindado.app and @guike.zip. We read the account's own profile (username, id) and its
> own media list to know which posts to scan for comments and to confirm each publication.

**instagram_business_content_publish**
> We publish photo carousels created by our team to our own professional account @blindado.app
> (announcing the Blindado iPhone app beta). Posts are only published when the account owner
> runs the tool; there is no posting on behalf of third parties.

**instagram_business_manage_comments**
> Our posts ask people who want to join the free beta to comment the keyword "BETA". The tool
> reads comments on our own posts, finds the ones containing that keyword and replies publicly
> to each person once ("We sent you a DM!"). We store only the comment id, username and text
> locally to avoid replying twice; nothing is shared or used for ads.

**instagram_business_manage_messages**
> For each person who commented "BETA" on our own post, we send one private reply (using the
> comment id as recipient) containing the public TestFlight invite link of the beta. We do not
> send unsolicited messages, promotional sequences or messages to anyone who did not comment.
> Users can ask for data deletion by DM or e-mail (see our data deletion URL).

## Roteiro do vídeo de tela (um vídeo cobre as 4 permissões, ~2 min)

1. Mostrar o perfil @blindado.app no navegador (logado) e o post com a chamada "Comenta BETA".
2. No terminal: `python3 scripts/instagram/publish_instagram.py --images slide1.png slide2.png --caption "..."`
   → mostrar a saída "Publicado com sucesso" e o post novo aparecendo no perfil (**content_publish** + **basic**).
3. Com outra conta (@guike.zip), comentar **BETA** no post.
4. No terminal: `python3 scripts/instagram/responder_beta.py --dry-run` (lista o comentário) e depois
   `python3 scripts/instagram/responder_beta.py` → saída "DM enviada · resposta pública ok" (**manage_comments**).
5. Abrir o post e mostrar a resposta pública; abrir o direct da @guike.zip e mostrar a mensagem com o
   link do TestFlight (**manage_messages**).
6. Encerrar mostrando a página de privacidade e a de exclusão de dados.

Grave em inglês ou legende em inglês (a Meta pede o fluxo compreensível para o revisor).
