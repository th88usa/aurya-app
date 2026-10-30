import 'dart:convert';
import 'package:flutter/services.dart';
import 'domain.dart';
const nativeLanguages=<String,String>{'pt-BR':'Português','en':'English','es':'Español','zh-Hans':'简体中文','ja':'日本語','ru':'Русский','fr':'Français','it':'Italiano'};
const intentionLabels=<String,String>{'prosperity':'Prosperidade','gratitude':'Gratidão','visualization':'Visualização','wealth':'Riqueza','abundance':'Abundância'};
const voiceLocales=<String,String>{'pt-BR':'pt-BR','en':'en-US','es':'es-ES','zh-Hans':'zh-CN','ja':'ja-JP','ru':'ru-RU','fr':'fr-FR','it':'it-IT'};
class ContentRepository {
 final Map<String,dynamic> data,journey;
 final Map<String,Map<String,dynamic>> packs;
 ContentRepository(this.data,{this.journey=const {},this.packs=const {}});
 static Future<ContentRepository> load() async {
  Future<Map<String,dynamic>> read(String path) async=>Map<String,dynamic>.from(jsonDecode(await rootBundle.loadString(path)) as Map);
  final data=await read('assets/content.json'),journey=await read('assets/journey.json');
  final packs=<String,Map<String,dynamic>>{};
  await Future.wait(nativeLanguages.keys.where((c)=>c!='pt-BR').map((c) async{final pack=await read('assets/locales/$c.json');if(pack['locale']!=c||(pack['messages'] as Map).length!=20)throw FormatException('Invalid locale $c');packs[c]=pack;}));
  return ContentRepository(data,journey:journey,packs:packs);
 }
 List<dynamic> get locales=>data['locales'] as List<dynamic>;
 Map<String,dynamic>? byId(String id){for(final item in data['messages']){if(item['id']==id)return Map<String,dynamic>.from(item);}return null;}
 Map<String,dynamic> daily(RitualMoment moment,DateTime now){final items=(data['messages'] as List).where((m)=>m['moment']==moment.name).toList();if(items.isEmpty)throw StateError('Sem conteúdo para este período.');final index=((dayIndex(now)%items.length)+items.length)%items.length;return Map<String,dynamic>.from(items[index]);}
 Map<String,dynamic> intended(String intention,RitualMoment moment,DateTime now)=>byId('${moment.name}-intention-$intention-01')??daily(moment,now);
 bool translated(String id,String locale)=>locale=='pt-BR'||packs[locale]?['messages']?[id]!=null;
 Map<String,dynamic> text(Map<String,dynamic> message,String locale){
  final source=Map<String,dynamic>.from(message['translations']['pt-BR'] as Map),value=packs[locale]?['messages']?[message['id']];
  if(value==null)return source;
  final localized=Map<String,dynamic>.from(value as Map),body=value['body'] as String;
  return {...source,'title':localized['title'],'body':body,'widget':compactWidget(body),'reflection':{...Map<String,dynamic>.from(source['reflection'] as Map),'title':localized['title'],'paragraphs':localized['paragraphs']}};
 }
 String tr(String source,String locale){
  final pack=packs[locale];if(pack==null)return source;final ui=Map<String,dynamic>.from(pack['ui'] as Map),direct=pack['ui'][source];if(direct is String)return direct;
  for(final pair in (pack['patterns'] as List? ?? [])){final match=RegExp(pair[0] as String,unicode:true).firstMatch(source);if(match!=null)return (pair[1] as String).replaceAllMapped(RegExp(r'\$(\d+)'),(m)=>match.group(int.parse(m[1]!))??'');}
  if(source.contains(' · '))return source.split(' · ').map((s)=>tr(s,locale)).join(' · ');
  for(final key in ui.keys){if(key.toLowerCase()==source.toLowerCase())return ui[key] as String;}
  return source;
 }
 Map<String,dynamic> practice(String theme,int day,String locale){
  if(!intentionLabels.containsKey(theme)||day<1||day>100)throw RangeError('Invalid journey position');
  final pack=packs[locale],practices=pack?['practices']??journey['practices'],phases=pack?['phases']??journey['phases'];
  final base=practices[theme] as List,phase=phases[(day-1)~/7] as List,item=practices[theme][(day-1)%7] as List;
  if(day==100){final ending=pack?['ending'];return {'day':day,'phase':phase[0],'title':ending?['title']??'Reconheça seu caminho e renove sua intenção','action':ending?['action']??'Releia um registro do início e um recente. Reconheça uma mudança e escolha uma prática deste tema para continuar.','meaning':'${(base[6] as List)[2]} ${phase[1]}','prompt':ending?['prompt']??'O que você leva destes cem dias e deseja cultivar a seguir?'};}
  return {'day':day,'phase':phase[0],'title':item[0],'action':item[1],'meaning':'${item[2]} ${phase[1]}','prompt':item[3]};
 }
}
String compactWidget(String text){if(text.runes.length<=120)return text;var result=String.fromCharCodes(text.runes.take(119));final space=result.lastIndexOf(' ');if(space>70)result=result.substring(0,space);return '${result.trimRight()}…';}
