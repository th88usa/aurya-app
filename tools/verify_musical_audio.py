"""Check musical assets: duration, safe peaks, time-varying notes and tuning metadata."""
import json,wave
from pathlib import Path
import numpy as np
r=Path(__file__).resolve().parents[1];d=json.loads((r/'assets/audio_catalog.json').read_text(encoding='utf-8'))
for t in d['tracks']:
 assert t['kind']=='instrumental-piano'
 with wave.open(str(r/'assets'/t['asset'])) as w:
  assert w.getnchannels()==1 and w.getsampwidth()==2
  rate=w.getframerate();x=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float)/32768
 assert abs(len(x)/rate-t['durationSeconds'])<.001
 assert len(x)/rate>=60 and 0<np.max(np.abs(x))<=.43
 assert abs(np.log2(t['frequencyHz']/t['referenceNoteHz'])-round(np.log2(t['frequencyHz']/t['referenceNoteHz'])))<1e-8
 # Real notes evolve: dominant frequencies differ across the piece.
 peaks=[]
 for second in [5,12,20,30,45]:
  a=x[int(second*rate):int((second+1)*rate)];s=np.abs(np.fft.rfft(a*np.hanning(len(a))))
  peaks.append(round(np.argmax(s)*rate/len(a)))
 assert len(set(peaks))>=3,(t['id'],peaks)
 assert np.max(np.abs(x[:100]))<.01 and np.max(np.abs(x[-100:]))<.01
 print(t['title'], 'OK',len(x)/rate,'s',peaks)
from collections import defaultdict
import hashlib
groups=defaultdict(list)
for t in d['tracks']:groups[t['frequencyHz']].append(t)
for hz,tracks in groups.items():
 assert len(tracks)==3,(hz,len(tracks))
 assert len({t['composition'] for t in tracks})==3
 assert len({hashlib.sha256((r/'assets'/t['asset']).read_bytes()).hexdigest() for t in tracks})==3
print(f"{len(d['tracks'])} faixas musicais verificadas; três melodias por frequência. Análise de sinal, sem avaliação humana.")
