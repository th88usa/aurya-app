import test from 'node:test';import assert from 'node:assert/strict';import {readFileSync} from 'node:fs';
import {findMessage,parseReflectionLink,reflectionChunks} from './reflections.mjs';
import {widgetPayload,exampleTimes} from './model.mjs';
const c=JSON.parse(readFileSync(new URL('../assets/content.json',import.meta.url)));
test('aprofundamentos completos, identificados e com contagem correta',()=>{
 assert.equal(c.reflectionConfig.access,'undecided');assert.equal(c.reflectionConfig.optional,true);
 const all=[];for(const m of c.messages){const t=m.translations['pt-BR'],r=t.reflection,words=r.paragraphs.join(' ').trim().split(/\s+/).length;
  assert.equal(r.messageId,m.id);assert.ok(words>=(m.intention?80:150)&&words<=250);assert.equal(r.wordCount,words);assert.equal(r.origin,'original-aurya');assert.equal(r.paragraphs.length,3);assert.ok(r.title);assert.equal(r.narration.kind,'device_tts');assert.equal(r.narration.autoplay,false);all.push(r.paragraphs.join('\n'));
 }assert.equal(new Set(all).size,c.messages.length);
});
test('links aceitam apenas IDs simples e esquema/caminho de reflexão',()=>{
 const id=c.messages[0].id;assert.equal(parseReflectionLink('#reflection/'+id),id);assert.equal(parseReflectionLink('aurya://reflection/'+id),id);
 for(const link of ['https://other/reflection/'+id,'aurya://other/'+id,'aurya://reflection/../secret','#reflection/%2Fbad','#reflection/%ZZ','aurya://reflection/'+id+'?autoplay=1','aurya://reflection/'+id+'#x'])assert.equal(parseReflectionLink(link),null);
});
test('link desconhecido não retorna conteúdo arbitrário e todos os IDs resolvem',()=>{
 assert.equal(findMessage(c,'unknown'),null);for(const m of c.messages)assert.equal(findMessage(c,parseReflectionLink('aurya://reflection/'+m.id)),m);
});
test('leitura recebe só a afirmação e seu aprofundamento; widget recebe somente frase curta',()=>{
 for(const m of c.messages){const chunks=reflectionChunks(m);assert.equal(chunks[0],m.translations['pt-BR'].body);assert.deepEqual(chunks.slice(1),m.translations['pt-BR'].reflection.paragraphs);}
 const payload=widgetPayload(c,exampleTimes);assert.equal(JSON.stringify(payload).includes('paragraphs'),false);
 for(const group of payload.moments)for(const m of group.messages)assert.ok(m.text.length<=120);
});
