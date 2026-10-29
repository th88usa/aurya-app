// Real Web Speech API. Only local voices in the requested language; no recorded or cloned narrator.
export class NarrationSession {
 constructor({synth=globalThis.speechSynthesis,Utterance=globalThis.SpeechSynthesisUtterance,notify=()=>{},startTimeout=4500}={}){
  this.synth=synth;this.Utterance=Utterance;this.notify=notify;this.startTimeout=startTimeout;
  this.locale='pt-BR';this.status='idle';this.message='Leitura automática pela voz local do dispositivo. Sem início automático.';
  this.ticket=0;this.chunks=[];this.index=0;this.watchdog=null;this.voice=null;this.utterance=null;
 }
 emit(){this.notify(this);}
 voices(){return this.synth?.getVoices().filter(v=>v.localService===true&&v.lang.replace('_','-').toLowerCase().split('-')[0]===this.locale.toLowerCase().split('-')[0])??[];}
 async localVoice(){
  let available=this.voices();
  if(!available.length&&this.synth?.addEventListener){await new Promise(resolve=>{
   let timer;const done=()=>{clearTimeout(timer);this.synth.removeEventListener('voiceschanged',done);resolve();};
   this.synth.addEventListener('voiceschanged',done,{once:true});timer=setTimeout(done,650);
  });available=this.voices();}
  const score=v=>(v.lang.toLowerCase()===this.locale.toLowerCase()?10:0)+(/natural|neural|enhanced|premium|aprimorada/i.test(v.name)?20:0)+(/daniel|antonio|antônio|duarte|felipe/i.test(v.name)?8:0);
  return available.slice().sort((a,b)=>score(b)-score(a))[0]??null;
 }
 async play(chunks,{locale='pt-BR'}={}){
  this.locale=locale;
  this.stop(false);this.chunks=chunks;const ticket=this.ticket;
  if(!this.synth||!this.Utterance){this.unavailable('Leitura automática indisponível neste navegador. Você pode continuar lendo.');return;}
  this.status='preparing';this.message='Verificando voz local no idioma escolhido…';this.emit();
  try{this.voice=await this.localVoice();}catch{this.voice=null;}
  if(ticket!==this.ticket)return;
  if(!this.voice){this.unavailable('Voz local no idioma escolhido indisponível. Ative uma voz no dispositivo ou continue lendo.');return;}
  this.index=0;this.say(ticket);
 }
 say(ticket){
  if(ticket!==this.ticket)return;
  if(this.index>=this.chunks.length){this.status='ended';this.message='Leitura automática concluída.';this.emit();return;}
  const u=new this.Utterance(this.chunks[this.index]);this.utterance=u;
  u.voice=this.voice;u.lang=this.voice.lang;u.rate=0.92;u.pitch=0.9;u.volume=0.5;
  this.status='preparing';this.message='Preparando leitura automática…';this.emit();
  u.onstart=()=>{if(ticket!==this.ticket)return;clearTimeout(this.watchdog);this.status='speaking';this.message=`Leitura automática · ${this.voice.name} (${this.voice.lang})`;this.emit();};
  u.onpause=()=>{if(ticket!==this.ticket)return;clearTimeout(this.watchdog);this.status='paused';this.message='Leitura pausada.';this.emit();};
  u.onresume=()=>{if(ticket!==this.ticket)return;clearTimeout(this.watchdog);this.status='speaking';this.message='Leitura automática retomada.';this.emit();};
  u.onend=()=>{if(ticket!==this.ticket)return;clearTimeout(this.watchdog);this.index++;this.say(ticket);};
  u.onerror=()=>{if(ticket!==this.ticket)return;this.unavailable('A voz não conseguiu concluir a leitura. O texto continua disponível.');};
  this.watchdog=setTimeout(()=>{if(ticket===this.ticket)this.unavailable('A voz não iniciou neste dispositivo. Continue lendo ou tente novamente.');},this.startTimeout);
  try{this.synth.speak(u);}catch{this.unavailable('Não foi possível iniciar a voz. O texto continua disponível.');}
 }
 pause(){
  if(this.status!=='speaking')return;
  try{this.synth.pause();if(this.synth.paused){this.status='paused';this.message='Leitura pausada.';this.emit();}}
  catch{this.unavailable('Pausa indisponível. Leitura encerrada; o texto continua disponível.');}
 }
 resume(){
  if(this.status!=='paused')return;
  try{this.synth.resume();if(!this.synth.paused&&this.synth.speaking){this.status='speaking';this.message='Leitura automática retomada.';this.emit();}}
  catch{this.unavailable('Não foi possível retomar. Você pode reiniciar a leitura.');}
 }
 stop(emit=true){
  ++this.ticket;clearTimeout(this.watchdog);this.watchdog=null;this.utterance=null;
  try{this.synth?.cancel();}catch{}
  this.status='idle';this.message='Leitura automática encerrada.';if(emit)this.emit();
 }
 unavailable(message){this.stop(false);this.status='unavailable';this.message=message;this.emit();}
}
