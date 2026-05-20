$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }

$src = Get-Content $mainPath -Raw

# Fix the FieldbookHome page call. Do not use a global onOpenProducts check because HomeScreen also has one.
$oldCall = 'SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, onSave: saveSpray)'
$newCall = 'SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, onOpenProducts: () => setState(() => tab = 4), onSave: saveSpray)'
$src = $src.Replace($oldCall, $newCall)

$oldWeatherCall = 'SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, activeRecords: activeSprays, weather: weather, onSave: saveSpray)'
$newWeatherCall = 'SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, activeRecords: activeSprays, weather: weather, onOpenProducts: () => setState(() => tab = 4), onSave: saveSpray)'
$src = $src.Replace($oldWeatherCall, $newWeatherCall)

# Fix the constructor if the old form is still present.
$src = $src.Replace(
  'const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.onSave, super.key});',
  'const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.onOpenProducts, required this.onSave, super.key});'
)
$src = $src.Replace(
  'const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.activeRecords, required this.weather, required this.onSave, super.key});',
  'const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.activeRecords, required this.weather, required this.onOpenProducts, required this.onSave, super.key});'
)

# Add the field specifically inside SprayLogScreen, even if other widgets already have a field with the same name.
$sprayClassMatch = [regex]::Match($src, 'class SprayLogScreen extends StatefulWidget \{[\s\S]*?\r?\n\}')
if (-not $sprayClassMatch.Success) { throw 'Could not locate SprayLogScreen class.' }
$sprayClass = $sprayClassMatch.Value

if ($sprayClass -notmatch 'final VoidCallback onOpenProducts;') {
  $sprayClassFixed = [regex]::Replace($sprayClass, '(\r?\n\s*final List<SprayProduct> products;)', "`$1`r`n  final VoidCallback onOpenProducts;", 1)
  if ($sprayClassFixed -eq $sprayClass) { throw 'Could not insert onOpenProducts field inside SprayLogScreen.' }
  $src = $src.Remove($sprayClassMatch.Index, $sprayClassMatch.Length).Insert($sprayClassMatch.Index, $sprayClassFixed)
}

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
$sprayClassCheck = [regex]::Match($check, 'class SprayLogScreen extends StatefulWidget \{[\s\S]*?\r?\n\}').Value
if ($sprayClassCheck -notmatch 'final VoidCallback onOpenProducts;') { throw 'Repair failed: SprayLogScreen field missing.' }
if ($check -notmatch 'SprayLogScreen\(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, onOpenProducts: \(\) => setState\(\(\) => tab = 4\), onSave: saveSpray\)') { throw 'Repair failed: SprayLogScreen call site still missing onOpenProducts.' }
if ($check -notmatch 'widget\.onOpenProducts') { throw 'Repair failed: widget.onOpenProducts usage missing.' }

Write-Host 'Repaired SprayLogScreen onOpenProducts wiring.'
Write-Host 'Next: flutter analyze; flutter run'
