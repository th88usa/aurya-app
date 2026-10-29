import {mkdirSync,copyFileSync,readdirSync,readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root=fileURLToPath(new URL('../',import.meta.url)),out=path.join(root,'web-deploy');
function copy(relative){const target=path.join(out,relative);mkdirSync(path.dirname(target),{recursive:true});copyFileSync(path.join(root,relative),target);}
for(const name of readdirSync(path.join(root,'preview'))){if(name.endsWith('.test.mjs')||name.endsWith('.test.cjs')||name==='export-example.mjs')continue;if(/\.(html|css|mjs)$/.test(name))copy('preview/'+name);}
copy('assets/content.json');copy('assets/audio_catalog.json');
const catalog=JSON.parse(readFileSync(path.join(root,'assets/audio_catalog.json'),'utf8'));
for(const track of catalog.tracks)copy('assets/'+track.asset);
copy('assets/audio/reflection-piano-original.wav');
console.log(`Prepared static preview and ${catalog.tracks.length} music tracks.`);
