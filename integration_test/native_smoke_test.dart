import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aurya/main.dart';
import 'package:aurya/content_repository.dart';
import 'package:aurya/native_state.dart';
import 'package:aurya/domain.dart';
import 'package:aurya/widget_bridge.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('simulator renders messages and preserves real device storage and widget sharing', (tester) async {
    final repo = await ContentRepository.load();
    final storage = PreferencesStore();
    final seed = NativeState(storage)..onboarded = true;
    seed.intention = 'visualization';
    await seed.persist();
    seed.dispose();
    await tester.pumpWidget(AuryaApp(repository: repo, storage: storage));
    await tester.pumpAndSettle();
    for (final moment in RitualMoment.values) {
      final chip = find.widgetWithText(ChoiceChip, momentLabels[moment]!);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      final message = repo.intended('visualization', moment, DateTime.now());
      expect(find.text(repo.text(message, 'pt-BR')['body'] as String), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Ao acordar'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ao acordar'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01-native-home');
    final open = find.text('Aprofundar');
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02-native-reflection');
    final source = repo.text(repo.intended('visualization', RitualMoment.wake, DateTime.now()), 'pt-BR');
    final paragraphs = (source['reflection']['paragraphs'] as List).cast<String>();
    await tester.ensureVisible(find.text(paragraphs.last));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03-native-reflection-end');
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tarefas'));
    await tester.pumpAndSettle();
    final note = find.byKey(const ValueKey('journey-note'));
    await tester.ensureVisible(note);
    await tester.enterText(note, 'Registro fictício do teste do simulador');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final done = find.text('Concluí esta atividade');
    await tester.ensureVisible(done);
    await tester.tap(done);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04-native-journey');

    final restored = NativeState(storage);
    await restored.load();
    expect(restored.record('visualization', 1)['done'], isTrue);
    expect(restored.record('visualization', 1)['note'], 'Registro fictício do teste do simulador');
    expect(restored.saveError, isFalse);
    restored.dispose();
    await tester.tap(find.byKey(const ValueKey('locale-pt-BR')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(note).controller!.text, 'Registro fictício do teste do simulador');
    await tester.tap(find.text('Lock screen'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05-native-english');

    // This calls the real iOS bridge and App Group, without mocking the channel.
    final result = await WidgetBridge.save(repo, RitualSchedule(exampleMinutes), intention: 'visualization', locale: 'en');
    expect(result, startsWith('Configuração de demonstração compartilhada.'));
    final raw = await WidgetBridge.channel.invokeMethod<String>('inspectDebug');
    final snapshot = jsonDecode(raw!) as Map;
    expect(snapshot['locale'], 'en');
    expect((snapshot['moments'] as List).length, 4);
    expect(raw.contains('Registro fictício'), isFalse);
    final cleared = await WidgetBridge.clear();
    expect(cleared, startsWith('Conteúdo compartilhado removido;'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 5)));
}
