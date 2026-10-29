// One independent audio element; no widget timer or message can invoke play.
export class AudioSession {
  constructor({media=new Audio(),clock=()=>Date.now(),notify=()=>{}}={}) {
    this.media=media;this.clock=clock;this.notify=notify;this.track=null;
    this.volume=0.15;this.durationMs=300000;this.remainingMs=this.durationMs;
    this.deadline=null;this.status='idle';this.message='Escolha uma amostra e toque em Reproduzir.';
    this.ticket=0;this.interval=null;
    media.preload='none';media.loop=true;media.volume=this.volume;
    media.addEventListener('error',()=>this.fail());
    media.addEventListener('pause',()=>{if(this.status==='playing')this.pause();});
  }
  emit(){this.notify(this);}
  select(track){
    this.stop(false);this.track=track;this.media.src=`../assets/${track.asset}`;
    this.status='ready';this.message='Pronto para ouvir. Sem reprodução automática.';this.emit();
  }
  setVolume(value){this.volume=Math.max(0,Math.min(1,Number(value)||0));this.media.volume=this.volume;this.emit();}
  setTimer(minutes){if(![1,5,10,15].includes(Number(minutes)))throw new Error('Temporizador inválido');
    this.durationMs=Number(minutes)*60000;this.remainingMs=this.durationMs;
    if(this.status==='playing')this.deadline=this.clock()+this.remainingMs;this.emit();}
  async play(){
    if(!this.track||this.status==='loading')return;
    const ticket=++this.ticket;this.status='loading';this.message='Preparando áudio…';this.emit();
    try {
      if(this.remainingMs<=0)this.remainingMs=this.durationMs;
      await this.media.play();
      if(ticket!==this.ticket)return;
      this.status='playing';this.message='Reproduzindo amostra em repetição.';
      this.deadline=this.clock()+this.remainingMs;
      clearInterval(this.interval);this.interval=setInterval(()=>this.tick(),500);this.emit();
    } catch {if(ticket===this.ticket)this.fail();}
  }
  pause(reason='Áudio pausado. Toque em Continuar para retomar.'){
    ++this.ticket;if(this.deadline!==null)this.remainingMs=Math.max(0,this.deadline-this.clock());
    this.deadline=null;clearInterval(this.interval);this.interval=null;
    this.status=this.track?'paused':'idle';this.media.pause();this.message=reason;this.emit();
  }
  stop(emit=true){
    ++this.ticket;clearInterval(this.interval);this.interval=null;this.deadline=null;
    this.status=this.track?'ready':'idle';this.media.pause();this.media.currentTime=0;
    this.remainingMs=this.durationMs;this.message='Sessão encerrada.';if(emit)this.emit();
  }
  tick(){if(this.status!=='playing')return;this.remainingMs=Math.max(0,this.deadline-this.clock());
    if(!this.remainingMs){this.stop(false);this.remainingMs=0;this.status='ended';this.message='Temporizador concluído. Áudio encerrado.';}this.emit();}
  fail(){this.stop(false);this.status='error';this.message='Não foi possível reproduzir. Selecione a amostra novamente e tente iniciar.';this.emit();}
  dispose(){this.stop(false);this.media.removeAttribute('src');this.media.load();}
}
