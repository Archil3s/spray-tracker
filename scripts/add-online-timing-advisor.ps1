$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

# Add online timing model after FeedingAdvisorReport.
$model = @'

class OnlineTimingAdvice {
  const OnlineTimingAdvice({
    required this.sprayTitle,
    required this.sprayDetail,
    required this.feedTitle,
    required this.feedDetail,
    required this.riskLine,
    required this.source,
    required this.updatedLabel,
    required this.color,
    required this.background,
  });

  final String sprayTitle;
  final String sprayDetail;
  final String feedTitle;
  final String feedDetail;
  final String riskLine;
  final String source;
  final String updatedLabel;
  final Color color;
  final Color background;
}

class WeatherHourCandidate {
  const WeatherHourCandidate({required this.time, required this.rain, required this.humidity, required this.wind, required this.temp, required this.score});
  final DateTime time;
  final int rain;
  final int humidity;
  final int wind;
  final int temp;
  final int score;
}

String timingLabel(DateTime time) {
  final now = DateTime.now();
  final today = dayOnly(now);
  final day = dayOnly(time);
  final hour = time.hour == 0 ? 12 : time.hour > 12 ? time.hour - 12 : time.hour;
  final suffix = time.hour >= 12 ? 'pm' : 'am';
  final clock = '$hour$suffix';
  if (day == today) return 'today around $clock';
  if (day == today.add(const Duration(days: 1))) return 'tomorrow around $clock';
  return '${shortDate(time)} around $clock';
}

WeatherHourCandidate? bestForecastWindow({required List<DateTime> times, required List<int> rain, required List<int> humidity, required List<int> wind, required List<int> temp, required bool spray}) {
  final now = DateTime.now();
  final candidates = <WeatherHourCandidate>[];
  final count = [times.length, rain.length, humidity.length, wind.length, temp.length].reduce((a, b) => a < b ? a : b);
  for (var i = 0; i < count; i++) {
    final time = times[i];
    if (time.isBefore(now.add(const Duration(hours: 1)))) continue;
    if (time.hour < 6 || time.hour > 20) continue;
    var score = 100;
    score -= rain[i] * 2;
    score -= wind[i] >= 24 ? 45 : wind[i] >= 18 ? 22 : wind[i] >= 14 ? 10 : 0;
    if (spray) {
      score -= temp[i] >= 28 ? 35 : temp[i] >= 25 ? 14 : 0;
      score -= humidity[i] >= 92 ? 16 : humidity[i] >= 85 ? 8 : 0;
    } else {
      score -= temp[i] >= 29 ? 24 : 0;
      score -= wind[i] >= 24 ? 18 : 0;
      if (rain[i] >= 60) score -= 12;
    }
    candidates.add(WeatherHourCandidate(time: time, rain: rain[i], humidity: humidity[i], wind: wind[i], temp: temp[i], score: score.clamp(0, 100).toInt()));
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.score.compareTo(a.score));
  return candidates.first;
}

