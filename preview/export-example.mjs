import {readFileSync,writeFileSync} from 'node:fs';
import {widgetPayload,exampleTimes} from './model.mjs';
const catalog=JSON.parse(readFileSync(new URL('../assets/content.json',import.meta.url)));
const target=new URL('../ios_integration/widget-config-example.json',import.meta.url);
writeFileSync(target,JSON.stringify(widgetPayload(catalog,exampleTimes),null,2)+'\n');
console.log('Configuração de exemplo gerada. Horários não aprovados; somente demonstração.');
