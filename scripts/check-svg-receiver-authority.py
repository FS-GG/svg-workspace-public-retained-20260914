#!/usr/bin/env python3
import hashlib, json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
path = root / 'models' / 'receiver-authority.json'
value = json.loads(path.read_text())
assert value.get('schema') == 'fsgg.svg-workspace.receiver-model-authority/v1'
producer = value.get('producer', {})
assert producer.get('package') == 'FS.GG.SDD.Artifacts'
assert producer.get('version') == '1.8.0'
assert producer.get('backend') == 'quint-specification-v1'
assert producer.get('profileIdentity') == 'fsgg-quint-profile/2'
assert len(producer.get('toolchainIdentity', '')) == 64
assert value.get('authoring', {}).get('authorOutcome') == 'succeeded'
assert value.get('authoring', {}).get('inspectOutcome') == 'succeeded'
rows = value.get('models', [])
assert [row.get('id') for row in rows] == ['arena', 'tactical', 'arcade']
for row in rows:
    for key in ('source', 'bindings'):
        relative = Path(row[key])
        assert not relative.is_absolute() and '..' not in relative.parts
        actual = hashlib.sha256((root / relative).read_bytes()).hexdigest()
        assert actual == row[key + 'Sha256'], f'{row["id"]} {key} authority is stale'
    for key in ('typedAuthoritySha256', 'compilationReceiptSha256', 'compilationFingerprint'):
        assert len(row.get(key, '')) == 64
print('receiver model authority: exact SDD 1.8 profile-2 source and bindings matched')
