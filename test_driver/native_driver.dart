import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(name) || bytes.isEmpty) return false;
    final folder = Directory('integration_screenshots')..createSync(recursive: true);
    await File('${folder.path}/$name.png').writeAsBytes(bytes);
    return true;
  });
}
