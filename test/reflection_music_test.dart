import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurya/reflection_music.dart';
class ManualTimer implements Timer {
 final void Function(Timer) callback;bool active=true;int count=0;
 ManualTimer(this.callback);
 void fire(){if(active){count++;callback(this);}}
 @override void cancel(){active=false;}
 @override bool get isActive=>active;
 @override int get tick=>count;
}
class FakeMusic implements MusicOutput {
 final levels=<double>[];final assets=<String>[];int stops=0,pauses=0;bool reject=false;
 @override Future<void> start(String asset) async{if(reject)throw StateError('media unavailable');assets.add(asset);}
 @override Future<void> resume() async{}
 @override Future<void> pause() async{pauses++;}
 @override Future<void> volume(double value) async{levels.add(value);}
 @override Future<void> stop() async{stops++;}
 @override Future<void> dispose() async{}
}
const tracks=<Map<String,dynamic>>[
 {'id':'a','theme':'prosperity','frequencyHz':432,'asset':'audio/piano-a.wav'},
 {'id':'b','theme':'prosperity','frequencyHz':528,'asset':'audio/piano-b.wav'},
 {'id':'c','theme':'gratitude','frequencyHz':639,'asset':'audio/piano-c.wav'},
];
Future<void> drain()=>Future<void>.delayed(Duration.zero);
void main(){
 test('approved theme music varies frequency and refuses arbitrary paths',(){
  final chosen=chooseReflectionTrack(tracks,'prosperity',432,Random(1));expect(chosen!['frequencyHz'],528);expect(chosen['theme'],'prosperity');expect(chooseReflectionTrack([{'theme':'prosperity','frequencyHz':432,'asset':'https://example.com/tone.wav'}],'prosperity',null,Random(1)),isNull);
 });
 test('natural end keeps music for eight seconds with a gradual fade',() async{
  var now=DateTime(2026,10,30);final timers=<ManualTimer>[],output=FakeMusic();
  final music=ReflectionMusic(output:output,now:()=>now,periodic:(duration,callback){final timer=ManualTimer(callback);timers.add(timer);return timer;});
  await music.prepare(tracks,'gratitude');expect(output.assets,isEmpty);await music.speaking();now=now.add(const Duration(milliseconds:450));timers.last.fire();await drain();expect(music.level,closeTo(.16,.001));
  final before=output.stops;music.finish();expect(music.ending,isTrue);now=now.add(const Duration(seconds:4));timers.last.fire();await drain();expect(music.level,closeTo(.08,.001));expect(output.stops,before);
  now=now.add(const Duration(seconds:4));timers.last.fire();await drain();expect(music.level,closeTo(0,.001));expect(music.ending,isFalse);expect(output.stops,before+1);await music.dispose();
 });
 test('manual stop cancels the tail and stale fade cannot silence a restart',() async{
  var now=DateTime(2026,10,30);final timers=<ManualTimer>[],output=FakeMusic();
  final music=ReflectionMusic(output:output,now:()=>now,periodic:(duration,callback){final timer=ManualTimer(callback);timers.add(timer);return timer;});
  await music.prepare(tracks,'prosperity');await music.speaking();now=now.add(const Duration(milliseconds:450));timers.last.fire();await drain();music.finish();final old=timers.last;await music.stop();expect(music.ending,isFalse);expect(old.isActive,isFalse);
  await music.prepare(tracks,'gratitude');await music.speaking();final stops=output.stops;now=now.add(const Duration(seconds:10));old.callback(old);await drain();expect(output.stops,stops);expect(music.loaded,isTrue);await music.dispose();
 });
 test('music failure is explicit and never pretends to play',() async{
  final output=FakeMusic()..reject=true;final session=ReflectionMusic(output:output);await session.prepare(tracks,'gratitude');await session.speaking();expect(session.available,isFalse);expect(session.loaded,isFalse);expect(output.assets,isEmpty);await session.dispose();
 });
}