OnlineTimingAdvice buildOnlineTimingAdviceFromForecast({required List<DateTime> times, required List<int> rain, required List<int> humidity, required List<int> wind, required List<int> temp, required DateTime updated}) {
  final spray = bestForecastWindow(times: times, rain: rain, humidity: humidity, wind: wind, temp: temp, spray: true);
  final feed = bestForecastWindow(times: times, rain: rain, humidity: humidity, wind: wind, temp: temp, spray: false);
  final nextRain = rain.take(24).fold<int>(0, (a, b) => a > b ? a : b);
  final nextHumidity = humidity.take(24).fold<int>(0, (a, b) => a > b ? a : b);
  final nextWind = wind.take(24).fold<int>(0, (a, b) => a > b ? a : b);
  final blocked = spray == null || spray.score < 55;
  final sprayTitle = blocked ? 'Spray review: wait' : 'Spray review: ${timingLabel(spray.time)}';
  final sprayDetail = spray == null
      ? 'No useful spray-review window found in the forecast. Recheck later.'
      : 'Score ${spray.score}/100 · rain ${spray.rain}% · wind ${spray.wind} km/h · ${spray.temp}°C. Check the product label before use.';
  final feedTitle = feed == null || feed.score < 45 ? 'Feed review: wait' : 'Feed review: ${timingLabel(feed.time)}';
  final feedDetail = feed == null
      ? 'No useful feed window found in the forecast. Recheck later.'
      : 'Score ${feed.score}/100 · rain ${feed.rain}% · wind ${feed.wind} km/h · ${feed.temp}°C. Soil feeds are less weather-sensitive than foliar feeds.';
  final riskLine = 'Next 24h: rain risk ${nextRain}% · humidity ${nextHumidity}% · wind up to ${nextWind} km/h.';
  return OnlineTimingAdvice(
    sprayTitle: sprayTitle,
    sprayDetail: sprayDetail,
    feedTitle: feedTitle,
    feedDetail: feedDetail,
    riskLine: riskLine,
    source: 'Online forecast: Marlborough / Blenheim · Open-Meteo',
    updatedLabel: 'Updated ${timingLabel(updated)}',
    color: blocked ? C.amber : C.forest,
    background: blocked ? C.amberSoft : C.forestSoft,
  );
}

'@
if ($src -notmatch 'class OnlineTimingAdvice') {
  $src = $src.Replace('String southernSeason(DateTime date) {', $model + "`r`nString southernSeason(DateTime date) {")
}

# Add state field.
if ($src -notmatch 'OnlineTimingAdvice onlineTiming') {
  $src = $src.Replace(
    "GardenWeatherSnapshot weather = const GardenWeatherSnapshot(rainLikelyTonight: true, humidityPercent: 86, windKph: 18, temperatureC: 14, bestSprayWindow: 'tomorrow morning', source: 'Using offline Marlborough fallback until live weather loads');",
    "GardenWeatherSnapshot weather = const GardenWeatherSnapshot(rainLikelyTonight: true, humidityPercent: 86, windKph: 18, temperatureC: 14, bestSprayWindow: 'tomorrow morning', source: 'Using offline Marlborough fallback until live weather loads');`r`n  OnlineTimingAdvice onlineTiming = const OnlineTimingAdvice(sprayTitle: 'Spray review: loading online forecast', sprayDetail: 'Fetching Marlborough forecast before choosing a review window.', feedTitle: 'Feed review: loading online forecast', feedDetail: 'Fetching wind, rain and temperature before choosing a feed window.', riskLine: 'Waiting for online forecast.', source: 'Offline fallback until Open-Meteo loads', updatedLabel: 'Not updated yet', color: C.amber, background: C.amberSoft);"
  )
}

# Replace fetchLiveWeather with a richer version.
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
      final timing = buildOnlineTimingAdviceFromForecast(times: times, rain: rain, humidity: humidity, wind: wind, temp: temp, updated: DateTime.now());
      final bestWindow = timing.sprayTitle.replaceFirst('Spray review: ', '');
      if (!mounted) return;
      setState(() {
        weather = GardenWeatherSnapshot(rainLikelyTonight: rainTonight, humidityPercent: maxHumidity, windKph: maxWind, temperatureC: avgTemp, bestSprayWindow: bestWindow, source: 'Live weather: Marlborough region · Open-Meteo forecast');
        onlineTiming = timing;
      });
    } catch (_) {
      // Keep offline fallback.
    }
  }
'@
$src = [regex]::Replace($src, '  Future<void> fetchLiveWeather\(\) async \{[\s\S]*?\r?\n  \}\r?\n\r?\n  int get holdBeds', $newFetch + "`r`n  int get holdBeds", 1)

