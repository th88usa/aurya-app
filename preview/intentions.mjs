export const intentions=[
 {id:'prosperity',label:'Prosperidade',description:'Acolher oportunidades e cultivar confiança.',ids:['wake-intention-prosperity-01','commute-intention-prosperity-01','midday-intention-prosperity-01','sleep-intention-prosperity-01']},
 {id:'gratitude',label:'Gratidão',description:'Reconhecer o que sustenta você e apreciar suas conquistas.',ids:['wake-intention-gratitude-01','commute-intention-gratitude-01','midday-intention-gratitude-01','sleep-intention-gratitude-01']},
 {id:'visualization',label:'Visualização',description:'Imaginar o que deseja cultivar e dar sentido aos próximos passos.',ids:['wake-intention-visualization-01','commute-intention-visualization-01','midday-intention-visualization-01','sleep-intention-visualization-01']},
 {id:'wealth',label:'Riqueza',description:'Reconhecer seu valor e cuidar dos recursos que deseja construir.',ids:['wake-intention-wealth-01','commute-intention-wealth-01','midday-intention-wealth-01','sleep-intention-wealth-01']},
 {id:'abundance',label:'Abundância',description:'Cultivar receptividade, generosidade e reconhecimento.',ids:['wake-intention-abundance-01','commute-intention-abundance-01','midday-intention-abundance-01','sleep-intention-abundance-01']}
];
export function intentionMessage(catalog,intention,moment){const index=['wake','commute','midday','sleep'].indexOf(moment);const plan=intentions.find(x=>x.id===intention);return plan&&index>=0?catalog.messages.find(x=>x.id===plan.ids[index]&&x.moment===moment):null;}
