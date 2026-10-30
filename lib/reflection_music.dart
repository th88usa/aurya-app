import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
abstract interface class MusicOutput {
 Future<void> start(String asset);Future<void> resume();Future<void> pause();Future<void> volume(double value);Future<void> stop();Future<void> dispose();
}
class DeviceMusicOutput implements MusicOutput {
 final AudioPlayer player=AudioPlayer();
 @override Future<void> start(String asset) async{await player.setAudioContext(AudioContext(iOS:AudioContextIOS(category:AVAudioSessionCategory.playback,options:{AVAudioSessionOptions.mixWithOthers})));await player.setReleaseMode(ReleaseMode.loop);await player.play(AssetSource(asset),volume:0);}
 @override Future<void> resume()=>player.resume();
 @override Future<void> pause()=>player.pause();
 @override Future<void> volume(double value)=>player.setVolume(value);
 @override Future<void> stop()=>player.stop();
 @override Future<void> dispose()=>player.dispose();
}
Map<String,dynamic>? chooseReflectionTrack(List<Map<String,dynamic>> tracks,String theme,int? last,Random random){
 final valid=tracks.where((t)=>['prosperity','wealth','gratitude'].contains(t['theme'])&&t['frequencyHz'] is num&&t['asset'] is String&&RegExp(r'^audio/[a-z0-9-]+\.wav$').hasMatch(t['asset'] as String)).toList();
 final themed=valid.where((t)=>t['theme']==theme).toList(),pool=themed.isEmpty?valid:themed;
 final fresh=pool.where((t)=>t['frequencyHz']!=last).toList(),choices=fresh.isEmpty?pool:fresh;
 return choices.isEmpty?null:choices[random.nextInt(choices.length)];
}
class ReflectionMusic {
 static int? lastFrequency;
 final MusicOutput output;final void Function() notify;final DateTime Function() now;
 final Timer Function(Duration,void Function(Timer)) periodic;
 ReflectionMusic({required this.output,this.notify=_noop,DateTime Function()? now,Timer Function(Duration,void Function(Timer))? periodic}):now=now??DateTime.now,periodic=periodic??Timer.periodic;
 static void _noop(){}
 Map<String,dynamic>? track;bool enabled=true,ending=false,available=true,loaded=false,disposed=false;
 double level=0;int token=0;Timer? fade;Future<void> _commands=Future.value();
 Future<void> command(Future<void> Function() action,int ticket){_commands=_commands.then((_) async{if(ticket!=token||disposed)return;try{await action();}catch(_){available=false;notify();}});return _commands;}
 Future<void> prepare(List<Map<String,dynamic>> tracks,String theme) async{await stop();available=true;track=chooseReflectionTrack(tracks,theme,lastFrequency,Random());if(track!=null)lastFrequency=(track!['frequencyHz'] as num).toInt();}
 Future<void> speaking() async{
  if(!enabled||track==null||disposed)return;ending=false;fade?.cancel();final ticket=token;
  await command(() async{if(loaded){await output.resume();}else{await output.start(track!['asset'] as String);loaded=true;}},ticket);
  if(ticket==token&&available)fadeTo(.16,const Duration(milliseconds:450));
 }
 void fadeTo(double target,Duration duration,{bool pause=false,bool finish=false}){
  fade?.cancel();final start=now(),initial=level,ticket=token;
  fade=periodic(const Duration(milliseconds:40),(timer){
   if(ticket!=token||disposed){timer.cancel();return;}
   final progress=(now().difference(start).inMilliseconds/duration.inMilliseconds).clamp(0.0,1.0),smooth=(1-cos(pi*progress))/2;
   level=initial+(target-initial)*smooth;unawaited(command(()=>output.volume(level),ticket));
   if(progress>=1){timer.cancel();if(pause)unawaited(command(()=>output.pause(),ticket));if(finish){ending=false;unawaited(command(()=>output.stop(),ticket));loaded=false;}notify();}
  });
 }
 void pause(){ending=false;if(loaded)fadeTo(0,const Duration(milliseconds:300),pause:true);}
 void finish(){if(!enabled||!loaded)return;ending=true;fadeTo(0,const Duration(seconds:8),finish:true);notify();}
 Future<void> stop() async{token++;fade?.cancel();ending=false;level=0;loaded=false;final ticket=token;await command(()=>output.stop(),ticket);if(ticket==token)loaded=false;}
 Future<void> dispose() async{await stop();disposed=true;try{await output.dispose();}catch(_){} }
}
