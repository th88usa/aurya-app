"""Render the approved original piano composition in musical tunings for all audio tracks."""
from pathlib import Path
import json
import numpy as np
import wave
root=Path(__file__).resolve().parents[1]
catalog_path=root/'assets/audio_catalog.json'
catalog=json.loads(catalog_path.read_text(encoding='utf-8'))
sr=24000
chords=[[48,55,60,64],[45,52,57,60],[41,48,53,57],[43,50,55,59]]
melodies=[[76,74,72,None],[72,None,69,71],[69,72,74,None],[71,None,67,None],[72,76,None,79],[76,None,72,71],[69,67,65,None],[67,None,None,None],[76,None,74,72],[72,71,69,None],[69,None,72,74],[71,69,67,None],[72,None,76,74],[72,69,None,67],[65,None,69,67],[67,None,71,None]]
arrangements=[
 ('Aurora',[72,None,76,79,77,76,74,None]),
 ('Horizonte',[67,72,None,76,74,None,71,72]),
 ('Acolhimento',[76,None,72,None,69,67,None,72]),
 ('Brisa',[67,None,69,72,71,None,67,None]),
 ('Novos caminhos',[72,74,76,None,79,76,74,72]),
 ('Raízes',[64,67,72,None,71,67,64,None]),
 ('Florescer',[76,79,None,81,79,76,None,72]),
 ('Luz serena',[72,None,67,69,65,None,69,67]),
 ('Amplitude',[67,71,74,None,76,74,71,None]),
 ('Presença',[64,None,67,72,69,None,65,67]),
 ('Possibilidades',[79,None,76,74,72,76,None,79])]
progressions=[
 [[48,55,60,64],[45,52,57,60],[41,48,53,57],[43,50,55,59]],
 [[41,48,53,57],[48,55,60,64],[43,50,55,59],[45,52,57,60]],
 [[48,55,60,64],[43,50,55,59],[45,52,57,60],[41,48,53,57]]]
originals=list({t['frequencyHz']:t for t in catalog['tracks']}.values())
expanded=[]
for base in originals:
 for variant in range(3):
  track=dict(base);track['variant']=variant;track['id']=f"music-{base['frequencyHz']}-melody-{variant+1}";expanded.append(track)
catalog['tracks']=expanded
for track_index,track in enumerate(catalog['tracks']):
 variant=track['variant']
 name,motif=arrangements[variant]
 chords=progressions[variant]
 melodies=[]
 for bar in range(16):
  phrase=motif[(bar%2)*4:(bar%2+1)*4].copy()
  if bar%8>=4:phrase=[None if n is None else n-12 for n in phrase]
  if bar in [7,15]:phrase=[72,None,None,None]
  melodies.append(phrase)
 hz=track['frequencyHz'];theme=track['theme'];beat={'prosperity':.96,'wealth':1.02,'gratitude':1.08}[theme]+.01*variant
 duration=16*4*beat;audio=np.zeros(int((duration+5)*sr));rng=np.random.default_rng(14)
 root_hz=float(hz)
 while root_hz>=348:root_hz/=2
 while root_hz<174:root_hz*=2
 def note(midi,start,length,velocity):
  n=int(length*sr);t=np.arange(n)/sr;f=root_hz*2**((midi-60)/12);tone=np.zeros(n)
  for k,amp in [(1,1),(2,.26),(3,.105),(4,.035),(5,.012)]:
   tone+=amp*np.sin(2*np.pi*f*k*(1+.00006*(k*k-1))*t)*np.exp(-t*(.9+.3*k))
  tone*=(1-np.exp(-t/.012))*np.minimum(1,np.maximum(0,(length-t)/.22))*velocity
  at=int(max(0,start)*sr);audio[at:at+n]+=tone[:len(audio[at:at+n])]
 for bar in range(16):
  base=bar*4*beat;ch=chords[bar%4];note(ch[0]-12,base+.01,4.8,.12)
  for j in range(8):note(ch[([0,1,2,3,2,1,3,1] if variant%2==0 else [0,2,1,3,1,2,3,2])[j]]+12,base+j*.5*beat+rng.uniform(-.012,.012),3,.055+rng.uniform(-.007,.007))
  for j,pitch in enumerate(melodies[bar]):
   if pitch is not None:note(pitch,base+j*beat+.04,3.8,.115+rng.uniform(-.01,.01))
 dry=audio.copy()
 for delay,gain in [(.137,.12),(.233,.10),(.389,.08),(.617,.055),(.941,.035)]:
  n=int(delay*sr);audio[n:]+=dry[:-n]*gain
 audio=audio[:int(duration*sr)];fade=int(2.5*sr);audio[:fade]*=np.linspace(0,1,fade);audio[-fade:]*=np.linspace(1,0,fade);audio*=.42/np.max(np.abs(audio))
 target=root/f'assets/audio/music-v3-{hz}-{variant+1}.wav'
 with wave.open(str(target),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);w.writeframes((audio*32767).astype('<i2').tobytes())
 label={'prosperity':'Prosperidade','wealth':'Riqueza','gratitude':'Gratidão'}[theme]
 track.update(title=f'{name} · Piano suave · {hz} Hz',composition=name,kind='instrumental-piano',asset=f'audio/music-v3-{hz}-{variant+1}.wav',durationSeconds=round(duration,2),sampleRate=sr,channels=1,referenceNoteHz=root_hz,description='Composição instrumental original com melodia, acordes e piano sintetizado. Frequência indicada como referência de afinação, com equivalência por oitavas; a música contém várias notas.')
 print(f'{name} - {hz} Hz: {duration:.2f}s; referência de afinação {root_hz} Hz')
catalog['generation']={'method':'Composição original de 16 compassos, melodia e arpejos em piano sintetizado, com reverberação e variação de dinâmica. Afinação referenciada por oitavas à frequência indicada.','source':'tools/generate_musical_audio.py','thirdPartyRecordings':False}
catalog['editorialNote']='Prosperidade, riqueza e gratidão são temas de intenção. As frequências identificam referências de afinação musical, não efeitos financeiros ou clínicos comprovados.'
catalog_path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
