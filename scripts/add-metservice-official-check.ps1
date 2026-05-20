$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

$metServiceCode = @'
const metServiceBlenheimUrl = 'https://www.metservice.com/towns-cities/regions/marlborough/locations/blenheim';
const metServiceWarningsUrl = 'https://www.metservice.com/warnings/home';

Future<void> openMetServiceUrl(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

'@

if ($src -notmatch 'metServiceBlenheimUrl') {
  if ($src -match 'Future<void> openBunningsUrl') {
    $src = $src.Replace('Future<void> openBunningsUrl', $metServiceCode + 'Future<void> openBunningsUrl')
  } else {
    throw 'Could not find place to insert MetService helpers.'
  }
}

$card = @'
class MetServiceOfficialCard extends StatelessWidget {
  const MetServiceOfficialCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(radius: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: C.blueSoft, borderRadius: BorderRadius.circular(17)), child: const Icon(CupertinoIcons.cloud_sun, color: C.blue, size: 24)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('MetService check', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.forest)),
                    SizedBox(height: 3),
                    Text('Open the official Blenheim forecast or NZ warnings before acting on weather-sensitive jobs.', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: PrimaryButton(label: 'Blenheim forecast', icon: CupertinoIcons.location, onPressed: () => openMetServiceUrl(metServiceBlenheimUrl))),
              const SizedBox(width: 10),
              Expanded(child: SecondaryButton(label: 'Warnings', onPressed: () => openMetServiceUrl(metServiceWarningsUrl))),
            ]),
          ],
        ),
      );
}

'@

if ($src -notmatch 'class MetServiceOfficialCard extends StatelessWidget') {
  if ($src -match 'class GardenTodayCard extends StatelessWidget') {
    $src = $src.Replace('class GardenTodayCard extends StatelessWidget {', $card + 'class GardenTodayCard extends StatelessWidget {')
  } else {
    throw 'Could not find widget insertion point.'
  }
}

if ($src -notmatch 'MetServiceOfficialCard\(') {
  if ($src -match 'FrostLiveMeterCard\(report: frostMeter\)') {
    $src = $src.Replace('        FrostLiveMeterCard(report: frostMeter),
        const SizedBox(height: 14),', '        FrostLiveMeterCard(report: frostMeter),
        const SizedBox(height: 14),
        const MetServiceOfficialCard(),
        const SizedBox(height: 14),')
  } elseif ($src -match 'GardenTodayCard\(report: today\)') {
    $src = $src.Replace('        GardenTodayCard(report: today),', '        const MetServiceOfficialCard(),
        const SizedBox(height: 14),
        GardenTodayCard(report: today),')
  } else {
    throw 'Could not find Home card insertion point.'
  }
}

# Make the live-source text honest if Open-Meteo is still used for numeric forecast values.
$src = $src.Replace(
  "source: 'Live weather: Marlborough region · Open-Meteo forecast'",
  "source: 'Live calculations: Open-Meteo · Official check: MetService Blenheim'"
)
$src = $src.Replace(
  "source: 'Live frost meter · Marlborough / Blenheim forecast'",
  "source: 'Live frost calculations · verify with MetService Blenheim'"
)

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('metServiceBlenheimUrl', 'metServiceWarningsUrl', 'MetServiceOfficialCard', 'Blenheim forecast', 'Official check: MetService')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing MetService marker: $marker" }
}

Write-Host 'Applied MetService official check layer.'
Write-Host 'The app now opens MetService Blenheim forecast and warnings from Home.'
Write-Host 'Numeric frost/feed/spray calculations still use Open-Meteo unless a MetService API key is added later.'
Write-Host 'Next: flutter analyze; flutter run'
