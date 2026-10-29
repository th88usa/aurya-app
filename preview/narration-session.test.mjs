import test from 'node:test';import assert from 'node:assert/strict';
import {NarrationSession} from './narration-session.mjs';
class Utterance {constructor(text){this.text=text;}}
class Synth {
 constructor(){this.items=[];this.cancelled=0;this.paused=false;this.speaking=false;this.available=[{name:'Voz local de teste',lang:'pt-BR',localService:true}];}
 getVoices(){return this.available;}
 speak(u){this.items.push(u);this.current=u;this.speaking=true;u.onstart?.();}
 pause(){this.paused=true;this.current?.onpause?.();}
 resume(){this.paused=false;this.current?.onresume?.();}
 cancel(){this.cancelled++;this.speaking=false;this.paused=false;}
}
test('controle de voz: sem autoplay, frases em ordem e conclusão após último trecho (API simulada)',async()=>{
 const synth=new Synth(),s=new NarrationSession({synth,Utterance});assert.equal(synth.items.length,0);await s.play(['Eu sou próspero.','Meu texto completo.']);assert.equal(s.status,'speaking');assert.equal(synth.items[0].lang,'pt-BR');synth.current.onend();assert.equal(synth.items[1].text,'Meu texto completo.');synth.current.onend();assert.equal(s.status,'ended');s.stop();
});
test('pausa/retomada e cancelamento descartam callbacks anteriores (API simulada)',async()=>{
 const synth=new Synth(),s=new NarrationSession({synth,Utterance});await s.play(['Primeiro','Segundo']);s.pause();assert.equal(s.status,'paused');s.resume();assert.equal(s.status,'speaking');const old=synth.current;s.stop();old.onend();assert.equal(synth.items.length,1);assert.equal(s.status,'idle');
});
test('sem engine ou voz portuguesa local há fallback legível, sem fingir reprodução',async()=>{
 const unavailable=new NarrationSession({synth:null,Utterance:null});await unavailable.play(['Texto']);assert.equal(unavailable.status,'unavailable');
 const synth=new Synth();synth.available=[{name:'English',lang:'en-US',localService:true},{name:'Remote PT',lang:'pt-BR',localService:false}];const s=new NarrationSession({synth,Utterance});await s.play(['Texto']);assert.equal(s.status,'unavailable');assert.equal(synth.items.length,0);
});
test('engine sem evento de início termina com erro honesto (API simulada)',async()=>{
 const synth=new Synth();synth.speak=u=>{synth.current=u;};const s=new NarrationSession({synth,Utterance,startTimeout:15});await s.play(['Texto']);assert.equal(s.status,'preparing');await new Promise(r=>setTimeout(r,30));assert.equal(s.status,'unavailable');assert.ok(synth.cancelled>=2);
});
test('erro e troca de texto não avançam fila antiga (API simulada)',async()=>{
 const synth=new Synth(),s=new NarrationSession({synth,Utterance});await s.play(['Antigo']);const old=synth.current;await s.play(['Novo']);old.onend();assert.equal(synth.items.length,2);synth.current.onerror();assert.equal(s.status,'unavailable');s.stop();
});
