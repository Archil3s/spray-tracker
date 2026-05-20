$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

# Add a clean empty-start method that leaves default products available but clears beds/logs/holds.
$emptyMethod = @'

  void startWithEmptyGarden({bool silent = false}) {
    void run() {
      bedCrops.clear();
      sprayRecords.clear();
      feedRecords.clear();
      nextRecordId = 1;
      nextFeedId = 1;
      nextProductId = 5;
      selectedBed = 1;
      sprayBeds = {1};
      sprayCrops = {'Whole bed'};
      sprayTarget = 'pest';
      products = defaultProducts();
      message = 'Empty garden ready';
      tab = 0;
    }

    if (silent) {
      run();
    } else {
      setState(run);
    }
  }
'@

if ($src -notmatch 'void startWithEmptyGarden') {
  $src = $src.Replace('  void seedDemoData() {', $emptyMethod + "`r`n`r`n  void seedDemoData() {")
}

# Fresh app launch should be empty, not demo seeded.
$src = $src.Replace('    products = defaultProducts();`r`n    resetToDemoData(silent: true);`r`n    fetchLiveWeather();', '    products = defaultProducts();`r`n    startWithEmptyGarden(silent: true);`r`n    fetchLiveWeather();')
$src = $src.Replace('    products = defaultProducts();`n    resetToDemoData(silent: true);`n    fetchLiveWeather();', '    products = defaultProducts();`n    startWithEmptyGarden(silent: true);`n    fetchLiveWeather();')

# If local persistence has been applied locally, disable auto-load on fresh build and clear stored state at startup.
$src = $src.Replace('    products = defaultProducts();`r`n    loadLocalData();`r`n    fetchLiveWeather();', '    products = defaultProducts();`r`n    startWithEmptyGarden(silent: true);`r`n    clearLocalDataStore();`r`n    fetchLiveWeather();')
$src = $src.Replace('    products = defaultProducts();`n    loadLocalData();`n    fetchLiveWeather();', '    products = defaultProducts();`n    startWithEmptyGarden(silent: true);`n    clearLocalDataStore();`n    fetchLiveWeather();')

# Make clear-all leave default products available so app is blank but still usable.
$src = $src.Replace('        products.clear();', '        products = defaultProducts();')
$src = $src.Replace("        message = 'All test data cleared';", "        message = 'Empty garden ready';")

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('startWithEmptyGarden', 'Empty garden ready', 'bedCrops.clear()', 'sprayRecords.clear()', 'feedRecords.clear()')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing empty startup marker: $marker" }
}
if ($check -match 'resetToDemoData\(silent: true\);') { throw 'Startup still calls resetToDemoData(silent: true).' }
if ($check -match 'loadLocalData\(\);') { throw 'Startup still calls loadLocalData(); fresh build may restore old data.' }

Write-Host 'Applied empty startup state.'
Write-Host 'Fresh build starts with no plants, no spray records, no feed records and no harvest holds.'
Write-Host 'Default products are kept so the app remains usable.'
Write-Host 'Next: flutter analyze; flutter run'
