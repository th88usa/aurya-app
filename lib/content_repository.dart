import 'dart:convert';
import 'package:flutter/services.dart';
import 'domain.dart';

class ContentRepository {
  final Map<String, dynamic> data;
  ContentRepository(this.data);
  static Future<ContentRepository> load() async => ContentRepository(
    jsonDecode(await rootBundle.loadString('assets/content.json')) as Map<String, dynamic>);
  List<dynamic> get locales => data['locales'] as List<dynamic>;
  Map<String,dynamic>? byId(String id) {
    for(final item in data['messages']) {if(item['id']==id)return Map<String,dynamic>.from(item);}
    return null;
  }
  Map<String, dynamic> daily(RitualMoment moment, DateTime now) {
    final items = (data['messages'] as List<dynamic>)
        .where((m) => m['moment'] == moment.name).toList();
    if (items.isEmpty) throw StateError('Sem conteúdo para este período.');
    return Map<String, dynamic>.from(items[dayIndex(now) % items.length]);
  }
}
