import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'content_repository.dart';
import 'domain.dart';
abstract interface class LocalStore {Future<String?> read();Future<void> write(String value);}
class PreferencesStore implements LocalStore {
 final SharedPreferencesAsync preferences;
 PreferencesStore({SharedPreferencesAsync? preferences}):preferences=preferences??SharedPreferencesAsync();
 static const key='aurya-native-v1';
 @override Future<String?> read()=>preferences.getString(key);
 @override Future<void> write(String value)=>preferences.setString(key,value);
}
class MemoryStore implements LocalStore {
 String? value;MemoryStore([this.value]);
 @override Future<String?> read() async=>value;
 @override Future<void> write(String value) async{this.value=value;}
}
class NativeState extends ChangeNotifier {
 final LocalStore store;NativeState(this.store);
 String locale='pt-BR',intention='prosperity';
 bool onboarded=false,saveError=false,loadError=false;
 Map<RitualMoment,int> times=Map.of(exampleMinutes);
 Map<String,dynamic> records={};
 Future<void> _writes=Future.value();bool _disposed=false;
 @override void notifyListeners(){if(!_disposed)super.notifyListeners();}
 Future<void> load() async {
  try{final raw=await store.read();if(raw==null)return;final value=jsonDecode(raw);if(value is! Map||value['version']!=1)throw const FormatException('Invalid state');
   if(nativeLanguages.containsKey(value['locale']))locale=value['locale'] as String;
   if(intentionLabels.containsKey(value['intention']))intention=value['intention'] as String;
   onboarded=value['onboarded']==true;
   final savedTimes=value['times'];if(savedTimes is Map){final restored=<RitualMoment,int>{};for(final m in RitualMoment.values){final v=savedTimes[m.name];if(v is int)restored[m]=v;}if(RitualSchedule(restored).valid)times=restored;}
   final saved=value['records'];if(saved is Map)for(final theme in intentionLabels.keys){final rows=saved[theme];if(rows is! Map)continue;final clean=<String,dynamic>{};for(var day=1;day<=100;day++){final row=rows['$day'];if(row is! Map)continue;clean['$day']={'done':row['done']==true,'adapted':row['adapted']==true,'note':row['note'] is String?String.fromCharCodes((row['note'] as String).runes.take(1000)):''};}records[theme]=clean;}
  }catch(_){loadError=true;}finally{notifyListeners();}
 }
 Map<String,dynamic> snapshot()=>{'version':1,'locale':locale,'intention':intention,'onboarded':onboarded,'times':{for(final e in times.entries)e.key.name:e.value},'records':records};
 Future<bool> persist() async {final raw=jsonEncode(snapshot());var succeeded=false;_writes=_writes.then((_) async{try{await store.write(raw);saveError=false;succeeded=true;}catch(_){saveError=true;}notifyListeners();});await _writes;return succeeded;}
 Future<void> flush()=>_writes;
 void setLocale(String code){if(!nativeLanguages.containsKey(code))return;locale=code;notifyListeners();unawaited(persist());}
 void setIntention(String id){if(!intentionLabels.containsKey(id))return;intention=id;notifyListeners();unawaited(persist());}
 void completeOnboarding(){onboarded=true;notifyListeners();unawaited(persist());}
 bool updateTimes(Map<RitualMoment,int> value){if(!RitualSchedule(value).valid)return false;times=Map.of(value);notifyListeners();unawaited(persist());return true;}
 Map<String,dynamic> record(String theme,int day)=>Map<String,dynamic>.from(records[theme]?['$day'] as Map? ?? {});
 void updateRecord(String theme,int day,Map<String,dynamic> patch){if(!intentionLabels.containsKey(theme)||day<1||day>100)throw RangeError('Invalid journey position');final rows=Map<String,dynamic>.from(records[theme] as Map? ?? {}),row={...record(theme,day),...patch};rows['$day']={'done':row['done']==true,'adapted':row['adapted']==true,'note':String.fromCharCodes((row['note'] is String?row['note'] as String:'').runes.take(1000))};records[theme]=rows;notifyListeners();unawaited(persist());}
 int completed(String theme)=>List.generate(100,(i)=>i+1).where((d)=>record(theme,d)['done']==true).length;
 Future<void> reset() async{locale='pt-BR';intention='prosperity';onboarded=false;times=Map.of(exampleMinutes);records={};loadError=false;notifyListeners();await persist();}
 @override void dispose(){_disposed=true;super.dispose();}
}
