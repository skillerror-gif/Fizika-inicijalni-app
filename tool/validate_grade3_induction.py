import hashlib,json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
m=json.loads((root/'assets/content/manifest_g3.json').read_text())
p=m['packages'][0];raw=(root/'assets/content'/p['file']).read_bytes();d=json.loads(raw)
assert hashlib.sha256(raw).hexdigest()==p['sha256']
assert m['grade']==d['grade']==3
assert d['content_version']==m['content_version']=='3.2.0'
assert len(d['questions'])==m['question_count']==p['question_count']==156
old=json.loads((root/'assets/content/g3_magnetno_polje_3.0.0_PASS.json').read_text())['questions']
by={q['id']:q for q in d['questions']};assert len(by)==156
for q in old:assert by[q['id']]==q
new=[q for q in d['questions'] if q['id'] not in {o['id'] for o in old}]
assert len(new)==56
for q in new:
 assert q['status']=='published' and q['scientific_status']=='pass'
 assert q['unlock_order']<=d['current_unlock_order']==m['current_unlock_order']
 assert q['track']==['PM','DJ'] and q['outcome_ids']
 assert len(q['options'])==len({o['option_id'] for o in q['options']})==len({o['text'] for o in q['options']})==4
 assert sum(o['option_id']==q['correct_option_id'] for o in q['options'])==1
 assert len(q['common_errors'])==3
 assert q['subdomain_id'] not in {'IND-19','IND-20'}
 assert q['subdomain_id'] in q['lesson_ids']
 assert q['achievement_level'] in {'N1','N2','N3'}
assert len({q['subdomain_id'] for q in new})==18
print('Verified: 156 cumulative questions; 56 new core items; checksum, metadata, selection groups, and existing question identity.')
