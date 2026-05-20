$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

$models = @'

class FrostMeterReport {
  const FrostMeterReport({required this.risk, required this.lowC, required this.title, required this.detail, required this.window, required this.color, required this.background, required this.source});
  final int risk;
  final int lowC;
  final String title;
  final String detail;
  final String window;
  final Color color;
  final Color background;
  final String source;
}

class AutomaticActionReport {
  const AutomaticActionReport({required this.title, required this.detail, required this.sprayLine, required this.feedLine, required this.frostLine, required this.color, required this.background});
  final String title;
  final String detail;
  final String sprayLine;
  final String feedLine;
  final String frostLine;
  final Color color;
  final Color background;
}

'@
if ($src -notmatch 'class FrostMeterReport') {
  $src = $src.Replace('String southernSeason(DateTime date) {', $models + 'String southernSeason(DateTime date) {')
}

$helpers = @'

FrostMeterReport buildFrostMeterReport({required List<DateTime> times, required List<int> temp, required List<int> humidity, required List<int> wind}) {
  final now = DateTime.now();
  final samples = <int>[];
  final humidSamples = <int>[];
  final windSamples = <int>[];
  final sampleTimes = <DateTime>[];
  final count = [times.length, temp.length, humidity.length, wind.length].reduce((a, b) => a < b ? a : b);
  for (var i = 0; i < count; i++) {
    final time = times[i];
    if (time.isBefore(now)) continue;
    final isOvernight = time.hour >= 18 || time.hour <= 8;
    if (!isOvernight) continue;
    samples.add(temp[i]);
    humidSamples.add(humidity[i]);
    windSamples.add(wind[i]);
    sampleTimes.add(time);
    if (samples.length >= 18) break;
  }

  if (samples.isEmpty) {
    return const FrostMeterReport(risk: 0, lowC: 0, title: 'Frost meter loading', detail: 'Waiting for overnight temperature data.', window: 'Tonight', color: C.muted, background: C.soft, source: 'Waiting for live forecast');
  }

  var low = samples.first;
  var lowIndex = 0;
  for (var i = 1; i < samples.length; i++) {
    if (samples[i] < low) {
      low = samples[i];
      lowIndex = i;
    }
  }
  final maxHumidity = humidSamples.fold<int>(0, (a, b) => a > b ? a : b);
  final avgWind = (windSamples.fold<int>(0, (a, b) => a + b) / windSamples.length).round();

  var risk = 0;
  if (low <= -1) {
    risk = 95;
  } else if (low <= 0) {
    risk = 85;
  } else if (low <= 2) {
    risk = 68;
  } else if (low <= 4) {
    risk = 42;
  } else if (low <= 6) {
    risk = 18;
  } else {
    risk = 5;
  }
  if (maxHumidity >= 88) risk += 8;
  if (avgWind <= 6) risk += 8;
  if (avgWind >= 16) risk -= 10;
  risk = risk.clamp(0, 100).toInt();

  final time = sampleTimes[lowIndex];
  final label = timingLabel(time);
  final color = risk >= 70 ? C.red : risk >= 35 ? C.amber : C.forest;
  final background = risk >= 70 ? C.redSoft : risk >= 35 ? C.amberSoft : C.forestSoft;
  return FrostMeterReport(
    risk: risk,
    lowC: low,
    title: risk >= 70 ? 'Frost risk high' : risk >= 35 ? 'Frost risk watch' : 'Frost risk low',
    detail: 'Low ${low}°C · humidity ${maxHumidity}% · wind ${avgWind} km/h',
    window: label,
    color: color,
    background: background,
    source: 'Live frost meter · Marlborough / Blenheim forecast',
  );
}

