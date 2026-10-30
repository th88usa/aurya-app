import 'dart:convert';
import 'package:flutter/services.dart';
import 'content_repository.dart';
import 'domain.dart';
class WidgetBridge {
 static const channel=MethodChannel('aurya/widget');
 static Map<String,dynamic> payload(ContentRepository repo,RitualSchedule schedule,{String intention='prosperity',String locale='pt-BR'})=>{
  'version':2,'locale':locale,'demo':true,'moments':[
   for(final m in RitualMoment.values){'id':m.name,'label':repo.tr(momentLabels[m]!,locale),'minute':schedule.times[m],
    'messages':[{'id':repo.intended(intention,m,DateTime.now())['id'],
      'text':compactWidget(repo.text(repo.intended(intention,m,DateTime.now()),locale)['widget'] as String)}]}]};
 static Future<String> save(ContentRepository repo,RitualSchedule schedule,{String intention='prosperity',String locale='pt-BR'}) async {
  if(!schedule.valid)throw StateError('Horários inválidos');
  try{await channel.invokeMethod('save',jsonEncode(payload(repo,schedule,intention:intention,locale:locale)));
   return 'Configuração de demonstração compartilhada. Atualização solicitada ao iOS; não confirma instalação ou troca imediata.';
  } on MissingPluginException {return 'Ponte iOS não integrada neste ambiente. Nada enviado a um widget real.';}
    on PlatformException {return 'Falha ao compartilhar configuração. Confira App Group e integração no Xcode.';}
 }
 static Future<String> clear() async {
  try{await channel.invokeMethod('clear');return 'Conteúdo compartilhado removido; atualização solicitada ao iOS.';}
  on MissingPluginException {return 'Sem ponte iOS neste ambiente; nenhuma remoção nativa foi confirmada.';}
  on PlatformException {return 'Falha ao remover conteúdo nativo. Confira integração no Xcode.';}
 }
}
