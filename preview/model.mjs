export const momentIds=['wake','commute','midday','sleep'];
export const exampleTimes={wake:'07:00',commute:'08:30',midday:'12:30',sleep:'22:00'};
export function validEmail(v){return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.trim());}
export function minutes(v){if(!/^\d{2}:\d{2}$/.test(v))return NaN;const[h,m]=v.split(':').map(Number);return h<24&&m<60?h*60+m:NaN;}
export function validSchedule(times){const v=momentIds.map(id=>minutes(times[id]));return v.every(Number.isFinite)&&new Set(v).size===4;}
export function occurrences(times,date,days=8){
 if(!validSchedule(times))throw new Error('Defina quatro horários válidos e diferentes.');
 const rows=[];for(let d=-1;d<=days;d++)for(const id of momentIds){const minute=minutes(times[id]);rows.push({id,minute,date:new Date(date.getFullYear(),date.getMonth(),date.getDate()+d,Math.floor(minute/60),minute%60)});}
 return rows.sort((a,b)=>a.date-b.date||a.minute-b.minute);
}
export function activeOccurrence(times,date){return occurrences(times,date,1).filter(o=>o.date<=date).at(-1);}
export function nextOccurrence(times,date){return occurrences(times,date,2).find(o=>o.date>date);}
export function dailyMessage(catalog,moment,date){
 const items=catalog.messages.filter(m=>m.moment===moment);if(!items.length)throw new Error('Sem conteúdo para este momento.');
 const day=Math.floor((Date.UTC(date.getFullYear(),date.getMonth(),date.getDate())-Date.UTC(2026,0,1))/86400000);
 return items[((day%items.length)+items.length)%items.length];
}
export function selection(catalog,times,date){const active=activeOccurrence(times,date);return {...active,message:dailyMessage(catalog,active.id,active.date)};}
export function widgetPayload(catalog,times){
 if(!validSchedule(times))throw new Error('Horários inválidos');
 return {version:2,locale:'pt-BR',demo:true,moments:catalog.moments.map(m=>({id:m.id,label:m.label,minute:minutes(times[m.id]),messages:catalog.messages.filter(x=>x.moment===m.id).map(x=>({id:x.id,text:x.translations['pt-BR'].widget}))}))};
}