FrostMeterReport fallbackFrostMeter(GardenWeatherSnapshot weather) {
  var risk = 0;
  if (weather.temperatureC <= 0) {
    risk = 90;
  } else if (weather.temperatureC <= 2) {
    risk = 68;
  } else if (weather.temperatureC <= 4) {
    risk = 42;
  } else {
    risk = 8;
  }
  if (weather.humidityPercent >= 88) risk += 8;
  if (weather.windKph <= 6) risk += 8;
  risk = risk.clamp(0, 100).toInt();
  final color = risk >= 70 ? C.red : risk >= 35 ? C.amber : C.forest;
  final background = risk >= 70 ? C.redSoft : risk >= 35 ? C.amberSoft : C.forestSoft;
  return FrostMeterReport(risk: risk, lowC: weather.temperatureC, title: risk >= 70 ? 'Frost risk high' : risk >= 35 ? 'Frost risk watch' : 'Frost risk low', detail: '${weather.temperatureC}°C · humidity ${weather.humidityPercent}% · wind ${weather.windKph} km/h', window: weather.bestSprayWindow, color: color, background: background, source: weather.source);
}

AutomaticActionReport buildAutomaticActionReport({required Map<int, List<VegetableDefinition>> bedCrops, required List<SprayRecord> activeRecords, required List<FeedRecord> feedRecords, required GardenWeatherSnapshot weather, required FrostMeterReport frost, required DateTime now}) {
  final planted = bedCrops.keys.toList()..sort();
  final activeHoldCount = activeRecords.length;
  final lastFeedByBed = <int, FeedRecord>{};
  for (final record in feedRecords) {
    for (final bed in record.beds) {
      final current = lastFeedByBed[bed];
      if (current == null || record.date.isAfter(current.date)) lastFeedByBed[bed] = record;
    }
  }

  final feedPreset = feedingPresetForSeason(now, weather);
  final feedDue = <int>[];
  for (final bed in planted) {
    final last = lastFeedByBed[bed];
    if (last == null || dayOnly(now).difference(dayOnly(last.date)).inDays >= feedPreset.intervalDays) feedDue.add(bed);
  }

  final sprayBlocked = weather.rainLikelyTonight || weather.windKph >= 24 || weather.temperatureC >= 30;
  final sprayLine = sprayBlocked
      ? 'Spray: wait · ${weather.rainLikelyTonight ? 'rain likely' : weather.windKph >= 24 ? 'wind high' : 'too hot'}'
      : 'Spray: review ${weather.bestSprayWindow}';
  final feedLine = feedDue.isEmpty ? 'Feed: nothing clearly due' : 'Feed: Bed ${feedDue.take(4).join(', Bed ')} due';
  final frostLine = 'Frost: ${frost.risk}% · low ${frost.lowC}°C';

  String title;
  String detail;
  Color color;
  Color background;
  if (frost.risk >= 70) {
    title = 'Protect frost-sensitive plants';
    detail = 'Frost risk is high ${frost.window}. Cover tender crops before evening.';
    color = C.red;
    background = C.redSoft;
  } else if (feedDue.isNotEmpty) {
    title = 'Feed is due';
    detail = '${feedDue.length} planted bed${feedDue.length == 1 ? '' : 's'} due. Open feed log to record it.';
    color = C.purple;
    background = C.purpleSoft;
  } else if (!sprayBlocked && planted.isNotEmpty) {
    title = 'Spray window to review';
    detail = 'Weather looks usable. Inspect beds first and check product label before spraying.';
    color = C.forest;
    background = C.forestSoft;
  } else if (activeHoldCount > 0) {
    title = 'Check harvest holds';
    detail = '$activeHoldCount active withholding record${activeHoldCount == 1 ? '' : 's'}.';
    color = C.amber;
    background = C.amberSoft;
  } else {
    title = planted.isEmpty ? 'Set up planted beds' : 'No action needed now';
    detail = planted.isEmpty ? 'Add crops to beds so the app can tell you what is due.' : 'Weather and logs do not show an urgent feed or spray review.';
    color = planted.isEmpty ? C.blue : C.forest;
    background = planted.isEmpty ? C.blueSoft : C.forestSoft;
  }

  return AutomaticActionReport(title: title, detail: detail, sprayLine: sprayLine, feedLine: feedLine, frostLine: frostLine, color: color, background: background);
}

