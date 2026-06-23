param(
    [string]$ExpectedRoot = "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3",
    [int]$ChangedFileWarningLimit = 12
)

$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "== $Title =="
}

function Normalize-PathText {
    param([string]$PathText)
    if ([string]::IsNullOrWhiteSpace($PathText)) {
        return ""
    }
    return ([System.IO.Path]::GetFullPath($PathText).TrimEnd("\", "/")).ToLowerInvariant()
}

$warnings = New-Object System.Collections.Generic.List[string]
$blocks = New-Object System.Collections.Generic.List[string]
$repoRoot = ""
$isGitRepo = $false

Write-Section "Repository"
Write-Host "PWD: $(Get-Location)"

try {
    $repoRoot = (& git rev-parse --show-toplevel 2>$null).Trim()
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($repoRoot)) {
        $isGitRepo = $true
        Write-Host "Git repository: YES"
        Write-Host "Git root: $repoRoot"
    } else {
        $blocks.Add("Current directory is not inside a Git repository.")
    }
} catch {
    $blocks.Add("Current directory is not inside a Git repository.")
}

if ($isGitRepo) {
    $actualRoot = Normalize-PathText $repoRoot
    $expected = Normalize-PathText $ExpectedRoot
    if ($actualRoot -ne $expected) {
        $blocks.Add("Git root does not match the unique source-of-truth path.")
    }
}

Write-Host "Expected root: $ExpectedRoot"

if ($isGitRepo) {
    Write-Section "Git Status"
    $statusLines = @(& git status --porcelain)
    $changedFiles = @()
    foreach ($line in $statusLines) {
        if ($line.Length -ge 4) {
            $pathPart = $line.Substring(3)
            if ($pathPart -match " -> ") {
                $pathPart = ($pathPart -split " -> ")[-1]
            }
            $changedFiles += $pathPart
        }
    }

    Write-Host "Changed files count: $($changedFiles.Count)"
    if ($changedFiles.Count -gt 0) {
        $changedFiles | ForEach-Object { Write-Host " - $_" }
    }

    if ($changedFiles.Count -gt $ChangedFileWarningLimit) {
        $warnings.Add("Changed file count is above warning limit: $($changedFiles.Count) > $ChangedFileWarningLimit.")
    }

    Write-Section "Diff Stat"
    $diffStat = @(& git diff --stat)
    if ($diffStat.Count -eq 0) {
        Write-Host "(no tracked-file diff stat)"
    } else {
        $diffStat | ForEach-Object { Write-Host $_ }
    }

    $changedText = ($changedFiles -join "`n")
    if ($changedText -match "(?i)(save|autosave|SaveSystem|save_schema)") {
        $warnings.Add("Changed files include save-related paths.")
    }
    if ($changedText -match "(?i)(^|/)(scenes|ui)(/|$)|\.tscn$|Main\.gd|Panel\.gd|ShopPanel") {
        $warnings.Add("Changed files include UI-related paths.")
    }

    $diffTextParts = New-Object System.Collections.Generic.List[string]
    $unstagedDiff = @(& git diff --)
    $stagedDiff = @(& git diff --cached --)
    $diffTextParts.Add(($unstagedDiff -join "`n"))
    $diffTextParts.Add(($stagedDiff -join "`n"))

    foreach ($file in $changedFiles) {
        if ($file.StartsWith('"') -and $file.EndsWith('"')) {
            continue
        }
        $fullPath = Join-Path $repoRoot $file
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            try {
                $item = Get-Item -LiteralPath $fullPath
                if ($item.Length -le 1048576) {
                    $diffTextParts.Add((Get-Content -LiteralPath $fullPath -Raw -ErrorAction Stop))
                }
            } catch {
                $warnings.Add("Could not scan changed file content: $file")
            }
        }
    }

    $scanText = ($diffTextParts -join "`n")

    Write-Section "Keyword Checks"
    $debugHit = $scanText -match "(?i)\b(debug|test|heartbeat)\b"
    $saveRiskHit = $scanText -match "(?i)(Vector2|Node|Resource|Callable|Signal|typed array|TypedArray|Packed[A-Za-z0-9_]*Array|Array\[)"
    $wrongPathHit = $scanText -match [regex]::Escape("C:\Users\admin\CoralReefIdle")

    Write-Host "debug/test/heartbeat keywords: $(if ($debugHit) { 'FOUND' } else { 'not found' })"
    Write-Host "save-risk keywords: $(if ($saveRiskHit) { 'FOUND' } else { 'not found' })"
    Write-Host "wrong project path: $(if ($wrongPathHit) { 'FOUND' } else { 'not found' })"

    if ($debugHit) {
        $warnings.Add("debug/test/heartbeat keyword found in changed content.")
    }
    if ($saveRiskHit) {
        $warnings.Add("Save-risk keyword found in changed content.")
    }
    if ($wrongPathHit) {
        $warnings.Add("Wrong project path C:\Users\admin\CoralReefIdle found in changed content; verify it is only mentioned as a forbidden path.")
    }
}

Write-Section "Gate Result"
if ($blocks.Count -gt 0) {
    Write-Host "BLOCKED"
    $blocks | ForEach-Object { Write-Host " - $_" }
} elseif ($warnings.Count -gt 0) {
    Write-Host "WARNING"
    $warnings | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host "PASS"
}

$allowContinue = ($blocks.Count -eq 0)
$allowCommit = ($blocks.Count -eq 0 -and $warnings.Count -eq 0)
$allowTag = ($blocks.Count -eq 0 -and $warnings.Count -eq 0 -and $isGitRepo -and @(& git status --porcelain).Count -eq 0)
$allowNextMilestone = $false

Write-Section "Final Gate"
Write-Host "Allow continue: $(if ($allowContinue) { 'YES' } else { 'NO' })"
Write-Host "Allow commit: $(if ($allowCommit) { 'YES' } else { 'NO' })"
Write-Host "Allow tag: $(if ($allowTag) { 'YES' } else { 'NO' })"
Write-Host "Allow next milestone: $(if ($allowNextMilestone) { 'YES' } else { 'NO' })"

if ($blocks.Count -gt 0) {
    exit 2
}
if ($warnings.Count -gt 0) {
    exit 1
}
exit 0
