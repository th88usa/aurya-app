export function findMessage(catalog,id){return catalog.messages.find(m=>m.id===id)??null;}
export function parseReflectionLink(value){
 try {
  let id;
  if(value.startsWith('#reflection/'))id=decodeURIComponent(value.slice(12));
  else {const raw=/^aurya:\/\/reflection\/([^/?#]+)$/i.exec(value);if(!raw)return null;id=decodeURIComponent(raw[1]);}
  return /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)?id:null;
 }catch{return null;}
}
export function reflectionChunks(message){
 const t=message.translations['pt-BR'];return [t.body,...t.reflection.paragraphs];
}
