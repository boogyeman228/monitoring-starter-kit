<#
.SYNOPSIS
  Append an HTTP(S) URL to targets/http.yml.
.EXAMPLE
  .\scripts\add-target.ps1 https://example.com
.NOTES
  Prometheus picks the change up within ~1 minute (file-based service discovery).
  Works on Windows PowerShell 5.1 and PowerShell 7+.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Url
)

$ErrorActionPreference = 'Stop'

if ($Url -notmatch '^https?://[^\s''"]+$') {
    throw "Invalid URL '$Url'. It must start with http:// or https:// and contain no spaces or quotes."
}

$file = Join-Path (Split-Path -Parent $PSScriptRoot) 'targets/http.yml'
$utf8 = New-Object System.Text.UTF8Encoding($false)   # UTF-8 without BOM
$existing = ''
if (Test-Path $file) { $existing = [System.IO.File]::ReadAllText($file) }

if ($existing.Contains("'$Url'")) {
    Write-Host "Already present: $Url"
    return
}

$prefix = ''
if ($existing.Length -gt 0 -and -not $existing.EndsWith("`n")) { $prefix = "`n" }
[System.IO.File]::AppendAllText($file, "$prefix- targets: ['$Url']`n", $utf8)

Write-Host "Added: $Url  ->  $file"
Write-Host 'Prometheus reloads targets automatically within ~1 minute.'
