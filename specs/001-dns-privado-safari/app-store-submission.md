# Submissão à App Store: Blindado

Rascunho de material de submissão. Revisar contra Constitution Princípio III (Conformidade com
a App Store Acima de Tudo) e Princípio IX (App Pago de Download Único) antes de enviar —
nenhum texto abaixo pode sugerir bloqueio de anúncios fora do Safari, nem compra/assinatura
dentro do app.

## Preço e modelo de negócio

- **Modelo**: app pago de **download único**. Sem compras dentro do app, sem assinatura, sem
  paywall, sem versão "Pro" — todo comprador tem acesso completo a Padrão, Família,
  Personalizado, Safari e Testar desde a primeira abertura (Constitution Princípio IX, FR-018).
- **Preço base (Tier do App Store Connect)**: **US$ 2,99**.
- **Preço no Brasil**: **R$ 14,90** (definido manualmente no App Store Connect para a
  territorialidade Brasil, em vez do câmbio automático do tier, por ser o valor psicológico
  usual da faixa "app pago simples" no mercado brasileiro).
- Nenhum SKU de IAP é criado no App Store Connect — apenas o preço de venda do app.

## Compatibilidade

- **Requer iOS 26 ou posterior.** Decisão deliberada: o app usa a linguagem visual nativa atual
  da Apple (Liquid Glass), cujas APIs não existem em versões anteriores (research.md #10). O
  App Store já impede a compra em dispositivos com iOS mais antigo, mas vale reforçar isso na
  ficha e nas notas de revisão para não gerar reembolso de quem tentar instalar antes de
  atualizar o sistema.

## Descrição (App Store)

> **Blindado — DNS privado e bloqueador de conteúdo para Safari**
>
> Blindado protege sua navegação com DNS criptografado em todo o iPhone — em Wi-Fi e também na
> rede celular — e com um bloqueador de conteúdo dedicado ao Safari.
>
> - Ative em poucos toques, sem cadastro e sem configuração técnica.
> - Escolha entre proteção Padrão, Família (também filtra conteúdo adulto) ou um servidor DNS
>   seguro personalizado — com mais de um provedor de DNS reconhecido disponível em cada nível
>   (AdGuard DNS e Control D), para você não depender de um único serviço.
> - Teste sua proteção a qualquer momento e veja exatamente o que está sendo bloqueado.
> - Bloqueador de conteúdo nativo para o Safari, fácil de habilitar e recarregar.
> - Zero coleta de dados. Zero servidor próprio. Suas consultas DNS vão diretamente para o
>   provedor que você escolher.
> - Pagamento único. Sem assinatura, sem compras dentro do app: tudo que o Blindado faz já vem
>   liberado no preço da compra.
>
> **O que o Blindado NÃO faz** (para você comprar sabendo exatamente o que está levando):
> - Não é uma VPN — não esconde seu IP nem troca sua localização.
> - Não bloqueia anúncios *dentro* de outros aplicativos, como YouTube, Instagram, TikTok ou
>   jogos. Ele age no DNS do sistema (o que reduz alguns rastreadores mesmo fora do Safari) e,
>   dentro do Safari, também remove elementos de página — mas não edita o conteúdo de outros
>   apps.
> - Não guarda histórico nem estatísticas de navegação — nem para você, nem para nós.
>
> O foco do Blindado é DNS privado em todo o sistema e um Safari mais limpo — nada além disso.

## Roteiro de screenshots (App Store)

Ordem pensada para reduzir mal-entendido de compra (o item 2 existe só para isso — colocado
cedo de propósito, antes do usuário já ter decidido comprar).

1. **Início — Blindado** (tela "proteção ativa", escudo verde): "Um toque, DNS criptografado
   no iPhone inteiro". Reforça a promessa central.
2. **O que o Blindado não faz** (tela de texto simples, não é screenshot de app, é uma arte
   com os 3 bullets de "NÃO faz" da descrição, mesma redação): "Antes de comprar, saiba
   exatamente o que o Blindado é — e o que não é". Screenshot deliberadamente "anti-venda",
   para reduzir reembolso de quem esperava bloqueio de anúncio dentro de app.
3. **Nível de proteção**: "Padrão, Família ou seu próprio servidor DNS seguro — sem depender
   de um único provedor".
4. **Testar**: "Veja com seus olhos o que está sendo bloqueado, domínio por domínio".
5. **Safari**: "Bloqueador de conteúdo nativo, direto nos Ajustes do Safari".
6. **Privacidade**: "Zero coleta. Zero servidor nosso. Você decide para onde suas consultas
   DNS vão".
7. **Ajustes/preço** (opcional, tela de loja ou card final): "Pagamento único. Sem assinatura,
   sem compra dentro do app — tudo liberado."

## Palavras-chave

`dns privado, dns criptografado, bloqueador safari, content blocker, privacidade, anti-rastreador, dns seguro, navegação segura, dns família, controle parental safari`

## Notas de revisão (App Review Notes)

> Este app usa `NEDNSSettingsManager` (Network Extension → DNS Settings) para configurar
> DNS-over-HTTPS em todo o sistema. Não implementamos VPN nem um Packet Tunnel Provider — apenas
> a API de configuração de DNS do sistema, que exige confirmação manual do usuário em
> Ajustes > Geral > VPN e Gestão de Dispositivo > DNS.
>
> O app também inclui uma Content Blocker Extension (`SFContentBlockerManager`) que atua
> exclusivamente dentro do Safari, via lista de regras estática (`blockerList.json`).
>
> O app não coleta, transmite ou armazena qualquer dado do usuário em servidor próprio — não
> existe backend. As únicas chamadas de rede são: (1) as consultas DNS enviadas ao provedor
> escolhido pelo usuário (AdGuard DNS ou Control D para os níveis Padrão/Família — o usuário
> pode escolher entre os dois —, ou um servidor informado pelo próprio usuário no nível
> Personalizado) e (2) a checagem de uma lista fixa de domínios na tela "Testar", usada apenas
> para mostrar ao usuário se a proteção está ativa.
>
> O app é um download pago único (US$ 2,99 / R$ 14,90). Não há compras dentro do app,
> assinatura, paywall ou recursos bloqueados — nenhum SKU de IAP é usado.
>
> O requisito mínimo é iOS 26 porque a interface usa o Liquid Glass nativo do SwiftUI
> (`TabView`/`NavigationStack`/toolbars adotam o material automaticamente ao compilar com
> Xcode 26) — não é uma limitação artificial, é a versão em que essas APIs de sistema existem.
>
> Para testar: instale o app, toque em "Blindar meu iPhone", siga a instrução para ativar em
> Ajustes, volte ao app e confirme que o indicador muda para "Blindado".

## Formulário de privacidade (App Privacy / "Nutrition Label")

- **Dados coletados pelo desenvolvedor**: Nenhum.
- **Dados vinculados à identidade do usuário**: Nenhum.
- **Dados usados para rastreamento**: Nenhum.
- **Terceiros que recebem dados**: apenas o provedor de DNS escolhido pelo usuário recebe as
  consultas DNS necessárias para resolver nomes de domínio — isso é inerente ao funcionamento
  de qualquer configuração de DNS e não constitui coleta de dados pelo Blindado.

## Screenshots

Os 7 itens do roteiro acima estão gerados em `fastlane/screenshots/pt-BR/` (6,9" — iPhone
18 Pro Max, 1320×2868), prontos para `./bin/fastlane ios release`. Cada arquivo é um painel
com moldura de iPhone + título + subtítulo (estilo App Store), montado pelo template
`design/blindado-app-store-screenshots.html` (gerado via Open Design, projeto `blindado-7a73`,
usando só os tokens de `design-tokens.md` — sem paleta nova):

1. `01-inicio-protegido.png` — captura real do app no Simulador, com um `MockDNSManager`
   temporário (nunca commitado) forçando o estado "Blindado" só para esta captura, já que
   `NEDNSSettingsManager` não ativa de verdade no Simulador (quickstart.md).
2. `02-o-que-nao-faz.png` — arte de texto (não é screenshot de app), com os 3 bullets do que
   o app NÃO faz.
3–6. `03-nivel-protecao.png`, `04-testar.png`, `05-safari.png`, `06-privacidade.png` — capturas
   reais do app no Simulador.
7. `07-preco.png` — arte de texto, pagamento único.

**Como regenerar**: as capturas "cruas" (sem moldura) ficam em `screenshots/*.png` dentro do
projeto Open Design; o template as compõe automaticamente ao abrir
`design/blindado-app-store-screenshots.html` num navegador (`--zoom:1` no `:root` para
exportar em tamanho real, um `.panel` por vez — ver comentário no próprio arquivo).

**Pendente**: revalidar o item 1 em dispositivo físico assim que possível (T045/T047/T048) —
a captura atual usa um mock só de tela, não uma ativação real de DNS.

## Checklist pré-submissão

- [ ] Nenhuma tela, screenshot ou texto de marketing menciona bloqueio de anúncios em apps de
      terceiros (YouTube, Instagram, etc.) — Constitution Princípio III.
- [ ] Descrição e screenshots incluem explicitamente o que o app NÃO faz (item 2 do roteiro de
      screenshots), para reduzir reembolsos por expectativa equivocada.
- [ ] Preço configurado no App Store Connect: US$ 2,99 (tier base) com R$ 14,90 manual para o
      território Brasil; nenhum produto de IAP criado (Constitution Princípio IX).
- [ ] Deployment target iOS 26.0 configurado nos dois targets; ficha da loja confirma "Requer
      iOS 26 ou posterior".
- [ ] Formulário de privacidade da App Store preenchido como "Data Not Collected".
- [ ] Notas de revisão explicam o uso de `NEDNSSettingsManager`, o fluxo manual de ativação, os
      dois provedores de DNS suportados (AdGuard e Control D) e o modelo de download único.
- [ ] Política de privacidade publicada e linkada na tela de Transparência (FR-014).
- [ ] Entitlement `com.apple.developer.networking.networkextension` aprovado para a conta de
      desenvolvedor antes do envio.
- [ ] Projeto Xcode auditado (T049) sem StoreKit, sem SDK de compra/assinatura e sem código
      morto de versão "Pro".
