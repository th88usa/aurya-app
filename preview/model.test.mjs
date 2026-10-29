import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {momentIds,exampleTimes,validEmail,minutes,validSchedule,activeOccurrence,nextOccurrence,occurrences,dailyMessage,selection,widgetPayload} from './model.mjs';
const c=JSON.parse(readFileSync(new URL('../assets/content.json',import.meta.url)));
test('cadastro demo valida e-mail',()=>{assert.ok(validEmail('teste@example.com'));for(const v of ['','x','a@b','a b@c.com'])assert.equal(validEmail(v),false);});
test('quatro horários válidos e únicos; 00:00 aceito',()=>{
 assert.ok(validSchedule(exampleTimes));assert.ok(validSchedule({...exampleTimes,wake:'00:00'}));
 for(const t of [{...exampleTimes,commute:'07:00'},{...exampleTimes,sleep:'24:00'},{...exampleTimes,wake:''},{...exampleTimes,midday:'12:60'}])assert.equal(validSchedule(t),false);
 assert.equal(minutes('23:59'),1439);
});
test('fronteiras exatas dos quatro momentos',()=>{
 for(const [h,m,id] of [[6,59,'sleep'],[7,0,'wake'],[8,29,'wake'],[8,30,'commute'],[12,29,'commute'],[12,30,'midday'],[21,59,'midday'],[22,0,'sleep']])assert.equal(activeOccurrence(exampleTimes,new Date(2026,9,23,h,m)).id,id);
});
test('mesma mensagem até próxima troca, inclusive após meia-noite',()=>{
 const before=selection(c,exampleTimes,new Date(2026,9,23,23,59));
 const after=selection(c,exampleTimes,new Date(2026,9,24,0,0));
 const dawn=selection(c,exampleTimes,new Date(2026,9,24,6,59));
 assert.equal(before.message.id,after.message.id);assert.equal(before.message.id,dawn.message.id);
 assert.equal(after.date.getDate(),23);assert.equal(after.id,'sleep');
});
test('rotina noturna usa ordem cronológica sem impor ordem das categorias',()=>{
 const t={wake:'20:00',commute:'22:00',midday:'02:00',sleep:'08:00'};
 assert.ok(validSchedule(t));assert.equal(activeOccurrence(t,new Date(2026,9,23,3)).id,'midday');assert.equal(nextOccurrence(t,new Date(2026,9,23,23)).id,'midday');
});
test('timeline tem somente as quatro fronteiras, sem entrada extra à meia-noite',()=>{
 const now=new Date(2026,9,23,13),rows=occurrences(exampleTimes,now,8).filter(o=>o.date>now);
 assert.equal(rows.filter(o=>o.date.getDate()===24).length,4);
 assert.ok(rows.every(o=>o.date.getMinutes()!==0||[7,22].includes(o.date.getHours())));
 assert.ok(rows.length>=32);for(let i=1;i<rows.length;i++)assert.ok(rows[i].date>=rows[i-1].date);
});
test('catálogo válido com traduções identificadas e mensagens de bloqueio',()=>{
 assert.equal(c.version,2);assert.deepEqual(c.moments.map(m=>m.id),momentIds);assert.equal(c.locales.length,8);assert.equal(c.locales.filter(l=>l.available).length,1);
 assert.equal(new Set(c.messages.map(m=>m.id)).size,c.messages.length);
 for(const id of momentIds)assert.ok(c.messages.some(m=>m.moment===id));
 for(const m of c.messages){assert.deepEqual(Object.keys(m.translations),['pt-BR']);const t=m.translations['pt-BR'];assert.ok(t.widget.trim());assert.ok(t.widget.length<=120);assert.equal(t.body,t.widget);if(m.intention){assert.equal(t.editorialOrigin.kind,'original-aurya');assert.equal(t.citation,undefined);}else assert.equal(t.citation.kind,'video-exact-transcript');}
});

test('mensagem diária determinística por ocorrência e não por hora de consulta',()=>{
 for(const id of momentIds){const a=dailyMessage(c,id,new Date(2026,9,23,0)),b=dailyMessage(c,id,new Date(2026,9,23,23)),next=dailyMessage(c,id,new Date(2026,9,24));assert.equal(a.id,b.id);assert.notEqual(a.id,next.id);}
 assert.throws(()=>dailyMessage({messages:[]},'wake',new Date()),/Sem conteúdo/);
});
test('catálogo de 44 pares e fixture nativa sincronizada',()=>{
 assert.equal(c.messages.length,44);
 for(const id of momentIds)assert.equal(c.messages.filter(m=>m.moment===id).length,11);
 const fixture=JSON.parse(readFileSync(new URL('../ios_integration/widget-config-example.json',import.meta.url)));
 assert.deepEqual(fixture,widgetPayload(c,exampleTimes));
});

test('payload nativo só contém catálogo compacto e horários, sem dados de cadastro',()=>{
 const p=widgetPayload(c,exampleTimes);assert.equal(p.version,2);assert.equal(p.demo,true);assert.deepEqual(p.moments.map(m=>m.minute),[420,510,750,1320]);
 assert.deepEqual(Object.keys(p).sort(),['demo','locale','moments','version']);for(const m of p.moments){assert.deepEqual(Object.keys(m).sort(),['id','label','messages','minute']);for(const x of m.messages)assert.deepEqual(Object.keys(x).sort(),['id','text']);}
});
test('DST: dias civis mantêm mensagem e hora local sem somar 86400s',()=>{
 for(const [month,day] of [[2,8],[10,1]]){const now=new Date(2026,month,day,0);const rows=occurrences(exampleTimes,now,2);assert.equal(rows.filter(o=>o.date.getDate()===day).length,4);assert.equal(rows.find(o=>o.id==='wake'&&o.date.getDate()===day).date.getHours(),7);}
 const custom={wake:'02:30',commute:'08:00',midday:'12:00',sleep:'22:00'};
 if(Intl.DateTimeFormat().resolvedOptions().timeZone==='America/Los_Angeles'){
  const spring=occurrences(custom,new Date(2026,2,8,0),1).find(o=>o.id==='wake'&&o.date.getDate()===8);assert.equal(spring.date.getHours(),3);assert.equal(spring.date.getMinutes(),30);
  const repeated={...custom,wake:'01:30'};const fall=occurrences(repeated,new Date(2026,10,1,0),1).find(o=>o.id==='wake'&&o.date.getDate()===1);assert.equal(fall.date.getTimezoneOffset(),420);
 }
});
