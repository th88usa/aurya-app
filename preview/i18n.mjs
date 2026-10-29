export const languages=[
 {code:'pt-BR',label:'Português',voice:'pt-BR'}, {code:'en',label:'English',voice:'en-US'},
 {code:'es',label:'Español',voice:'es-ES'}, {code:'zh-Hans',label:'简体中文',voice:'zh-CN'},
 {code:'ja',label:'日本語',voice:'ja-JP'}, {code:'ru',label:'Русский',voice:'ru-RU'},
 {code:'fr',label:'Français',voice:'fr-FR'}, {code:'it',label:'Italiano',voice:'it-IT'}
];
let active='pt-BR',pack=null,activation=0;
const cache=new Map();
export const currentLocale=()=>active;
export const localePack=()=>pack;
export const voiceLocale=()=>languages.find(l=>l.code===active).voice;
export function validLocale(code){return languages.some(l=>l.code===code);}
export async function activateLocale(code,fetcher=globalThis.fetch){
 const ticket=++activation;
 if(!validLocale(code))throw new Error('Unsupported language');
 let next=null;
 if(code!=='pt-BR'){
  next=cache.get(code);
  if(!next){const response=await fetcher(`../assets/locales/${code}.json`);if(!response.ok)throw new Error('Translation unavailable');next=await response.json();if(next.locale!==code||!next.ui||!next.messages||!next.practices||!next.phases)throw new Error('Invalid translations');cache.set(code,next);}
 }
 if(ticket===activation){active=code;pack=next;}return next;
}
export function translate(source){
 const raw=String(source);if(!pack||!raw.trim())return raw;
 const s=raw.trim();let result=pack.ui[s];
 if(result===undefined){const key=Object.keys(pack.ui).find(k=>k.toLocaleLowerCase()===s.toLocaleLowerCase());if(key)result=pack.ui[key];}
 if(result===undefined&&/^▣\s+SIMULAÇÃO$/.test(s))result='▣ '+pack.ui.SIMULAÇÃO;
 if(result===undefined){
  for(const [pattern,target] of pack.patterns||[]){const match=new RegExp(pattern,'u').exec(s);if(match){result=target.replace(/\$(\d+)/g,(_,i)=>match[Number(i)]??'');break;}}
 }
 if(result===undefined&&s.includes(' · ')){result=s.split(' · ').map(part=>translate(part)).join(' · ');if(result===s)result=undefined;}
 if(result===undefined)return raw;
 return raw.slice(0,raw.indexOf(s))+result+raw.slice(raw.indexOf(s)+s.length);
}
export function messageText(message){
 const source=message.translations['pt-BR'],translated=pack?.messages?.[message.id];
 if(!translated)return source;
 return {...source,...translated,widget:translated.body,reflection:{...source.reflection,title:translated.title,paragraphs:translated.paragraphs,wordCount:translated.paragraphs.join(' ').trim().split(/\s+/u).length,narration:{...source.reflection.narration,locale:voiceLocale()}},editorialOrigin:source.editorialOrigin?{...source.editorialOrigin,source:translate(source.editorialOrigin.source),note:translate(source.editorialOrigin.note)}:undefined};
}
export function localizeDOM(root){
 if(!pack)return;
 const walker=document.createTreeWalker(root,NodeFilter.SHOW_TEXT),nodes=[];
 while(walker.nextNode())nodes.push(walker.currentNode);
 for(const node of nodes){if(node.parentElement?.closest('textarea,input,script,style,[data-user-content]'))continue;const text=translate(node.nodeValue);if(text!==node.nodeValue)node.nodeValue=text;}
 for(const element of root.querySelectorAll('[aria-label],[placeholder]'))for(const attr of ['aria-label','placeholder']){if(element.hasAttribute(attr))element.setAttribute(attr,translate(element.getAttribute(attr)));}
}
