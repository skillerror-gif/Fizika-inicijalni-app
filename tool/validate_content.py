import hashlib, json
from collections import Counter
from pathlib import Path
root=Path(__file__).resolve().parents[1]
m=json.loads((root/"assets/content/manifest.json").read_text(encoding="utf-8"))
assert m["schema_version"]==1 and m["content_version"]=="1.3.0"
assert len(m["packages"])==1
pkg=m["packages"][0]
path=root/"assets/content"/pkg["file"]
raw=path.read_bytes()
actual_sha256=hashlib.sha256(raw).hexdigest()
assert actual_sha256==pkg["sha256"], f"SHA-256 mismatch: expected {pkg['sha256']}, actual {actual_sha256}"
p=json.loads(raw)
qs=p["questions"]
assert len(qs)==m["question_count"]==pkg["question_count"]==136
ids=[q["id"] for q in qs]
assert len(ids)==len(set(ids)), "duplicate IDs"
required={"id","status","scientific_status","unlock_order","difficulty","achievement_level","nature","representation","subdomain_id","subdomain_name","lesson_ids","question_type","stem","options","correct_option_id","explanation"}
for q in qs:
    assert required <= q.keys(), f"missing metadata {q.get('id')}"
    if q["status"]=="published":
        assert str(q["scientific_status"]).lower()=="pass", f"published without PASS {q['id']}"
    assert str(q["stem"]).strip(), f"empty stem {q['id']}"
    assert str(q["explanation"]).strip(), f"empty explanation {q['id']}"
    assert q["question_type"]=="single_choice", f"invalid question_type {q['id']}"
    assert isinstance(q["lesson_ids"],list) and q["lesson_ids"], f"missing lesson_ids {q['id']}"
    assert len(q["options"])==4
    assert all(str(o.get("text","")).strip() for o in q["options"]), f"empty option text {q['id']}"
    option_ids=[o["option_id"] for o in q["options"]]
    assert len(option_ids)==len(set(option_ids))==4, f"duplicate option IDs {q['id']}"
    assert set(option_ids)=={"A","B","V","G"}, f"invalid option IDs {q['id']}: {option_ids}"
    assert q["correct_option_id"] in set(option_ids)
    assert isinstance(q["unlock_order"],int) and q["unlock_order"]>=1, f"invalid unlock_order {q['id']}"
active=[q for q in qs if q["status"]=="published" and str(q["scientific_status"]).lower()=="pass" and q["unlock_order"]<=m["current_unlock_order"]]
# Locked content may still carry legacy "mixed"/"N4" until normalized; enforce before it unlocks.
for q in active:
    assert q["achievement_level"] in {"N1","N2","N3"}, f"invalid achievement_level {q['id']}"
    assert q["nature"] in {"theory","calculation"}, f"invalid nature {q['id']}"
assert len(active)==116
expected=Counter({"UVF-01":12,"UVF-02":12,"UVF-03":12,"KIN-01":20,"KIN-02":20,"KIN-03":20,"KIN-08":20})
assert Counter(q["subdomain_id"] for q in active)==expected
assert all(len([q for q in active if q["subdomain_id"]==sid])>=5 for sid in expected), "formative pool below 5"
assert all(q["subdomain_id"] in q["lesson_ids"] for q in active), "lesson/subdomain mismatch"
levels=Counter(q["achievement_level"] for q in active)
assert set(levels) <= {"N1","N2","N3"}, f"invalid achievement_level: {levels}"
assert levels["N1"]>=8 and levels["N2"]>=5 and levels["N3"]>=3
nature=Counter(q["nature"] for q in active)
assert nature["theory"]>=7 and nature["calculation"]>=7
rep=Counter(q["representation"] for q in active)
assert rep["graph"]>=2 and rep["table"]>=1 and rep["scheme"]>=1
print("PASS: content 1.3.0, SHA, metadata, cumulative boundary and MASTER pool preflight")

# Grade III magnetic-field bank: independent structural and distribution gate.
g3=json.loads((root/"assets/content/g3_magnetno_polje_3.0.0_PASS.json").read_text(encoding="utf-8"))
g3q=g3["questions"]
assert g3["grade"]==3 and g3["content_version"]=="3.1.0"
assert g3["question_count"]==len(g3q)==100
assert len({q["id"] for q in g3q})==100
assert len({ " ".join(q["stem"].lower().split()) for q in g3q })==100
assert Counter(q["correct_option_id"] for q in g3q)==Counter({"A":25,"B":25,"V":25,"G":25})
for q in g3q:
    assert required <= q.keys(), f"G3 missing fields: {q.get('id')}"
    assert q["status"]=="published" and q["scientific_status"].lower()=="pass"
    assert q["grade"]==3 and q["unlock_order"]<=35
    assert q["correct_option_id"] in {o["option_id"] for o in q["options"]}
    assert len(q["options"])==4
    assert q["explanation"].strip() and q["stem"].strip()
print("PASS: G3 100 unique IDs/stems, balanced key, metadata and answer integrity")
