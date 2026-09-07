#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$agyCommand = Get-Command 'agy' -CommandType Application, ExternalScript -ErrorAction SilentlyContinue |
  Select-Object -First 1

if (-not $agyCommand) {
  [Console]::Error.WriteLine('agyd.ps1: agy not found on PATH')
  exit 127
}

& $agyCommand.Source '--dangerously-skip-permissions' @args
exit $LASTEXITCODE
