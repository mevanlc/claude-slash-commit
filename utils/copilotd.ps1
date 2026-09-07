#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$copilotCommand = Get-Command 'copilot' -CommandType Application, ExternalScript -ErrorAction SilentlyContinue |
  Select-Object -First 1

if (-not $copilotCommand) {
  [Console]::Error.WriteLine('copilotd.ps1: copilot not found on PATH')
  exit 127
}

& $copilotCommand.Source '--yolo' @args
exit $LASTEXITCODE
