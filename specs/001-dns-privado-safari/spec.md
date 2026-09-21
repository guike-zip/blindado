# Feature Specification: DNS Privado e Bloqueador de Conteúdo para Safari (Blindado)

**Feature Branch**: `001-dns-privado-safari`

**Created**: 2026-09-21

**Status**: Draft

**Input**: User description: "Blindado é um app para iPhone que protege a navegação do usuário usando DNS criptografado em todo o sistema, funcionando tanto em Wi-Fi quanto em rede celular, e inclui um bloqueador de conteúdo para o Safari. Público: pessoas leigas que querem menos rastreadores e uma internet mais limpa sem pagar nem configurar nada técnico. Histórias de usuário: Blindar o aparelho, Escolher o nível de proteção, Testar a proteção, Safari mais limpo, Transparência. Navegação por quatro abas: Início, Safari, Testar, Ajustes. Fora do escopo: VPN, bloqueio de anúncios em apps de terceiros, contas de usuário, compras, estatísticas, widgets."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Blindar o aparelho (Priority: P1)

O usuário abre o app pela primeira vez e vê um indicador visual grande (escudo) mostrando um de
três estados: "Blindado" (proteção ativa), "Instalado mas desativado" (configurado, porém
desligado nos Ajustes do sistema) ou "Não configurado". Ao tocar em "Blindar meu iPhone", o app
prepara a configuração de DNS criptografado e guia o usuário, passo a passo, para ativá-la
manualmente em Ajustes do sistema (já que o iOS exige confirmação explícita do usuário fora do
app), oferecendo um botão que abre os Ajustes diretamente. Ao retornar ao app, o estado exibido é
atualizado automaticamente para refletir se a ativação foi concluída. O usuário também pode
remover a proteção a qualquer momento.

**Why this priority**: É o valor central do produto — sem esta história o app não protege nada.
Precisa funcionar sozinha para o app ter propósito.

**Independent Test**: Pode ser testada integralmente instalando o app em um iPhone físico,
tocando em "Blindar meu iPhone", completando a ativação em Ajustes e confirmando que o escudo
muda para o estado "Blindado" ao voltar ao app — e que a remoção reverte o estado.

**Acceptance Scenarios**:

1. **Given** o app nunca foi configurado, **When** o usuário abre o app, **Then** o escudo mostra
   o estado "Não configurado" e o botão principal oferece "Blindar meu iPhone".
2. **Given** o usuário tocou em "Blindar meu iPhone", **When** ele segue as instruções e ativa a
   configuração em Ajustes do sistema, **Then** ao retornar ao app o escudo muda para "Blindado"
   sem precisar de nenhuma ação adicional do usuário.
3. **Given** a configuração foi instalada mas o usuário ainda não a ativou em Ajustes, **When** o
   usuário abre o app, **Then** o escudo mostra "Instalado mas desativado" com um atalho para
   concluir a ativação.
4. **Given** a proteção está ativa ("Blindado"), **When** o usuário escolhe remover a proteção,
   **Then** a configuração é removida e o escudo volta ao estado "Não configurado".

---

### User Story 2 - Escolher o nível de proteção (Priority: P1)

O usuário escolhe entre três níveis de proteção: "Padrão" (bloqueia anúncios e rastreadores),
"Família" (também bloqueia conteúdo adulto) e "Personalizado" (o usuário informa o endereço de um
servidor DNS seguro próprio). No modo Personalizado, o endereço informado é validado antes de ser
salvo. A escolha do usuário é lembrada, e trocar de nível reaplica a proteção com a nova
configuração sem exigir que o usuário refaça a ativação em Ajustes. Os níveis "Padrão" e
"Família" funcionam sem nenhuma configuração adicional (o app já escolhe um provedor de DNS
padrão para cada um), mas são apoiados por mais de um provedor de DNS criptografado reconhecido,
e o usuário pode opcionalmente ver e trocar qual provedor está em uso dentro do nível escolhido.

**Why this priority**: Sem escolha de nível, o produto não atende às diferentes necessidades do
público (ex.: famílias) nem usuários avançados que já têm um provedor DNS de confiança. É P1
porque está diretamente ligada à ativação inicial (o usuário já escolhe um nível ao blindar o
aparelho pela primeira vez).

**Independent Test**: Pode ser testada com a proteção já ativa, trocando entre os três níveis e
confirmando que a nova escolha permanece após fechar e reabrir o app, e que uma URL de servidor
inválida no modo Personalizado é rejeitada com uma mensagem clara antes de ser salva.

