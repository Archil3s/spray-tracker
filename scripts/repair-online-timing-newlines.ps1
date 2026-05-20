$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }

$src = Get-Content $mainPath -Raw

# Repair literal PowerShell escape text that was accidentally written into Dart.
$src = $src.Replace(',`r`n        const SizedBox(height: 14),`r`n        SprayAdvisorCard', ",`r`n        const SizedBox(height: 14),`r`n        SprayAdvisorCard")
$src = $src.Replace('`r`n', "`r`n")

# Ensure the Online Timing Advisor card is correctly inserted only once above SprayAdvisorCard.
$badInline = 'OnlineTimingAdvisorCard(advice: onlineTiming, onPlanSpray: onPlanSpray, onLogFeed: onLogFeed),        const SizedBox(height: 14),        SprayAdvisorCard'
if ($src.Contains($badInline)) {
  $src = $src.Replace($badInline, "OnlineTimingAdvisorCard(advice: onlineTiming, onPlanSpray: onPlanSpray, onLogFeed: onLogFeed),`r`n        const SizedBox(height: 14),`r`n        SprayAdvisorCard")
}

# If previous replacement produced duplicate timing cards, keep the first and remove immediate duplicates.
$duplicate = "OnlineTimingAdvisorCard(advice: onlineTiming, onPlanSpray: onPlanSpray, onLogFeed: onLogFeed),`r`n        const SizedBox(height: 14),`r`n        OnlineTimingAdvisorCard(advice: onlineTiming, onPlanSpray: onPlanSpray, onLogFeed: onLogFeed),"
if ($src.Contains($duplicate)) {
  $src = $src.Replace($duplicate, "OnlineTimingAdvisorCard(advice: onlineTiming, onPlanSpray: onPlanSpray, onLogFeed: onLogFeed),")
}

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
if ($check -match '`r`n') { throw 'Repair failed: literal `r`n still exists in lib/main.dart.' }
if ($check -notmatch 'OnlineTimingAdvisorCard') { throw 'Repair failed: OnlineTimingAdvisorCard missing.' }
if ($check -notmatch 'SprayAdvisorCard') { throw 'Repair failed: SprayAdvisorCard missing.' }

Write-Host 'Repaired Online Timing Advisor newline issue.'
Write-Host 'Next: flutter analyze; flutter run'
