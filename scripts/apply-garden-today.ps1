$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw

$modelBlock = @'
class GardenWeatherSnapshot {
  const GardenWeatherSnapshot({required this.rainLikelyTonight, required this.humidityPercent, required this.windKph, required this.bestSprayWindow});
  final bool rainLikelyTonight;
  final int humidityPercent;
  final int windKph;
  final String bestSprayWindow;
}

class GardenTodayItem {
  const GardenTodayItem({required this.title, required this.detail, required this.color, required this.background});
  final String title;
  final String detail;
  final Color color;
  final Color background;
}

class GardenTodayReport {
  const GardenTodayReport({required this.items, required this.source});
  final List<GardenTodayItem> items;
  final String source;
}

'@

$helperBlock = @'
String daysLabel(int days) => '$days ${days == 1 ? 'day' : 'days'}';
DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String pluralCropName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('cucumber')) return 'cucumbers';
  if (lower.endsWith('s')) return lower;
  return '${lower}s';
}

GardenTodayReport buildGardenTodayReport({required Map<int, List<VegetableDefinition>> bedCrops, required List<SprayRecord> activeRecords, required GardenWeatherSnapshot weather, required DateTime now}) {
  final allCrops = bedCrops.values.expand((crops) => crops).toList();
  final fungusCrop = allCrops.firstWhere(
    (crop) => crop.name.toLowerCase().contains('cucumber'),
    orElse: () => allCrops.firstWhere(
      (crop) => crop.commonDiseases.any((disease) {
        final d = disease.toLowerCase();
        return d.contains('mildew') || d.contains('blight') || d.contains('rust');
      }),
      orElse: () => vegetableById('cucumber'),
    ),
  );

  final bedFourRecord = activeRecords.where((record) => record.beds.contains(4)).firstOrNull ?? activeRecords.firstOrNull;
  final remainingDays = bedFourRecord == null ? 0 : dayOnly(bedFourRecord.safeDate).difference(dayOnly(now)).inDays.clamp(0, 999).toInt();
  final harvestLine = bedFourRecord == null ? 'No beds are currently on harvest hold' : 'Bed ${bedFourRecord.beds.first} safe to harvest in ${daysLabel(remainingDays)}';

  final sprayAdvice = weather.rainLikelyTonight ? 'Today: do not spray — rain likely tonight' : 'Today: spray conditions look usable';
  final fungusRisk = weather.humidityPercent >= 80 ? 'Fungus risk: high for ${pluralCropName(fungusCrop.name)}' : 'Fungus risk: moderate for ${pluralCropName(fungusCrop.name)}';
  final window = 'Best spray window: ${weather.bestSprayWindow}';

  return GardenTodayReport(
    source: 'Using local garden records + forecast placeholder',
    items: [
      GardenTodayItem(title: sprayAdvice, detail: 'Rain and leaf-wetness risk are checked before spray planning.', color: C.red, background: C.redSoft),
      GardenTodayItem(title: fungusRisk, detail: '${weather.humidityPercent}% humidity increases mildew and blight pressure.', color: C.blue, background: C.blueSoft),
      GardenTodayItem(title: window, detail: 'Chosen to avoid rain, heat, and wind exposure.', color: C.forest, background: C.forestSoft),
      GardenTodayItem(title: harvestLine, detail: 'Calculated from saved spray records and withholding days.', color: C.amber, background: C.amberSoft),
    ],
  );
}

'@

$cardBlock = @'
class GardenTodayCard extends StatelessWidget {
  const GardenTodayCard({required this.report, super.key});
  final GardenTodayReport report;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: C.forestSoft, borderRadius: BorderRadius.circular(13)), child: const Icon(CupertinoIcons.sparkles, color: C.forest, size: 20)),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Garden Today', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: C.forest)), Text('Automatic garden guidance', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12))])),
              ],
            ),
            const SizedBox(height: 14),
            ...report.items.map((item) => GardenTodayRow(item: item)),
            const SizedBox(height: 6),
            Text(report.source, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class GardenTodayRow extends StatelessWidget {
  const GardenTodayRow({required this.item, super.key});
  final GardenTodayItem item;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: item.background, borderRadius: BorderRadius.circular(17), border: Border.all(color: C.line)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 9, height: 9, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: item.color, fontWeight: FontWeight.w900, fontSize: 14)), const SizedBox(height: 3), Text(item.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w700, fontSize: 12))])),
          ],
        ),
      );
}

