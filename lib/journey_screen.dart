import 'package:flutter/material.dart';
import 'content_repository.dart';
import 'native_state.dart';
class IntentionSelector extends StatelessWidget {
 final ContentRepository repository;final NativeState state;
 const IntentionSelector({super.key,required this.repository,required this.state});
 @override Widget build(BuildContext context){String t(String s)=>repository.tr(s,state.locale);return Padding(padding:const EdgeInsets.only(bottom:24),child:DropdownButtonFormField<String>(key:ValueKey('intention-${state.intention}-${state.locale}'),initialValue:state.intention,isExpanded:true,decoration:InputDecoration(labelText:t('O que você quer cultivar neste momento?')),items:[for(final e in intentionLabels.entries)DropdownMenuItem(value:e.key,child:Text(t(e.value)))],onChanged:(v){if(v!=null)state.setIntention(v);}));}
}
class JourneyScreen extends StatefulWidget {
 final ContentRepository repository;final NativeState state;
 const JourneyScreen({super.key,required this.repository,required this.state});
 @override State<JourneyScreen> createState()=>_JourneyScreenState();
}
class _JourneyScreenState extends State<JourneyScreen> {
 int day=1;final note=TextEditingController();
 String t(String s)=>widget.repository.tr(s,widget.state.locale);
 Map<String,dynamic> get record=>widget.state.record(widget.state.intention,day);
 void syncNote(){final value=record['note'] as String? ?? '';if(note.text!=value)note.text=value;}
 @override void initState(){super.initState();syncNote();}
 @override void didUpdateWidget(covariant JourneyScreen old){super.didUpdateWidget(old);syncNote();}
 @override void dispose(){note.dispose();super.dispose();}
 void selectDay(int value){setState((){day=value;syncNote();});}
 @override Widget build(BuildContext context){
  final state=widget.state,d=widget.repository.practice(state.intention,day,state.locale),done=state.completed(state.intention),week=(day-1)~/7;
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   IntentionSelector(repository:widget.repository,state:state),
   Text(t('Jornada · 100 dias'),style:const TextStyle(letterSpacing:1.5,fontSize:12)),const SizedBox(height:12),
   Text(t('Um passo por dia.'),style:const TextStyle(fontSize:32)),const SizedBox(height:12),
   Text(t('Uma prática por dia, com retomadas que aprofundam sua intenção.')),const SizedBox(height:20),
   Text(t('$done de 100 atividades concluídas')),const SizedBox(height:8),
   LinearProgressIndicator(value:done/100,semanticsLabel:t('Progresso da jornada')),
   const SizedBox(height:20),
   DropdownButtonFormField<int>(key:ValueKey('week-$week-${state.locale}'),initialValue:week,isExpanded:true,decoration:InputDecoration(labelText:t('Etapa da jornada')),items:[for(var w=0;w<15;w++)DropdownMenuItem(value:w,child:Text(t('Dias ${w*7+1}–${((w+1)*7).clamp(1,100)}')))],onChanged:(w){if(w!=null)selectDay(w*7+1);}),
   const SizedBox(height:16),Wrap(spacing:8,runSpacing:8,children:[for(var d=week*7+1;d<=((week+1)*7).clamp(1,100);d++)ChoiceChip(label:Text('${t('Dia $d')}${state.record(state.intention,d)['done']==true?' ✓':''}'),selected:day==d,onSelected:(_)=>selectDay(d))]),
   const SizedBox(height:24),Text('${t('Dia $day')} · ${d['phase']}',style:const TextStyle(fontSize:12)),const SizedBox(height:12),
   Text(d['title'] as String,style:const TextStyle(fontSize:25)),const SizedBox(height:14),
   Text(d['action'] as String,style:const TextStyle(fontSize:18,height:1.5)),const SizedBox(height:12),
   Text(t(record['adapted']==true?'Versão breve: faça apenas uma parte ou registre uma ideia, no seu ritmo.':'Reserve cerca de cinco minutos ou adapte ao seu dia.')),
   TextButton(onPressed:()=>state.updateRecord(state.intention,day,{'adapted':record['adapted']!=true}),child:Text(t(record['adapted']==true?'Voltar à prática completa':'Adaptar para uma versão breve'))),
   ExpansionTile(key:ValueKey('meaning-${state.intention}-$day'),tilePadding:EdgeInsets.zero,title:Text(t('Aprofundar')),children:[Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(d['meaning'] as String,style:const TextStyle(fontSize:17,height:1.7)))]),
   const SizedBox(height:16),TextField(key:ValueKey('journey-note'),controller:note,maxLength:1000,minLines:4,maxLines:8,decoration:InputDecoration(labelText:d['prompt'] as String,alignLabelWithHint:true,hintText:t('Seu registro é opcional…')),onChanged:(value)=>state.updateRecord(state.intention,day,{'note':value})),
   const SizedBox(height:12),FilledButton(onPressed:()=>state.updateRecord(state.intention,day,{'done':record['done']!=true}),child:Text(t(record['done']==true?'Concluída ✓ · desfazer':'Concluí esta atividade'))),
   TextButton(onPressed:()=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t('Tudo bem. Volte quando fizer sentido para você.')))),child:Text(t('Fazer depois'))),
   const SizedBox(height:16),Text(t('Prática original do AURYA · sua intenção em uma experiência diária.')),
   const SizedBox(height:10),Text(t('Seus registros ficam neste aparelho. Uma pausa não apaga suas conquistas.')),
  ]);
 }
}
