# M19 Contract-Driven Execution Protocol v2

CONTRACT_ID=M19-CONTRACT-DRIVEN-V2
STATUS=ACTIVE
WAVES=W01,W02,W03,W04
GENERATED=2026-07-14T01:36:39.547736

## Architecture
- M19-A: 02-06 Hybrid Raster UI (Shell plate + dynamic Fact layer)
- M19-B: 01 Main Interface (Chrome plate + World layer + Fact controls)
- M20: DIY tank, drag-drop, layout persistence (OUT OF M19 SCOPE)

## Waves
| Wave | ID | Scope | Defects |
|---|---|---|---|
| W01 | M19-W01-PRODUCTION-TAKEOVER | Production entry, frozen plates, legacy cleanup | D001-D004 |
| W02 | M19-W02-FACT-INTEGRATION | Dynamic text, variables, LED states | D005-D010 |
| W03 | M19-W03-STABILITY | Modal close, text layout, behavior | D011-D016 |
| W04 | M19-W04-FINAL-FREEZE | Full regression, screenshots, freeze | D017-D018 |

## Hard Gates
```
GODOT_ERROR_COUNT=0
GODOT_SCRIPT_ERROR_COUNT=0
SAVE_SCHEMA_CHANGE_COUNT=0
SOURCE_ASSET_MODIFICATION_COUNT=0
MANIFEST_MODIFICATION_COUNT=0
LEGACY_VISIBLE_COUNT=0
FROZEN_PLATE_MATCH_COUNT=6
SUBVIEWPORT_NODE_COUNT=0
```

## Evidence Rules
1. All evidence must be from current HEAD
2. All evidence must contain run_id, commit_sha, generated_at
3. Acceptance script launches probe, probe produces staging/<run_id>/
4. Ratchets read only from explicit run_id — never "latest"
5. Stale or hand-written evidence rejected

## Ratchet Rules
1. Must use relative paths (no C:/Users/...)
2. Must read from probe output JSON (not source strings)
3. Must accept -EvidenceDir parameter with explicit run_id
