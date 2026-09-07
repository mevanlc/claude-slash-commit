#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$usage = 'usage: cxci.ps1 (-a|-s|-k) [-y] [-p] [-.] [-c] [-l|-m|-h|-x] [-f] [instructions...] [-- codexd_args...]'

function Write-Usage {
  [Console]::Error.WriteLine($usage)
}

function Write-Help {
  @"
$usage

Flags:
  -a      Commit all changes (`$commit --all).
  -s      Commit only staged changes (`$commit --staged).
  -k      Ask interactively what to commit (`$commit --ask).
  -y      Preconfirm the commit gate; valid only with -a or -s.
  -p      Push the branch after the commit lands (mode suffix -push).
  -.      Use `$gdf-commit instead of `$commit.
  -c      Use gpt-5.3-codex-spark (default effort: xhigh).
  -l      Use low model reasoning effort.
  -m      Use medium model reasoning effort (default).
  -h      Use high model reasoning effort.
  -x      Use xhigh model reasoning effort.
  -f      Use the fast service tier.
  --      Pass all remaining arguments directly to codexd.
  --help  Show this help.

Bare (non-flag) arguments are appended to the commit command as additional
instructions, e.g. ``cxci.ps1 -a use imperative mood``.
"@
}

$mode = $null
$commitCommand = 'commit'
$model = 'gpt-5.6-sol'
$effort = 'medium'
$effortSet = $false
$fast = $false
$preconfirmed = $false
$push = $false
$instructions = @()
$codexArgs = @()
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
    '-.' { $commitCommand = 'gdf-commit' }
    '-c' {
      $model = 'gpt-5.3-codex-spark'
      if (-not $effortSet) {
        $effort = 'xhigh'
      }
    }
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
    '-x' {
      if ($effortSet) { Write-Usage; exit 2 }
      $effort = 'xhigh'
      $effortSet = $true
    }
    '-f' { $fast = $true }
    '-y' { $preconfirmed = $true }
    '-p' { $push = $true }
    '--help' {
      Write-Help
      exit 0
    }
    '--' {
      if ($i + 1 -lt $inputArgs.Count) {
        $codexArgs = @($inputArgs[($i + 1)..($inputArgs.Count - 1)])
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

$prompt = '$' + $commitCommand + " --$mode"
if ($instructions.Count -gt 0) {
  $prompt += ' ' + ($instructions -join ' ')
}

$launchArgs = @(
  '--x-no-mcp'
  '-m'
  $model
  '-c'
  "model_reasoning_effort=$effort"
  '--disable'
  'memories'
)
if ($fast) {
  $launchArgs += @('-c', 'service_tier=fast')
}
$launchArgs += $prompt
$launchArgs += $codexArgs

$codexLauncher = if ($env:CXCIA_CODEX_BIN) { $env:CXCIA_CODEX_BIN } else { 'codexd.ps1' }
& $codexLauncher @launchArgs
exit $LASTEXITCODE
