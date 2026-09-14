#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
model="$root/models/svg-arcade/arcade-rules.md"
generated="$root/models/svg-arcade/arcade-rules.qnt"
bindings="$root/models/svg-arcade/arcade-rules.bindings.json"
correspondence="$root/models/svg-arcade/correspondence.qnt"
trace="$root/Conformance/arcade-rules.trace"
quint="${QUINT_BIN:-$(command -v quint || true)}"
temporary="$(mktemp)"; trace_json="$(mktemp)"; projection="$(mktemp)"; combined="$(mktemp --suffix=.qnt)"
trap 'rm -f "$temporary" "$trace_json" "$projection" "$combined"' EXIT
if [[ -z "$quint" || ! -x "$quint" ]]; then echo 'QUINT_BIN must name the qualified Quint 0.32.0 executable' >&2; exit 1; fi
[[ "$($quint --version)" == "0.32.0" ]]
awk '/^```quint arcade-rules\.qnt \+=/ { inside=1; next } inside && /^```$/ { exit } inside { print }' "$model" > "$temporary"
cmp "$generated" "$temporary"
jq -e '.schema=="fsgg.quint.general-bindings/v1" and .profile=="fsgg-quint-profile/2" and (.exports|length)==1 and (.actions|length)==9 and ([.exports[],.actions[]]|all(.source.path=="models/svg-arcade/arcade-rules.md"))' "$bindings" >/dev/null
"$quint" typecheck "$generated"
cat "$generated" "$correspondence" > "$combined"
"$quint" typecheck "$combined"
"$quint" run "$combined" --main SvgArcadeCorrespondence --max-samples=1 --max-steps=11 --out-itf "$trace_json" --verbosity=0
jq -r '.states[].observed | "health:\(.health["#bigint"])|score:\(.score["#bigint"])|collected:\(.collected)|outcome:\(.outcome)|hazardContact:\(.hazardContact)"' "$trace_json" > "$projection"
cmp "$trace" "$projection"
"$quint" run "$generated" --main SvgArcadeRules --max-samples=500 --max-steps=20 --invariants healthBound scoreShape collectedScore wonRequiresCollection terminalOutcome hazardContactImpliesDamage --witnesses witnessCollect witnessWin witnessLoss witnessRestart witnessHazardEntry witnessHazardStay witnessTerminalRefusal
