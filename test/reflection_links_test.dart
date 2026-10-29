import 'package:flutter_test/flutter_test.dart';
import 'package:aurya/reflection_links.dart';
void main(){
 test('somente links de reflexão, nunca áudio automático',(){
  expect(reflectionIdFromUri(Uri.parse('aurya://reflection/wake-prosperidade-01')),'wake-prosperidade-01');
  for(final value in ['https://example.com/reflection/x','aurya://other/x','aurya://reflection/x?autoplay=1','aurya://reflection/x#play','aurya://reflection/a/b'])expect(reflectionIdFromUri(Uri.parse(value)),isNull);
 });
}
