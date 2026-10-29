# Preparação do widget de bloqueio do iPhone

## Estado real

Código nativo fornecido para revisão e integração, **não compilado ou instalado**. Windows sem Flutter/Dart/Swift/Xcode. O mock web/Flutter está rotulado como simulação e não representa execução WidgetKit. O alvo de preparação é iPhone/iOS 16+; validar em versões efetivamente suportadas, incluindo iOS atual. Não há target `.xcodeproj`, App Group ou certificado registrado.

## Base técnica consultada em 23/10/2026

- [`accessoryRectangular`](https://developer.apple.com/documentation/widgetkit/widgetfamily/accessoryrectangular): família retangular disponível no bloqueio do iPhone. O widget usa somente essa família.
- [Accessory widgets](https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications): conteúdo compacto e de leitura rápida na tela de bloqueio.
- [Manter widgets atualizados](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date): eventos previsíveis devem ser enviados como timeline. O sistema administra recursos, orçamento e pode agrupar atualizações. Quatro entradas diárias não significam garantia de quatro trocas pontuais.
- [Criar extensão e privacidade](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension): extensão separada, adição manual, necessidade de abrir o app pelo menos uma vez para a galeria e proteção de conteúdo sensível pelo sistema.
- [App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups): compartilhamento entre o app e sua extensão, com capability e assinatura correspondentes.
- [Aparência e contextos](https://developer.apple.com/documentation/widgetkit/developing-a-widgetkit-strategy): no bloqueio, a aparência é determinada pelo sistema; não é um cartão com cores/fontes livres como na prévia.
- [Horários inexistentes em DST](https://developer.apple.com/documentation/foundation/calendar/matchingpolicy/nexttimepreservingsmallercomponents): política nativa escolhida preserva minutos ao avançar para horário existente; hora repetida usa primeira ocorrência.

## Arquitetura preparada

```text
assets/content.json + quatro horários locais
    → WidgetBridge.payload (Flutter, consentimento explícito)
    → MethodChannel aurya/widget: save / clear
    → JSON validado e reserializado em arquivo atômico no App Group
    → WidgetKit TimelineProvider
    → entrada atual + próximas fronteiras por oito dias
    → accessoryRectangular: label de demonstração e afirmação curta
```

O Provider lê dados locais, sem rede ou dependência do app aberto, e monta as trocas futuras de uma vez. A entrada atual usa a última ocorrência, incluindo o dia anterior antes do primeiro momento. Não existe entrada extra à meia-noite. Ao fim da timeline solicita nova timeline (`.atEnd`); se ainda não houver configuração válida, mostra instrução genérica e aguarda mudança (`.never`). App solicita `reloadTimelines` somente ao salvar, limpar ou receber mudança significativa de horário enquanto puder receber esse evento.

Cada categoria tem seis amostras; a data civil do início da ocorrência escolhe uma. Swift calcula dias civis em calendário gregoriano e constrói datas locais com Calendar, em vez de somar 24h. Datas inexistentes por DST avançam preservando minutos; horário repetido usa a primeira ocorrência. Se duas fronteiras caírem no mesmo instante após ajuste DST, a última na ordem planejada prevalece. Essas regras nativas ainda precisam de XCTest e teste de aparelho.

## Integrar em macOS/Xcode

1. Gere o projeto Flutter em uma cópia, execute `flutter pub get` e abra `ios/Runner.xcworkspace` no Xcode.
2. Adicione um target **Widget Extension**, nome por exemplo `AuryaLockScreen`. Desmarque Live Activity e configuração App Intent para esta versão estática. Mantenha o Info.plist da extensão criado pelo template, incluindo `NSExtension`; o fragmento fornecido não o substitui. Use deployment target iOS 16+ compatível com o app.
3. Adicione `Shared/AuryaWidgetStore.swift` ao target Runner **e** ao target da extensão. Adicione `Shared/AuryaTimelineEngine.swift` à extensão e ao target de testes. Adicione `Widget/AuryaLockScreenWidget.swift` **somente** à extensão e remova o widget gerado de exemplo para evitar dois `@main`.
4. Adicione `Runner/AuryaWidgetBridge.swift` somente ao Runner. Registre a ponte **uma vez** com o `binaryMessenger` do engine Flutter ativo: `AuryaWidgetBridge.register(with: engine.binaryMessenger)`. `engine` aqui representa o engine real do template gerado, não uma variável pronta neste projeto. Em templates com `FlutterViewController`, pode usar o `binaryMessenger` desse controller; em templates com engine implícito, faça o registro no callback de inicialização apropriado. Não cole um AppDelegate antigo sobre um template recente. A ponte não é auto-registrada pelo pubspec.
5. Nos dois targets, habilite **App Groups** com **o mesmo identificador real da equipe**. Não há identificador ou equipe aprovados neste pacote. Defina o build setting `AURYA_APP_GROUP` com esse valor para Debug/Release. Mescle a entrada de `AppGroup.entitlements.example` nos entitlements reais e a chave de `Info.fragment.plist` nos Info.plists dos **dois** targets. Não substitua os plists inteiros. Confira `CODE_SIGN_ENTITLEMENTS`, assinatura, bundle IDs próprios e extensão embutida no app. O código falha explicitamente se o grupo não existir ou não estiver acessível.
6. Compile Runner + extensão. Execute Flutter analyze/test e os XCTest preparados antes de considerar pronto. Resolva erros de compatibilidade do SDK encontrados pelo compilador; nada desta etapa foi compilado neste ambiente.
7. Instale em iPhone de desenvolvimento. Abra o AURYA, faça o cadastro fictício, ajuste os quatro exemplos para seus horários e habilite explicitamente as frases no widget de demonstração. Salve. Uma resposta de sucesso confirma apenas escrita/solicitação de reload, nunca instalação no bloqueio.
8. No iPhone, personalize a tela bloqueada, abra a área de widgets e adicione **AURYA · quatro momentos**. Esse passo é manual. A posição/tamanho são controlados pelo sistema.

## Privacidade e limites

- A exportação inclui exclusivamente versão, locale português efetivo, flag demo, IDs/rótulos, minutos e frases públicas. A ponte valida quatro IDs exatos, horários únicos 0–1439, tamanho do payload, IDs de conteúdo e comprimento das frases. Ela reserializa somente os campos permitidos.
- Arquivo no App Group com proteção até o primeiro desbloqueio após reiniciar. Antes disso, leitura pode falhar e o widget exibe instrução genérica. O conteúdo da view tem `.privacySensitive()`, permitindo ao sistema ocultar dados conforme Face ID/código e Always On. O app não consegue garantir visibilidade sob todas as escolhas de privacidade.
- O layout usa título de uma linha e afirmação de até três linhas. **Não há garantia de número fixo de caracteres, tamanho universal ou encaixe sem teste**. Não há texto rolável, ticker, relógio dinâmico, notificação ou Live Activity. O mock de 160 × 76 px é somente ilustrativo; o nativo usa o espaço oferecido pelo sistema.
- Frases não contêm dados pessoais. Não adicionar e-mail, nome, gravações, temas sensíveis ou credenciais ao snapshot. A auth futura precisará controlar criação, revogação e limpeza no ciclo de conta; a flag demo não é autorização de segurança.
- O conteúdo pode ficar renderizado por algum tempo após limpar. Não prometer remoção visual instantânea. O estado de configuração não prova que há widget instalado.
- Mudança de fuso/relógio, suspensão, bateria, Focus e privacidade exigem teste real. O Provider usa o fuso atual quando o iOS o consulta; uma timeline já entregue contém datas absolutas e não há promessa de reprogramação imediata ao viajar.
- A Apple recomenda espaçar entradas e pode agrupar trocas. Se a pessoa escolher quatro horários muito próximos, não prometer quatro estados visíveis separados.

## Roteiro de aceite em iPhone/macOS — ainda pendente

| Teste | Resultado esperado a verificar |
|---|---|
| App Group ausente/errado | Erro no app e instrução genérica no widget |
| Primeiro uso/sem configuração | Widget sem nome/e-mail/frase pessoal; instrução para configurar |
| Quatro horários definidos pelo usuário | Timeline com quatro fronteiras/dia, conteúdo adequado em cada uma |
| App fechado por um dia e depois por vários dias | Leitura sem abrir o app; recarga após horizonte da timeline |
| 23:59 → 00:00 → primeiro momento | Mesma frase até a próxima ocorrência, sem rotação à meia-noite |
| DST de primavera/outono e viagem de fuso | Calendar segue políticas previstas; medir limites reais de reload |
| Face ID, bloqueio total, Always On e reinício | Respeitar redaction e primeiro desbloqueio, sem contornar ajustes |
| Dynamic Type, modelo menor e wallpaper | Frase legível, sem corte indevido; ajustar lineLimit/fonte se necessário |
| Editar horários e salvar | JSON novo válido; reload solicitado; medir atraso do sistema |
| Sair/apagar, inclusive falha de escrita | Limpeza solicitada, falha informada e nenhuma falsa confirmação visual |
| Sem conectividade | Conteúdo local funciona sem auth/rede real na demonstração |

Registre modelo do iPhone, versão do iOS, horários pedidos/observados e capturas do aparelho. Somente esses testes poderão comprovar funcionamento real.

## Aprofundamento opcional — preparação 0.4

A entrada do widget agora inclui o ID da afirmação e uma URL `aurya://reflection/ID`, para abrir o aprofundamento no app por `.widgetURL`. O texto longo não entra no widget nem no snapshot compartilhado. Não há voz automática ao tocar. A preparação e os testes de sessão/retomada estão em `REFLEXOES.md`. O novo `ReflectionLinks.Runner.fragment.plist` é **somente do Runner**; o fragmento de App Group permanece para os dois targets. Compilar/testar no Mac e iPhone continua obrigatório antes de confirmar funcionamento.
