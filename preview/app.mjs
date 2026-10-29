import {intentions,intentionMessage} from './intentions.mjs';
import {readJourney,journeyView} from './journey.mjs';

import {validEmail,validSchedule,exampleTimes,selection,nextOccurrence,occurrences,dailyMessage,widgetPayload} from './model.mjs';
import {AudioSession} from './audio-session.mjs';
import {findMessage,parseReflectionLink,reflectionChunks} from './reflections.mjs';
import {NarrationSession} from './narration-session.mjs?revision=voz-grave-3';
import {ReflectionAmbience} from './ambience.mjs?revision=trilhas-variadas-1';
const ambience=new ReflectionAmbience({notify:()=>paintNarration()});
const app=document.querySelector('#app'),nav=document.querySelector('#nav');
let catalog,boundaryTimer,audioCatalog,audioPromise,audioError=false;
let audioTheme='prosperity';
const sound=new AudioSession({notify:paintAudio});
const narration=new NarrationSession({notify:paintNarration});
let reflectionId=null,pendingReflection=null,routeError=false;
const defaults=()=>({step:0,tab:'home',name:'',email:'visitante@example.com',locale:'pt-BR',times:{...exampleTimes},preview:null,reviewMessage:null,showContent:true});
let state=defaults();
let chosenIntention='prosperity';try{const saved=localStorage.getItem('aurya-intention');if(intentions.some(x=>x.id===saved))chosenIntention=saved;}catch{}
let journeyDay=1;
let journeyRecords={};try{journeyRecords=readJourney(localStorage);}catch{}
function currentJourney(){if(!journeyRecords[chosenIntention]||typeof journeyRecords[chosenIntention]!=='object')journeyRecords[chosenIntention]={};return journeyRecords[chosenIntention];}
function saveJourney(){try{localStorage.setItem('aurya-journey-v1',JSON.stringify(journeyRecords));return true;}catch{return false;}}
if(new URLSearchParams(location.search).get('view')==='intentions'){state.step=3;state.tab='home';}
if(new URLSearchParams(location.search).get('view')==='tasks'){state.step=3;state.tab='tasks';}
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const title=(tag,heading,body)=>`<div class="eyebrow">${tag}</div><h1>${heading}</h1><p class="intro">${body}</p>`;
const button=(label,action,cls='primary')=>`<button class="${cls}" data-action="${action}">${label}</button>`;
function timeFields(){return `<p class="note callout">Os valores abaixo são exemplos editáveis, não horários escolhidos por você. Defina os quatro momentos; a mensagem fica até a próxima troca.</p>${catalog.moments.map(m=>`<div class="time-row"><label for="${m.id}">${m.label}</label><input id="${m.id}" type="time" value="${state.times[m.id]}" required></div>`).join('')}<p class="note">Horário local: ${esc(Intl.DateTimeFormat().resolvedOptions().timeZone)}. Horários diferentes; a ordem de troca segue o relógio, inclusive em rotinas noturnas.</p><p id="scheduleError" class="error" role="alert"></p>`;}
function localeFields(){return `<label for="locale">Idioma preferido</label><select id="locale">${catalog.locales.map(l=>`<option value="${l.code}" ${state.locale===l.code?'selected':''}>${l.label}${l.available?'':' • em preparação'}</option>`).join('')}</select><p class="note" id="fallback">${state.locale==='pt-BR'?'Amostras originais em português. Os outros sete idiomas estão previstos.':'Preferência registrada nesta sessão. Tradução em preparação; interface e mensagens continuam em português.'}</p>`;}
function signup(){return `${title('Um espaço para você','Comece por dentro.','Quatro momentos do seu dia. Uma mensagem para ler na tela de bloqueio do iPhone.')}<div class="orb" aria-hidden="true"></div><h2>Cadastro de demonstração</h2><form id="signup"><label for="name">Como podemos chamar você? (opcional)</label><input id="name" maxlength="60" autocomplete="off" value="${esc(state.name)}"><label for="email">E-mail fictício de teste</label><input id="email" type="email" required autocomplete="off" value="${esc(state.email)}"><p class="note callout">Use dados fictícios. O cadastro é obrigatório para entrar nesta demonstração. Não cria conta real, não envia e-mail e não solicita senha. Os dados desaparecem ao recarregar.</p><p id="emailError" class="error" role="alert"></p><button class="primary" type="submit">Criar cadastro de demonstração &nbsp; →</button></form>`;}
function premium(){return `${title('Futuro Premium','Seu ritual.<br>Sua própria voz.','Um espaço para escutar as palavras que você escolheu, do seu jeito.')}<div class="feature">Gravar e reproduzir sua voz<span>Integração futura. Microfone não utilizado.</span></div><div class="feature">Experiência sem anúncios<span>Benefício previsto para o Premium.</span></div><p class="note callout">Premium indisponível nesta versão. Preços, compras e restauração ainda não configurados. Não há cobranças nem ativação de benefícios.</p>`;}