# Pass online timing into HomeScreen.
$src = $src.Replace(
  'HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, sprayRecords: sprayRecords, feedRecords: feedRecords, today: today, sprayAdvisor: sprayAdvisor, feedingAdvisor: feedingAdvisor, message: message, onPlanSpray:',
  'HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, sprayRecords: sprayRecords, feedRecords: feedRecords, today: today, sprayAdvisor: sprayAdvisor, feedingAdvisor: feedingAdvisor, onlineTiming: onlineTiming, message: message, onPlanSpray:'
)
$src = $src.Replace(
  'const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.sprayRecords, required this.feedRecords, required this.today, required this.sprayAdvisor, required this.feedingAdvisor, required this.message, required this.onPlanSpray,',
  'const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.sprayRecords, required this.feedRecords, required this.today, required this.sprayAdvisor, required this.feedingAdvisor, required this.onlineTiming, required this.message, required this.onPlanSpray,'
)
if ($src -notmatch 'final OnlineTimingAdvice onlineTiming;') {
  $src = $src.Replace('  final FeedingAdvisorReport feedingAdvisor;', "  final FeedingAdvisorReport feedingAdvisor;`r`n  final OnlineTimingAdvice onlineTiming;")
}

# Insert the Online Timing Advisor card above Spray Advisor.
if ($src -notmatch 'OnlineTimingAdvisorCard\(') {
  $src = $src.Replace(
    '        SprayAdvisorCard(report: sprayAdvisor, onPlanSpray: onPlanSpray, onOpenProducts: onOpenProducts),',
    '        OnlineTimingAdvisorCard(advice: onlineTiming, onPlanSpray: onPlanSpray, onLogFeed: onLogFeed),`r`n        const SizedBox(height: 14),`r`n        SprayAdvisorCard(report: sprayAdvisor, onPlanSpray: onPlanSpray, onOpenProducts: onOpenProducts),'
  )
}

$card = @'
class OnlineTimingAdvisorCard extends StatelessWidget {
  const OnlineTimingAdvisorCard({required this.advice, required this.onPlanSpray, required this.onLogFeed, super.key});
  final OnlineTimingAdvice advice;
  final VoidCallback onPlanSpray;
  final VoidCallback onLogFeed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: advice.background, borderRadius: BorderRadius.circular(26), border: Border.all(color: C.line), boxShadow: softShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(17)), child: Icon(CupertinoIcons.cloud_sun, color: advice.color, size: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Online Timing Advisor', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.forest)),
                  Text(advice.source, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                ])),
              ],
            ),
            const SizedBox(height: 12),
            AdvisorRow(text: advice.sprayTitle, color: advice.color, background: C.card),
            AdvisorRow(text: advice.sprayDetail, color: advice.color, background: C.card),
            AdvisorRow(text: advice.feedTitle, color: C.purple, background: C.card),
            AdvisorRow(text: advice.feedDetail, color: C.purple, background: C.card),
            AdvisorRow(text: advice.riskLine, color: C.blue, background: C.card),
            AdvisorRow(text: advice.updatedLabel, color: C.muted, background: C.card),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: PrimaryButton(label: 'Open spray log', icon: CupertinoIcons.drop, onPressed: onPlanSpray)),
              const SizedBox(width: 10),
              Expanded(child: SecondaryButton(label: 'Open feed log', onPressed: onLogFeed)),
            ]),
          ],
        ),
      );
}

'@
if ($src -notmatch 'class OnlineTimingAdvisorCard extends StatelessWidget') {
  $src = $src.Replace('class SprayAdvisorCard extends StatelessWidget {', $card + 'class SprayAdvisorCard extends StatelessWidget {')
}

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('OnlineTimingAdvice', 'OnlineTimingAdvisorCard', 'buildOnlineTimingAdviceFromForecast', 'forecast_days', 'Online Timing Advisor')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing online timing marker: $marker" }
}

Write-Host 'Applied Online Timing Advisor.'
Write-Host 'Uses Open-Meteo Marlborough forecast to calculate spray/feed review windows from rain, humidity, wind and temperature.'
Write-Host 'Next: flutter analyze; flutter run'
