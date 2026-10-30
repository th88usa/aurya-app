import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurya/main.dart';
import 'package:aurya/content_repository.dart';
import 'package:aurya/native_state.dart';
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();late ContentRepository repository;
 setUpAll(() async{repository=await ContentRepository.load();});
 testWidgets('journal notes and completion survive language and intention changes on a phone layout',(tester) async{
  tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  final initial=NativeState(MemoryStore())..onboarded=true;final storage=MemoryStore(jsonEncode(initial.snapshot()));initial.dispose();
  await tester.pumpWidget(AuryaApp(repository:repository,storage:storage));await tester.pumpAndSettle();
  await tester.tap(find.text('Tarefas'));await tester.pumpAndSettle();
  final note=find.byKey(const ValueKey('journey-note'));await tester.ensureVisible(note);await tester.enterText(note,'Minha intenção permanece');await tester.pumpAndSettle();
  final done=find.text('Concluí esta atividade');await tester.ensureVisible(done);await tester.tap(done);await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('locale-pt-BR')));await tester.pumpAndSettle();await tester.tap(find.text('English').last);await tester.pumpAndSettle();
  expect(tester.widget<TextField>(note).controller!.text,'Minha intenção permanece');expect(find.text('Completed 1 of 100 activities'),findsOneWidget);
  final intention=find.byKey(const ValueKey('intention-prosperity-en'));await tester.ensureVisible(intention);await tester.tap(intention);await tester.pumpAndSettle();await tester.tap(find.text('Wealth').last);await tester.pumpAndSettle();
  expect(tester.widget<TextField>(note).controller!.text,isEmpty);expect(find.text('Completed 0 of 100 activities'),findsOneWidget);
  final wealth=find.byKey(const ValueKey('intention-wealth-en'));await tester.ensureVisible(wealth);await tester.tap(wealth);await tester.pumpAndSettle();await tester.tap(find.text('Prosperity').last);await tester.pumpAndSettle();
  expect(tester.widget<TextField>(note).controller!.text,'Minha intenção permanece');expect(find.text('Completed 1 of 100 activities'),findsOneWidget);expect(tester.takeException(),isNull);
  await tester.pumpWidget(const SizedBox.shrink());
 });
 testWidgets('all four moments resolve current intention messages',(tester) async{
  final initial=NativeState(MemoryStore())..onboarded=true;initial.intention='visualization';final storage=MemoryStore(jsonEncode(initial.snapshot()));initial.dispose();
  await tester.pumpWidget(AuryaApp(repository:repository,storage:storage));await tester.pumpAndSettle();
  for(final label in ['Ao acordar','Indo para o trabalho','Meio do dia','Antes de dormir']){
   final chip=find.widgetWithText(ChoiceChip,label);await tester.ensureVisible(chip);await tester.tap(chip);await tester.pumpAndSettle();expect(tester.takeException(),isNull);
  }
  expect(find.text('TEXTO ORIGINAL AURYA'),findsOneWidget);await tester.pumpWidget(const SizedBox.shrink());
 });
}
