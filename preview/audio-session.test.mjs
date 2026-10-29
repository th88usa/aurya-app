import test from 'node:test';import assert from 'node:assert/strict';
import {AudioSession} from './audio-session.mjs';
class Media extends EventTarget {
 constructor(){super();this.paused=true;this.currentTime=0;this.calls=0;}
 async play(){this.calls++;this.paused=false;}
 pause(){this.paused=true;}
 removeAttribute(){} load(){}
}
const track={id:'tone-528',asset:'audio/tone-528.wav'};
test('selecionar mantém silêncio, volume inicial baixo e arquivo local',()=>{
 const media=new Media(),s=new AudioSession({media});s.select(track);
 assert.equal(media.calls,0);assert.equal(media.volume,0.15);assert.equal(media.paused,true);assert.match(media.src,/assets\/audio\/tone-528.wav/);s.dispose();
});
test('pausa preserva tempo restante e temporizador encerra ao retomar',async()=>{
 let now=1000;const media=new Media(),s=new AudioSession({media,clock:()=>now});s.select(track);s.setTimer(1);await s.play();now+=20000;s.pause();assert.equal(s.remainingMs,40000);
 now+=90000;await s.play();assert.equal(s.remainingMs,40000);now+=40001;s.tick();assert.equal(media.paused,true);assert.equal(s.status,'ended');assert.equal(s.remainingMs,0);s.dispose();
});
test('troca de faixa e encerramento não iniciam outra reprodução',async()=>{
 const media=new Media(),s=new AudioSession({media});s.select(track);await s.play();s.select({id:'tone-888',asset:'audio/tone-888.wav'});assert.equal(media.calls,1);assert.equal(media.paused,true);assert.equal(s.status,'ready');s.stop();assert.equal(s.remainingMs,300000);s.dispose();
});
test('volume é limitado e só temporizadores oferecidos são aceitos',()=>{
 const media=new Media(),s=new AudioSession({media});s.setVolume(5);assert.equal(media.volume,1);s.setVolume(-1);assert.equal(media.volume,0);assert.throws(()=>s.setTimer(0),/inválido/);s.dispose();
});
test('falha de mídia não deixa sessão reproduzindo',async()=>{
 const media=new Media();media.play=async()=>{throw new Error('decode');};const s=new AudioSession({media});s.select(track);await s.play();assert.equal(s.status,'error');assert.equal(media.paused,true);s.dispose();
});
test('cancelamento durante preparação invalida a conclusão atrasada',async()=>{
 const media=new Media();let done;media.play=()=>new Promise(r=>{done=r;});const s=new AudioSession({media});s.select(track);const pending=s.play();s.pause();done();await pending;assert.equal(s.status,'paused');assert.equal(s.interval,null);s.dispose();
});
