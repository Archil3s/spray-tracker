$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw

if ($src -notmatch 'class GardenWeatherSnapshot') {
  throw 'Garden weather support is required. Run apply-garden-today.ps1 and apply-live-weather.ps1 before this script.'
}

if ($src -notmatch 'String southernSeason') {
  throw 'Season advisor support is required. Run apply-season-advisor.ps1 before this script.'
}

$modelBlock = @'
class FeedRecord {
  const FeedRecord({required this.id, required this.beds, required this.product, required this.method, required this.note, required this.date});
  final int id;
  final List<int> beds;
  final String product;
  final String method;
  final String note;
  final DateTime date;
}

class FeedProductPreset {
  const FeedProductPreset({required this.name, required this.method, required this.intervalDays, required this.note, required this.color, required this.background});
  final String name;
  final String method;
  final int intervalDays;
  final String note;
  final Color color;
  final Color background;
}

const feedProductPresets = [
  FeedProductPreset(name: 'Seasol / seaweed tonic', method: 'Tonic', intervalDays: 14, note: 'Good after cold, wind, transplanting, pruning or general stress. Not a complete fertiliser.', color: C.purple, background: C.purpleSoft),
  FeedProductPreset(name: 'Yates Thrive Vegie & Herb', method: 'Liquid feed', intervalDays: 14, note: 'Useful while leafy crops are actively growing. Use lighter in cold weather.', color: C.forest, background: C.forestSoft),
  FeedProductPreset(name: 'Tomato & vegie liquid feed', method: 'Fruit feed', intervalDays: 10, note: 'Best for warm-season fruiting crops when they are actively flowering or cropping.', color: C.amber, background: C.amberSoft),
  FeedProductPreset(name: 'Compost / slow release', method: 'Soil feed', intervalDays: 42, note: 'Good baseline feeding. Less weather-sensitive than foliar sprays.', color: C.soil, background: C.soft),
];

class FeedingAdvisorReport {
  const FeedingAdvisorReport({
    required this.status,
    required this.feedWindow,
    required this.productSuggestion,
    required this.dueBeds,
    required this.recentFeed,
    required this.weatherNote,
    required this.score,
    required this.color,
    required this.background,
  });

  final String status;
  final String feedWindow;
  final String productSuggestion;
  final String dueBeds;
  final String recentFeed;
  final String weatherNote;
  final int score;
  final Color color;
  final Color background;
}

FeedProductPreset feedingPresetForSeason(DateTime now, GardenWeatherSnapshot weather) {
  final season = southernSeason(now);
  if (season == 'autumn' || season == 'winter') return feedProductPresets[0];
  if (weather.humidityPercent >= 85 || weather.rainLikelyTonight) return feedProductPresets[3];
  return feedProductPresets[1];
}

FeedingAdvisorReport buildFeedingAdvisorReport({
  required Map<int, List<VegetableDefinition>> bedCrops,
  required List<FeedRecord> feedRecords,
  required GardenWeatherSnapshot weather,
  required DateTime now,
}) {
  final season = southernSeason(now);
  final preset = feedingPresetForSeason(now, weather);
  var score = 100;
  final reasons = <String>[];

  if (weather.rainLikelyTonight) {
    score -= 25;
    reasons.add('rain likely tonight');
  }
  if (weather.windKph >= 24) {
    score -= 22;
    reasons.add('wind too high for foliar feeding');
  }
  if (weather.humidityPercent >= 90) {
    score -= 12;
    reasons.add('very high humidity');
  }
  if (season == 'winter') {
    score -= 14;
    reasons.add('slow winter growth');
  }

  score = score.clamp(0, 100).toInt();
  final color = score < 55 ? C.red : score < 75 ? C.amber : C.forest;
  final background = score < 55 ? C.redSoft : score < 75 ? C.amberSoft : C.forestSoft;

  final status = score < 55
      ? 'Delay feeding'
      : score < 75
          ? 'Feed lightly if needed'
          : 'Good feed window';

  final window = weather.rainLikelyTonight
      ? 'Best feed window: after rain clears, preferably a calm morning.'
      : weather.windKph >= 24
          ? 'Best feed window: next calm morning.'
          : season == 'winter'
              ? 'Best feed window: mild morning, light rate only.'
              : 'Best feed window: morning or late afternoon, avoid heat and wind.';

  final plantedBeds = bedCrops.keys.toSet();
  final lastFeedByBed = <int, FeedRecord>{};
  for (final record in feedRecords) {
    for (final bed in record.beds) {
      final current = lastFeedByBed[bed];
      if (current == null || record.date.isAfter(current.date)) lastFeedByBed[bed] = record;
    }
  }

  final due = <int>[];
  for (final bed in plantedBeds) {
    final last = lastFeedByBed[bed];
    if (last == null || dayOnly(now).difference(dayOnly(last.date)).inDays >= preset.intervalDays) due.add(bed);
  }
  due.sort();

  final dueBeds = due.isEmpty
      ? 'Due beds: no planted beds are clearly due based on the current feed interval.'
      : 'Due beds: ${due.take(6).map((bed) => 'Bed $bed').join(', ')}.';

  final sortedFeeds = [...feedRecords]..sort((a, b) => b.date.compareTo(a.date));
  final recent = sortedFeeds.isEmpty
      ? 'Recent feed: none logged yet.'
      : 'Recent feed: ${sortedFeeds.first.product} on Bed ${sortedFeeds.first.beds.join('/')} · ${daysLabel(dayOnly(now).difference(dayOnly(sortedFeeds.first.date)).inDays)} ago.';

  final productSuggestion = 'Suggestion: ${preset.name} · ${preset.note}';
  final weatherNote = reasons.isEmpty
      ? 'Weather note: feeding conditions are acceptable. Water soil first if dry.'
      : 'Weather note: ${reasons.join(', ')}.';

  return FeedingAdvisorReport(
    status: status,
    feedWindow: window,
    productSuggestion: productSuggestion,
    dueBeds: dueBeds,
    recentFeed: recent,
    weatherNote: weatherNote,
    score: score,
    color: color,
    background: background,
  );
}

