import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

// Independent from WidgetBridge and the four-moment schedule. No autoplay.
class AudioScreen extends StatefulWidget {
  final String Function(String) translate;
  const AudioScreen({super.key,required this.translate});
  @override State<AudioScreen> createState()=>_AudioScreenState();
}
class _AudioScreenState extends State<AudioScreen> with WidgetsBindingObserver {
  Text label(String value,{TextStyle? style})=>Text(widget.translate(value),style:style);
  final player=AudioPlayer();
  late Future<Map<String,dynamic>> catalog;
  Timer? timer;
  StreamSubscription<PlayerState>? playerEvents;
  Map<String,dynamic>? track;
  String theme='prosperity',status='Escolha uma amostra e toque em Reproduzir.';
  double volume=0.15;
  int timerMinutes=5,remainingMs=300000,generation=0;
  bool playing=false,busy=false;
  DateTime? deadline;
  String? loadedId;
  Future<Map<String,dynamic>> load() async=>jsonDecode(await rootBundle.loadString('assets/audio_catalog.json')) as Map<String,dynamic>;
  @override void initState(){
    super.initState();catalog=load();WidgetsBinding.instance.addObserver(this);
    playerEvents=player.onPlayerStateChanged.listen((state){
      if(playing&&(state==PlayerState.paused||state==PlayerState.stopped))pause('Áudio pausado. Toque em Continuar para retomar.');
    },onError:(Object error)=>fail());
  }
  void fail(){if(!mounted)return;timer?.cancel();setState((){busy=false;playing=false;deadline=null;loadedId=null;status='Não foi possível reproduzir. Selecione a amostra novamente e tente iniciar.';});}
  Future<void> select(Map<String,dynamic> value) async {
    generation++;timer?.cancel();setState(()=>busy=true);
    try {await player.stop();if(!mounted)return;setState((){track=value;loadedId=null;playing=false;busy=false;deadline=null;remainingMs=timerMinutes*60000;status='Pronto para ouvir. Sem reprodução automática.';});}
    catch(_){fail();}
  }
  Future<void> play() async {
    if(track==null||busy)return;final token=++generation;
    setState((){busy=true;status='Preparando áudio…';});
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      if(!mounted||token!=generation){if(mounted)setState(()=>busy=false);return;}
      if(remainingMs<=0)remainingMs=timerMinutes*60000;
      if(loadedId==track!['id']){await player.setVolume(volume);await player.resume();}
      else{await player.play(AssetSource(track!['asset'] as String),volume:volume);}
      if(!mounted||token!=generation){await player.pause();if(mounted)setState(()=>busy=false);return;}
      loadedId=track!['id'] as String;deadline=DateTime.now().add(Duration(milliseconds:remainingMs));
      setState((){busy=false;playing=true;status='Reproduzindo amostra em repetição.';});
      timer?.cancel();timer=Timer.periodic(const Duration(milliseconds:500),(_){
        if(!mounted||!playing||deadline==null)return;
        final left=deadline!.difference(DateTime.now()).inMilliseconds;
        if(left<=0){stop(completed:true);}else{setState(()=>remainingMs=left);}
      });
    }catch(_){fail();}
  }
  Future<void> pause([String? reason]) async {
    generation++;timer?.cancel();
    if(deadline!=null)remainingMs=deadline!.difference(DateTime.now()).inMilliseconds.clamp(0,timerMinutes*60000).toInt();
    if(mounted)setState((){busy=false;playing=false;deadline=null;status=reason??'Áudio pausado. Toque em Continuar para retomar.';});
    try{await player.pause();}catch(_){fail();}
  }
  Future<void> stop({bool completed=false}) async {
    generation++;timer?.cancel();if(mounted)setState((){playing=false;busy=false;deadline=null;loadedId=null;remainingMs=completed?0:timerMinutes*60000;status=completed?'Temporizador concluído. Áudio encerrado.':'Sessão encerrada.';});
    try{await player.stop();}catch(_){fail();}
  }
  Future<void> setVolume(double value) async {
    setState(()=>volume=value);try{await player.setVolume(value);}catch(_){fail();}
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state){
    if(state!=AppLifecycleState.resumed&&(playing||busy))pause('Áudio pausado ao sair do aplicativo.');
  }
  @override void dispose(){generation++;timer?.cancel();WidgetsBinding.instance.removeObserver(this);playerEvents?.cancel();unawaited(player.dispose());super.dispose();}
  @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(future:catalog,builder:(context,snapshot){
    if(snapshot.hasError)return Column(children:[label('Não foi possível carregar as amostras.'),TextButton(onPressed:()=>setState(()=>catalog=load()),child:label('Tentar novamente'))]);
    if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
    final data=snapshot.data!,all=(data['tracks'] as List).map((t)=>Map<String,dynamic>.from(t as Map)).toList();
    track??=all.first;final themeTracks=all.where((t)=>t['theme']==theme).toList();
    final frequencies=themeTracks.map((t)=>t['frequencyHz'] as int).toSet().toList();
    final tracks=themeTracks.where((t)=>t['frequencyHz']==track!['frequencyHz']).toList();
    final seconds=(remainingMs/1000).ceil();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      label('ÁUDIOS',style:TextStyle(letterSpacing:2)),const SizedBox(height:12),
      label('Ouça no seu ritmo.',style:TextStyle(fontSize:32)),const SizedBox(height:12),
      label('Prosperidade, riqueza e gratidão como temas de intenção.'),const SizedBox(height:20),
      Wrap(spacing:8,children:[for(final item in data['themes'])ChoiceChip(label:label(item['label'] as String),selected:theme==item['id'],onSelected:busy?null:(_){setState(()=>theme=item['id'] as String);select(all.firstWhere((t)=>t['theme']==theme));})]),
      const SizedBox(height:20),label('ACESSO FREE / PREMIUM A DEFINIR',style:TextStyle(fontSize:11)),const SizedBox(height:20),
      DropdownButtonFormField<int>(key:ValueKey('frequency-$theme'),initialValue:track!['frequencyHz'] as int,decoration:InputDecoration(labelText:widget.translate('Frequência de referência')),items:frequencies.map((hz)=>DropdownMenuItem<int>(value:hz,child:label('$hz Hz'))).toList(),onChanged:busy?null:(hz)=>select(themeTracks.firstWhere((t)=>t['frequencyHz']==hz))),
      const SizedBox(height:16),
      DropdownButtonFormField<String>(key:ValueKey('$theme-${track!['frequencyHz']}'),initialValue:track!['id'] as String,isExpanded:true,decoration:InputDecoration(labelText:widget.translate('Escolha a melodia')),
        items:tracks.map((t)=>DropdownMenuItem<String>(value:t['id'] as String,child:label((t['composition']??t['title']) as String))).toList(),onChanged:busy?null:(id)=>select(all.firstWhere((t)=>t['id']==id))),
      const SizedBox(height:16),label('Música suave original com piano, melodia e acordes. As frequências indicam a afinação de referência; a música contém várias notas.'),const SizedBox(height:24),
      Center(child:label('${(seconds~/60).toString().padLeft(2,'0')}:${(seconds%60).toString().padLeft(2,'0')}',style:const TextStyle(fontSize:42))),
      Row(children:[Expanded(child:FilledButton(onPressed:busy?null:()=>playing?pause():play(),child:label(busy?'Preparando…':playing?'Pausar':loadedId!=null?'Continuar':'Reproduzir'))),const SizedBox(width:12),OutlinedButton(onPressed:busy?null:()=>stop(),child:label('Encerrar'))]),
      Padding(padding:const EdgeInsets.symmetric(vertical:16),child:label(status)),
      label('Volume · ${(volume*100).round()}%'),Slider(value:volume,onChanged:(v)=>setVolume(v)),
      DropdownButtonFormField<int>(initialValue:timerMinutes,decoration:InputDecoration(labelText:widget.translate('Encerrar após')),items:[for(final m in data['timerMinutes'])DropdownMenuItem<int>(value:m as int,child:label('$m ${m==1?'minuto':'minutos'}'))],onChanged:(m){if(m==null)return;setState((){timerMinutes=m;remainingMs=m*60000;if(playing)deadline=DateTime.now().add(Duration(milliseconds:remainingMs));});}),
      const SizedBox(height:20),label('Comece com volume confortável. Sem início automático. Ao sair desta área ou do app, a reprodução pausa.'),const SizedBox(height:12),
      label('Escolha o tema da sua intenção. O acesso aos planos será decidido depois.')]);
  });
}

