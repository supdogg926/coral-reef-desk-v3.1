$ErrorActionPreference = "Continue"
$repo = "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M19_T2_LOOP"
$godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$stateDir = "$repo\reports\m19_complete_release\runtime"
$stateFile = "$stateDir\M19_RELEASE_STATE.json"
$logFile = "$stateDir\M19_RELEASE_LATEST.log"
$evidenceDir = "$repo\reports\m19_t2_blue_guardian_min_loop\evidence"

New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

function Write-Log {
    param($msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts $msg" | Tee-Object -FilePath $logFile -Append
}

function Invoke-Stage {
    param($stage, $command, $timeout = 120)
    Write-Log "STAGE_START: $stage"
    $started = Get-Date -Format "o"
    try {
        $proc = Start-Process -FilePath $godot -ArgumentList $command -NoNewWindow -Wait -PassThru -WorkingDirectory $repo
        $exit = $proc.ExitCode
        $completed = Get-Date -Format "o"
        $result = if ($exit -eq 0) { "PASS" } else { "FAIL" }
    } catch {
        $exit = -1
        $completed = Get-Date -Format "o"
        $result = "FAIL"
    }
    Write-Log "STAGE_END: $stage result=$result exit=$exit"
    return @{
        stage = $stage; status = $result; exit_code = $exit
        started_at = $started; completed_at = $completed
    }
}

function Update-State {
    param($stage, $result)
    $state = @{}
    if (Test-Path $stateFile) { $state = Get-Content $stateFile | ConvertFrom-Json }
    $state[$stage] = $result
    $state | ConvertTo-Json -Depth 3 | Set-Content $stateFile
}

function Get-StageStatus {
    param($stage)
    if (-not (Test-Path $stateFile)) { return "NOT_STARTED" }
    $state = Get-Content $stateFile | ConvertFrom-Json
    $entry = $state[$stage]
    if ($null -eq $entry) { return "NOT_STARTED" }
    return $entry.status
}

# ── Stage Definitions ──────────────────────────────
$stages = @(
    @{id="01_env"; desc="Environment check"; cmd="--headless --quit --path `"$repo`""},
    @{id="02_parse"; desc="Headless parse"; cmd="--headless --quit --path `"$repo`""},
    @{id="03_h1"; desc="M19-H1 acceptance"; cmd="--headless --path `"$repo`" --script tests/m19_h1/test_runner.tscn"},
    @{id="04_service"; desc="Service acceptance"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="05_ui"; desc="Runtime UI acceptance"; cmd="--headless --path `"$repo`" --script tests/m19_t2_ui/m19_t2_runtime_ui_driver.gd"},
    @{id="06_content"; desc="Content acceptance"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="07_economy"; desc="Economy acceptance"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="99_status"; desc="Final status report"; cmd=""}
)

Write-Log "M19_RELEASE_ORCHESTRATOR_START repo=$repo branch=$(git -C $repo branch --show-current) head=$(git -C $repo rev-parse --short HEAD)"

foreach ($s in $stages) {
    $status = Get-StageStatus $s.id
    if ($status -eq "PASS") {
        Write-Log "SKIP: $($s.id) $($s.desc) (already PASS)"
        continue
    }
    Write-Log "RUN: $($s.id) $($s.desc)"
    if ($s.cmd) {
        $r = Invoke-Stage -stage $s.id -command $s.cmd
        Update-State -stage $s.id -result $r
        if ($r.status -eq "FAIL") {
            Write-Log "STAGE_FAILED: $($s.id) $($s.desc)"
        }
    }
}

# Final summary
$state = @{}
if (Test-Path $stateFile) { $state = Get-Content $stateFile | ConvertFrom-Json }
$pass = 0; $fail = 0; $total = 0
foreach ($prop in $state.PSObject.Properties) {
    $total++
    if ($prop.Value.status -eq "PASS") { $pass++ } else { $fail++ }
}
Write-Log "ORCHESTRATOR_DONE total=$total pass=$pass fail=$fail"
if ($fail -eq 0) { exit 0 } else { exit 1 }
