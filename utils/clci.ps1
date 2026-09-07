#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$usage = 'usage: clci.ps1 (-a|-s|-k) [-y] [-p] [-.] [-l|-m|-h|-x|-X] [-O|-F|-S|-H] [-f] [instructions...] [-- claude_args...]'

function Write-Usage {
  [Console]::Error.WriteLine($usage)
}

function Write-Help {
  @"
$usage

Flags:
  -a      Commit all changes (/commit --all).
  -s      Commit only staged changes (/commit --staged).
  -k      Ask interactively what to commit (/commit --ask).
  -y      Preconfirm the commit gate; valid only with -a or -s.
  -p      Push the branch after the commit lands (mode suffix -push).
  -.      Use /gdf-commit instead of /commit.
  -l      Use low model reasoning effort.
  -m      Use medium model reasoning effort.
  -h      Use high model reasoning effort (default).
  -x      Use xhigh model reasoning effort.
  -X      Use max model reasoning effort.
  -O      Use the Opus model (default).
  -F      Use the Fable model.
  -S      Use the Sonnet model.
  -H      Use the Haiku model.
  -f      Use fast mode; valid only with the Opus model.
  --      Pass all remaining arguments directly to claude.
  --help  Show this help.

Bare (non-flag) arguments are appended to the commit command as additional
instructions, e.g. ``clci.ps1 -a use imperative mood``.
"@
}

$mode = $null
$commitCommand = 'commit'
$effort = 'high'
$effortSet = $false
$model = 'opus'
$modelSet = $false
$fast = $false
$preconfirmed = $false
$push = $false
$instructions = @()
$claudeArgs = @()
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
    '-X' {
      if ($effortSet) { Write-Usage; exit 2 }
      $effort = 'max'
      $effortSet = $true
    }
    '-O' {
      if ($modelSet) { Write-Usage; exit 2 }
      $model = 'opus'
      $modelSet = $true
    }
    '-F' {
      if ($modelSet) { Write-Usage; exit 2 }
      $model = 'fable'
      $modelSet = $true
    }
    '-S' {
      if ($modelSet) { Write-Usage; exit 2 }
      $model = 'sonnet'
      $modelSet = $true
    }
    '-H' {
      if ($modelSet) { Write-Usage; exit 2 }
      $model = 'haiku'
      $modelSet = $true
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
        $claudeArgs = @($inputArgs[($i + 1)..($inputArgs.Count - 1)])
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

$settings = '{"autoMemoryEnabled":false}'
if ($fast) {
  if ($model -ne 'opus') {
    Write-Usage
    exit 2
  }
  $settings = '{"autoMemoryEnabled":false,"fastMode":true}'
}

$prompt = "/$commitCommand --$mode"
if ($instructions.Count -gt 0) {
  $prompt += ' ' + ($instructions -join ' ')
}

$launchArgs = @(
  '--strict-mcp-config'
  '--model'
  $model
  '--effort'
  $effort
  '--settings'
  $settings
  $prompt
)
$launchArgs += $claudeArgs

$claudeLauncher = if ($env:CLCI_CLAUDE_BIN) { $env:CLCI_CLAUDE_BIN } else { 'clauded.ps1' }
& $claudeLauncher @launchArgs
exit $LASTEXITCODE
