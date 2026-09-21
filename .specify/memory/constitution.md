<!--
Sync Impact Report
Version change: (none) → 1.0.0
Modified principles: n/a (initial ratification)
Added sections:
  - Core Principles (I–VIII: Privacidade Absoluta, Apenas Frameworks Nativos da Apple,
    Conformidade com a App Store Acima de Tudo, Honestidade com o Usuário, Testabilidade,
    Acessibilidade Obrigatória, Simplicidade, Entrega Independente por História de Usuário)
  - Padrões de Qualidade e Segurança
  - Fluxo de Desenvolvimento
  - Governance
Removed sections: n/a
Deferred TODOs: none
Templates requiring follow-up: none checked in this pass (initial ratification; no dependent
  templates yet reference project-specific principle names)
-->

# Blindado Constitution

## Core Principles

### I. Privacidade Absoluta
O aplicativo NÃO DEVE coletar dados do usuário, NÃO DEVE integrar SDKs de analytics ou
rastreamento, e NÃO DEVE operar servidor próprio. Nenhuma chamada de rede é permitida além de:
(a) o teste de eficácia da proteção contra uma lista fixa de domínios, e (b) as consultas DNS
enviadas ao provedor DoH escolhido pelo usuário. SDKs de publicidade, crash reporting de
terceiros ou qualquer telemetria estão proibidos.
Rationale: privacidade é a proposta de valor central do produto; qualquer coleta de dados mina
a confiança do usuário e contradiz o propósito do app.

### II. Apenas Frameworks Nativos da Apple
O projeto DEVE usar exclusivamente frameworks fornecidos pela Apple (SwiftUI, NetworkExtension,
SafariServices, Foundation, etc.). Nenhuma dependência de terceiros (via Swift Package Manager,
CocoaPods ou Carthage) É PERMITIDA.
Rationale: reduz a superfície de ataque, elimina risco de supply-chain, simplifica a auditoria
de privacidade e mantém o app leve.

### III. Conformidade com a App Store Acima de Tudo
Nenhum texto de interface, metadado de loja ou material de marketing PODE afirmar ou insinuar
que o app bloqueia anúncios dentro de aplicativos de terceiros (ex.: YouTube, Instagram). O
posicionamento oficial do produto é "DNS privado e bloqueador de conteúdo para Safari". Toda
funcionalidade e todo texto voltado ao usuário DEVE ser revisado contra as guidelines da App
Store antes do lançamento.
Rationale: um app rejeitado ou removido não serve a ninguém; a Apple proíbe bloqueio de
anúncios em todo o sistema fora do escopo do Safari Content Blocker e do DNS de sistema.

### IV. Honestidade com o Usuário
O estado de proteção exibido na interface DEVE sempre corresponder ao estado real do sistema
(DNS configurado e ativo, content blocker habilitado, etc.). O app NÃO DEVE exibir um estado
"ativo" de forma otimista ou em cache quando o estado real é desconhecido ou diferente.
Qualquer discrepância DEVE ser resolvida a favor de mostrar o estado real assim que detectável.
Rationale: usuários leigos confiam no indicador visual para decisões de segurança; um
indicador falso é pior do que nenhuma proteção.

### V. Testabilidade
Todo acesso a APIs de sistema (NEDNSSettingsManager, SFContentBlockerManager, etc.) DEVE ficar
atrás de um protocolo com uma implementação mock injetável. ViewModels DEVEM ter cobertura de
testes unitários. As SwiftUI Previews DEVEM funcionar sem necessidade de dispositivo físico ou
entitlements reais.
Rationale: essas APIs de sistema não funcionam no simulador; sem essa barreira arquitetural o
desenvolvimento e a integração contínua ficam reféns de hardware físico.

### VI. Acessibilidade Obrigatória
Toda tela DEVE suportar VoiceOver com rótulos descritivos, DEVE respeitar Dynamic Type, e DEVE
funcionar corretamente em modo claro e em modo escuro.
Rationale: acessibilidade é um requisito de qualidade não negociável e faz parte dos critérios
de revisão da App Store.

### VII. Simplicidade
A arquitetura DEVE seguir MVVM enxuto. Abstrações especulativas (camadas, protocolos ou
generalizações sem um consumidor atual) NÃO SÃO PERMITIDAS. pt-BR é o idioma principal da
interface; toda string voltada ao usuário DEVE ser preparada para localização em inglês via
String Catalog.
Rationale: um app pequeno e focado não precisa de complexidade arquitetural desnecessária; a
preparação para localização desde o início evita retrabalho.

### VIII. Entrega Independente por História de Usuário
Cada história de usuário priorizada (P1, P2, P3...) DEVE ser entregável, testável e
demonstrável de forma independente em dispositivo físico, sem depender da conclusão de
histórias de prioridade inferior.
Rationale: permite validar o fluxo crítico (P1) cedo em hardware real antes de investir nas
demais histórias.

## Padrões de Qualidade e Segurança

O código Swift DEVE compilar sem warnings ignorados em builds de Release. Qualquer permissão
de rede ou entitlement declarado DEVE ser justificável em relação a uma história de usuário
ativa. Como o app não possui backend próprio, nenhum segredo, chave de API ou credencial DEVE
ser embutido no binário. Uma revisão de conformidade com a App Store (ver Princípio III) É
OBRIGATÓRIA antes de qualquer submissão.

## Fluxo de Desenvolvimento

Cada mudança DEVE referenciar a história de usuário priorizada que implementa. Testes
unitários DEVEM passar antes do merge. Qualquer mudança que afete o estado de proteção exibido
ao usuário (Princípio IV) DEVE ser validada em dispositivo físico antes de considerar a
história de usuário concluída, já que as APIs de DNS de sistema e de Content Blocker não
funcionam de forma confiável no simulador.

## Governance

Esta constituição tem precedência sobre qualquer outra prática ou convenção do projeto.
Emendas exigem: (1) documentação da mudança e sua motivação, (2) atualização deste arquivo com
o número de versão incrementado conforme versionamento semântico, e (3) revisão da data de
"Last Amended". Toda revisão de código e todo plano de implementação DEVEM verificar
conformidade com os princípios aqui descritos; complexidade que viole o Princípio VII
(Simplicidade) DEVE ser justificada explicitamente no plano ou rejeitada.

**Version**: 1.0.0 | **Ratified**: 2026-09-21 | **Last Amended**: 2026-09-21
