import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {intentions,intentionMessage} from './intentions.mjs';
import {journeyDays} from './journey-plans.mjs';
import {journeyView,readJourney} from './journey.mjs';
const catalog=JSON.parse(readFileSync(new URL('../assets/content.json',import.meta.url)));
const moments=['wake','commute','midday','sleep'];
test('cada intenção resolve quatro mensagens distintas nos momentos corretos',()=>{
 const selected=new Set();
 for(const intention of intentions)for(const moment of moments){const m=intentionMessage(catalog,intention.id,moment);assert.ok(m);assert.equal(m.moment,moment);assert.equal(m.intention,intention.id);assert.equal(m.translations['pt-BR'].editorialOrigin.kind,'original-aurya');selected.add(m.id);}
 assert.equal(selected.size,20);assert.equal(intentionMessage(catalog,'unknown','wake'),null);assert.equal(intentionMessage(catalog,'wealth','unknown'),null);
});
test('cada tema tem cem dias acessíveis e encerramento completo',()=>{
 for(const intention of intentions){const days=journeyDays(intention.id);assert.equal(days.length,100);assert.deepEqual(days.map(d=>d.day),Array.from({length:100},(_,i)=>i+1));assert.equal(new Set(days.map(d=>d.meaning)).size,100);assert.match(days[99].title,/renove sua intenção/);for(const d of days)for(const field of ['title','action','meaning','prompt','phase'])assert.ok(d[field].trim());}
});
test('renderização do dia cem permite navegar no último bloco',()=>{
 const html=journeyView({},100,String,'visualization');assert.match(html,/Dia 100/);assert.match(html,/Dias 99–100/);assert.doesNotMatch(html,/data-day="101"/);assert.match(html,/0 de 100 atividades concluídas/);
});
test('o progresso recebido não conta dias fora do calendário',()=>{
 const html=journeyView({1:{done:true},100:{done:true},101:{done:true}},1,String,'wealth');assert.match(html,/2 de 100 atividades concluídas/);
});
test('armazenamento indisponível ou inválido permite começar sem registros',()=>{
 for(const getItem of [()=>{throw new Error();},()=>'{',()=>'[]',()=>'null'])assert.deepEqual(readJourney({getItem}),{});
});
test('anotações são escapadas antes de entrar no formulário',()=>{
 const escape=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
 const html=journeyView({1:{note:'</textarea><script>alert(1)</script>'}},1,escape,'gratitude');assert.ok(html.includes('&lt;/textarea&gt;'));assert.ok(!html.includes('<script>'));
});
