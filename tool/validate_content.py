import hashlib, json
from collections import Counter
from pathlib import Path
root=Path(__file__).resolve().parents[1]
m=json.loads((root/"assets/content/manifest.json").read_text(encoding="utf-8"))
assert m["schema_version"]==1 and m["content_version"]=="1.2.0"
assert len(m["packages"])==1
pkg=m["packages"][0]
path=root/"assets/content"/pkg["file"]
raw=path.read_bytes()
assert hashlib.sha256(raw).hexdigest()==pkg["sha256"], "SHA-256 mismatch"
p=json.loads(raw)
qs=p["questions"]
assert len(qs)==m["question_count"]==pkg["question_count"]==100
ids=[q["id"] for q in qs]
assert len(ids)==len(set(ids)), "duplicate IDs"
required={"id","status","scientific_status","unlock_order","difficulty","nature","representation","subdomain_id","options","correct_option_id","explanation"}
for q in qs:
    assert required <= q.keys(), f"missing metadata {q.get('id')}"
    if q["status"]=="published":
        assert str(q["scientific_status"]).lower()=="pass", f"published without PASS {q['id']}"
    assert len(q["options"])==4
    assert q["correct_option_id"] in {o["option_id"] for o in q["options"]}
active=[q for q in qs if q["status"]=="published" and str(q["scientific_status"]).lower()=="pass" and q["unlock_order"]<=m["current_unlock_order"]]
assert len(active)==80
assert Counter(q["subdomain_id"] for q in active)==Counter({"KIN-01":20,"KIN-02":20,"KIN-03":20,"KIN-08":20})
levels=Counter(q["difficulty"] for q in active)
assert levels["basic"]>=8 and levels["intermediate"]>=5 and levels["advanced"]>=3
nature=Counter(q["nature"] for q in active)
assert nature["theory"]>=7 and nature["calculation"]>=7
rep=Counter(q["representation"] for q in active)
assert rep["graph"]>=2 and rep["table"]>=1 and rep["scheme"]>=1
print("PASS: content 1.2.0, SHA, metadata, boundary and MASTER pool preflight")