function intentionPanel(){const choice=intentions.find(x=>x.id===chosenIntention);return `<section class="callout" aria-label="Sua intenção"><div class="eyebrow">Seu caminho de hoje</div><label for="intention-choice">O que você quer cultivar neste momento?</label><select id="intention-choice">${intentions.map(x=>`<option value="${x.id}" ${chosenIntention===x.id?'selected':''}>${x.label}</option>`).join('')}</select><p>${esc(choice.description)}</p><p class="note">Ao acordar, acolha a intenção. No caminho, fortaleça sua postura. Ao meio-dia, reconheça o que está cultivando. À noite, reflita e descanse.</p><button data-tab="tasks" class="small-action">Explorar tarefas diárias →</button></section>`;}
function home(){
 const date=new Date(),active=selection(catalog,state.times,date);
 const selected=state.preview?{id:state.preview,date:new Date(date.getFullYear(),date.getMonth(),date.getDate()),message:dailyMessage(catalog,state.preview,date)}:active;
 const demoMessage=new URLSearchParams(location.search).get('example');
 if(demoMessage!=='auto'){
  selected.id=state.preview||'wake';
  const examples={wake:'wake-atencao-01',commute:'commute-confianca-01',midday:'midday-foco-01',sleep:'sleep-descanso-01'};
  selected.message=catalog.messages.find(m=>m.id===examples[selected.id]);
 }
 selected.message=intentionMessage(catalog,chosenIntention,selected.id)||selected.message;
 const reviewed=catalog.messages.find(m=>m.id===state.reviewMessage&&m.moment===selected.id);
 if(reviewed)selected.message=reviewed;
 const moment=catalog.moments.find(m=>m.id===selected.id),text=selected.message.translations['pt-BR'];
 const next=nextOccurrence(state.times,date);
 return `${intentionPanel()}${title('Feito para a tela de bloqueio','Uma frase.<br>O seu momento.','Configure no app. A proposta é ler no widget do iPhone, sem precisar abrir o AURYA.')}<p class="note callout"><strong>SIMULAÇÃO DE TELA DE BLOQUEIO</strong><br>Não é um widget instalado. Tamanho, fonte e aparência reais dependem do iPhone e do iOS.</p><div class="segments moments" aria-label="Simular um momento">${catalog.moments.map(m=>`<button data-moment="${m.id}" aria-pressed="${m.id===selected.id}">${m.label}</button>`).join('')}</div>${state.preview?button('Simulação manual • voltar ao relógio local','auto','small-action'):'<p class="note">Simulação pelo relógio local • sem rotação contínua</p>'}<div class="lock-screen" aria-label="Simulação de tela de bloqueio do iPhone"><div class="lock-label">▣ &nbsp; SIMULAÇÃO</div><div class="lock-time">${state.times[selected.id]}</div><div class="accessory" aria-label="Simulação de widget retangular"><div class="widget-title">AURYA · ${esc(moment.label)}</div><div class="widget-copy">${state.showContent?esc(text.widget):'Conteúdo oculto pela opção de privacidade.'}</div></div><div class="lock-caption">Prévia ilustrativa · accessoryRectangular</div></div><div class="switch-row"><input id="showContent" type="checkbox" ${state.showContent?'checked':''}><label for="showContent">Mostrar frase nesta simulação de bloqueio</label></div><p class="note">A frase é curta para caber no widget. O texto completo fica abaixo para revisão. O iOS pode ocultar conteúdo por privacidade ou cortar texto; não há garantia de troca no minuto exato.</p><label for="message-choice">Mensagem deste momento · intenção escolhida</label><select id="message-choice">${catalog.messages.filter(m=>m.moment===selected.id&&m.intention===chosenIntention).map((m,i)=>`<option value="${m.id}" ${m.id===selected.message.id?'selected':''}>${i+1}. ${esc(m.translations['pt-BR'].body)}</option>`).join('')}</select><article class="message ${selected.id}"><div class="eyebrow">${esc(moment.label)} · ${esc(selected.message.theme)}</div><h2>${esc(text.title)}</h2><p class="quote">${esc(text.body)}</p>${text.citation?`<div class="source">${text.citation.kind==='video-exact-transcript'?'FRASE DO VÍDEO · NARRADOR':'NAPOLEON HILL · TRADUÇÃO DO ORIGINAL'}</div><details><summary>Origem da citação</summary><p>${esc(text.citation.original)}</p><p>${esc(text.citation.source)}</p><p>${esc(text.citation.translation)}</p><a href="${esc(text.citation.url)}" target="_blank" rel="noopener">Consultar fonte</a></details><button class="primary" data-reflection="${selected.message.id}">Aprofundar</button>`:`<div class="source">TEXTO ORIGINAL AURYA • PORTUGUÊS</div><button class="primary" data-reflection="${selected.message.id}">Aprofundar</button>`}</article><div class="rhythm">${catalog.moments.map(m=>`<span>${m.label}: ${state.times[m.id]}</span>`).join('')}</div><p class="note">${state.preview?'A seleção manual acima não altera seus horários.':`Próxima troca prevista nesta simulação: ${esc(catalog.moments.find(m=>m.id===next.id).label)} às ${state.times[next.id]}.`}<br>A mensagem não muda à meia-noite; permanece até o próximo momento.${state.locale!=='pt-BR'?'<br>Tradução em preparação. Amostra em português.':''}</p>${button('Baixar configuração de exemplo do widget','export','small-action')}<p class="note">Exportação JSON para revisão técnica; não instala nada no iPhone. Não inclui nome ou e-mail.</p><div class="ad">FREE · ESPAÇO FUTURO DE ANÚNCIO SOMENTE NO APP<br>Nenhum anúncio na tela de bloqueio</div>`;
}