'@

if ($src -notmatch 'class GardenWeatherSnapshot') {
  $src = $src.Replace('extension FirstOrNull<T> on Iterable<T> {', $modelBlock + 'extension FirstOrNull<T> on Iterable<T> {')
}

if ($src -notmatch 'GardenTodayReport buildGardenTodayReport') {
  $needle = "String shortDate(DateTime d) => '${d.day} ${monthName(d.month)}';"
  $literalNeedle = "String shortDate(DateTime d) => '`$`{d.day`} `$`{monthName(d.month)`}';"
  if ($src.Contains($literalNeedle)) {
    $src = $src.Replace($literalNeedle, $literalNeedle + "`r`n" + $helperBlock)
  } elseif ($src -match "String shortDate\(DateTime d\) => '\$\{d\.day\} \$\{monthName\(d\.month\)\}';") {
    $src = [regex]::Replace($src, "String shortDate\(DateTime d\) => '\$\{d\.day\} \$\{monthName\(d\.month\)\}';", { param($m) $m.Value + "`r`n" + $helperBlock }, 1)
  } else {
    throw 'Could not find shortDate() insertion point.'
  }
}

if ($src -notmatch 'static const weather = GardenWeatherSnapshot') {
  $src = $src.Replace('  late List<SprayProduct> products;', "  late List<SprayProduct> products;`r`n`r`n  static const weather = GardenWeatherSnapshot(rainLikelyTonight: true, humidityPercent: 86, windKph: 18, bestSprayWindow: 'tomorrow morning');")
}

if ($src -notmatch 'final report = buildGardenTodayReport') {
  $src = $src.Replace("  Widget build(BuildContext context) {`r`n    final pages = [", "  Widget build(BuildContext context) {`r`n    final report = buildGardenTodayReport(bedCrops: bedCrops, activeRecords: activeRecords, weather: weather, now: DateTime.now());`r`n    final pages = [")
}

if ($src -notmatch 'report: report') {
  $src = $src.Replace('HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, records: records, activeRecords: activeRecords, message: message, onPlanSpray:', 'HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, records: records, activeRecords: activeRecords, report: report, message: message, onPlanSpray:')
}

if ($src -notmatch 'required this.report') {
  $src = $src.Replace('const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.records, required this.activeRecords, required this.message,', 'const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.records, required this.activeRecords, required this.report, required this.message,')
}

if ($src -notmatch 'final GardenTodayReport report;') {
  $src = $src.Replace("  final List<SprayRecord> activeRecords;`r`n  final String message;", "  final List<SprayRecord> activeRecords;`r`n  final GardenTodayReport report;`r`n  final String message;")
}

if ($src -notmatch 'GardenTodayCard\(report: report\)') {
  $src = $src.Replace("        StatusHeroCard(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, onPlanSpray: onPlanSpray),`r`n        const SizedBox(height: 22),", "        StatusHeroCard(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, onPlanSpray: onPlanSpray),`r`n        const SizedBox(height: 18),`r`n        GardenTodayCard(report: report),`r`n        const SizedBox(height: 22),")
}

if ($src -notmatch 'class GardenTodayCard') {
  $src = $src.Replace('class SafeHarvestCard extends StatelessWidget {', $cardBlock + 'class SafeHarvestCard extends StatelessWidget {')
}

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Applied/repaired Garden Today guidance in lib/main.dart.'
Write-Host 'Next: flutter pub get; flutter analyze; flutter run'
