import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
m=json.loads((root/"assets/content/manifest.json").read_text())
p=json.loads((root/"assets/content/g1_kinematika_1.0.0.json").read_text())
assert m["schema_version"]==1
assert p["schema_version"]==1
print("PASS: bootstrap schema OK")
