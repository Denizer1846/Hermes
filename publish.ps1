param(
    [string]$Destination = "C:\Projects\Hermes-Public"
)
$ErrorActionPreference = 'Stop'
$repo = 'Denizer1846/Hermes'
$origin = 'https://github.com/Denizer1846/Hermes.git'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required.'
}
$login = (& gh api user --jq '.login')
if ($LASTEXITCODE -ne 0 -or ($login.Trim() -ne 'Denizer1846')) {
    throw 'Select account Denizer1846 with: gh auth switch --user Denizer1846'
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is required.'
}

if (-not (Test-Path -LiteralPath (Join-Path $Destination '.git'))) {
    if ((Test-Path -LiteralPath $Destination) -and
        (Get-ChildItem -LiteralPath $Destination -Force | Select-Object -First 1)) {
        throw "Directory is not empty: $Destination"
    }
    & git clone $origin $Destination
    if ($LASTEXITCODE -ne 0) { throw 'Clone failed' }
}
$remote = & git -C $Destination remote get-url origin
if ($LASTEXITCODE -ne 0 -or
    ($remote.Trim() -notin @($origin, 'https://github.com/Denizer1846/Hermes', 'git@github.com:Denizer1846/Hermes.git'))) {
    throw "Unexpected remote: $remote"
}
& git -C $Destination pull --ff-only origin main
if ($LASTEXITCODE -ne 0) { throw 'Cannot fast-forward; check local changes' }

$paths = @('README.md', 'CHANGELOG.md', 'RELEASE_NOTES.md', 'assets', 'docs')
foreach ($item in $paths) {
    $from = Join-Path $PSScriptRoot $item
    $to = Join-Path $Destination $item
    if (Test-Path -LiteralPath $from -PathType Container) {
        New-Item -ItemType Directory -Path $to -Force | Out-Null
        Copy-Item -Path (Join-Path $from '*') -Destination $to -Force -Recurse
    }
    else {
        Copy-Item -LiteralPath $from -Destination $to -Force
    }
}
& git -C $Destination add -- README.md CHANGELOG.md RELEASE_NOTES.md assets docs
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
& git -C $Destination --no-pager diff --cached --stat
& git -C $Destination diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host 'No new public documentation changes.' -ForegroundColor Green
    exit 0
}
& git -C $Destination commit -m 'docs: оформлена публичная страница Гермеса'
if ($LASTEXITCODE -ne 0) { throw 'Commit failed' }
& git -C $Destination push origin main
if ($LASTEXITCODE -ne 0) { throw 'Push failed' }
Write-Host 'Public repository updated: https://github.com/Denizer1846/Hermes' -ForegroundColor Green
