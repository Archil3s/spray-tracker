$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
$gardenTodayScript = Join-Path $PSScriptRoot 'apply-garden-today.ps1'

if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw
if ($src -notmatch 'class GardenTodayReport') {
  if (-not (Test-Path $gardenTodayScript)) {
    throw 'Garden Today script is missing. Run git pull origin main first.'
  }
  & $gardenTodayScript
  $src = Get-Content $mainPath -Raw
}

$helperBlock = @'
String daysLabel(int days) => '$days ${days == 1 ? 'day' : 'days'}';
DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String southernSeason(DateTime date) {
  final month = date.month;
  if (month == 12 || month <= 2) return 'summer';
  if (month >= 3 && month <= 5) return 'autumn';
  if (month >= 6 && month <= 8) return 'winter';
  return 'spring';
}

String pluralCropName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('cucumber')) return 'cucumbers';
  if (lower.endsWith('s')) return lower;
  return '${lower}s';
}

bool hasDiseasePressureRisk(VegetableDefinition crop) => crop.commonDiseases.any((disease) {
      final d = disease.toLowerCase();
      return d.contains('mildew') || d.contains('blight') || d.contains('rust') || d.contains('rot') || d.contains('leaf spot');
    });

bool isWarmSeasonCrop(VegetableDefinition crop) => const {
      'tomato',
      'capsicum',
      'chilli',
      'eggplant',
      'potato',
      'cucumber',
      'zucchini',
      'pumpkin',
      'melon',
      'sweetcorn',
      'okra',
      'kumara',
    }.contains(crop.id);

bool isCropInAucklandSeason(VegetableDefinition crop, DateTime now) {
  final season = southernSeason(now);
  if (isWarmSeasonCrop(crop)) return season == 'spring' || season == 'summer';
  if (crop.familyId == 'brassicas' || crop.familyId == 'leafy_greens' || crop.familyId == 'root_vegetables' || crop.familyId == 'alliums' || crop.familyId == 'apiaceae') {
    return season == 'autumn' || season == 'winter' || season == 'spring';
  }
  if (crop.familyId == 'legumes') return season == 'autumn' || season == 'spring' || crop.id == 'broad_beans';
  return true;
}

String seasonalPlantingLine(DateTime now) {
  final season = southernSeason(now);
  if (season == 'autumn') return 'In season now: brassicas, leafy greens, peas, roots and alliums';
  if (season == 'winter') return 'In season now: brassicas, leafy greens, broad beans, peas and alliums';
  if (season == 'spring') return 'In season soon: tomatoes, chillies, cucurbits, beans, corn and herbs';
  return 'In season now: tomatoes, chillies, cucumbers, zucchini, beans and corn';
}

String seasonalDiseaseTarget(List<VegetableDefinition> crops, DateTime now) {
  final inSeason = crops.where((crop) => isCropInAucklandSeason(crop, now)).where(hasDiseasePressureRisk).toList();
  final families = inSeason.map((crop) => crop.familyId).toSet();

  if (families.contains('brassicas') && families.contains('leafy_greens')) return 'brassicas and leafy greens';
  if (families.contains('brassicas')) return 'brassicas';
  if (families.contains('leafy_greens')) return 'leafy greens';
  if (families.contains('alliums')) return 'alliums';
  if (families.contains('root_vegetables')) return 'root crops';
  if (families.contains('legumes')) return 'peas and beans';

  final first = inSeason.firstOrNull;
  if (first != null) return pluralCropName(first.name);

  final fallback = crops.where((crop) => !isWarmSeasonCrop(crop)).firstOrNull;
  if (fallback != null) return pluralCropName(fallback.name);

  return 'cool-season beds';
}

String offSeasonNote(DateTime now) {
  final season = southernSeason(now);
  if (season == 'autumn' || season == 'winter') return 'Warm-season crops like cucumbers are ignored unless you mark them as actively planted.';
  return 'Cool-season crops are watched, but warm-season disease pressure is prioritised.';
}

GardenTodayReport buildGardenTodayReport({required Map<int, List<VegetableDefinition>> bedCrops, required List<SprayRecord> activeRecords, required GardenWeatherSnapshot weather, required DateTime now, String source = 'Using local garden records + forecast placeholder'}) {
  final allCrops = bedCrops.values.expand((crops) => crops).toList();
  final seasonalTarget = seasonalDiseaseTarget(allCrops, now);

  final bedFourRecord = activeRecords.where((record) => record.beds.contains(4)).firstOrNull ?? activeRecords.firstOrNull;
  final remainingDays = bedFourRecord == null ? 0 : dayOnly(bedFourRecord.safeDate).difference(dayOnly(now)).inDays.clamp(0, 999).toInt();
  final harvestLine = bedFourRecord == null ? 'No beds are currently on harvest hold' : 'Bed ${bedFourRecord.beds.first} safe to harvest in ${daysLabel(remainingDays)}';

  final sprayAdvice = weather.rainLikelyTonight ? 'Today: do not spray — rain likely tonight' : 'Today: spray conditions look usable';
  final fungusRisk = weather.humidityPercent >= 80 ? 'Fungus risk: high for $seasonalTarget' : 'Fungus risk: moderate for $seasonalTarget';
  final window = 'Best spray window: ${weather.bestSprayWindow}';
  final seasonLine = seasonalPlantingLine(now);

  return GardenTodayReport(
    source: source,
    items: [
      GardenTodayItem(title: sprayAdvice, detail: 'Rain and leaf-wetness risk are checked before spray planning.', color: C.red, background: C.redSoft),
      GardenTodayItem(title: fungusRisk, detail: '${weather.humidityPercent}% humidity increases disease pressure in current-season beds.', color: C.blue, background: C.blueSoft),
      GardenTodayItem(title: window, detail: 'Chosen to avoid rain, heat, and wind exposure.', color: C.forest, background: C.forestSoft),
      GardenTodayItem(title: seasonLine, detail: offSeasonNote(now), color: C.purple, background: C.purpleSoft),
      GardenTodayItem(title: harvestLine, detail: 'Calculated from saved spray records and withholding days.', color: C.amber, background: C.amberSoft),
    ],
  );
}

'@

$pattern = "String daysLabel\([\s\S]*?\r?\n\r?\nclass FieldbookHome"
if ($src -match $pattern) {
  $src = [regex]::Replace($src, $pattern, $helperBlock + 'class FieldbookHome', 1)
} else {
  $shortDatePattern = "String shortDate\(DateTime d\) => '\$\{d\.day\} \$\{monthName\(d\.month\)\}';"
  if ($src -match $shortDatePattern) {
    $src = [regex]::Replace($src, $shortDatePattern, { param($m) $m.Value + "`r`n" + $helperBlock }, 1)
  } else {
    throw 'Could not find the Garden Today helper insertion point.'
  }
}

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Applied season-aware Garden Today guidance.'
Write-Host 'Humidity warnings now prefer Auckland in-season crop groups before warm-season crops like cucumber.'
Write-Host 'Next: flutter analyze; flutter run'
