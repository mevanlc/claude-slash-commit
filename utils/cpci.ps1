#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$usage = 'usage: cpci.ps1 (-a|-s|-k) [-y] [-p] [-.] [-l|-m|-h|-x] [--model=<model>] [instructions...] [-- copilot_args...]'

function Write-Usage {
  [Console]::Error.WriteLine($usage)
}

function Write-Help {
  @"
$usage

Flags:
  -a      Commit all changes (use the 'commit' skill with arguments --all).
  -s      Commit only staged changes (use the 'commit' skill with arguments --staged).
  -k      Ask interactively what to commit (use the 'commit' skill with arguments --ask).
  -y      Preconfirm the commit gate; valid only with -a or -s.
  -p      Push the branch after the commit lands (mode suffix -push).
  -.      Use the 'gdf-commit' skill instead of 'commit'.
  -l      Use low reasoning effort; repeat for minimal, or three times for none.
  -m      Use medium reasoning effort.
  -h      Use high reasoning effort.
  -x      Use xhigh reasoning effort; repeat for max.
  --model=<model>
          Select the Copilot model (default: gpt-5.6-terra).
  --      Pass all remaining arguments directly to copilot.
  --help  Show this help.

Bare (non-flag) arguments are appended to the commit skill arguments as additional
instructions, e.g. ``cpci.ps1 -a use imperative mood``.
"@
}

$mode = $null
$skill = 'commit'
$preconfirmed = $false
$push = $false
$effort = $null
$effortFlag = $null
$effortCount = 0
$model = 'gpt-5.6-terra'
$instructions = @()
$copilotArgs = @()
[string[]]$inputArgs = @($args)

for ($i = 0; $i -lt $inputArgs.Count; $i++) {
  $arg = $inputArgs[$i]

  switch -CaseSensitive ($arg) {
    '-a' {
      if ($mode) { Write-Usage; exit 2 }
      $mode = 'all'
    }
    '-s' {
      if ($mode) { Write-Usage; exit 2 }
      $mode = 'staged'
    }
    '-k' {
      if ($mode) { Write-Usage; exit 2 }
      $mode = 'ask'
    }
    '-.' { $skill = 'gdf-commit' }
    '-y' { $preconfirmed = $true }
    '-p' { $push = $true }
    '-l' {
      if ($effortFlag -and $effortFlag -ne 'l') {
        Write-Usage
        exit 2
      }
      $effortFlag = 'l'
      $effortCount++
      switch ($effortCount) {
        1 { $effort = 'low' }
        2 { $effort = 'minimal' }
        3 { $effort = 'none' }
        default { Write-Usage; exit 2 }
      }
    }
    '-m' {
      if ($effortFlag) { Write-Usage; exit 2 }
      $effortFlag = 'm'
      $effort = 'medium'
    }
    '-h' {
      if ($effortFlag) { Write-Usage; exit 2 }
      $effortFlag = 'h'
      $effort = 'high'
    }
    '-x' {
      if ($effortFlag -and $effortFlag -ne 'x') {
        Write-Usage
        exit 2
      }
      $effortFlag = 'x'
      $effortCount++
      switch ($effortCount) {
        1 { $effort = 'xhigh' }
        2 { $effort = 'max' }
        default { Write-Usage; exit 2 }
      }
    }
    '--help' {
      Write-Help
      exit 0
    }
    '--' {
      if ($i + 1 -lt $inputArgs.Count) {
        $copilotArgs = @($inputArgs[($i + 1)..($inputArgs.Count - 1)])
      }
      $i = $inputArgs.Count
    }
    default {
      if ($arg.StartsWith('--model=')) {
        $model = $arg.Substring('--model='.Length)
        if (-not $model) {
          Write-Usage
          exit 2
        }
      } elseif ($arg.StartsWith('-')) {
        Write-Usage
        exit 2
      } else {
        $instructions += $arg
      }
    }
  }
}

if (-not $mode) {
  Write-Usage
  exit 2
}

if ($preconfirmed) {
  if ($mode -eq 'ask') {
    Write-Usage
    exit 2
  }
  $mode += '-yes'
}

if ($push) {
  $mode += '-push'
}

$commitToolArguments = "--$mode"
if ($instructions.Count -gt 0) {
  $commitToolArguments += ' ' + ($instructions -join ' ')
}

$launchArgs = @('--yolo', "--model=$model")
if ($effort) {
  $launchArgs += @('--effort', $effort)
}
$launchArgs += @('-i', "use the '$skill' skill with arguments $commitToolArguments")
$launchArgs += $copilotArgs

$copilotLauncher = if ($env:CPCI_COPILOT_BIN) { $env:CPCI_COPILOT_BIN } else { 'copilotd.ps1' }
& $copilotLauncher @launchArgs
exit $LASTEXITCODE
