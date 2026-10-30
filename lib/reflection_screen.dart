import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'reflection_music.dart';
class ReflectionScreen extends StatefulWidget {
 final Map<String,dynamic> message,translation;final String locale;final String Function(String) translate;final VoidCallback onBack;
 const ReflectionScreen({super.key,required this.message,required this.translation,required this.locale,required this.translate,required this.onBack});
 @override State<ReflectionScreen> createState()=>_ReflectionScreenState();
}
class _ReflectionScreenState extends State<ReflectionScreen> with WidgetsBindingObserver {
 final tts=FlutterTts();late final ReflectionMusic music;
 String state='idle',status='Leitura automática pela voz local do dispositivo. Sem início automático.';
 bool active=true;int ticket=0;Timer? watchdog;Future<List<Map<String,dynamic>>>? tracks;
 Map<String,dynamic> get reflection=>Map<String,dynamic>.from(widget.translation['reflection'] as Map);
 String get text=>[widget.translation['body'],...reflection['paragraphs']].join('\n\n');
 String t(String value)=>widget.translate(value);
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);music=ReflectionMusic(output:DeviceMusicOutput(),notify:(){if(mounted&&active)setState((){});});tracks=loadTracks();}
 Future<List<Map<String,dynamic>>> loadTracks() async{try{final data=jsonDecode(await rootBundle.loadString('assets/audio_catalog.json'));return (data['tracks'] as List).map((x)=>Map<String,dynamic>.from(x as Map)).toList();}catch(_){return [];}}
 void update(String value,String label){if(mounted&&active)setState((){state=value;status=label;});}
 Future<void> stop([String label='Leitura automática encerrada.']) async{ticket++;watchdog?.cancel();await music.stop();update('idle',label);try{await tts.stop();}catch(_){update('unavailable','Leitura automática indisponível neste navegador. Você pode continuar lendo.');}}
 Future<void> listen() async{
  if(state=='preparing'||state=='speaking')return;final resuming=state=='paused',token=++ticket;
  update('preparing','Verificando voz local no idioma escolhido…');
  try{
   if(!resuming){await tts.stop();await music.prepare(await tracks!,widget.message['ambienceTheme'] as String? ?? 'prosperity');}
   final raw=await tts.getVoices;if(!mounted||!active||token!=ticket)return;
   final language=widget.locale.toLowerCase().split('-').first;
   final voices=(raw as List).whereType<Map>().where((v)=>'${v['locale']??''}'.replaceAll('_','-').toLowerCase().split('-').first==language&&v['network_required']!=true&&v['network_required']!='true').toList();
   if(voices.isEmpty){await music.stop();update('unavailable','Voz local no idioma escolhido indisponível. Ative uma voz no dispositivo ou continue lendo.');return;}
   voices.sort((a,b){int score(Map v)=>('${v['locale']}'.toLowerCase()==widget.locale.toLowerCase()?10:0)+(RegExp(r'natural|neural|enhanced|premium',caseSensitive:false).hasMatch('${v['name']}')?20:0);return score(b)-score(a);});
   final voice=voices.first;await tts.setVoice({'name':voice['name'] as String,'locale':voice['locale'] as String});await tts.setLanguage(voice['locale'] as String);await tts.setVolume(.5);await tts.setSpeechRate(.45);await tts.setPitch(.9);
   if(defaultTargetPlatform==TargetPlatform.iOS){await tts.setSharedInstance(true);await tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,[IosTextToSpeechAudioCategoryOptions.mixWithOthers]);}
   if(!mounted||!active||token!=ticket)return;
   tts.setStartHandler((){if(token==ticket){watchdog?.cancel();update('speaking','Leitura automática · ${voice['name']} (${voice['locale']})');unawaited(music.speaking());}});
   tts.setContinueHandler((){if(token==ticket){watchdog?.cancel();update('speaking','Leitura automática retomada.');unawaited(music.speaking());}});
   tts.setPauseHandler((){if(token==ticket){music.pause();update('paused','Leitura pausada.');}});
   tts.setCompletionHandler((){if(token==ticket&&state=='speaking'){watchdog?.cancel();music.finish();update('ended','Leitura automática concluída.');}});
   tts.setErrorHandler((error){if(token==ticket){watchdog?.cancel();unawaited(music.stop());update('unavailable','A voz não conseguiu concluir a leitura. O texto continua disponível.');}});
   watchdog=Timer(const Duration(seconds:5),(){if(token==ticket)unawaited(stop('A voz não iniciou neste dispositivo. Continue lendo ou tente novamente.'));});
   await tts.speak(text);if(!active||token!=ticket)await tts.stop();
  }catch(_){watchdog?.cancel();await music.stop();if(token==ticket)update('unavailable','Não foi possível iniciar a voz. O texto continua disponível.');}
 }
 Future<void> pause() async{if(state!='speaking')return;try{music.pause();await tts.pause();update('paused','Leitura pausada.');}catch(_){await stop('Pausa indisponível. Leitura encerrada; o texto continua disponível.');}}
 @override void didChangeAppLifecycleState(AppLifecycleState value){if(value!=AppLifecycleState.resumed)unawaited(stop());}
 @override void dispose(){active=false;ticket++;watchdog?.cancel();WidgetsBinding.instance.removeObserver(this);unawaited(music.dispose());unawaited(tts.stop().catchError((Object _)=>0));super.dispose();}
 @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  TextButton(onPressed:(){unawaited(stop());widget.onBack();},child:Text(t('← Voltar à afirmação'))),if(widget.message['intention']==null)Text(t('Conteúdo anterior disponível apenas em português.')),Text(t('Aprofundar · leitura opcional'),style:const TextStyle(fontSize:11)),const SizedBox(height:16),Text(reflection['title'] as String,style:const TextStyle(fontSize:30)),const SizedBox(height:16),Text(widget.translation['body'] as String,style:const TextStyle(fontSize:23,height:1.5)),const SizedBox(height:24),
  Text(t('LEITURA AUTOMÁTICA'),style:const TextStyle(fontSize:11)),Wrap(spacing:8,runSpacing:8,children:[FilledButton(onPressed:['preparing','speaking'].contains(state)?null:listen,child:Text(t(state=='paused'?'Continuar':'Ouvir'))),OutlinedButton(onPressed:state=='speaking'?pause:null,child:Text(t('Pausar'))),OutlinedButton(onPressed:['preparing','speaking','paused'].contains(state)||music.ending?()=>stop():null,child:Text(t('Parar')))]),
  Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(t(music.ending?'Leitura concluída. Música encerrando suavemente…':status))),SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(t('Fundo musical suave')),value:music.enabled,onChanged:(v){setState(()=>music.enabled=v);if(!v){unawaited(music.stop());}else if(state=='speaking'){unawaited(music.speaking());}}),
  if(!music.available)Text(t('Fundo musical indisponível; a leitura continua disponível.')),
  if(music.track!=null)Text(t('Trilha: ${music.track!['composition']} · ${music.track!['frequencyHz']} Hz'),style:const TextStyle(fontSize:12)),
  for(final paragraph in reflection['paragraphs'])Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(paragraph as String,style:const TextStyle(fontSize:18,height:1.8))),
  if(widget.translation['editorialOrigin']!=null)ExpansionTile(title:Text(t('Origem da inspiração')),tilePadding:EdgeInsets.zero,children:[Text(t(widget.translation['editorialOrigin']['source'] as String)),const SizedBox(height:8),Text(t(widget.translation['editorialOrigin']['note'] as String)),SelectableText(widget.translation['editorialOrigin']['url'] as String)]),
  if(widget.translation['citation']!=null)ExpansionTile(title:Text(t('Origem da citação')),tilePadding:EdgeInsets.zero,children:[Text(widget.translation['citation']['original'] as String? ?? ''),Text(widget.translation['citation']['source'] as String? ?? '')]),
  Text(t('TEXTO ORIGINAL AURYA'),style:const TextStyle(fontSize:11)),
 ]);
}
