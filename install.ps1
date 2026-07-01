# install.ps1 — lay the factory out into ~\.claude on Windows (PowerShell).
# Mirrors install.sh: same structure, backs up preexisting core files before overwriting, and never
# clobbers an accreted stack.md. Run from the unpacked factory bundle directory:  .\install.ps1
$ErrorActionPreference = "Stop"

$Src  = $PSScriptRoot
$Dest = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME ".claude" }

Write-Host "Installing factory into $Dest"

# Create the tree.
$dirs = @(
  "skills\new-line", "skills\spec-interview", "skills\eval-scaffold",
  "skills\add-stack-part", "skills\as-built", "skills\import-handoff", "skills\foreman",
  "hooks", "commands",
  "shapes\docker-analog\analog", "shapes\aws-dev-analog\analog",
  "workflows"
)
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path (Join-Path $Dest $d) | Out-Null }

function Copy-Part($srcRel, $destRel) {
  $s = Join-Path $Src $srcRel
  $d = Join-Path $Dest $destRel
  New-Item -ItemType Directory -Force -Path (Split-Path $d) | Out-Null
  Copy-Item $s $d -Force
  Write-Host "  $destRel"
}

function Backup-Copy($srcRel, $destRel) {
  $s = Join-Path $Src $srcRel
  $d = Join-Path $Dest $destRel
  New-Item -ItemType Directory -Force -Path (Split-Path $d) | Out-Null
  if (Test-Path $d) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $bak = "$d.bak.$stamp"
    Copy-Item $d $bak -Force
    Write-Host "  BACKED UP existing $destRel -> $(Split-Path $bak -Leaf)"
  }
  Copy-Item $s $d -Force
  Write-Host "  $destRel"
}

# settings.json is special: the factory OWNS only the hooks + routing keys. We rewrite the
# machine-specific tokens (interpreter + absolute hooks dir) in the template, then MERGE those
# keys into any existing settings.json so the user's model/theme/plugins/etc. survive a re-install.
function Install-Settings {
  $s = Join-Path $Src "settings.json"
  $d = Join-Path $Dest "settings.json"
  $hooksDir = (Join-Path $Dest "hooks") -replace '\\', '/'
  $tplText = (Get-Content $s -Raw -Encoding UTF8) -replace '__PYTHON__', 'py' -replace '__HOOKS_DIR__', $hooksDir
  $tpl = $tplText | ConvertFrom-Json

  if (Test-Path $d) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $d "$d.bak.$stamp" -Force
    Write-Host "  BACKED UP existing settings.json -> settings.json.bak.$stamp"
    $out = (Get-Content $d -Raw -Encoding UTF8) | ConvertFrom-Json
    foreach ($p in $tpl.PSObject.Properties) {
      $out | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
    }
    Write-Host "  settings.json (hooks + routing merged; other keys preserved)"
  } else {
    $out = $tpl
    Write-Host "  settings.json"
  }
  # Write UTF-8 WITHOUT BOM (PS 5.1 Set-Content -Encoding utf8 would add one).
  [System.IO.File]::WriteAllText($d, ($out | ConvertTo-Json -Depth 20), (New-Object System.Text.UTF8Encoding($false)))
}

Write-Host "core:"
Backup-Copy "CLAUDE.md" "CLAUDE.md"
Install-Settings
# stack.md accretes your real tech standard — never clobber a populated one; install template only if absent.
$stackDest = Join-Path $Dest "stack.md"
if (Test-Path $stackDest) {
  Write-Host "  KEPT existing stack.md (accreted standard — not overwritten)"
} else {
  Copy-Item (Join-Path $Src "stack.md") $stackDest -Force
  Write-Host "  stack.md"
}

Write-Host "skills:"
Copy-Part "new-line-SKILL.md"       "skills\new-line\SKILL.md"
Copy-Part "spec-interview-SKILL.md" "skills\spec-interview\SKILL.md"
Copy-Part "eval-scaffold-SKILL.md"  "skills\eval-scaffold\SKILL.md"
Copy-Part "add-stack-part-SKILL.md" "skills\add-stack-part\SKILL.md"
Copy-Part "as-built-SKILL.md"       "skills\as-built\SKILL.md"
Copy-Part "import-handoff-SKILL.md" "skills\import-handoff\SKILL.md"
Copy-Part "foreman-SKILL.md"        "skills\foreman\SKILL.md"
Copy-Part "program-scaffold-REFERENCE.md" "skills\foreman\program-scaffold-REFERENCE.md"

Write-Host "commands:"
Copy-Part "retro-COMMAND.md"   "commands\retro.md"
Copy-Part "promote-COMMAND.md" "commands\promote.md"
Copy-Part "submit-COMMAND.md"  "commands\submit.md"
Copy-Part "program-COMMAND.md" "commands\program.md"

Write-Host "hooks:"
Copy-Part "burn-detect.py" "hooks\burn-detect.py"
Copy-Part "cost-log.py"    "hooks\cost-log.py"
Copy-Part "cred-guard.py"  "hooks\cred-guard.py"
Copy-Part "loop-gate.py"   "hooks\loop-gate.py"

Write-Host "shapes\docker-analog:"
Copy-Part "shapes\docker-analog\README.md"          "shapes\docker-analog\README.md"
Copy-Part "shapes\docker-analog\docker-compose.yml" "shapes\docker-analog\docker-compose.yml"
Copy-Part "shapes\docker-analog\analog\apply.sh"    "shapes\docker-analog\analog\apply.sh"
Copy-Part "shapes\docker-analog\analog\teardown.sh" "shapes\docker-analog\analog\teardown.sh"

Write-Host "shapes\aws-dev-analog:"
Copy-Part "shapes\aws-dev-analog\README.md"           "shapes\aws-dev-analog\README.md"
Copy-Part "shapes\aws-dev-analog\analog\bootstrap.sh" "shapes\aws-dev-analog\analog\bootstrap.sh"
Copy-Part "shapes\aws-dev-analog\analog\teardown.sh"  "shapes\aws-dev-analog\analog\teardown.sh"

Write-Host "workflows:"
Copy-Part "workflows\deploy.yml" "workflows\deploy.yml"

$log = Join-Path $Dest "factory-log.jsonl"
if (-not (Test-Path $log)) { New-Item -ItemType File -Path $log | Out-Null }

Write-Host ""
Write-Host "Factory installed. Create the floor with:  New-Item -ItemType Directory -Force ~\prototypes"
Write-Host "Note: the analog scripts are bash (.sh) — run them under WSL or Git Bash. The factory"
Write-Host "skills/hooks/commands are OS-agnostic; only the Docker/AWS analog scripts assume a POSIX shell."
Write-Host "Hooks are wired with 'py' + absolute paths and merged into your settings.json (other keys kept)."
Write-Host "The settings.json 'routing' block is a documentation placeholder (not read by Claude Code); wire the IaC scanner in deploy.yml."