function paintAudio(){
 const status=document.querySelector('#audio-status');if(!status)return;
 if(status.textContent!==sound.message)status.textContent=sound.message;
 const playing=sound.status==='playing',loading=sound.status==='loading';
 const play=document.querySelector('#audio-play');play.textContent=playing?'Pausar':sound.status==='paused'?'Continuar':'Reproduzir';play.disabled=loading||!sound.track;
 document.querySelector('#audio-stop').disabled=!sound.track;
 const total=Math.ceil(sound.remainingMs/1000);document.querySelector('#audio-remaining').textContent=`${Math.floor(total/60).toString().padStart(2,'0')}:${(total%60).toString().padStart(2,'0')}`;
 document.querySelector('#volume-label').textContent=`Volume · ${Math.round(sound.volume*100)}%`;
}
function audioView(){
 if(!audioCatalog)return `${title('Áudios','Um som para sua intenção.','Prosperidade, riqueza e gratidão. Você escolhe quando ouvir.')}<p role="status">${audioError?'Não foi possível carregar as amostras.':'Preparando as amostras…'}</p>${audioError?button('Tentar carregar áudios','retryAudio'):''}`;
 if(!sound.track)sound.select(audioCatalog.tracks.find(t=>t.theme===audioTheme));
 const themeTracks=audioCatalog.tracks.filter(t=>t.theme===audioTheme);
 const frequencies=[...new Set(themeTracks.map(t=>t.frequencyHz))];
 const tracks=themeTracks.filter(t=>t.frequencyHz===sound.track.frequencyHz);
 return `${title('Áudios','Ouça no seu ritmo.','Prosperidade, riqueza e gratidão como temas de intenção.')}<div class="segments audio-themes" aria-label="Tema dos áudios">${audioCatalog.themes.map(t=>`<button data-audio-theme="${t.id}" aria-pressed="${audioTheme===t.id}">${t.label}</button>`).join('')}</div><section class="audio-panel" aria-label="Player de amostras sonoras"><div class="eyebrow">ACESSO FREE / PREMIUM A DEFINIR</div><label for="audio-frequency">Frequência de referência</label><select id="audio-frequency">${frequencies.map(hz=>`<option value="${hz}" ${sound.track.frequencyHz===hz?'selected':''}>${hz} Hz</option>`).join('')}</select><label for="audio-track">Escolha a melodia</label><select id="audio-track">${tracks.map(t=>`<option value="${t.id}" ${sound.track.id===t.id?'selected':''}>${esc(t.composition||t.title)}</option>`).join('')}</select><p class="note">Música suave original · piano, melodia e acordes.<br>As frequências indicam a afinação de referência. A música contém várias notas.</p><div class="audio-countdown"><span id="audio-remaining" aria-live="off">05:00</span><span>tempo restante de reprodução</span></div><div class="audio-buttons"><button class="primary" id="audio-play" data-action="audioPlay">Reproduzir</button><button id="audio-stop" data-action="audioStop">Encerrar</button></div><p class="note" id="audio-status" role="status"></p><label id="volume-label" for="audio-volume">Volume · 15%</label><input id="audio-volume" class="audio-volume" type="range" min="0" max="100" value="${Math.round(sound.volume*100)}" step="1"><label for="audio-timer">Encerrar após</label><select id="audio-timer">${audioCatalog.timerMinutes.map(m=>`<option value="${m}" ${sound.durationMs===m*60000?'selected':''}>${m} ${m===1?'minuto':'minutos'}</option>`).join('')}</select></section><p class="note">Comece com volume confortável. Sem início automático. Ao sair desta área ou ocultar a prévia, a reprodução pausa.</p><p class="note">Escolha o tema da sua intenção e ouça no seu ritmo. O acesso Free/Premium será decidido depois.</p>`;
}
async function loadAudio(){
 if(audioPromise)return audioPromise;
 audioError=false;audioPromise=(async()=>{try{const r=await fetch('../assets/audio_catalog.json?revision=melodias-3',{cache:'no-store'});if(!r.ok)throw new Error();const data=await r.json();if(!data.tracks?.length||data.access!=='undecided')throw new Error();audioCatalog=data;ambience.setCatalog(data.tracks);}catch{audioError=true;}finally{audioPromise=null;if(state.tab==='audio'&&state.step>=3)render();}})();return audioPromise;
}

