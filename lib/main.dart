import 'dart:async';
import 'package:flutter/material.dart';
import 'content_repository.dart';
import 'domain.dart';
import 'widget_bridge.dart';
import 'audio_screen.dart';
import 'package:app_links/app_links.dart';
import 'reflection_screen.dart';
import 'reflection_links.dart';
void main()=>runApp(const AuryaApp());
class AuryaApp extends StatelessWidget {
 const AuryaApp({super.key});
 @override Widget build(BuildContext context)=>MaterialApp(title:'AURYA • Demo',debugShowCheckedModeBanner:false,
  theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:const Color(0xFF121C24),
   colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFFDDC49E),brightness:Brightness.dark),
   inputDecorationTheme:const InputDecorationTheme(border:OutlineInputBorder())),home:const AuryaShell());
}
class AuryaShell extends StatefulWidget {
 const AuryaShell({super.key});
 @override State<AuryaShell> createState()=>_AuryaShellState();
}
class _AuryaShellState extends State<AuryaShell> with WidgetsBindingObserver {
 late Future<ContentRepository> content;
 final form=GlobalKey<FormState>();
 final name=TextEditingController(),email=TextEditingController(text:'visitante@example.com');
 final times=Map<RitualMoment,int>.from(exampleMinutes);
 final links=AppLinks();
 StreamSubscription<Uri>? linkSubscription;
 String? reflectionId,pendingReflection;
 bool linkError=false;
 Timer? boundary;
 int step=0,tab=0;
 String locale='pt-BR',bridgeStatus='Widget real ainda não integrado ou validado neste ambiente.';
 RitualMoment? preview;
 bool reveal=true,allowWidget=false,busy=false;
 RitualSchedule get schedule=>RitualSchedule(times);
 @override void initState(){super.initState();content=ContentRepository.load();WidgetsBinding.instance.addObserver(this);
  linkSubscription=links.uriLinkStream.listen(receiveLink,onError:(Object _){if(mounted)setState(()=>linkError=true);});
 }
 void armBoundary(){
  boundary?.cancel();if(step<3||!schedule.valid)return;
  final now=DateTime.now();final delay=schedule.nextAt(now).date.difference(now)+const Duration(milliseconds:100);
  boundary=Timer(delay,(){if(mounted){setState((){});armBoundary();}});
 }
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed){setState((){});armBoundary();}}
 @override void dispose(){linkSubscription?.cancel();boundary?.cancel();WidgetsBinding.instance.removeObserver(this);name.dispose();email.dispose();super.dispose();}
 Future<void> receiveLink(Uri uri) async {
  try {
   final id=reflectionIdFromUri(uri);
   final repo=await content;if(!mounted)return;
   if(id==null||repo.byId(id)==null){setState(()=>linkError=true);return;}
   setState((){linkError=false;if(step<3){pendingReflection=id;}else{reflectionId=id;tab=0;}});
  }catch(_){if(mounted)setState(()=>linkError=true);}
 }
 void openReflection(String id)=>setState((){reflectionId=id;linkError=false;tab=0;});
 Widget gap([double n=20])=>SizedBox(height:n);
 Widget title(String tag,String heading,String text)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Text(tag.toUpperCase(),style:const TextStyle(color:Color(0xFFDDC49E),letterSpacing:2)),gap(12),
  Text(heading,style:const TextStyle(fontSize:34,fontWeight:FontWeight.w300)),gap(12),Text(text,style:const TextStyle(height:1.6)),gap(24)]);
 Widget note(String text)=>Padding(padding:const EdgeInsets.symmetric(vertical:14),child:Text(text,style:const TextStyle(color:Color(0xFFBAC7CF),height:1.5)));
 Widget button(String label,VoidCallback action)=>FilledButton(onPressed:action,style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(52)),child:Text(label));
 Future<void> pick(RitualMoment m) async {
  final v=times[m]!;final result=await showTimePicker(context:context,initialTime:TimeOfDay(hour:v~/60,minute:v%60));
  if(result!=null&&mounted)setState((){times[m]=result.hour*60+result.minute;bridgeStatus='Horários alterados no app. Salve para atualizar a configuração compartilhada.';});
  armBoundary();
 }
 Widget languages(ContentRepository repo)=>Column(children:[DropdownButtonFormField<String>(initialValue:locale,isExpanded:true,
  decoration:const InputDecoration(labelText:'Idioma preferido'),items:repo.locales.map((l)=>DropdownMenuItem<String>(value:l['code'] as String,
   child:Text('${l['label']}${l['available']==true?'':' • em preparação'}'))).toList(),onChanged:(v)=>setState(()=>locale=v!)),
  note(locale=='pt-BR'?'Amostras originais em português.':'Tradução em preparação. Interface e conteúdo continuam em português.')]);
 Widget timeFields()=>Column(children:[note('Os horários iniciais são exemplos editáveis, não escolhas suas. Defina os quatro momentos em horário local.'),
  for(final m in RitualMoment.values)ListTile(contentPadding:EdgeInsets.zero,title:Text(momentLabels[m]!),trailing:Text(clockLabel(times[m]!)),onTap:()=>pick(m)),
  if(!schedule.valid)const Text('Defina quatro horários válidos e diferentes.',style:TextStyle(color:Colors.orangeAccent)),
  note('A ordem segue o relógio. Cada mensagem permanece até a próxima troca, inclusive após a meia-noite. Não são alarmes ou notificações.')]);
 void enter(){if(!schedule.valid)return;setState((){step=3;reflectionId=pendingReflection;pendingReflection=null;});armBoundary();}
 Widget onboarding(ContentRepository repo){
  if(step==0)return Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   title('Um espaço para você','Comece por dentro.','Quatro momentos para ler na tela de bloqueio do iPhone.'),
   const Text('Cadastro de demonstração',style:TextStyle(fontSize:20)),gap(),
   TextFormField(controller:name,maxLength:60,decoration:const InputDecoration(labelText:'Nome fictício (opcional)')),gap(),
   TextFormField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-mail fictício de teste'),validator:(v)=>validDemoEmail(v??'')?null:'Informe um e-mail fictício válido.'),
   note('Cadastro obrigatório apenas para a demonstração. Sem conta real ou senha. Use dados fictícios.'),
   button('Criar cadastro de demonstração',(){if(form.currentState!.validate())setState(()=>step=1);})]));
  if(step==1)return Column(children:[title('01 / Idioma','Palavras que acolhem.','Oito idiomas previstos; apenas amostras em português nesta etapa.'),languages(repo),button('Continuar',()=>setState(()=>step=2))]);
  return Column(children:[title('02 / Seus momentos','Quatro momentos.\nUm ritmo seu.','Ao acordar, indo para o trabalho, meio do dia e antes de dormir.'),timeFields(),
   FilledButton(onPressed:schedule.valid?enter:null,child:const Text('Revisar tela de bloqueio')),TextButton(onPressed:()=>setState(()=>step=1),child:const Text('Voltar'))]);
 }
 Widget home(ContentRepository repo){
  final now=DateTime.now(),active=schedule.activeAt(DateTime.now());final m=preview??active.moment;
  final message=repo.daily(m,preview==null?active.date:now),text=message['translations']['pt-BR'];
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[title('Tela de bloqueio','Uma frase.\nO seu momento.','O app configura; o widget é a experiência principal.'),
   note('SIMULAÇÃO • Não é um widget instalado. Dimensões e aparência reais dependem do iPhone/iOS.'),
   Wrap(spacing:8,runSpacing:8,children:[for(final item in RitualMoment.values)ChoiceChip(label:Text(momentLabels[item]!),selected:m==item,onSelected:(_)=>setState(()=>preview=item))]),
   if(preview!=null)TextButton(onPressed:()=>setState(()=>preview=null),child:const Text('Voltar ao relógio local')),
   gap(),Center(child:Container(width:280,padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:const Color(0xFF273645),borderRadius:BorderRadius.circular(28)),child:Column(children:[
    const Text('SIMULAÇÃO DE BLOQUEIO',style:TextStyle(fontSize:10)),gap(),Text(clockLabel(times[m]!),style:const TextStyle(fontSize:52)),gap(),
    SizedBox(width:160,height:76,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('AURYA · ${momentLabels[m]}',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,fontWeight:FontWeight.bold)),
     Text(reveal?text['widget'] as String:'Conteúdo oculto por privacidade.',maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,height:1.3))])),gap(),const Text('accessoryRectangular • ilustrativo',style:TextStyle(fontSize:9))]))),
   SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Mostrar frase na simulação'),value:reveal,onChanged:(v)=>setState(()=>reveal=v)),
   note('Sem rotação contínua. O iOS controla atualização e privacidade; o minuto exato não é garantido. Texto pode ser cortado no widget real.'),
   Text(text['title'] as String,style:const TextStyle(fontSize:20)),gap(),Text(text['body'] as String,style:const TextStyle(fontSize:25,height:1.5)),gap(),button('Aprofundar',()=>openReflection(message['id'] as String)),
   if(locale!='pt-BR')note('Tradução em preparação; exibindo português.'),gap(),
   for(final item in RitualMoment.values)Text('${momentLabels[item]} · ${clockLabel(times[item]!)}'),
   note('Free: espaço de anúncio futuro apenas dentro do app. Nenhum anúncio no widget.')]);
 }
 Future<void> saveWidget(ContentRepository repo) async {
  if(!schedule.valid||busy)return;setState(()=>busy=true);
  final result=allowWidget?await WidgetBridge.save(repo,schedule):await WidgetBridge.clear();
  if(mounted)setState((){busy=false;bridgeStatus=result;});armBoundary();
 }
 Future<void> leave({bool reset=false}) async {
  if(busy)return;setState(()=>busy=true);final result=await WidgetBridge.clear();
  if(!mounted)return;setState((){busy=false;step=0;tab=0;preview=null;reflectionId=null;pendingReflection=null;name.clear();email.text='visitante@example.com';allowWidget=false;bridgeStatus=result;
   if(reset){times..clear()..addAll(exampleMinutes);locale='pt-BR';reveal=true;}});boundary?.cancel();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(result)));
 }
 Widget settings(ContentRepository repo)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[title('Configuração','No seu ritmo.','Quatro trocas previstas; leitura sem abrir o app.'),languages(repo),timeFields(),
  SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Permitir frases no widget de demonstração'),subtitle:const Text('A frase será visível na tela bloqueada conforme os ajustes de privacidade do iOS. Nome/e-mail não são compartilhados.'),value:allowWidget,onChanged:(v)=>setState(()=>allowWidget=v)),
  FilledButton(onPressed:schedule.valid&&!busy?()=>saveWidget(repo):null,child:Text(busy?'Preparando…':'Salvar configuração do widget')),
  note(bridgeStatus),note('Adicionar o widget ao bloqueio é uma ação manual no iPhone. A ponte nativa precisa ser integrada no Xcode; esta versão não confirma instalação.'),
  button('Sair da demonstração',()=>leave()),TextButton(onPressed:() async {
   final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Apagar demonstração?'),content:const Text('Redefine a sessão e solicita limpeza do conteúdo compartilhado no iOS.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),TextButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Apagar'))]));
   if(yes==true)await leave(reset:true);
  },child:const Text('Apagar dados da demonstração'))]);
 Widget premium()=>Column(children:[title('Futuro Premium','Seu ritual. Sua voz.','Sem anúncios, com gravação e reprodução da própria voz.'),note('Integrações futuras. Sem preço, compra, restauração ou microfone ativo. Widget não foi condicionado a compra nesta demonstração.')]);
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('A U R Y A'),actions:const[Padding(padding:EdgeInsets.all(16),child:Text('DEMO'))]),
  body:SafeArea(child:FutureBuilder<ContentRepository>(future:content,builder:(context,snapshot){
   if(snapshot.hasError)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Falha ao carregar conteúdo.'),TextButton(onPressed:()=>setState(()=>content=ContentRepository.load()),child:const Text('Tentar novamente'))]));
   if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());final repo=snapshot.data!;
   return SingleChildScrollView(padding:const EdgeInsets.all(24),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:560),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(linkError)note('Esta reflexão não está disponível. Você pode continuar usando o AURYA.'),step<3?onboarding(repo):reflectionId!=null?ReflectionScreen(key:ValueKey(reflectionId),message:repo.byId(reflectionId!)!,onBack:()=>setState(()=>reflectionId=null)):tab==0?home(repo):tab==1?const AudioScreen():tab==2?settings(repo):premium()]))));
  })),bottomNavigationBar:step<3?null:NavigationBar(selectedIndex:tab,onDestinationSelected:(v){if(!schedule.valid){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Defina quatro horários diferentes.')));return;}setState((){reflectionId=null;tab=v;});},destinations:const[
   NavigationDestination(icon:Icon(Icons.lock_outline),label:'Bloqueio'),NavigationDestination(icon:Icon(Icons.headphones_outlined),label:'Áudios'),NavigationDestination(icon:Icon(Icons.tune),label:'Horários'),NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),label:'Premium')]));
}


