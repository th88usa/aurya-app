import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurya/content_repository.dart';
import 'package:aurya/native_state.dart';
import 'package:aurya/domain.dart';
import 'package:aurya/widget_bridge.dart';
class FailingStore implements LocalStore {
 @override Future<String?> read() async=>null;
 @override Future<void> write(String value) async=>throw StateError('storage unavailable');
}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();late ContentRepository repo;
 setUpAll(() async{repo=await ContentRepository.load();});
 test('all eight languages resolve twenty current messages and complete journeys',(){
  for(final locale in nativeLanguages.keys){
   for(final theme in intentionLabels.keys){
    for(final moment in RitualMoment.values){final message=repo.intended(theme,moment,DateTime(2026,10,30));final text=repo.text(message,locale);expect(message['intention'],theme);expect(repo.translated(message['id'] as String,locale),isTrue);expect((text['body'] as String).isNotEmpty,isTrue);expect((text['widget'] as String).runes.length,lessThanOrEqualTo(120));expect((text['reflection']['paragraphs'] as List).length,3);}
    for(var day=1;day<=100;day++){final practice=repo.practice(theme,day,locale);expect(practice['day'],day);expect((practice['meaning'] as String).isNotEmpty,isTrue);}
   }
  }
 });
 test('language, intention, times, notes and progress survive relaunch',() async{
  final store=MemoryStore();
  final first=NativeState(store);first.completeOnboarding();first.updateRecord('gratitude',100,{'done':true,'note':'Meu registro <não é HTML>'});first.setLocale('ja');first.setIntention('wealth');expect(first.updateTimes({...exampleMinutes,RitualMoment.wake:360}),isTrue);await first.flush();
  final restored=NativeState(store);await restored.load();expect(restored.locale,'ja');expect(restored.intention,'wealth');expect(restored.onboarded,isTrue);expect(restored.times[RitualMoment.wake],360);expect(restored.record('gratitude',100)['note'],'Meu registro <não é HTML>');expect(restored.completed('gratitude'),1);expect(restored.completed('wealth'),0);first.dispose();restored.dispose();
 });
 test('writes preserve latest keystroke, completion and language in order',() async{
  final store=MemoryStore();final model=NativeState(store);
  for(final note in ['a','ab','abc']){model.updateRecord('prosperity',1,{'note':note});}model.updateRecord('prosperity',1,{'done':true});model.setLocale('fr');await model.flush();final saved=jsonDecode(store.value!);expect(saved['records']['prosperity']['1']['note'],'abc');expect(saved['records']['prosperity']['1']['done'],true);expect(saved['locale'],'fr');model.dispose();
 });
 test('invalid storage and rejected writes remain explicit; retry can recover',() async{
  final invalid=NativeState(MemoryStore('broken'));await invalid.load();expect(invalid.loadError,isTrue);expect(invalid.records,isEmpty);invalid.dispose();
  final unavailable=NativeState(FailingStore());unavailable.updateRecord('prosperity',1,{'note':'still here'});await unavailable.flush();expect(unavailable.saveError,isTrue);expect(unavailable.record('prosperity',1)['note'],'still here');unavailable.dispose();
 });
 test('restore excludes out-of-range records; resets are persisted',() async{
  final initial={'version':1,'records':{'prosperity':{'0':{'done':true},'1':{'done':true},'101':{'done':true}}}};
  final store=MemoryStore(jsonEncode(initial));final model=NativeState(store);await model.load();expect(model.completed('prosperity'),1);expect(model.record('prosperity',101),isEmpty);await model.reset();final restored=NativeState(store);await restored.load();expect(restored.records,isEmpty);expect(restored.onboarded,isFalse);model.dispose();restored.dispose();
 });
 test('widget payload reflects selected theme and language without journal data',(){
  final payload=WidgetBridge.payload(repo,RitualSchedule(exampleMinutes),intention:'gratitude',locale:'en');expect(payload['locale'],'en');expect((payload['moments'] as List).length,4);for(final row in payload['moments']){expect((row['messages'] as List).single['id'],contains('intention-gratitude'));expect((row['messages'] as List).single['text'],isNot(contains('Desperto')));}expect(jsonEncode(payload),isNot(contains('email')));expect(jsonEncode(payload),isNot(contains('records')));
 });
 test('long widget text is clipped safely without splitting a unicode code point',(){final value=compactWidget(List.filled(200,'🌱').join());expect(value.runes.length,120);expect(value.endsWith('…'),isTrue);expect(value, isNot(contains('\uFFFD')));});
}
