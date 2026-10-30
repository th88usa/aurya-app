import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'content_repository.dart';
import 'native_state.dart';
import 'domain.dart';
import 'widget_bridge.dart';
import 'audio_screen.dart';
import 'reflection_screen.dart';
import 'reflection_links.dart';
import 'journey_screen.dart';
void main()=>runApp(const AuryaApp());
Locale materialLocale(String code){if(code=='zh-Hans')return const Locale('zh','CN');final parts=code.split('-');return Locale(parts.first,parts.length>1?parts[1]:null);}
class AuryaApp extends StatefulWidget {
 final ContentRepository? repository;final LocalStore? storage;
 const AuryaApp({super.key,this.repository,this.storage});
 @override State<AuryaApp> createState()=>_AuryaAppState();
}
class _AuryaAppState extends State<AuryaApp> {
 late final NativeState state;late Future<ContentRepository> ready;
 @override void initState(){super.initState();state=NativeState(widget.storage??PreferencesStore());ready=load();}
 Future<ContentRepository> load() async{final repo=widget.repository??await ContentRepository.load();await state.load();return repo;}
 @override void dispose(){state.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>AnimatedBuilder(animation:state,builder:(context,_)=>MaterialApp(
  title:'AURYA',debugShowCheckedModeBanner:false,locale:materialLocale(state.locale),supportedLocales:nativeLanguages.keys.map(materialLocale).toList(),
  localizationsDelegates:GlobalMaterialLocalizations.delegates,
  theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:const Color(0xFF121C24),colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFFDDC49E),brightness:Brightness.dark),inputDecorationTheme:const InputDecorationTheme(border:OutlineInputBorder())),
  home:FutureBuilder<ContentRepository>(future:ready,builder:(context,snapshot){
   if(snapshot.hasError)return Scaffold(body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('AURYA'),const Text('Falha ao carregar conteúdo.'),TextButton(onPressed:()=>setState(()=>ready=load()),child:const Text('Tentar novamente'))])));
   if(!snapshot.hasData)return const Scaffold(body:Center(child:CircularProgressIndicator()));
   return AuryaShell(repository:snapshot.data!,state:state);
  })));
}
class AuryaShell extends StatefulWidget {
 final ContentRepository repository;final NativeState state;
 const AuryaShell({super.key,required this.repository,required this.state});
 @override State<AuryaShell> createState()=>_AuryaShellState();
}
class _AuryaShellState extends State<AuryaShell> with WidgetsBindingObserver {
 final form=GlobalKey<FormState>();final email=TextEditingController(text:'visitante@example.com');
 StreamSubscription<Uri>? linkSubscription;Timer? boundary;
 String? reflectionId,pendingReflection;bool linkError=false,busy=false,reveal=true,allowWidget=false;
 String bridgeStatus='Widget real ainda não integrado ou validado neste ambiente.';
 int step=0,tab=0;RitualMoment? preview;
 NativeState get model=>widget.state;ContentRepository get repo=>widget.repository;
 String t(String s)=>repo.tr(s,model.locale);
 RitualSchedule get schedule=>RitualSchedule(model.times);
 @override void initState(){super.initState();step=model.onboarded?3:0;WidgetsBinding.instance.addObserver(this);linkSubscription=AppLinks().uriLinkStream.listen(receiveLink,onError:(Object _){if(mounted)setState(()=>linkError=true);});armBoundary();}
 @override void dispose(){linkSubscription?.cancel();boundary?.cancel();email.dispose();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 @override void didChangeAppLifecycleState(AppLifecycleState value){if(value==AppLifecycleState.resumed){if(mounted)setState((){});armBoundary();}else{unawaited(model.flush());}}
 void armBoundary(){boundary?.cancel();if(step<3)return;final delay=schedule.nextAt(DateTime.now()).date.difference(DateTime.now())+const Duration(milliseconds:100);boundary=Timer(delay.isNegative?Duration.zero:delay,(){if(mounted){setState((){});armBoundary();}});}
 void receiveLink(Uri uri){final id=reflectionIdFromUri(uri);if(!mounted)return;setState((){if(id==null||repo.byId(id)==null){linkError=true;return;}linkError=false;if(step<3){pendingReflection=id;}else{reflectionId=id;tab=0;}});}
 Widget gap([double h=20])=>SizedBox(height:h);
 Widget note(String s)=>Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(t(s),style:const TextStyle(height:1.6,color:Color(0xFFBAC7CF))));
 Widget heading(String tag,String title,String body)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t(tag).toUpperCase(),style:const TextStyle(letterSpacing:1.6,fontSize:11)),gap(12),Text(t(title),style:const TextStyle(fontSize:32)),gap(12),Text(t(body)),gap(24)]);
 Widget button(String label,VoidCallback? action)=>FilledButton(onPressed:action,style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(48)),child:Text(t(label)));
 Widget languageChoice()=>DropdownButton<String>(key:ValueKey('locale-${model.locale}'),value:model.locale,underline:const SizedBox.shrink(),isExpanded:true,items:[for(final e in nativeLanguages.entries)DropdownMenuItem(value:e.key,child:Text(e.value,style:const TextStyle(fontSize:13)))],onChanged:(v){if(v!=null){setState(()=>reflectionId=null);model.setLocale(v);}});
 Future<void> pick(RitualMoment m) async{final v=model.times[m]!;final result=await showTimePicker(context:context,initialTime:TimeOfDay(hour:v~/60,minute:v%60));if(result==null||!mounted)return;if(!model.updateTimes({...model.times,m:result.hour*60+result.minute})){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t('Defina quatro horários válidos e diferentes.'))));}armBoundary();}
 Widget timeFields()=>Column(children:[for(final m in RitualMoment.values)ListTile(contentPadding:EdgeInsets.zero,title:Text(t(momentLabels[m]!)),trailing:Text(clockLabel(model.times[m]!)),onTap:()=>pick(m)),note('Os horários controlam as transições da mensagem. Não são alarmes nem notificações.')]);
 void enter(){model.completeOnboarding();setState((){step=3;reflectionId=pendingReflection;pendingReflection=null;});armBoundary();}
 Widget onboarding(){
  if(step==0)return Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('Um espaço para você','Comece por dentro.','Quatro momentos do seu dia. Uma mensagem para ler na tela de bloqueio do iPhone.'),Text(t('Cadastro de demonstração'),style:const TextStyle(fontSize:20)),gap(),TextFormField(controller:email,keyboardType:TextInputType.emailAddress,decoration:InputDecoration(labelText:t('E-mail fictício de teste')),validator:(v)=>validDemoEmail(v??'')?null:t('Informe um e-mail fictício válido.')),note('Use dados fictícios. O cadastro é obrigatório para entrar nesta demonstração. Não cria conta real, não envia e-mail e não solicita senha. Os dados desaparecem ao recarregar.'),button('Criar cadastro de demonstração',(){if(form.currentState!.validate())setState(()=>step=1);})]));
  if(step==1)return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('01 / Seu idioma','Palavras que acolhem.','Escolha o idioma que deseja usar na versão completa.'),languageChoice(),gap(),IntentionSelector(repository:repo,state:model),button('Continuar →',()=>setState(()=>step=2)),TextButton(onPressed:()=>setState(()=>step=0),child:Text(t('Voltar')))]);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('02 / Seus momentos','Quatro momentos.','Ao acordar, indo para o trabalho, meio do dia e antes de dormir.'),timeFields(),button('Revisar tela de bloqueio →',enter),TextButton(onPressed:()=>setState(()=>step=1),child:Text(t('Voltar')))]);
 }
 Widget home(){
  final active=schedule.activeAt(DateTime.now()),moment=preview??active.moment,message=repo.intended(model.intention,moment,active.date),text=repo.text(message,model.locale);
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[IntentionSelector(repository:repo,state:model),heading('Feito para a tela de bloqueio','Uma frase.','O seu momento.'),note('SIMULAÇÃO DE TELA DE BLOQUEIO'),Wrap(spacing:8,runSpacing:8,children:[for(final m in RitualMoment.values)ChoiceChip(label:Text(t(momentLabels[m]!)),selected:moment==m,onSelected:(_)=>setState(()=>preview=m))]),if(preview!=null)TextButton(onPressed:()=>setState(()=>preview=null),child:Text(t('Simulação manual • voltar ao relógio local'))),gap(),
   Center(child:Container(width:280,padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:const Color(0xFF273645),borderRadius:BorderRadius.circular(28)),child:Column(children:[Text(t('SIMULAÇÃO'),style:const TextStyle(fontSize:10)),gap(),Text(clockLabel(model.times[moment]!),style:const TextStyle(fontSize:48)),gap(),SizedBox(width:190,height:90,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('AURYA · ${t(momentLabels[moment]!)}',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10)),Text(reveal?text['widget'] as String:t('Conteúdo oculto pela opção de privacidade.'),maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,height:1.4))]))]))),
   SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(t('Mostrar frase nesta simulação de bloqueio')),value:reveal,onChanged:(v)=>setState(()=>reveal=v)),note('Não é um widget instalado. Tamanho, fonte e aparência reais dependem do iPhone e do iOS.'),Text(text['title'] as String,style:const TextStyle(fontSize:23)),gap(),Text(text['body'] as String,style:const TextStyle(fontSize:24,height:1.6)),gap(),Text(t('TEXTO ORIGINAL AURYA'),style:const TextStyle(fontSize:11)),gap(12),button('Aprofundar',()=>setState(()=>reflectionId=message['id'] as String)),gap(),for(final m in RitualMoment.values)Text('${t(momentLabels[m]!)} · ${clockLabel(model.times[m]!)}'),note('A mensagem não muda à meia-noite; permanece até o próximo momento.')]);
 }
 Future<void> saveWidget() async{if(busy)return;setState(()=>busy=true);final result=allowWidget?await WidgetBridge.save(repo,schedule,intention:model.intention,locale:model.locale):await WidgetBridge.clear();if(mounted)setState((){busy=false;bridgeStatus=result;});}
 Widget settings()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading('Seus quatro momentos','No seu ritmo.','Seus registros ficam neste aparelho.'),Text(t('Idioma preferido')),languageChoice(),timeFields(),SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(t('Permitir frases no widget de demonstração')),value:allowWidget,onChanged:(v)=>setState(()=>allowWidget=v)),button('Salvar configuração do widget',busy?null:saveWidget),note(bridgeStatus),note('A ponte do widget ainda precisa de integração e teste no iPhone.'),button('Apagar dados locais',()=>confirmReset())]);
 Future<void> confirmReset() async{final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(t('Apagar dados locais?')),content:Text(t('Isso remove as anotações, o progresso e as preferências deste aparelho.')),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(t('Cancelar'))),TextButton(onPressed:()=>Navigator.pop(c,true),child:Text(t('Apagar')))]));if(yes!=true)return;await WidgetBridge.clear();await model.reset();if(mounted)setState((){step=0;tab=0;reflectionId=null;allowWidget=false;});}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('A U R Y A'),actions:[SizedBox(width:130,child:languageChoice()),const SizedBox(width:16)]),body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:560),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  if(model.loadError)note('Não foi possível recuperar todos os dados locais. Confira seus registros antes de continuar.'),if(model.saveError)note('Não foi possível salvar. Seus registros estão apenas nesta sessão.'),if(linkError)note('Esta reflexão não está disponível. Você pode continuar usando o AURYA.'),
  step<3?onboarding():reflectionId!=null?ReflectionScreen(key:ValueKey('$reflectionId-${model.locale}'),message:repo.byId(reflectionId!)!,translation:repo.text(repo.byId(reflectionId!)!,model.locale),locale:repo.translated(reflectionId!,model.locale)?voiceLocales[model.locale]!:'pt-BR',translate:t,onBack:()=>setState(()=>reflectionId=null)):tab==0?home():tab==1?AudioScreen(translate:t):tab==2?JourneyScreen(repository:repo,state:model):settings(),
 ]))))),bottomNavigationBar:step<3?null:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState((){reflectionId=null;tab=v;}),destinations:[NavigationDestination(icon:const Icon(Icons.lock_outline),label:t('Bloqueio')),NavigationDestination(icon:const Icon(Icons.headphones_outlined),label:t('Áudios')),NavigationDestination(icon:const Icon(Icons.check_circle_outline),label:t('Tarefas')),NavigationDestination(icon:const Icon(Icons.tune),label:t('Horários'))]));
}