function paintNarration(){
 ambience.sync(narration.status);
 const status=document.querySelector('#narration-status');if(!status)return;
 if(!document.querySelector('#reflection-music')){
  const label=document.createElement('label');label.className='note';
  const toggle=document.createElement('input');toggle.type='checkbox';toggle.id='reflection-music';toggle.checked=ambience.enabled;
  toggle.addEventListener('change',()=>{ambience.enabled=toggle.checked;if(!toggle.checked)ambience.stop();else if(narration.status==='speaking'){ambience.prepare(findMessage(catalog,reflectionId)?.ambienceTheme);ambience.sync(narration.status);}});
  label.append(toggle,document.createTextNode(' Fundo musical suave'));status.after(label);
 }
 const message=ambience.ending?'Leitura concluída. Música encerrando suavemente…':narration.message;
 if(status.textContent!==message)status.textContent=message;
 let musicInfo=document.querySelector('#reflection-track');
 if(!musicInfo){musicInfo=document.createElement('p');musicInfo.id='reflection-track';musicInfo.className='note';status.after(musicInfo);}
 const chosen=ambience.track;
 musicInfo.textContent=chosen?`Trilha: ${chosen.composition||chosen.title} · ${chosen.frequencyHz} Hz · ${audioCatalog?.themes.find(t=>t.id===chosen.theme)?.label||''}`:ambience.enabled&&!audioCatalog?'Fundo musical indisponível; a leitura continua disponível.':'';
 const preparing=narration.status==='preparing';
 const play=document.querySelector('#reflection-listen');play.disabled=preparing||narration.status==='speaking';play.textContent=narration.status==='paused'?'Continuar':preparing?'Preparando…':'Ouvir';
 document.querySelector('#reflection-pause').disabled=narration.status!=='speaking';
 document.querySelector('#reflection-stop').disabled=!ambience.ending&&!['speaking','paused','preparing'].includes(narration.status);
}
function reflectionView(){
 const m=findMessage(catalog,reflectionId);if(!m)return `<p role="alert">Esta reflexão não está disponível.</p>${button('Voltar','closeReflection')}`;
 const t=m.translations['pt-BR'],r=t.reflection;
 return `${button('← Voltar à afirmação','closeReflection','small-action')}${title('Aprofundar · leitura opcional',esc(r.title),esc(t.body))}<section class="narration-panel" aria-label="Leitura automática da reflexão"><span class="eyebrow">LEITURA AUTOMÁTICA · PORTUGUÊS</span><div class="narration-actions"><button id="reflection-listen" class="primary" data-action="listenReflection">Ouvir</button><button id="reflection-pause" data-action="pauseReflection">Pausar</button><button id="reflection-stop" data-action="stopReflection">Parar</button></div><p id="narration-status" role="status" class="note">Leitura pela voz local do dispositivo. Sem início automático.</p></section>${t.editorialOrigin?`<details class="note"><summary>Origem da inspiração</summary><p>${esc(t.editorialOrigin.source)}</p><p>${esc(t.editorialOrigin.note)}</p><a href="${esc(t.editorialOrigin.url)}" target="_blank" rel="noopener">Consultar perfil de referência</a></details>`:''}${t.citation?`<p class="note"><strong>${t.citation.kind==='video-exact-transcript'?'Reflexão AURYA · inspiração com origem identificada.':'Citação: Napoleon Hill · tradução do original.'}</strong><br>Texto original AURYA para acompanhar sua reflexão.</p><details class="note"><summary>Origem da inspiração</summary><p>${esc(t.citation.source)}</p><p>${esc(t.citation.translation)}</p><a href="${esc(t.citation.url)}" target="_blank" rel="noopener">Consultar fonte</a></details>`:""}<article class="reflection-text" data-message-id="${m.id}">${r.paragraphs.map(text=>`<p>${esc(text)}</p>`).join('')}</article><p class="note">Texto original AURYA · ${r.wordCount} palavras. Acesso Free/Premium a definir.</p>${button('Voltar à afirmação','closeReflection','back')}`;
}
function openReflection(id,{push=true}={}){
 if(!findMessage(catalog,id)?.translations['pt-BR'].reflection){routeError=true;render();return;}
 if(state.step<3){pendingReflection=id;render();return;}
 narration.stop(false);narration.message='Leitura automática pela voz local do dispositivo. Sem início automático.';sound.pause('Áudio de tons pausado para a reflexão.');reflectionId=id;pendingReflection=null;routeError=false;
 if(push)history.pushState(null,'',`#reflection/${encodeURIComponent(id)}`);render(true);
}
function closeReflection(){narration.stop(false);reflectionId=null;pendingReflection=null;routeError=false;state.tab='home';history.replaceState(null,'',location.pathname+location.search);render(true);}
function readRoute(){
 const id=parseReflectionLink(location.hash);
 if(id){if(findMessage(catalog,id))openReflection(id,{push:false});else{narration.stop(false);reflectionId=null;pendingReflection=null;routeError=true;render();}}
 else if(location.hash){narration.stop(false);reflectionId=null;pendingReflection=null;routeError=true;render();}
 else {narration.stop(false);reflectionId=null;pendingReflection=null;routeError=false;render();}
}
window.addEventListener('hashchange',()=>{if(catalog)readRoute();});
window.addEventListener('popstate',()=>{if(catalog)readRoute();});
function settings(){return `${title('Seus quatro momentos','Ajuste uma vez.<br>Leia no seu dia.','Os horários controlam as transições da mensagem. Não são alarmes nem notificações.')}<form id="settings">${localeFields()}${timeFields()}<button class="primary" type="submit">Guardar nesta sessão</button><p id="saved" role="status" class="note"></p></form><p class="note callout">WidgetKit e App Group têm código nativo preparado, mas ainda não compilado ou instalado. Auth, backend, anúncios, compras e voz continuam como integrações futuras.</p>${button('Sair da demonstração','logout','back')}${button('Apagar dados da demonstração','delete','back')}`;}
function readTimes(){return Object.fromEntries(catalog.moments.map(m=>[m.id,document.getElementById(m.id).value]));}
function saveTimes(){const times=readTimes();const ok=validSchedule(times);document.querySelector('#scheduleError').textContent=ok?'':'Defina quatro horários válidos e diferentes.';if(ok)state.times=times;return ok;}
function armBoundary(){
 clearTimeout(boundaryTimer);
 if(!catalog||state.step<3||reflectionId||state.preview||state.tab!=='home')return;
 const next=nextOccurrence(state.times,new Date()).date;
 boundaryTimer=setTimeout(()=>render(),Math.max(1,next-Date.now()+100));
}
function render(focus=false){
 nav.hidden=state.step<3;
 if(state.step>=3&&pendingReflection){reflectionId=pendingReflection;pendingReflection=null;}
 if(state.step===0)app.innerHTML=signup();
 else if(state.step===1)app.innerHTML=`${title('01 / Seu idioma','Palavras que acolhem.','Escolha o idioma que deseja usar na versão completa.')}${localeFields()}${button('Continuar →','language')}${button('Voltar','backSignup','back')}`;
 else if(state.step===2)app.innerHTML=`${title('02 / Seus momentos','Quatro momentos.<br>Um ritmo seu.','Ao acordar, indo para o trabalho, meio do dia e antes de dormir.')}<form id="schedule">${timeFields()}<button class="primary" type="submit">Revisar tela de bloqueio →</button></form>${button('Voltar','backLanguage','back')}`;
 else app.innerHTML=reflectionId?reflectionView():state.tab==='home'?home():state.tab==='audio'?audioView():state.tab==='tasks'?`${intentionPanel()}${journeyView(currentJourney(),journeyDay,esc,chosenIntention)}`:state.tab==='premium'?premium():settings();
 nav.innerHTML=[['home','▣','Bloqueio'],['audio','♫','Áudios'],['tasks','✓','Tarefas'],['settings','☷','Horários'],['premium','✧','Premium']].map(([id,icon,label])=>`<button data-tab="${id}" ${state.tab===id?'aria-current="page"':''}>${icon}<br>${label}</button>`).join('');
 document.querySelector('#signup')?.addEventListener('submit',e=>{e.preventDefault();const email=document.querySelector('#email').value.trim();if(!validEmail(email)){document.querySelector('#emailError').textContent='Informe um e-mail fictício válido.';return;}state.email=email;state.name=document.querySelector('#name').value.trim();state.step=1;render(true);});
 document.querySelector('#locale')?.addEventListener('change',e=>{state.locale=e.target.value;document.querySelector('#fallback').textContent=state.locale==='pt-BR'?'Amostras originais em português. Os outros sete idiomas estão previstos.':'Preferência registrada nesta sessão. Tradução em preparação; interface e mensagens continuam em português.';});
 for(const input of document.querySelectorAll('input[type=time]'))input.addEventListener('input',()=>{const error=document.querySelector('#scheduleError');if(error?.textContent&&validSchedule(readTimes()))error.textContent='';});
 document.querySelector('#schedule')?.addEventListener('submit',e=>{e.preventDefault();if(!saveTimes())return;state.step=3;render(true);});
 document.querySelector('#settings')?.addEventListener('submit',e=>{e.preventDefault();if(!saveTimes())return;document.querySelector('#saved').textContent='Quatro horários guardados nesta sessão. Widget real ainda não instalado.';});
 document.querySelector('#intention-choice')?.addEventListener('change',e=>{chosenIntention=e.target.value;state.reviewMessage=null;try{localStorage.setItem('aurya-intention',chosenIntention);}catch{}render();});
 document.querySelector('#journey-week')?.addEventListener('change',e=>{journeyDay=Number(e.target.value);render();});
 document.querySelector('#journey-note')?.addEventListener('input',e=>{currentJourney()[journeyDay]={...currentJourney()[journeyDay],note:e.target.value};document.querySelector('#journey-status').textContent=saveJourney()?'Registro salvo neste navegador.':'Registro mantido apenas nesta sessão; o navegador não permitiu salvar.';});
 document.querySelector('#showContent')?.addEventListener('change',e=>{state.showContent=e.target.checked;render();});
 document.querySelector('#message-choice')?.addEventListener('change',e=>{state.reviewMessage=e.target.value;render();});
 document.querySelector('#audio-frequency')?.addEventListener('change',e=>{sound.select(audioCatalog.tracks.find(t=>t.theme===audioTheme&&t.frequencyHz===Number(e.target.value)));render();});
 document.querySelector('#audio-track')?.addEventListener('change',e=>{sound.select(audioCatalog.tracks.find(t=>t.id===e.target.value));paintAudio();});
 document.querySelector('#audio-volume')?.addEventListener('input',e=>sound.setVolume(Number(e.target.value)/100));
 document.querySelector('#audio-timer')?.addEventListener('change',e=>sound.setTimer(Number(e.target.value)));
 if(routeError)app.insertAdjacentHTML('afterbegin','<p class="note callout" role="alert">Esta reflexão não está disponível. Você pode continuar usando o AURYA.</p>');
 paintAudio();paintNarration();armBoundary();if(focus){app.focus();window.scrollTo(0,0);}
}
document.addEventListener('click',e=>{
 const b=e.target.closest('button');if(!b)return;const a=b.dataset.action;if(a==='retry'){load();return;}if(!catalog)return;
 if(b.dataset.day){journeyDay=Number(b.dataset.day);render();return;}
 if(a==='journeyAdapt'){currentJourney()[journeyDay]={...currentJourney()[journeyDay],adapted:!currentJourney()[journeyDay]?.adapted};saveJourney();render();return;}
 if(a==='journeyDone'){currentJourney()[journeyDay]={...currentJourney()[journeyDay],done:!currentJourney()[journeyDay]?.done};const saved=saveJourney();render();if(!saved)document.querySelector('#journey-status').textContent='Progresso mantido apenas nesta sessão.';return;}
 if(a==='journeyLater'){document.querySelector('#journey-status').textContent='Tudo bem. Volte quando fizer sentido para você.';return;}
 if(b.dataset.reflection){openReflection(b.dataset.reflection);return;}
 if(a==='closeReflection'){closeReflection();return;}
 if(a==='listenReflection'){const m=findMessage(catalog,reflectionId);if(m){sound.pause();if(narration.status==='paused')narration.resume();else {const playing=narration.play(reflectionChunks(m));ambience.prepare(m.ambienceTheme);paintNarration();playing.catch(()=>ambience.stop());}}return;}
 if(a==='pauseReflection'){narration.pause();return;}
 if(a==='stopReflection'){narration.stop();return;}
 if(b.dataset.tab&&state.step>=3){narration.stop(false);reflectionId=null;history.replaceState(null,'',location.pathname+location.search);if(state.tab==='audio'&&b.dataset.tab!=='audio')sound.pause('Áudio pausado ao sair da área.');state.tab=b.dataset.tab;render(true);if(state.tab==='audio'&&!audioCatalog)loadAudio();}
 if(b.dataset.audioTheme){audioTheme=b.dataset.audioTheme;sound.select(audioCatalog.tracks.find(t=>t.theme===audioTheme));render();}
 if(a==='retryAudio')loadAudio();
 if(a==='audioPlay'){if(sound.status==='playing')sound.pause();else sound.play();}
 if(a==='audioStop')sound.stop();
 if(b.dataset.moment){state.preview=b.dataset.moment;state.reviewMessage=null;render();}
 if(a==='language'){state.step=2;render(true);}
 if(a==='backSignup'){state.step=0;render(true);}
 if(a==='backLanguage'){state.times=readTimes();state.step=1;render(true);}
 if(a==='auto'){state.preview=null;state.reviewMessage=null;render();}
 if(a==='logout'){narration.stop(false);reflectionId=null;pendingReflection=null;history.replaceState(null,'',location.pathname+location.search);sound.stop();state.name='';state.email='visitante@example.com';state.step=0;state.tab='home';state.preview=null;render(true);}
 if(a==='delete'&&confirm('Apagar cadastro fictício e preferências desta sessão?')){narration.stop(false);reflectionId=null;pendingReflection=null;history.replaceState(null,'',location.pathname+location.search);sound.stop();state=defaults();render(true);}
 if(a==='export'){
  const url=URL.createObjectURL(new Blob([JSON.stringify(widgetPayload(catalog,state.times),null,2)],{type:'application/json'}));const link=document.createElement('a');link.href=url;link.download='aurya-widget-demo.json';link.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
 }
});
document.addEventListener('visibilitychange',()=>{if(document.visibilityState==='hidden')narration.stop();if(document.visibilityState==='hidden'&&(sound.status==='playing'||sound.status==='loading'))sound.pause('Áudio pausado ao ocultar a prévia.');if(document.visibilityState==='visible'&&catalog&&state.step>=3&&state.tab==='home'&&!reflectionId)render();});
window.addEventListener('pagehide',()=>narration.stop(false));
window.addEventListener('focus',()=>{if(catalog&&state.step>=3&&state.tab==='home'&&!reflectionId)render();});
async function load(){try{const r=await fetch('../assets/content.json?revision=trilhas-variadas-1',{cache:'no-store'});if(!r.ok)throw new Error();catalog=await r.json();if(catalog.version!==2||catalog.moments.length!==4||catalog.moments.some(m=>!catalog.messages.some(x=>x.moment===m.id)))throw new Error();await loadAudio();readRoute();}catch(error){console.error('Falha ao preparar a prévia:',error);app.innerHTML=`<h1>Seu espaço está quase pronto.</h1><p role="alert">Não foi possível carregar as mensagens locais.</p>${button('Tentar novamente','retry')}`;}}
load();



