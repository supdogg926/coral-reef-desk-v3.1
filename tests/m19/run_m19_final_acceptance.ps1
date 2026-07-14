param(
  [ValidateSet("M19-W01-PRODUCTION-TAKEOVER","M19-W02-FACT-DATA-LED","M19-W03-MODAL-BEHAVIOR","M19-W04-EVIDENCE-FINAL","ALL")]
  [string]$WaveId="ALL",
  [string]$RepoRoot=(Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [switch]$AllowDirty
)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
function Fail([string]$m){Write-Error $m; exit 1}
function Need([string]$p,[string]$l){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){Fail "MISSING_FILE [$l] $p"}}
function Run([string]$l,[scriptblock]$c){Write-Host "==> $l";&$c;if($LASTEXITCODE-ne 0){Fail "COMMAND_FAILED [$l] exit=$LASTEXITCODE"}}
$contract=Join-Path $RepoRoot "docs\m19\M19_FINAL_ACCEPTANCE_CONTRACT.md"
$reqPath=Join-Path $RepoRoot "docs\m19\M19_REQUIREMENTS.json"
$defPath=Join-Path $RepoRoot "reports\m19\acceptance\M19_OPEN_DEFECTS.json"
$capPath=Join-Path $RepoRoot "reports\m19\acceptance\CAPABILITIES.json"
Need $contract contract; Need $reqPath requirements; Need $defPath defects; Need (Join-Path $RepoRoot "project.godot") project
$req=Get-Content $reqPath -Raw|ConvertFrom-Json; $defs=Get-Content $defPath -Raw|ConvertFrom-Json
Push-Location $RepoRoot
try{
 Run "git root" {git rev-parse --show-toplevel|Out-Null}
 if(-not $AllowDirty -and (git status --porcelain)){Fail "DIRTY_WORKTREE"}
 Need $capPath capabilities
 $caps=Get-Content $capPath -Raw|ConvertFrom-Json
 foreach($n in @('correct_worktree','git_push','godot_gui_capture','gui_input_automation','runtime_scene_tree_snapshot','asset_sha256_validation','real_ci_access')){if($caps.$n-ne $true){Fail "CAPABILITY_NOT_VERIFIED [$n]"}}
 $open=@($defs.defects|?{($WaveId-eq'ALL'-or$_.wave_id-eq$WaveId)-and$_.status-notin@('CLOSED_RATCHET','WAIVED_P2')})
 if($WaveId-ne'ALL'-and($open.Count-lt 0-or$open.Count-gt 5)){Fail "INVALID_WAVE_SIZE count=$($open.Count)"}
 foreach($d in @($open|?{$_.attempt_count-ge 3})){
   $r=Join-Path $RepoRoot "reports\m19\acceptance\root_cause\$($d.id)"
   Need (Join-Path $r 'root_cause_analysis.md') "$($d.id) root cause"
   Need (Join-Path $r 'minimal_repro.json') "$($d.id) repro"
   Need (Join-Path $r 'ruling.json') "$($d.id) ruling"
 }
 foreach($p in @('assets\m19\ui\manifests\asset_manifest.json','assets\m19\ui\manifests\coordinate_manifest.json','assets\m19\ui\manifests\dynamic_slot_manifest.json')){Need (Join-Path $RepoRoot $p) $p}
 foreach($s in @('scripts\m19\run_capability_preflight.ps1','scripts\m19\run_production_gpu_capture.ps1','scripts\m19\run_runtime_scene_tree_audit.ps1','scripts\m19\run_fact_slot_audit.ps1','scripts\m19\run_modal_stress.ps1','scripts\m19\run_m19_full_regression.ps1')){Need (Join-Path $RepoRoot $s) $s}
 Run preflight {powershell -NoProfile -ExecutionPolicy Bypass -File scripts\m19\run_capability_preflight.ps1}
 Run gpu {powershell -NoProfile -ExecutionPolicy Bypass -File scripts\m19\run_production_gpu_capture.ps1 -WaveId $WaveId}
 Run tree {powershell -NoProfile -ExecutionPolicy Bypass -File scripts\m19\run_runtime_scene_tree_audit.ps1 -WaveId $WaveId}
 Run facts {powershell -NoProfile -ExecutionPolicy Bypass -File scripts\m19\run_fact_slot_audit.ps1 -WaveId $WaveId}
 Run modal {powershell -NoProfile -ExecutionPolicy Bypass -File scripts\m19\run_modal_stress.ps1 -WaveId $WaveId}
 Run regression {powershell -NoProfile -ExecutionPolicy Bypass -File scripts\m19\run_m19_full_regression.ps1}
 $defs=Get-Content $defPath -Raw|ConvertFrom-Json
 $remaining=@($defs.defects|?{($WaveId-eq'ALL'-or$_.wave_id-eq$WaveId)-and$_.severity-in@('P0','P1')-and$_.status-ne'CLOSED_RATCHET'})
 if($remaining.Count){Fail "OPEN_P0_P1_DEFECTS_REMAIN [$((@($remaining.id)-join','))]"}
 $out=Join-Path $RepoRoot 'reports\m19\acceptance\latest';New-Item -ItemType Directory -Force $out|Out-Null
 [ordered]@{result='CANDIDATE_READY';wave_id=$WaveId;branch=(git branch --show-current).Trim();commit=(git rev-parse HEAD).Trim();generated_at=(Get-Date).ToString('o')}|ConvertTo-Json|Set-Content (Join-Path $out 'M19_ACCEPTANCE_SUMMARY.json') -Encoding UTF8
 Write-Host 'CANDIDATE_READY'; exit 0
}finally{Pop-Location}
