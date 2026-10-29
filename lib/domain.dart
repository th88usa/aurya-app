enum RitualMoment { wake, commute, midday, sleep }
const momentLabels={RitualMoment.wake:'Ao acordar',RitualMoment.commute:'Indo para o trabalho',RitualMoment.midday:'Meio do dia',RitualMoment.sleep:'Antes de dormir'};
const exampleMinutes={RitualMoment.wake:420,RitualMoment.commute:510,RitualMoment.midday:750,RitualMoment.sleep:1320};
class MomentOccurrence {
 final RitualMoment moment;final DateTime date;
 const MomentOccurrence(this.moment,this.date);
}
class RitualSchedule {
 final Map<RitualMoment,int> times;
 RitualSchedule(Map<RitualMoment,int> values):times=Map.unmodifiable(values);
 bool get valid=>RitualMoment.values.every((m)=>times.containsKey(m)&&times[m]!>=0&&times[m]!<1440)&&times.values.toSet().length==4&&times.length==4;
 List<MomentOccurrence> occurrences(DateTime now,{int days=8}){
  if(!valid)throw StateError('Quatro horários diferentes são necessários.');
  final rows=<MomentOccurrence>[];
  for(var d=-1;d<=days;d++)for(final m in RitualMoment.values){final v=times[m]!;rows.add(MomentOccurrence(m,DateTime(now.year,now.month,now.day+d,v~/60,v%60)));}
  rows.sort((a,b){final order=a.date.compareTo(b.date);return order!=0?order:times[a.moment]!.compareTo(times[b.moment]!);});return rows;
 }
 MomentOccurrence activeAt(DateTime now)=>occurrences(now,days:1).lastWhere((o)=>!o.date.isAfter(now));
 MomentOccurrence nextAt(DateTime now)=>occurrences(now,days:2).firstWhere((o)=>o.date.isAfter(now));
}
int dayIndex(DateTime now)=>DateTime.utc(now.year,now.month,now.day).difference(DateTime.utc(2026,1,1)).inDays;
bool validDemoEmail(String v)=>RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
String clockLabel(int v)=>'${(v~/60).toString().padLeft(2,'0')}:${(v%60).toString().padLeft(2,'0')}';