'@

$cardBlock = @'
class FeedingAdvisorCard extends StatelessWidget {
  const FeedingAdvisorCard({required this.report, required this.onLogFeed, super.key});
  final FeedingAdvisorReport report;
  final VoidCallback onLogFeed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: report.background, borderRadius: BorderRadius.circular(15)), child: Icon(CupertinoIcons.leaf_arrow_circlepath, color: report.color, size: 22)),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Feeding Tracker', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.forest)),
                  Text(report.status, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: report.color, fontWeight: FontWeight.w900, fontSize: 13)),
                ])),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: report.background, borderRadius: BorderRadius.circular(999)), child: Text('${report.score}/100', style: TextStyle(color: report.color, fontWeight: FontWeight.w900, fontSize: 13))),
              ],
            ),
            const SizedBox(height: 14),
            FeedingAdvisorRow(icon: CupertinoIcons.clock, text: report.feedWindow, color: C.forest, background: C.forestSoft),
            FeedingAdvisorRow(icon: CupertinoIcons.cube_box, text: report.productSuggestion, color: C.purple, background: C.purpleSoft),
            FeedingAdvisorRow(icon: CupertinoIcons.square_grid_2x2, text: report.dueBeds, color: C.blue, background: C.blueSoft),
            FeedingAdvisorRow(icon: CupertinoIcons.calendar, text: report.recentFeed, color: C.amber, background: C.amberSoft),
            FeedingAdvisorRow(icon: CupertinoIcons.cloud, text: report.weatherNote, color: report.color, background: report.background),
            const SizedBox(height: 6),
            SecondaryButton(label: 'Log feed', onPressed: onLogFeed),
          ],
        ),
      );
}

class FeedingAdvisorRow extends StatelessWidget {
  const FeedingAdvisorRow({required this.icon, required this.text, required this.color, required this.background, super.key});
  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(17), border: Border.all(color: C.line)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.25))),
        ]),
      );
}

void showFeedDialog(BuildContext context, void Function({required Set<int> beds, required FeedProductPreset preset, required String note}) onSave) {
  showCupertinoModalPopup<void>(context: context, builder: (_) => Sheet(child: FeedLogSheet(onSave: onSave)));
}

class FeedLogSheet extends StatefulWidget {
  const FeedLogSheet({required this.onSave, super.key});
  final void Function({required Set<int> beds, required FeedProductPreset preset, required String note}) onSave;

  @override
  State<FeedLogSheet> createState() => _FeedLogSheetState();
}

class _FeedLogSheetState extends State<FeedLogSheet> {
  final beds = <int>{4};
  var preset = feedProductPresets.first;
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SheetHeader(title: 'Log Feed', subtitle: 'Track liquid feed, tonic or soil feeding'),
          const SizedBox(height: 14),
          const SectionTitle('Beds fed'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: gardenBeds.map((b) => NumberChip(label: '${b.number}', selected: beds.contains(b.number), onTap: () => setState(() { beds.contains(b.number) ? beds.remove(b.number) : beds.add(b.number); }))).toList()),
          const SizedBox(height: 18),
          const SectionTitle('Feed used'),
          const SizedBox(height: 8),
          ...feedProductPresets.map((item) => FeedPresetChoice(preset: item, selected: preset.name == item.name, onTap: () => setState(() => preset = item))),
          const SizedBox(height: 14),
          Field(controller: note, placeholder: 'Notes optional', maxLines: 3),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Save feed record', onPressed: beds.isEmpty ? null : () { widget.onSave(beds: beds, preset: preset, note: note.text); Navigator.pop(context); }),
        ],
      );
}

