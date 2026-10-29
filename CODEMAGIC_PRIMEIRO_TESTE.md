# Primeiro teste nativo no Codemagic

## Estado
Preparado, ainda não executado. O fluxo aurya-ios-simulator gera um projeto iOS temporário usando o Flutter da máquina, copia as fontes atuais, analisa, testa e tenta compilar um aplicativo de simulador. O repositório fonte não é substituído pelo template. O identificador app.aurya.aurya é somente provisório de desenvolvimento; não representa registro Apple nem aprovação para distribuição.

## Executar depois de autorizar a conexão
1. Adicionar o repositório th88usa/aurya-app na conta Codemagic do proprietário.
2. Escolher codemagic.yaml e o fluxo aurya-ios-simulator. Conferir a franquia disponível antes de iniciar; não ativar plano pago sem decisão do proprietário.
3. Examinar os logs de dependências, análise, testes e build. Corrigir a primeira falha comprovada e repetir.
4. Se aprovado, baixar AURYA-simulator.zip. Esse arquivo é para simulador em Mac; não é IPA nem pode ser instalado diretamente em iPhone.

## Limites e próximo marco
As fontes Flutter ainda não incluem as intenções, a jornada e os idiomas atuais da web. A extensão WidgetKit e a ponte Swift não são instaladas por este fluxo. A compilação inicial valida a base antiga e revela erros reais; não representa o produto final. O ambiente stable precisa satisfazer as versões mínimas do pubspec; registrar as versões efetivamente usadas no primeiro build e então fixá-las para reprodutibilidade.

Depois de compilar e portar a experiência atual: definir identificador final, equipe Apple, certificados/perfis e distribuição de teste com o proprietário. Somente um build assinado e validado pode ser instalado em um iPhone. Não inserir senhas ou certificados no repositório.

Fontes oficiais consultadas em 29/10/2026:
- https://docs.codemagic.io/yaml-code-signing/ios-simulator-builds/
- https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/
- https://docs.flutter.dev/deployment/ios