'@
if ($src -notmatch 'FrostMeterReport buildFrostMeterReport') {
  $src = $src.Replace('GardenTodayReport buildGardenTodayReport', $helpers + 'GardenTodayReport buildGardenTodayReport')
}

# Add state fields.
if ($src -notmatch 'FrostMeterReport frostMeter') {
  $src = $src.Replace(
    "GardenWeatherSnapshot weather = const GardenWeatherSnapshot(rainLikelyTonight: true, humidityPercent: 86, windKph: 18, temperatureC: 14, bestSprayWindow: 'tomorrow morning', source: 'Using offline Marlborough fallback until live weather loads');",
    "GardenWeatherSnapshot weather = const GardenWeatherSnapshot(rainLikelyTonight: true, humidityPercent: 86, windKph: 18, temperatureC: 14, bestSprayWindow: 'tomorrow morning', source: 'Using offline Marlborough fallback until live weather loads');
  FrostMeterReport frostMeter = const FrostMeterReport(risk: 0, lowC: 0, title: 'Frost meter loading', detail: 'Waiting for live overnight forecast.', window: 'Tonight', color: C.muted, background: C.soft, source: 'Waiting for live forecast');"
  )
}

# Replace fetchLiveWeather so frost data is calculated from real hourly forecast.
$newFetch = @'
  Future<void> fetchLiveWeather() async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '-41.5134',
        'longitude': '173.9612',
        'hourly': 'precipitation_probability,relative_humidity_2m,wind_speed_10m,temperature_2m',
        'forecast_days': '3',
        'timezone': 'Pacific/Auckland',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly = data['hourly'] as Map<String, dynamic>;
      final times = (hourly['time'] as List).whereType<String>().map((value) => DateTime.tryParse(value)).whereType<DateTime>().toList();
      final rain = (hourly['precipitation_probability'] as List).whereType<num>().map((v) => v.toInt()).toList();
      final humidity = (hourly['relative_humidity_2m'] as List).whereType<num>().map((v) => v.toInt()).toList();
      final wind = (hourly['wind_speed_10m'] as List).whereType<num>().map((v) => v.round()).toList();
      final temp = (hourly['temperature_2m'] as List).whereType<num>().map((v) => v.round()).toList();
      int maxOf(List<int> values, int count) => values.take(count).fold(0, (a, b) => a > b ? a : b);
      int avgOf(List<int> values, int count) {
        final sample = values.take(count).toList();
        if (sample.isEmpty) return 0;
        return (sample.fold<int>(0, (a, b) => a + b) / sample.length).round();
      }
      final rainTonight = maxOf(rain, 18) >= 40;
      final maxHumidity = maxOf(humidity, 24);
      final maxWind = maxOf(wind, 12);
      final avgTemp = avgOf(temp, 12);
      final frost = buildFrostMeterReport(times: times, temp: temp, humidity: humidity, wind: wind);
      final bestWindow = rainTonight || maxWind > 22 ? 'tomorrow morning' : 'this evening';
      if (!mounted) return;
      setState(() {
        weather = GardenWeatherSnapshot(rainLikelyTonight: rainTonight, humidityPercent: maxHumidity, windKph: maxWind, temperatureC: avgTemp, bestSprayWindow: bestWindow, source: 'Live weather: Marlborough region · Open-Meteo forecast');
        frostMeter = frost;
      });
    } catch (_) {
      frostMeter = fallbackFrostMeter(weather);
    }
  }
'@
$src = [regex]::Replace($src, '  Future<void> fetchLiveWeather\(\) async \{[\s\S]*?\r?\n  \}\r?\n\r?\n  int get holdBeds', $newFetch + "`r`n  int get holdBeds", 1)

