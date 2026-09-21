# Submissão à App Store: Blindado

Rascunho de material de submissão. Revisar contra Constitution Princípio III (Conformidade com
a App Store Acima de Tudo) antes de enviar — nenhum texto abaixo pode sugerir bloqueio de
anúncios fora do Safari.

## Descrição (App Store)

> **Blindado — DNS privado e bloqueador de conteúdo para Safari**
>
> Blindado protege sua navegação com DNS criptografado em todo o iPhone — em Wi-Fi e também na
> rede celular — e com um bloqueador de conteúdo dedicado ao Safari.
>
> - Ative em poucos toques, sem cadastro e sem configuração técnica.
> - Escolha entre proteção Padrão, Família (também filtra conteúdo adulto) ou um servidor DNS
>   seguro personalizado.
> - Teste sua proteção a qualquer momento e veja exatamente o que está sendo bloqueado.
> - Bloqueador de conteúdo nativo para o Safari, fácil de habilitar e recarregar.
> - Zero coleta de dados. Zero servidor próprio. Suas consultas DNS vão diretamente para o
>   provedor que você escolher.
>
> Blindado não é uma VPN e não bloqueia anúncios dentro de outros aplicativos — o foco é DNS
> privado em todo o sistema e um Safari mais limpo.

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
> escolhido pelo usuário (AdGuard DNS para os níveis Padrão/Família, ou um servidor informado
> pelo próprio usuário no nível Personalizado) e (2) a checagem de uma lista fixa de domínios na
> tela "Testar", usada apenas para mostrar ao usuário se a proteção está ativa.
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

## Checklist pré-submissão

- [ ] Nenhuma tela, screenshot ou texto de marketing menciona bloqueio de anúncios em apps de
      terceiros (YouTube, Instagram, etc.) — Constitution Princípio III.
- [ ] Formulário de privacidade da App Store preenchido como "Data Not Collected".
- [ ] Notas de revisão explicam o uso de `NEDNSSettingsManager` e o fluxo manual de ativação.
- [ ] Política de privacidade publicada e linkada na tela de Transparência (FR-014).
- [ ] Entitlement `com.apple.developer.networking.networkextension` aprovado para a conta de
      desenvolvedor antes do envio.
