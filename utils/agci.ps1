#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$usage = 'usage: agci.ps1 (-a|-s|-k) [-y] [-p] [-.] [-l|-m|-h] [instructions...] [-- agy_args...]'

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
  -l      Use low reasoning effort.
  -m      Use medium reasoning effort (default).
  -h      Use high reasoning effort.
  --      Pass all remaining arguments directly to agy.
  --help  Show this help.

Bare (non-flag) arguments are appended to the commit skill arguments as additional
instructions, e.g. ``agci.ps1 -a use imperative mood``.
"@
}

$mode = $null
$skill = 'commit'
$preconfirmed = $false
$push = $false
$effort = 'medium'
$effortSet = $false
$instructions = @()
$agyArgs = @()
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
      if ($effortSet) { Write-Usage; exit 2 }
      $effort = 'low'
      $effortSet = $true
    }
    '-m' {
      if ($effortSet) { Write-Usage; exit 2 }
      $effort = 'medium'
      $effortSet = $true
    }
    '-h' {
      if ($effortSet) { Write-Usage; exit 2 }
      $effort = 'high'
      $effortSet = $true
    }
    '--help' {
      Write-Help
      exit 0
    }
    '--' {
      if ($i + 1 -lt $inputArgs.Count) {
        $agyArgs = @($inputArgs[($i + 1)..($inputArgs.Count - 1)])
      }
      $i = $inputArgs.Count
    }
    default {
      if ($arg.StartsWith('-')) {
        Write-Usage
        exit 2
      }
      $instructions += $arg
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

$launchArgs = @(
  '--dangerously-skip-permissions'
  '--add-dir'
  (Get-Location).Path
  '--prompt-interactive'
  "use the '$skill' skill with arguments $commitToolArguments"
  '--effort'
  $effort
)
$launchArgs += $agyArgs

$agyLauncher = if ($env:AGCI_AGY_BIN) { $env:AGCI_AGY_BIN } else { 'agyd.ps1' }
& $agyLauncher @launchArgs
exit $LASTEXITCODE
