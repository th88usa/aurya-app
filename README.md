# AURYA

Prévia web e fontes iniciais do aplicativo AURYA. Projeto mantido por th88usa.

## O que está disponível

- Cinco intenções: prosperidade, gratidão, visualização, riqueza e abundância.
- Vinte mensagens atuais com aprofundamentos, além dos 24 pares anteriores preservados no catálogo.
- Cem dias por intenção, construídos com 35 práticas-base revisitadas progressivamente.
- Registros e progresso locais por tema, sem sincronização entre dispositivos.
- Leitura pela voz local e 33 músicas instrumentais originais; trilha por tema e encerramento gradual.

A tela de bloqueio é uma simulação. Textos podem ser cortados no widget real conforme o espaço disponível no iPhone.

## Executar a prévia

Requer Python 3 para o servidor local:

```sh
python -m http.server 8765 --bind 127.0.0.1
```

Abra http://127.0.0.1:8765/preview/ no mesmo computador. No Windows, INICIAR_PREVIA.ps1 também pode iniciar o servidor.

A entrada normal usa cadastro fictício. Para revisar diretamente, use /preview/atualizada.html?view=intentions ou ?view=tasks. Não há contas reais nem autenticação nessa demonstração; esses atalhos não são controles de acesso.

## Validar e preparar a web

Requer Node.js 24 ou superior, sem dependências externas para essa etapa:

```sh
npm test
npm run build
```

O build gera web-deploy, que não deve ser versionado. Os testes de voz e música simulam o controle de reprodução; não avaliam a qualidade percebida do som.

## Vercel

Importe este repositório na sua conta Vercel. A raiz do projeto é esta pasta, onde está vercel.json. Preset Other. O arquivo configura o build node tools/prepare-web.mjs e a saída web-deploy. Não são necessárias variáveis de ambiente nesta prévia. Revise o plano de hospedagem antes de uso comercial.

A publicação na Vercel é uma etapa separada do envio do código ao GitHub. O repositório de referência é https://github.com/th88usa/aurya-app.

## Flutter e iPhone

lib, test e ios_integration preservam as fontes iniciais. Intenções e jornada de cem dias estão implementadas na prévia web e ainda precisam ser portadas para as telas nativas. Não há projeto Xcode completo, app assinado ou widget instalado.

codemagic.yaml contém apenas o fluxo inicial de análise e testes Flutter, ainda não validado neste computador. Leia IOS_WIDGET.md antes de preparar os projetos e certificados.

## Conteúdo e continuidade

As mensagens atuais de intenção são escritas originais do AURYA, identificadas como tal. A pesquisa dos canais de origem está incompleta. A revisão editorial agendada no chat do Codex não é executada por este repositório nem implantada na Vercel.

O proprietário mantém o controle da conta e do repositório. Nenhuma senha, sessão do navegador ou token faz parte desta entrega. Não há licença de software de terceiros concedida para o código do projeto neste momento.
