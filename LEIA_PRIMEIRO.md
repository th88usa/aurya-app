# AURYA — pacote atualizado em 28/10/2026

## Comece por aqui

Extraia o ZIP. A pasta aurya contém o projeto completo disponível até esta entrega. A prévia web é a versão mais atual da experiência. As fontes Flutter e Swift ainda precisam receber as novas funções e ser integradas e compiladas para instalação.

## Estado atual

- Cinco intenções: prosperidade, gratidão, visualização, riqueza e abundância.
- Vinte mensagens reforçadas e vinte aprofundamentos originais na sequência de intenções, quatro por tema. O catálogo preserva também os 24 pares anteriores: 44 pares no total. Os textos originais não são citações de Hill.
- Jornada de cem dias por tema: 35 práticas-base revisitadas com novos focos, totalizando 500 posições de calendário, sem representar 500 exercícios inteiramente independentes.
- Atividades, aprofundamentos, versão breve, anotações e conclusão reversível. Progresso separado por tema, salvo apenas neste navegador, sem sincronização de conta.
- Voz local do dispositivo, música sorteada conforme o tema e encerramento gradual de oito segundos na leitura das mensagens.
- 33 faixas instrumentais originais: três melodias para cada uma das onze frequências de referência.
- Inventário de pesquisa do Instagram e documentação das fontes; a análise dos 150 posts ainda está incompleta. Pesquisa do YouTube também está em andamento.
- Revisão editorial a cada noventa dias criada neste chat do Codex. Essa automação não é instalada pelo ZIP nem faz parte do app publicado. Consulte JORNADA_100_DIAS.md.

## Abrir no computador

Execute INICIAR_PREVIA.ps1 na pasta aurya, ou inicie um servidor HTTP nessa pasta. A prévia fica em /preview/atualizada.html. Para revisar diretamente as tarefas, acrescente ?view=tasks; para as intenções, ?view=intentions. Não abra o HTML diretamente como arquivo, pois o conteúdo precisa ser carregado pelo servidor.

O cadastro usa dados fictícios e não cria conta. O cadastro e os horários são temporários; a intenção escolhida e os registros da jornada ficam no navegador. Os cem dias podem ser consultados manualmente: ainda não há desbloqueio automático por data de instalação ou notificação no celular.

## GitHub e Vercel

Use o conteúdo da pasta aurya como raiz do repositório. Não há credenciais ou sessões do Instagram no pacote. O arquivo vercel.json configura a publicação da prévia estática com node tools/prepare-web.mjs e saída web-deploy. As músicas referenciadas são incluídas no build. A raiz publicada redireciona para /preview/.

A prévia web não instala um widget no iPhone e não é um aplicativo nativo pronto para loja.

## Codemagic e aplicativo nativo

codemagic.yaml contém o fluxo inicial aurya-validation para resolver dependências, analisar e executar testes Flutter. Não gera IPA/APK e não publica em lojas. O fluxo ainda precisa ser executado em um ambiente Flutter compatível.

Ainda faltam projetos nativos iOS/Android completos, integração e assinatura do widget, identificadores e certificados. Veja IOS_WIDGET.md. As novas intenções e tarefas de cem dias estão implementadas na prévia web; ainda não foram portadas para as telas Flutter. Não há conta real, compras ou backend de usuários.

## Validação

As vinte seleções de mensagens e os cinco calendários de cem dias foram verificados. A navegação até o dia cem e a separação do progresso por tema foram conferidas no navegador. O ZIP tem verificação de integridade e manifesto dos arquivos.

Testes históricos podem conter expectativas de conteúdo de versões anteriores; não representam uma aprovação completa da versão nativa. A voz depende das opções do dispositivo. A avaliação musical permanece subjetiva.

README, VALIDACAO e outros relatórios anteriores preservam o histórico. Este arquivo descreve o estado mais recente da entrega.
