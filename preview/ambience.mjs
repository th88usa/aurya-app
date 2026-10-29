// Original instrumental composition. Theme choice is artistic.
export function pickReflectionTrack(tracks,theme,lastFrequency,random=Math.random){
 const allowed=tracks.filter(t=>['prosperity','wealth','gratitude'].includes(t.theme)&&Number.isFinite(t.frequencyHz)&&/^audio\/[a-z0-9-]+\.wav$/.test(t.asset));
 const themed=allowed.filter(t=>t.theme===theme);
 const pool=themed.length?themed:allowed;
 const fresh=pool.filter(t=>t.frequencyHz!==lastFrequency);
 const choices=fresh.length?fresh:pool;
 return choices.length?choices[Math.min(choices.length-1,Math.floor(Math.max(0,random())*choices.length))]:null;
}
export class ReflectionAmbience {
 constructor({createAudio=url=>new Audio(url),now=()=>performance.now(),schedule=(fn,ms)=>setInterval(fn,ms),cancel=id=>clearInterval(id),tailMs=8000,notify=()=>{},tracks=[],random=Math.random}={}){
  this.enabled=true;this.audio=null;this.fade=null;this.token=0;this.status='idle';this.ending=false;
  this.tracks=tracks;this.random=random;this.lastFrequency=null;this.track=null;
  this.createAudio=createAudio;this.now=now;this.schedule=schedule;this.cancel=cancel;this.tailMs=tailMs;this.notify=notify;
 }
 setCatalog(tracks){this.tracks=Array.isArray(tracks)?tracks:[];}
 prepare(theme='prosperity'){
  this.stop();if(!this.enabled)return;
  this.track=pickReflectionTrack(this.tracks,theme,this.lastFrequency,this.random);
  if(!this.track)return;
  this.lastFrequency=this.track.frequencyHz;
  const audio=this.createAudio(new URL('../assets/'+this.track.asset,import.meta.url).href);
  audio.loop=true;audio.volume=0;audio.preload='auto';this.audio=audio;
  const token=this.token;
  audio.play().then(()=>{if(token!==this.token||this.audio!==audio){audio.pause();return;}if(this.status!=='speaking')audio.pause();}).catch(()=>{});
 }
 sync(status){
  const previous=this.status;this.status=status;
  if(['idle','unavailable'].includes(status)){this.stop();return;}
  if(!this.audio)return;
  if(status==='ended'){
   if(previous!=='ended'&&this.enabled){this.ending=true;this.audio.play().catch(()=>{});this.fadeTo(0,true,this.tailMs,()=>{this.stop();this.notify();});}
   return;
  }
  this.ending=false;
  if(status==='speaking'&&this.enabled){this.audio.play().catch(()=>{});this.fadeTo(.16);}
  else this.fadeTo(0,true);
 }
 fadeTo(target,pause=false,duration=450,finished=()=>{}){
  this.cancel(this.fade);const audio=this.audio;if(!audio)return;
  const initial=audio.volume,start=this.now(),token=this.token;
  this.fade=this.schedule(()=>{
   if(this.audio!==audio||token!==this.token)return;
   const progress=Math.min(1,Math.max(0,(this.now()-start)/duration));
   const smooth=(1-Math.cos(Math.PI*progress))/2;
   audio.volume=initial+(target-initial)*smooth;
   if(progress===1){this.cancel(this.fade);this.fade=null;if(pause)audio.pause();finished();}
  },30);
 }
 stop(){
  this.token++;this.cancel(this.fade);this.fade=null;this.ending=false;
  if(this.audio){this.audio.pause();this.audio.removeAttribute('src');this.audio.load();}
  this.audio=null;
 }
}
