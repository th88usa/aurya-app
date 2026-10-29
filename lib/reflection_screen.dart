import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReflectionScreen extends StatefulWidget {
 final Map<String,dynamic> message;
 final VoidCallback onBack;
 const ReflectionScreen({super.key,required this.message,required this.onBack});
 @override State<ReflectionScreen> createState()=>_ReflectionScreenState();
}
class _ReflectionScreenState extends State<ReflectionScreen> with WidgetsBindingObserver {
 final tts=FlutterTts();
 String state='idle',status='Leitura automática pela voz do dispositivo. Sem início automático.';
 bool active=true;
 int ticket=0;
 Timer? watchdog;
 Map<String,dynamic> get translation=>Map<String,dynamic>.from(widget.message['translations']['pt-BR'] as Map);
 Map<String,dynamic> get reflection=>Map<String,dynamic>.from(translation['reflection'] as Map);
 String get text=>[translation['body'],...reflection['paragraphs']].join('\n\n');
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);}
 void update(String value,String label){if(mounted&&active)setState((){state=value;status=label;});}
 Future<void> stop([String label='Leitura automática encerrada.']) async {
  ticket++;watchdog?.cancel();update('idle',label);try{await tts.stop();}catch(_){update('unavailable','Voz indisponível; o texto continua disponível.');}
 }
 Future<void> listen() async {
  if(state=='preparing'||state=='speaking')return;
  // The plugin retains its paused position where supported. Native pause behavior requires device QA.
  final resuming=state=='paused';final token=++ticket;
  update('preparing','Verificando voz em português…');
  try {
   if(!resuming)await tts.stop();
   final raw=await tts.getVoices;
   if(!mounted||!active||token!=ticket)return;
   final voices=(raw as List).whereType<Map>().where((v)=>((v['locale']??'') as String).toLowerCase().startsWith('pt')).toList();
   if(voices.isEmpty){update('unavailable','Voz em português indisponível. Ative uma voz no dispositivo ou continue lendo.');return;}
   final voice=voices.firstWhere((v)=>v['locale']=='pt-BR',orElse:()=>voices.first);
   await tts.setVoice({'name':voice['name'] as String,'locale':voice['locale'] as String});
   await tts.setLanguage(voice['locale'] as String);await tts.setVolume(0.5);await tts.setSpeechRate(0.45);
   if(!mounted||!active||token!=ticket)return;
   tts.setStartHandler((){if(token==ticket){watchdog?.cancel();update('speaking','Leitura automática em português.');}});
   tts.setContinueHandler((){if(token==ticket){watchdog?.cancel();update('speaking','Leitura automática retomada.');}});
   tts.setPauseHandler((){if(token==ticket)update('paused','Leitura pausada.');});
   tts.setCompletionHandler((){if(token==ticket){watchdog?.cancel();update('ended','Leitura automática concluída.');}});
   tts.setErrorHandler((error){if(token==ticket){watchdog?.cancel();update('unavailable','Não foi possível ler em voz alta. O texto continua disponível.');}});
   watchdog=Timer(const Duration(seconds:5),(){if(token==ticket){stop('A voz não iniciou neste dispositivo. Você pode continuar lendo.');}});
   await tts.speak(text);
   if(!active||token!=ticket)await tts.stop();
  }catch(_){watchdog?.cancel();if(token==ticket)update('unavailable','Leitura automática indisponível neste ambiente. O texto continua disponível.');}
 }
 Future<void> pause() async {
  if(state!='speaking')return;
  try{await tts.pause();}catch(_){await stop('Pausa indisponível; leitura encerrada.');}
 }
 @override void didChangeAppLifecycleState(AppLifecycleState value){if(value!=AppLifecycleState.resumed)stop('Leitura encerrada ao sair do app.');}
 @override void dispose(){active=false;ticket++;watchdog?.cancel();WidgetsBinding.instance.removeObserver(this);unawaited(tts.stop().catchError((Object _)=>0));super.dispose();}
 @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  TextButton(onPressed:(){stop();widget.onBack();},child:const Text('← Voltar à afirmação')),
  const Text('APROFUNDAR · LEITURA OPCIONAL',style:TextStyle(letterSpacing:1.5,fontSize:11)),const SizedBox(height:16),
  Text(reflection['title'] as String,style:const TextStyle(fontSize:32)),const SizedBox(height:16),
  Text(translation['body'] as String,style:const TextStyle(fontSize:23,height:1.5)),const SizedBox(height:24),
  const Text('LEITURA AUTOMÁTICA · PORTUGUÊS',style:TextStyle(fontSize:11)),
  Wrap(spacing:8,children:[FilledButton(onPressed:['preparing','speaking'].contains(state)?null:listen,child:Text(state=='paused'?'Continuar':'Ouvir')),
   OutlinedButton(onPressed:state=='speaking'?pause:null,child:const Text('Pausar')),
   OutlinedButton(onPressed:['preparing','speaking','paused'].contains(state)?()=>stop():null,child:const Text('Parar'))]),
  Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(status)),
  for(final paragraph in reflection['paragraphs'])Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(paragraph as String,style:const TextStyle(fontSize:18,height:1.8))),
  Text('Texto original AURYA · ${reflection['wordCount']} palavras. Acesso Free/Premium a definir.')]);
}