# Build auto action in build method.
if ($src -notmatch 'final autoAction = buildAutomaticActionReport') {
  $src = $src.Replace(
    'final feedingAdvisor = buildFeedingAdvisorReport(bedCrops: bedCrops, feedRecords: feedRecords, weather: weather, now: DateTime.now());',
    'final feedingAdvisor = buildFeedingAdvisorReport(bedCrops: bedCrops, feedRecords: feedRecords, weather: weather, now: DateTime.now());
    final autoAction = buildAutomaticActionReport(bedCrops: bedCrops, activeRecords: activeSprays, feedRecords: feedRecords, weather: weather, frost: frostMeter, now: DateTime.now());'
  )
}

# Pass new report to HomeScreen.
$src = $src.Replace(
  'HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, sprayRecords: sprayRecords, feedRecords: feedRecords, today: today, sprayAdvisor: sprayAdvisor, feedingAdvisor: feedingAdvisor, message: message, onPlanSpray:',
  'HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, sprayRecords: sprayRecords, feedRecords: feedRecords, today: today, sprayAdvisor: sprayAdvisor, feedingAdvisor: feedingAdvisor, autoAction: autoAction, frostMeter: frostMeter, message: message, onPlanSpray:'
)
$src = $src.Replace(
  'const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.sprayRecords, required this.feedRecords, required this.today, required this.sprayAdvisor, required this.feedingAdvisor, required this.message, required this.onPlanSpray,',
  'const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.sprayRecords, required this.feedRecords, required this.today, required this.sprayAdvisor, required this.feedingAdvisor, required this.autoAction, required this.frostMeter, required this.message, required this.onPlanSpray,'
)
if ($src -notmatch 'final AutomaticActionReport autoAction;') {
  $src = $src.Replace('  final FeedingAdvisorReport feedingAdvisor;', '  final FeedingAdvisorReport feedingAdvisor;
  final AutomaticActionReport autoAction;
  final FrostMeterReport frostMeter;')
}

# Replace bulky advisor cards with automatic dashboard + frost meter. Keep Garden Today and activity below.
$src = $src.Replace(
  "        SprayAdvisorCard(report: sprayAdvisor, onPlanSpray: onPlanSpray, onOpenProducts: onOpenProducts),
        const SizedBox(height: 14),
        FeedingAdvisorCard(report: feedingAdvisor, onLogFeed: onLogFeed, onOpenProducts: onOpenProducts),
        const SizedBox(height: 14),",
  "        AutomaticActionDashboard(report: autoAction, onPlanSpray: onPlanSpray, onLogFeed: onLogFeed),
        const SizedBox(height: 14),
        FrostLiveMeterCard(report: frostMeter),
        const SizedBox(height: 14),"
)
$src = $src.Replace(
  "        OnlineTimingAdvisorCard(advice: onlineTiming, onPlanSpray: onPlanSpray, onLogFeed: onLogFeed),
        const SizedBox(height: 14),
        SprayAdvisorCard(report: sprayAdvisor, onPlanSpray: onPlanSpray, onOpenProducts: onOpenProducts),
        const SizedBox(height: 14),
        FeedingAdvisorCard(report: feedingAdvisor, onLogFeed: onLogFeed, onOpenProducts: onOpenProducts),
        const SizedBox(height: 14),",
  "        AutomaticActionDashboard(report: autoAction, onPlanSpray: onPlanSpray, onLogFeed: onLogFeed),
        const SizedBox(height: 14),
        FrostLiveMeterCard(report: frostMeter),
        const SizedBox(height: 14),"
)
if ($src -notmatch 'AutomaticActionDashboard\(report: autoAction') {
  $src = $src.Replace(
    '        GardenTodayCard(report: today),',
    '        AutomaticActionDashboard(report: autoAction, onPlanSpray: onPlanSpray, onLogFeed: onLogFeed),
        const SizedBox(height: 14),
        FrostLiveMeterCard(report: frostMeter),
        const SizedBox(height: 14),
        GardenTodayCard(report: today),'
  )
}

$widgets = @'
class AutomaticActionDashboard extends StatelessWidget {
  const AutomaticActionDashboard({required this.report, required this.onPlanSpray, required this.onLogFeed, super.key});
  final AutomaticActionReport report;
  final VoidCallback onPlanSpray;
  final VoidCallback onLogFeed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: report.background, borderRadius: BorderRadius.circular(28), border: Border.all(color: C.line), boxShadow: softShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 54, height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(19)), child: Icon(CupertinoIcons.bolt_circle, color: report.color, size: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Next action', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: C.forest)),
                Text(report.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: report.color, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(report.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontSize: 12, fontWeight: FontWeight.w700, height: 1.2)),
              ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: ActionMiniTile(icon: CupertinoIcons.drop, label: 'Spray', value: report.sprayLine, color: C.blue, background: C.card)),
              const SizedBox(width: 8),
              Expanded(child: ActionMiniTile(icon: CupertinoIcons.leaf_arrow_circlepath, label: 'Feed', value: report.feedLine, color: C.purple, background: C.card)),
            ]),
            const SizedBox(height: 8),
            ActionMiniTile(icon: CupertinoIcons.snow, label: 'Frost', value: report.frostLine, color: C.red, background: C.card),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: PrimaryButton(label: 'Spray log', icon: CupertinoIcons.drop, onPressed: onPlanSpray)), const SizedBox(width: 10), Expanded(child: SecondaryButton(label: 'Feed log', onPressed: onLogFeed))]),
          ],
        ),
      );
}