**Acceptance Scenarios**:

1. **Given** a proteção está ativa no nível "Padrão", **When** o usuário seleciona "Família",
   **Then** a proteção é reconfigurada para o nível "Família" sem exigir nova ativação manual em
   Ajustes.
2. **Given** o usuário seleciona "Personalizado", **When** ele informa um endereço de servidor DNS
   seguro válido, **Then** o app valida o endereço, salva a escolha e aplica a configuração.
3. **Given** o usuário seleciona "Personalizado", **When** ele informa um endereço inválido ou
   inacessível, **Then** o app exibe um erro claro e não salva a escolha.
4. **Given** o usuário já escolheu um nível de proteção, **When** ele reabre o app mais tarde,
   **Then** o nível escolhido continua selecionado.
5. **Given** o usuário está no nível "Padrão" ou "Família", **When** ele abre os detalhes do
   nível, **Then** o app mostra qual provedor de DNS está em uso (dentre os provedores
   suportados para aquele nível) e permite trocar para outro provedor suportado sem sair do
   nível escolhido nem repetir a ativação manual em Ajustes.

---

### User Story 3 - Testar a proteção (Priority: P2)

O usuário acessa uma tela de teste que verifica, item a item, uma lista de domínios conhecidos
de anúncios/rastreadores e um domínio comum, mostrando se cada um foi bloqueado ou passou, além
de um resultado geral claro (protegido / parcialmente protegido / desprotegido).

**Why this priority**: Dá confiança de que a proteção realmente funciona, mas o app já entrega
valor sem ela (a proteção já está ativa via DNS do sistema independente do teste existir).

**Independent Test**: Pode ser testada isoladamente com a proteção ativa e desativada,
confirmando que o resultado do teste muda de acordo com o estado real da proteção.

**Acceptance Scenarios**:

1. **Given** a proteção está ativa no nível "Padrão", **When** o usuário roda o teste, **Then**
   os domínios de anúncios/rastreadores da lista aparecem como bloqueados e o domínio comum
   aparece como acessível, com um resultado geral "Protegido".
2. **Given** a proteção está desativada, **When** o usuário roda o teste, **Then** todos os
   domínios da lista aparecem como acessíveis e o resultado geral indica "Desprotegido".
3. **Given** o teste está em andamento, **When** o usuário aguarda a conclusão, **Then** cada
   domínio testado mostra seu resultado individual assim que verificado, sem travar a tela.

---

### User Story 4 - Safari mais limpo (Priority: P3)

O app oferece um bloqueador de conteúdo para o Safari. A tela mostra se ele está habilitado nos
Ajustes do Safari, permite recarregar as regras de bloqueio manualmente e ensina o usuário a
habilitá-lo caso ainda não esteja.

**Why this priority**: Complementa a proteção por DNS especificamente dentro do Safari, mas é um
reforço, não o mecanismo principal de proteção do app.

**Independent Test**: Pode ser testada isoladamente verificando que a tela reflete corretamente
se o bloqueador está habilitado ou não nos Ajustes do Safari, e que o botão de recarregar regras
conclui com uma confirmação visível.

**Acceptance Scenarios**:

1. **Given** o bloqueador de conteúdo não está habilitado no Safari, **When** o usuário acessa a
   aba Safari, **Then** o app mostra esse estado claramente e oferece instruções para habilitá-lo
   em Ajustes.
2. **Given** o bloqueador já está habilitado, **When** o usuário toca em "Recarregar regras",
   **Then** o app aciona a atualização das regras e confirma a conclusão ao usuário.

---

### User Story 5 - Transparência (Priority: P3)

O usuário acessa uma tela de privacidade explicando que o app não coleta dados, não opera
servidor próprio, e que as consultas DNS são enviadas ao provedor escolhido pelo usuário, com um
link para a política de privacidade completa.

**Why this priority**: Reforça a confiança do usuário e a conformidade regulatória/App Store, mas
não afeta a funcionalidade central de proteção.

**Independent Test**: Pode ser testada isoladamente conferindo que o texto exibido é consistente
com o comportamento real do app e que o link de política de privacidade abre corretamente.

**Acceptance Scenarios**:

1. **Given** o usuário está na aba Ajustes, **When** ele acessa "Privacidade", **Then** o app
   exibe uma explicação clara de que nenhum dado é coletado e para onde as consultas DNS são
   enviadas.
2. **Given** o usuário está na tela de privacidade, **When** ele toca no link da política de
   privacidade, **Then** o conteúdo completo da política é aberto.

---

### Edge Cases

