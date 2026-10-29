import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {languages,activateLocale,currentLocale,localePack,messageText,translate} from './i18n.mjs';
import {journeyDays} from './journey-plans.mjs';
import {journeyView} from './journey.mjs';
import {NarrationSession} from './narration-session.mjs';
const catalog=JSON.parse(readFileSync(new URL('../assets/content.json',import.meta.url)));
const packs=Object.fromEntries(languages.filter(l=>l.code!=='pt-BR').map(l=>[l.code,JSON.parse(readFileSync(new URL(`../assets/locales/${l.code}.json`,import.meta.url)))]));
const fetcher=async url=>({ok:true,json:async()=>packs[url.split('/').at(-1).replace('.json','')]});
test('seven locales cover all current messages, five paths and day 100',async()=>{
 for(const [code,pack] of Object.entries(packs)){
  await activateLocale(code,fetcher);assert.equal(currentLocale(),code);assert.equal(Object.keys(pack.messages).length,20);
  for(const m of catalog.messages.filter(m=>m.intention)){const t=messageText(m);assert.equal(t.body,pack.messages[m.id].body);assert.equal(t.reflection.paragraphs.length,3);assert.ok(t.reflection.paragraphs.every(p=>p.trim().length>8));}
  for(const theme of Object.keys(pack.practices)){assert.equal(pack.practices[theme].length,7);const days=journeyDays(theme,pack);assert.equal(days.length,100);assert.equal(days[99].title,pack.ending.title);assert.ok(days.every(d=>d.meaning&&!d.meaning.includes('Reserve um momento')));}
  assert.equal(pack.phases.length,15);assert.notEqual(translate('Aprofundar'),'Aprofundar');
 }
 await activateLocale('pt-BR');assert.equal(localePack(),null);
});
test('translation failure retains the last working locale',async()=>{
 await activateLocale('pt-BR');await assert.rejects(activateLocale('xx',fetcher));assert.equal(currentLocale(),'pt-BR');
});
test('late language response cannot override the latest selection',async()=>{
 // Already cached languages complete immediately; use a fresh module for the deferred fetch.
 const isolated=await import('./i18n.mjs?race-test');let release;
 const pending=isolated.activateLocale('en',()=>new Promise(r=>{release=()=>r({ok:true,json:async()=>packs.en});}));
 await isolated.activateLocale('pt-BR');release();await pending;assert.equal(isolated.currentLocale(),'pt-BR');
});
test('localized journey preserves raw notes and completion without mutating records',()=>{
 const records={1:{done:true,note:'<script>hello</script> Prosperidade'}};const before=JSON.stringify(records);
 const escape=s=>String(s).replaceAll('<','&lt;').replaceAll('>','&gt;');
 for(const pack of Object.values(packs)){const html=journeyView(records,1,escape,'prosperity',pack);assert.ok(html.includes('&lt;script&gt;hello'));assert.ok(html.includes('value="1"'));}assert.equal(JSON.stringify(records),before);
});
test('narration uses only a local voice matching the requested language',async()=>{
 class U{constructor(text){this.text=text;}}
 const synth={getVoices:()=>[{name:'Portuguese',lang:'pt-BR',localService:true},{name:'English',lang:'en-US',localService:true}],cancel(){},speak(u){this.last=u;u.onstart();}};
 const s=new NarrationSession({synth,Utterance:U});await s.play(['Welcome'],{locale:'en-US'});assert.equal(synth.last.lang,'en-US');s.stop();synth.last=null;await s.play(['Bonjour'],{locale:'fr-FR'});assert.equal(s.status,'unavailable');assert.equal(synth.last,null);
});

