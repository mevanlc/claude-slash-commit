#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$codexArgs = @()
$noMcp = $false

foreach ($arg in $args) {
  if ($arg -ceq '--x-no-mcp') {
    $noMcp = $true
  } else {
    $codexArgs += $arg
  }
}

$codexCommand = Get-Command 'codex' -CommandType Application, ExternalScript -ErrorAction SilentlyContinue |
  Select-Object -First 1

if (-not $codexCommand) {
  [Console]::Error.WriteLine('codexd.ps1: codex not found on PATH')
  exit 127
}

$commandArgs = @('--yolo', '--config', 'tui.notifications=false')

if ($noMcp) {
  $commandArgs += @('--disable', 'plugins')
  $mcpLines = @(& $codexCommand.Source '--disable' 'plugins' 'mcp' 'list')

  foreach ($line in $mcpLines) {
    $trimmed = ([string]$line).Trim()
    if (-not $trimmed) {
      continue
    }

    $serverName = ($trimmed -split '\s+')[0]
    if ($serverName -cne 'Name') {
      $commandArgs += @('-c', "mcp_servers.$serverName.enabled=false")
    }
  }
}

$commandArgs += $codexArgs
$env:RUST_BACKTRACE = '1'
& $codexCommand.Source @commandArgs
exit $LASTEXITCODE