- O que acontece quando o usuário toca em "Blindar meu iPhone" mas cancela ou não conclui a
  ativação em Ajustes? O app deve permanecer no estado "Instalado mas desativado" e permitir
  retomar a qualquer momento.
- Como o sistema se comporta quando o dispositivo já tem outra configuração de DNS ou VPN ativa
  de outro app? O usuário deve ser informado de que precisa substituí-la para usar o Blindado.
- O que acontece se o usuário trocar de rede (Wi-Fi para celular ou vice-versa) com a proteção
  ativa? A proteção deve permanecer ativa em ambas as redes sem exigir nova ativação.
- Como o app se comporta ao rodar o teste de proteção sem conexão de rede disponível? O app deve
  indicar claramente que o teste não pôde ser concluído, sem apresentar um resultado enganoso de
  "protegido" ou "desprotegido".
- O que acontece se o usuário desativar a configuração de DNS diretamente em Ajustes (fora do
  app), sem passar pelo fluxo de remoção do app? O escudo deve refletir "Instalado mas
  desativado" na próxima vez que o app for aberto ou voltar ao primeiro plano.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE exibir o estado real da proteção (Blindado / Instalado mas
  desativado / Não configurado) sempre que o app é aberto ou volta ao primeiro plano.
- **FR-002**: O sistema DEVE guiar o usuário passo a passo para ativar manualmente a configuração
  de DNS nos Ajustes do sistema, incluindo um atalho que abre a tela correta de Ajustes.
- **FR-003**: O sistema DEVE detectar automaticamente, sem exigir ação manual de "atualizar",
  quando a ativação em Ajustes foi concluída pelo usuário.
- **FR-004**: Os usuários DEVEM poder remover a proteção a qualquer momento a partir do app.
- **FR-005**: O sistema DEVE oferecer três níveis de proteção: Padrão, Família e Personalizado.
- **FR-006**: No nível Personalizado, o sistema DEVE validar o endereço do servidor DNS informado
  pelo usuário antes de salvá-lo, rejeitando endereços inválidos ou inacessíveis com uma mensagem
  de erro clara.
- **FR-007**: O sistema DEVE lembrar o nível de proteção escolhido entre sessões do app.
- **FR-008**: Trocar de nível de proteção DEVE reaplicar a configuração automaticamente, sem exigir
  que o usuário repita a ativação manual em Ajustes.
- **FR-009**: O sistema DEVE testar uma lista de domínios conhecidos de anúncios/rastreadores e um
  domínio comum, reportando o resultado individual de cada domínio e um resultado geral.
- **FR-010**: O sistema DEVE indicar de forma clara quando o teste de proteção não pôde ser
  concluído (ex.: sem conexão de rede), em vez de apresentar um resultado ambíguo.
- **FR-011**: O sistema DEVE mostrar se o bloqueador de conteúdo do Safari está habilitado nos
  Ajustes do sistema.
- **FR-012**: Os usuários DEVEM poder solicitar a recarga manual das regras do bloqueador de
  conteúdo do Safari, com confirmação de conclusão.
- **FR-013**: O sistema DEVE ensinar o usuário a habilitar o bloqueador de conteúdo do Safari
  quando ele ainda não estiver habilitado.
- **FR-014**: O sistema DEVE apresentar uma explicação de privacidade descrevendo que nenhum dado
  do usuário é coletado, que não há servidor próprio, e para qual provedor as consultas DNS são
  enviadas, com link para a política de privacidade completa.
- **FR-015**: O sistema NÃO DEVE, em nenhum texto de interface, afirmar ou insinuar que bloqueia
  anúncios dentro de outros aplicativos além do Safari.
- **FR-016**: O sistema DEVE organizar a navegação em quatro seções: Início, Safari, Testar e
  Ajustes.
- **FR-017**: O sistema DEVE detectar e avisar o usuário quando outra configuração de DNS ou VPN
  de terceiros já estiver ativa no dispositivo, orientando-o a resolver o conflito antes de
  blindar o aparelho.
- **FR-018**: O sistema NÃO DEVE implementar compras dentro do aplicativo, assinaturas, paywall
  ou qualquer mecanismo de bloqueio de recursos; todos os níveis de proteção e funcionalidades
  (Padrão, Família, Personalizado, Safari, Testar) DEVEM estar disponíveis para todo usuário que
  baixar o app, sem distinção de nível de pagamento.
- **FR-019**: O sistema DEVE oferecer, para os níveis "Padrão" e "Família", mais de um provedor
  de DNS criptografado reconhecido (evitando depender de um único fornecedor terceiro), com um
  provedor padrão pré-selecionado para que o usuário leigo não precise escolher nada.

