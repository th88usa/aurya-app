import test from 'node:test';
import assert from 'node:assert/strict';
import {ReflectionAmbience,pickReflectionTrack} from './ambience.mjs';
import {readFileSync} from 'node:fs';
const catalog=JSON.parse(readFileSync(new URL('../assets/audio_catalog.json',import.meta.url)));
function fixture(){
 let time=0,id=0,changes=0;const jobs=new Map(),media=[];
 const a=new ReflectionAmbience({tracks:[catalog.tracks[0]],now:()=>time,schedule:fn=>{jobs.set(++id,fn);return id;},cancel:id=>jobs.delete(id),notify:()=>changes++,createAudio:()=>{const m={volume:0,paused:true,play(){this.paused=false;return Promise.resolve();},pause(){this.paused=true;},removeAttribute(){},load(){}};media.push(m);return m;}});
 const advance=ms=>{time+=ms;for(const fn of [...jobs.values()])fn();};
 return {a,media,jobs,advance,changes:()=>changes};
}
test('natural end retains music and fades smoothly to silence over eight seconds',async()=>{
 const {a,media,advance,changes}=fixture();a.prepare();a.sync('speaking');await Promise.resolve();advance(450);const m=media[0];assert.equal(m.volume,.16);
 a.sync('ended');assert.ok(a.ending);assert.equal(m.paused,false);assert.equal(m.volume,.16);
 advance(4000);assert.ok(Math.abs(m.volume-.08)<1e-8);assert.equal(m.paused,false);
 a.sync('ended');advance(3999);assert.ok(a.audio);assert.equal(m.paused,false);
 advance(1);assert.equal(m.volume,0);assert.equal(m.paused,true);assert.equal(a.audio,null);assert.equal(a.ending,false);assert.equal(changes(),1);
});
test('manual stop, navigation and unavailable voice cancel the outro immediately',()=>{
 for(const status of ['idle','unavailable']){const {a,jobs,advance}=fixture();a.prepare();a.sync('speaking');advance(450);a.sync('ended');a.sync(status);assert.equal(a.audio,null);assert.equal(jobs.size,0);advance(9000);assert.equal(a.audio,null);}
});
test('restart cancels previous tail and cannot silence the new playback',async()=>{
 const {a,media,jobs,advance}=fixture();a.prepare();a.sync('speaking');await Promise.resolve();advance(450);a.sync('ended');const stale=[...jobs.values()][0];
 a.prepare();a.sync('speaking');await Promise.resolve();advance(450);stale();assert.equal(a.audio,media[1]);assert.equal(a.audio.volume,.16);assert.equal(a.audio.paused,false);
});
test('pause uses short fade; only natural completion receives the long ending',()=>{
 const {a,advance}=fixture();a.prepare();a.sync('speaking');advance(450);a.sync('paused');advance(450);assert.equal(a.audio.paused,true);assert.equal(a.ending,false);
});

test('random background uses only approved music and selected theme without consecutive frequency repeats',()=>{
 for(const theme of ['prosperity','wealth','gratitude']){
  let previous=null;
  for(let i=0;i<120;i++){
   const track=pickReflectionTrack(catalog.tracks,theme,previous,()=>((i*37)%120)/120);
   assert.equal(track.theme,theme);assert.ok(catalog.tracks.includes(track));assert.notEqual(track.frequencyHz,previous);previous=track.frequencyHz;
  }
 }
});
test('replay changes frequency while keeping the original catalog and theme',async()=>{
 const {a,advance}=fixture();a.setCatalog(catalog.tracks);a.prepare('wealth');a.sync('speaking');await Promise.resolve();advance(450);const first=a.track;
 a.sync('ended');advance(8000);a.prepare('wealth');a.sync('speaking');await Promise.resolve();advance(450);
 assert.equal(a.track.theme,'wealth');assert.notEqual(a.track.frequencyHz,first.frequencyHz);assert.ok(a.audio);
});
test('empty or invalid music catalog does not generate an unlisted fallback tone',()=>{
 assert.equal(pickReflectionTrack([],'wealth',null),null);
 const {a}=fixture();a.setCatalog([{theme:'wealth',frequencyHz:888,asset:'https://untrusted.invalid/audio.wav'}]);a.prepare('wealth');assert.equal(a.audio,null);
});
