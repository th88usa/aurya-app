import 'package:flutter_test/flutter_test.dart';
import 'package:aurya/domain.dart';
import 'package:aurya/main.dart';
void main(){
 test('quatro momentos, fronteiras e noite atravessando meia-noite',(){
  final s=RitualSchedule(exampleMinutes);expect(s.valid,isTrue);
  expect(s.activeAt(DateTime(2026,10,23,7)).moment,RitualMoment.wake);
  expect(s.activeAt(DateTime(2026,10,23,8,30)).moment,RitualMoment.commute);
  expect(s.activeAt(DateTime(2026,10,23,12,30)).moment,RitualMoment.midday);
  expect(s.activeAt(DateTime(2026,10,24,0)).date,DateTime(2026,10,23,22));
  expect(RitualSchedule({...exampleMinutes,RitualMoment.commute:420}).valid,isFalse);
 });
 test('rotina noturna não exige ordem por categoria',(){
  final s=RitualSchedule({RitualMoment.wake:1200,RitualMoment.commute:1320,RitualMoment.midday:120,RitualMoment.sleep:480});
  expect(s.valid,isTrue);expect(s.activeAt(DateTime(2026,10,23,3)).moment,RitualMoment.midday);
 });
 testWidgets('cadastro obrigatório de demonstração',(tester) async {
  await tester.pumpWidget(const AuryaApp());await tester.pumpAndSettle();expect(find.text('Cadastro de demonstração'),findsOneWidget);expect(find.text('Bloqueio'),findsNothing);
 });
}