### Key Entities

- **Perfil de Proteção**: representa a configuração de proteção do usuário — nível escolhido
  (Padrão, Família ou Personalizado), endereço do servidor associado quando Personalizado, e o
  estado atual de ativação no sistema.
- **Resultado de Teste de Proteção**: representa uma execução do teste de proteção — a lista de
  domínios verificados, o resultado individual de cada um (bloqueado, acessível ou
  indeterminado) e o resultado geral.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuário leigo consegue concluir a ativação da proteção (do toque em "Blindar meu
  iPhone" até o escudo mostrar "Blindado") em menos de 2 minutos.
- **SC-002**: O estado de proteção exibido no app corresponde ao estado real do sistema em 100%
  das verificações, incluindo quando a mudança foi feita fora do app (diretamente em Ajustes).
- **SC-003**: Um usuário consegue trocar de nível de proteção e ver a nova escolha refletida em
  menos de 10 segundos, sem sair do app.
- **SC-004**: Ao rodar o teste de proteção com a proteção ativa, pelo menos 95% dos domínios de
  anúncios/rastreadores conhecidos da lista de teste aparecem como bloqueados.
- **SC-005**: Nenhum texto do app ou da ficha da loja é rejeitado ou sinalizado em uma revisão da
  App Store por prometer bloqueio de anúncios em apps de terceiros.
- **SC-006**: Um usuário consegue entender, a partir da tela de Transparência, para onde suas
  consultas DNS são enviadas e confirmar que nenhum dado é coletado, sem precisar de explicação
  adicional fora do app.
- **SC-007**: O app funciona de ponta a ponta (níveis Padrão e Família) usando pelo menos dois
  provedores de DNS criptografado independentes, de modo que a indisponibilidade de um único
  fornecedor terceiro não deixe o usuário sem opção de proteção.

## Assumptions

- **Modelo de negócio**: o Blindado é um aplicativo pago de download único (preço definido no
  App Store Connect); não há compras dentro do app, assinatura, paywall ou versão "Pro" — todo
  usuário que baixar o app tem acesso completo a todos os recursos (ver `app-store-submission.md`
  para o preço definido).
- Os provedores de DNS criptografado dos níveis "Padrão" e "Família" são definidos pelo Blindado
  a partir de uma lista curada de mais de um provedor reconhecido (não pelo usuário); apenas o
  nível "Personalizado" permite um servidor informado pelo usuário. Um provedor padrão é
  pré-selecionado por nível para que o usuário leigo não precise escolher nada.
- A política de privacidade completa (FR-014) é um documento hospedado externamente, para o qual
  o app apenas oferece um link; seu conteúdo está fora do escopo desta especificação.
- O dispositivo do usuário está em uma versão do iOS que suporta configuração de DNS criptografado
  em todo o sistema via Ajustes nativos.
- A interface do app usa a linguagem visual nativa mais atual da Apple (Liquid Glass), o que
  exige iOS 26 ou posterior como versão mínima suportada — decisão do usuário, priorizando a
  aparência nativa correta sobre o alcance a versões mais antigas do iOS.
- Além do iPhone, o Blindado também é distribuído como app nativo de macOS (26+), não Mac
  Catalyst — mesma lógica de negócio (Models/Services/ViewModels), navegação própria por
  sidebar em vez da barra de abas do iPhone (research.md #11). O fluxo de ativação do DNS no
  macOS usa um mecanismo do sistema diferente do iOS (o perfil aparece como um novo serviço de
  rede em Ajustes do Sistema) — pendente de validação em hardware Mac real antes do lançamento.
- A interface visual do app DEVE seguir o design system Open Design (nexu-io/open-design), cuja
  fonte da verdade é o arquivo `DESIGN.md` na raiz do repositório e os artefatos em `/design`.
  Esses artefatos ainda não existem no repositório nesta data; a implementação de qualquer tela
  (View) fica bloqueada até que `DESIGN.md` seja fornecido — a lógica de negócio descrita nesta
  especificação não depende dele e pode ser planejada e implementada normalmente.
- Fora do escopo desta especificação: VPN completa, bloqueio de anúncios dentro de aplicativos de
  terceiros (ex.: YouTube, Instagram), contas de usuário, compras dentro do app, assinaturas,
  paywall, versão "Pro" ou qualquer recurso bloqueado por pagamento adicional, estatísticas
  históricas de consultas bloqueadas, e widgets de tela inicial.