class ActionMiniTile extends StatelessWidget {
  const ActionMiniTile({required this.icon, required this.label, required this.value, required this.color, required this.background, super.key});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontSize: 12, fontWeight: FontWeight.w800, height: 1.2)),
          ])),
        ]),
      );
}

class FrostLiveMeterCard extends StatelessWidget {
  const FrostLiveMeterCard({required this.report, super.key});
  final FrostMeterReport report;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: report.background, borderRadius: BorderRadius.circular(26), border: Border.all(color: C.line), boxShadow: softShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 50, height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)), child: Icon(CupertinoIcons.snow, color: report.color, size: 25)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Frost live meter', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: C.forest)),
              Text(report.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: report.color, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(report.source, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ])),
            FrostPercentBadge(risk: report.risk, color: report.color, background: C.card),
          ]),
          const SizedBox(height: 14),
          FrostMeterBar(risk: report.risk, color: report.color),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ActionMiniTile(icon: CupertinoIcons.thermometer, label: 'Low', value: '${report.lowC}°C', color: report.color, background: C.card)),
            const SizedBox(width: 8),
            Expanded(child: ActionMiniTile(icon: CupertinoIcons.clock, label: 'Window', value: report.window, color: report.color, background: C.card)),
          ]),
          const SizedBox(height: 8),
          Text(report.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontSize: 12, fontWeight: FontWeight.w800, height: 1.2)),
        ]),
      );
}

class FrostPercentBadge extends StatelessWidget {
  const FrostPercentBadge({required this.risk, required this.color, required this.background, super.key});
  final int risk;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$risk', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18, height: .95)),
          Text('%', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
        ]),
      );
}

class FrostMeterBar extends StatelessWidget {
  const FrostMeterBar({required this.risk, required this.color, super.key});
  final int risk;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 14,
          color: C.card,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: risk.clamp(0, 100) / 100,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999))),
          ),
        ),
      );
}

'@
if ($src -notmatch 'class AutomaticActionDashboard extends StatelessWidget') {
  $src = $src.Replace('class SprayAdvisorCard extends StatelessWidget {', $widgets + 'class SprayAdvisorCard extends StatelessWidget {')
}

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('AutomaticActionDashboard', 'FrostLiveMeterCard', 'FrostMeterReport', 'buildAutomaticActionReport', 'FrostMeterBar', 'Frost live meter')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing automatic/frost marker: $marker" }
}

Write-Host 'Applied automatic action dashboard and frost live meter.'
Write-Host 'Home now shows next action + frost meter instead of bulky score-card style advisors.'
Write-Host 'Next: flutter analyze; flutter run'