class FeedPresetChoice extends StatelessWidget {
  const FeedPresetChoice({required this.preset, required this.selected, required this.onTap, super.key});
  final FeedProductPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: selected ? preset.background : C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? preset.color : C.line)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(preset.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text('${preset.method} · every ${preset.intervalDays} days', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            ])),
            Text(selected ? '✓' : '○', style: TextStyle(color: selected ? preset.color : C.muted, fontSize: 22, fontWeight: FontWeight.w900)),
          ]),
        ),
      );
}

'@

if ($src -notmatch 'class FeedRecord') {
  $src = $src.Replace('class FieldbookHome extends StatefulWidget {', $modelBlock + 'class FieldbookHome extends StatefulWidget {')
}

if ($src -notmatch 'class FeedingAdvisorCard') {
  if ($src -match 'class SprayAdvisorCard extends StatelessWidget') {
    $src = $src.Replace('class SprayAdvisorCard extends StatelessWidget', $cardBlock + 'class SprayAdvisorCard extends StatelessWidget')
  } elseif ($src -match 'class GardenTodayCard extends StatelessWidget') {
    $src = $src.Replace('class GardenTodayCard extends StatelessWidget', $cardBlock + 'class GardenTodayCard extends StatelessWidget')
  } else {
    throw 'Could not find card insertion point.'
  }
}

if ($src -notmatch 'List<FeedRecord> feedRecords') {
  if ($src -match '\s+late List<SprayProduct> products;') {
    $src = [regex]::Replace($src, '(\s+late List<SprayProduct> products;)', "`$1`r`n  int nextFeedId = 1;`r`n  List<FeedRecord> feedRecords = [];", 1)
  } else {
    throw 'Could not find products field insertion point for feedRecords.'
  }
}

if ($src -notmatch 'void saveFeed') {
  $method = @'

  void saveFeed({required Set<int> beds, required FeedProductPreset preset, required String note}) => setState(() {
        final sortedBeds = beds.toList()..sort();
        feedRecords.insert(0, FeedRecord(id: nextFeedId++, beds: sortedBeds, product: preset.name, method: preset.method, note: note.trim(), date: DateTime.now()));
        message = '${preset.name} logged for Bed ${sortedBeds.join(', ')}';
      });
'@
  if ($src -match '\s+void removeProduct\(int id\) => setState\(\(\) \{') {
    $src = [regex]::Replace($src, '(\s+void removeProduct\(int id\) => setState\(\(\) \{)', $method + '$1', 1)
  } else {
    throw 'Could not find removeProduct insertion point for saveFeed.'
  }
}

if ($src -notmatch 'final feedingAdvisor = buildFeedingAdvisorReport') {
  if ($src -match 'final sprayAdvisor = buildSprayAdvisorReport\([^;]+;') {
    $src = [regex]::Replace($src, '(final sprayAdvisor = buildSprayAdvisorReport\([^;]+;)', "`$1`r`n    final feedingAdvisor = buildFeedingAdvisorReport(bedCrops: bedCrops, feedRecords: feedRecords, weather: weather, now: DateTime.now());", 1)
  } else {
    throw 'Could not find sprayAdvisor insertion point for feedingAdvisor.'
  }
}

if ($src -notmatch 'feedingAdvisor: feedingAdvisor') {
  $src = $src.Replace('HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, records: records, activeRecords: activeRecords, report: report, sprayAdvisor: sprayAdvisor, message: message, onPlanSpray:', 'HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, records: records, activeRecords: activeRecords, report: report, sprayAdvisor: sprayAdvisor, feedingAdvisor: feedingAdvisor, onLogFeed: () => showFeedDialog(context, saveFeed), message: message, onPlanSpray:')
}

if ($src -notmatch 'required this.feedingAdvisor') {
  $src = $src.Replace('required this.sprayAdvisor, required this.message,', 'required this.sprayAdvisor, required this.feedingAdvisor, required this.onLogFeed, required this.message,')
}

if ($src -notmatch 'final FeedingAdvisorReport feedingAdvisor;') {
  if ($src -match '  final SprayAdvisorReport sprayAdvisor;') {
    $src = $src.Replace('  final SprayAdvisorReport sprayAdvisor;', "  final SprayAdvisorReport sprayAdvisor;`r`n  final FeedingAdvisorReport feedingAdvisor;`r`n  final VoidCallback onLogFeed;")
  } else {
    throw 'Could not find HomeScreen sprayAdvisor field insertion point.'
  }
}

if ($src -notmatch 'FeedingAdvisorCard\(report: feedingAdvisor') {
  $src = $src.Replace('SprayAdvisorCard(report: sprayAdvisor),', "SprayAdvisorCard(report: sprayAdvisor),`r`n        const SizedBox(height: 14),`r`n        FeedingAdvisorCard(report: feedingAdvisor, onLogFeed: onLogFeed),")
}

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Applied Feeding Tracker v1.'
Write-Host 'Adds feeding score, timing advice, product suggestion, due beds, recent feed log and feed logging sheet.'
Write-Host 'Next: flutter analyze; flutter run'
