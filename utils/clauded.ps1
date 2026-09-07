#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$claudeCommand = Get-Command 'claude' -CommandType Application, ExternalScript -ErrorAction SilentlyContinue |
  Select-Object -First 1

if (-not $claudeCommand) {
  [Console]::Error.WriteLine('clauded.ps1: claude not found on PATH')
  exit 127
}

$env:CLAUDE_CODE_TMUX_TRUECOLOR = '1'
& $claudeCommand.Source '--chrome' '--dangerously-skip-permissions' @args
exit $LASTEXITCODE
