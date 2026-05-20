$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }

$src = Get-Content $mainPath -Raw

# 1) Make sure the HomeScreen call site passes the new reports.
$src = $src.Replace(
  'feedingAdvisor: feedingAdvisor, message: message,',
  'feedingAdvisor: feedingAdvisor, autoAction: autoAction, frostMeter: frostMeter, message: message,'
)
$src = $src.Replace(
  'feedingAdvisor: feedingAdvisor, onlineTiming: onlineTiming, message: message,',
  'feedingAdvisor: feedingAdvisor, onlineTiming: onlineTiming, autoAction: autoAction, frostMeter: frostMeter, message: message,'
)

# Avoid duplicated named args if the script is run more than once.
$src = $src.Replace(
  'autoAction: autoAction, frostMeter: frostMeter, autoAction: autoAction, frostMeter: frostMeter,',
  'autoAction: autoAction, frostMeter: frostMeter,'
)

# 2) Make sure the HomeScreen constructor initializes the final fields.
$src = $src.Replace(
  'required this.feedingAdvisor, required this.message,',
  'required this.feedingAdvisor, required this.autoAction, required this.frostMeter, required this.message,'
)
$src = $src.Replace(
  'required this.feedingAdvisor, required this.onlineTiming, required this.message,',
  'required this.feedingAdvisor, required this.onlineTiming, required this.autoAction, required this.frostMeter, required this.message,'
)

# Avoid duplicated constructor params if the script is run more than once.
$src = $src.Replace(
  'required this.autoAction, required this.frostMeter, required this.autoAction, required this.frostMeter,',
  'required this.autoAction, required this.frostMeter,'
)

# 3) If fields were not inserted, add them after feedingAdvisor.
if ($src -notmatch 'final AutomaticActionReport autoAction;') {
  $src = $src.Replace(
    '  final FeedingAdvisorReport feedingAdvisor;',
    "  final FeedingAdvisorReport feedingAdvisor;`r`n  final AutomaticActionReport autoAction;`r`n  final FrostMeterReport frostMeter;"
  )
}

# Avoid duplicated field declarations if re-run.
$src = [regex]::Replace($src, '(  final AutomaticActionReport autoAction;\r?\n  final FrostMeterReport frostMeter;\r?\n)+', "  final AutomaticActionReport autoAction;`r`n  final FrostMeterReport frostMeter;`r`n")

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
if ($check -notmatch 'required this.autoAction') { throw 'Repair failed: HomeScreen constructor still missing required this.autoAction.' }
if ($check -notmatch 'required this.frostMeter') { throw 'Repair failed: HomeScreen constructor still missing required this.frostMeter.' }
if ($check -notmatch 'autoAction: autoAction') { throw 'Repair failed: HomeScreen call site still missing autoAction: autoAction.' }
if ($check -notmatch 'frostMeter: frostMeter') { throw 'Repair failed: HomeScreen call site still missing frostMeter: frostMeter.' }
if ($check -notmatch 'final AutomaticActionReport autoAction;') { throw 'Repair failed: autoAction field missing.' }
if ($check -notmatch 'final FrostMeterReport frostMeter;') { throw 'Repair failed: frostMeter field missing.' }

Write-Host 'Repaired HomeScreen autoAction/frostMeter constructor wiring.'
Write-Host 'Next: flutter analyze; flutter run'
