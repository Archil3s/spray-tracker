$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }

Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))

Write-Host 'Adding shared_preferences package if needed...'
if (-not (Select-String -Path '.\pubspec.yaml' -Pattern 'shared_preferences:' -Quiet)) {
  flutter pub add shared_preferences
}

$src = Get-Content $mainPath -Raw

if ($src -notmatch "package:shared_preferences/shared_preferences.dart") {
  $src = $src.Replace("import 'package:url_launcher/url_launcher.dart';", "import 'package:url_launcher/url_launcher.dart';`r`nimport 'package:shared_preferences/shared_preferences.dart';")
}

if ($src -notmatch "const localStoreKey = 'fieldbook_local_state_v1';") {
  $src = $src.Replace("extension FirstOrNull<T> on Iterable<T> {", "const localStoreKey = 'fieldbook_local_state_v1';`r`n`r`nextension FirstOrNull<T> on Iterable<T> {")
}

$methods = @'

  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(localStoreKey);
    if (raw == null || raw.isEmpty) {
      resetToDemoData(silent: true, persist: false);
      return;
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      bedCrops.clear();
      final savedBeds = (data['bedCrops'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      for (final entry in savedBeds.entries) {
        final bed = int.tryParse(entry.key);
        final cropIds = (entry.value as List? ?? const []).whereType<String>().toList();
        if (bed != null) bedCrops[bed] = cropIds.map(vegetableById).toList();
      }

      products = ((data['products'] as List?) ?? const []).whereType<Map>().map((item) {
        final map = item.cast<String, dynamic>();
        return SprayProduct(id: (map['id'] as num?)?.toInt() ?? 0, name: '${map['name'] ?? ''}', type: '${map['type'] ?? ''}', days: (map['days'] as num?)?.toInt() ?? 0, targets: (map['targets'] as List? ?? const []).whereType<String>().toList());
      }).where((product) => product.name.isNotEmpty).toList();
      if (products.isEmpty) products = defaultProducts();

      sprayRecords = ((data['sprayRecords'] as List?) ?? const []).whereType<Map>().map((item) {
        final map = item.cast<String, dynamic>();
        return SprayRecord(
          id: (map['id'] as num?)?.toInt() ?? 0,
          beds: (map['beds'] as List? ?? const []).whereType<num>().map((n) => n.toInt()).toList(),
          crops: (map['crops'] as List? ?? const []).whereType<String>().toList(),
          targetId: '${map['targetId'] ?? 'pest'}',
          product: '${map['product'] ?? ''}',
          reason: '${map['reason'] ?? ''}',
          notes: '${map['notes'] ?? ''}',
          date: DateTime.tryParse('${map['date'] ?? ''}') ?? DateTime.now(),
          days: (map['days'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      feedRecords = ((data['feedRecords'] as List?) ?? const []).whereType<Map>().map((item) {
        final map = item.cast<String, dynamic>();
        return FeedRecord(
          id: (map['id'] as num?)?.toInt() ?? 0,
          beds: (map['beds'] as List? ?? const []).whereType<num>().map((n) => n.toInt()).toList(),
          product: '${map['product'] ?? ''}',
          method: '${map['method'] ?? ''}',
          note: '${map['note'] ?? ''}',
          date: DateTime.tryParse('${map['date'] ?? ''}') ?? DateTime.now(),
        );
      }).toList();

      nextRecordId = (data['nextRecordId'] as num?)?.toInt() ?? (sprayRecords.length + 1);
      nextFeedId = (data['nextFeedId'] as num?)?.toInt() ?? (feedRecords.length + 1);
      nextProductId = (data['nextProductId'] as num?)?.toInt() ?? (products.length + 1);
      selectedBed = (data['selectedBed'] as num?)?.toInt() ?? selectedBed;
      sprayTarget = '${data['sprayTarget'] ?? sprayTarget}';
      sprayBeds = ((data['sprayBeds'] as List?) ?? const [4]).whereType<num>().map((n) => n.toInt()).toSet();
      sprayCrops = ((data['sprayCrops'] as List?) ?? const ['Whole bed']).whereType<String>().toSet();
      message = 'Loaded saved local data';
      if (mounted) setState(() {});
    } catch (_) {
      resetToDemoData(silent: true, persist: false);
    }
  }

  Future<void> saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'nextRecordId': nextRecordId,
      'nextFeedId': nextFeedId,
      'nextProductId': nextProductId,
      'selectedBed': selectedBed,
      'sprayTarget': sprayTarget,
      'sprayBeds': sprayBeds.toList(),
      'sprayCrops': sprayCrops.toList(),
      'bedCrops': bedCrops.map((bed, crops) => MapEntry('$bed', crops.map((crop) => crop.id).toList())),
      'products': products.map((product) => {'id': product.id, 'name': product.name, 'type': product.type, 'days': product.days, 'targets': product.targets}).toList(),
      'sprayRecords': sprayRecords.map((record) => {'id': record.id, 'beds': record.beds, 'crops': record.crops, 'targetId': record.targetId, 'product': record.product, 'reason': record.reason, 'notes': record.notes, 'date': record.date.toIso8601String(), 'days': record.days}).toList(),
      'feedRecords': feedRecords.map((record) => {'id': record.id, 'beds': record.beds, 'product': record.product, 'method': record.method, 'note': record.note, 'date': record.date.toIso8601String()}).toList(),
    };
    await prefs.setString(localStoreKey, jsonEncode(data));
  }

  Future<void> clearLocalDataStore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(localStoreKey);
  }
'@

if ($src -notmatch 'Future<void> loadLocalData') {
  $src = $src.Replace('  DateTime ago(int days) {', $methods + "`r`n`r`n  DateTime ago(int days) {")
}

$src = $src.Replace('    products = defaultProducts();`r`n    resetToDemoData(silent: true);`r`n    fetchLiveWeather();', '    products = defaultProducts();`r`n    loadLocalData();`r`n    fetchLiveWeather();')

# Patch reset signature and persistence calls.
$src = $src.Replace('void resetToDemoData({bool silent = false}) {', 'void resetToDemoData({bool silent = false, bool persist = true}) {')
$src = $src.Replace('      tab = 0;`r`n    }`r`n    if (silent) {`r`n      run();`r`n    } else {`r`n      setState(run);`r`n    }', '      tab = 0;`r`n    }`r`n    if (silent) {`r`n      run();`r`n      if (persist) saveLocalData();`r`n    } else {`r`n      setState(run);`r`n      if (persist) saveLocalData();`r`n    }')

# Add saveLocalData after common state mutations.
$src = $src.Replace("        message = 'All test data cleared';`r`n        tab = 0;`r`n      });", "        message = 'All test data cleared';`r`n        tab = 0;`r`n        clearLocalDataStore();`r`n      });")
$src = $src.Replace("        message = '${crop.name} added to Bed $bed';`r`n      });", "        message = '${crop.name} added to Bed $bed';`r`n        saveLocalData();`r`n      });")
$src = $src.Replace("        message = '${crop.name} removed from Bed $bed';`r`n      });", "        message = '${crop.name} removed from Bed $bed';`r`n        saveLocalData();`r`n      });")
$src = $src.Replace("      tab = 1;`r`n    });`r`n  }`r`n`r`n  void saveFeed", "      tab = 1;`r`n      saveLocalData();`r`n    });`r`n  }`r`n`r`n  void saveFeed")
$src = $src.Replace("      tab = 1;`r`n    });`r`n  }`r`n`r`n  void addProduct", "      tab = 1;`r`n      saveLocalData();`r`n    });`r`n  }`r`n`r`n  void addProduct")
$src = $src.Replace("        message = '$name added';`r`n      });", "        message = '$name added';`r`n        saveLocalData();`r`n      });")
$src = $src.Replace("        message = 'Product removed';`r`n      });", "        message = 'Product removed';`r`n        saveLocalData();`r`n      });")

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('loadLocalData', 'saveLocalData', 'shared_preferences', 'fieldbook_local_state_v1')) {
  if ($check -notmatch $marker) { throw "Missing persistence marker: $marker" }
}
Write-Host 'Applied local save/load persistence.'
Write-Host 'Data saved locally: beds, crops, sprays, feeds, products, selected spray setup.'
Write-Host 'Next: flutter pub get; flutter analyze; flutter run'
