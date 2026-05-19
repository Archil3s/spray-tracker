$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw

if ($src -notmatch 'void saveFeed') {
  throw 'saveFeed() was not found. Run apply-feeding-tracker.ps1 first.'
}

if ($src -notmatch 'class FeedRecord') {
  throw 'FeedRecord was not found. Run apply-feeding-tracker.ps1 first.'
}

if ($src -notmatch 'int nextFeedId = 1;') {
  $fieldPattern = '(\r?\n\s+late List<SprayProduct> products;)'
  if ($src -match $fieldPattern) {
    $src = [regex]::Replace($src, $fieldPattern, "`$1`r`n  int nextFeedId = 1;`r`n  List<FeedRecord> feedRecords = [];", 1)
  } else {
    $statePattern = '(class _FieldbookHomeState extends State<FieldbookHome> \{[\s\S]*?String sprayTarget = [^;]+;)'
    if ($src -match $statePattern) {
      $src = [regex]::Replace($src, $statePattern, "`$1`r`n  int nextFeedId = 1;`r`n  List<FeedRecord> feedRecords = [];", 1)
    } else {
      throw 'Could not find a safe insertion point for feedRecords.'
    }
  }
}

# Remove accidental duplicate field insertions if a user ran this more than once manually.
$src = [regex]::Replace($src, '(\r?\n\s*int nextFeedId = 1;\r?\n\s*List<FeedRecord> feedRecords = \[\];){2,}', "`r`n  int nextFeedId = 1;`r`n  List<FeedRecord> feedRecords = [];", 1)

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Repaired Feeding Tracker state fields.'
Write-Host 'Next: flutter analyze; flutter run'
