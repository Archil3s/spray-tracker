$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

$connectedAdvisor = @'
class ConnectedAdvisorCard extends StatelessWidget {
  const ConnectedAdvisorCard({required this.title, required this.subtitle, required this.score, required this.color, required this.background, required this.icon, required this.rows, required this.primaryLabel, required this.primaryAction, required this.secondaryLabel, required this.secondaryAction, super.key});
  final String title;
  final String subtitle;
  final int score;
  final Color color;
  final Color background;
  final IconData icon;
  final List<String> rows;
  final String primaryLabel;
  final VoidCallback primaryAction;
  final String secondaryLabel;
  final VoidCallback secondaryAction;

  @override
  Widget build(BuildContext context) {
    final topLine = rows.isEmpty ? subtitle : rows.first;
    final secondLine = rows.length > 1 ? rows[1] : '';
    final thirdLine = rows.length > 2 ? rows[2] : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 50, height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: color, size: 25)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.forest)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
              ])),
              const SizedBox(width: 8),
              VisualScoreBadge(score: score, color: color, background: background),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: VisualInfoTile(icon: CupertinoIcons.timer, label: 'Window', value: topLine, color: color, background: background)),
              const SizedBox(width: 8),
              Expanded(child: VisualInfoTile(icon: CupertinoIcons.exclamationmark_triangle, label: 'Risk', value: secondLine.isEmpty ? subtitle : secondLine, color: color, background: background)),
            ],
          ),
          if (thirdLine.isNotEmpty) ...[
            const SizedBox(height: 8),
            VisualInfoTile(icon: CupertinoIcons.location, label: 'Linked beds', value: thirdLine, color: color, background: background),
          ],
          const SizedBox(height: 12),
          Row(children: [Expanded(child: PrimaryButton(label: primaryLabel, onPressed: primaryAction)), const SizedBox(width: 10), Expanded(child: SecondaryButton(label: secondaryLabel, onPressed: secondaryAction))]),
        ],
      ),
    );
  }
}

class VisualScoreBadge extends StatelessWidget {
  const VisualScoreBadge({required this.score, required this.color, required this.background, super.key});
  final int score;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18, height: .95)),
            Text('/100', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9)),
          ],
        ),
      );
}

class VisualInfoTile extends StatelessWidget {
  const VisualInfoTile({required this.icon, required this.label, required this.value, required this.color, required this.background, super.key});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 6), Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)))]),
            const SizedBox(height: 6),
            Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontSize: 12.2, fontWeight: FontWeight.w800, height: 1.2)),
          ],
        ),
      );
}

'@

$advisorPattern = 'class ConnectedAdvisorCard extends StatelessWidget \{[\s\S]*?\r?\nclass AdvisorRow extends StatelessWidget \{'
if ($src -match $advisorPattern) {
  $src = [regex]::Replace($src, $advisorPattern, $connectedAdvisor + 'class AdvisorRow extends StatelessWidget {', 1)
} else {
  throw 'Could not find ConnectedAdvisorCard block.'
}

$gardenToday = @'
class GardenTodayCard extends StatelessWidget {
  const GardenTodayCard({required this.report, super.key});
  final GardenTodayReport report;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(radius: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: C.forestSoft, borderRadius: BorderRadius.circular(16)), child: const Icon(CupertinoIcons.sun_max, color: C.forest, size: 23)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Garden Today', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.forest)),
                Text(report.source, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 390;
              final tileWidth = twoColumns ? (constraints.maxWidth - 8) / 2 : constraints.maxWidth;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: report.items.take(4).map((item) => SizedBox(width: tileWidth, child: GardenTodayTile(item: item))).toList(),
              );
            }),
          ],
        ),
      );
}

class GardenTodayTile extends StatelessWidget {
  const GardenTodayTile({required this.item, super.key});
  final GardenTodayItem item;

  IconData get icon {
    final lower = item.title.toLowerCase();
    if (lower.contains('do not') || lower.contains('rain')) return CupertinoIcons.cloud_rain;
    if (lower.contains('fungus')) return CupertinoIcons.drop;
    if (lower.contains('window')) return CupertinoIcons.clock;
    if (lower.contains('season') || lower.contains('focus')) return CupertinoIcons.leaf_arrow_circlepath;
    if (lower.contains('safe') || lower.contains('hold')) return CupertinoIcons.hand_raised;
    return CupertinoIcons.info_circle;
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: item.background, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: item.color, size: 18), const SizedBox(width: 7), Expanded(child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: item.color, fontWeight: FontWeight.w900, fontSize: 13)))]),
            const SizedBox(height: 5),
            Text(item.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 11.5)),
          ],
        ),
      );
}

'@

$todayPattern = 'class GardenTodayCard extends StatelessWidget \{[\s\S]*?\r?\nclass LinkedActivityList extends StatelessWidget \{'
if ($src -match $todayPattern) {
  $src = [regex]::Replace($src, $todayPattern, $gardenToday + 'class LinkedActivityList extends StatelessWidget {', 1)
} else {
  throw 'Could not find GardenTodayCard block.'
}

# If Online Timing Advisor has already been added locally, replace it with a compact visual version.
if ($src -match 'class OnlineTimingAdvisorCard extends StatelessWidget \{') {
$onlineCard = @'
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 50, height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)), child: Icon(CupertinoIcons.cloud_sun, color: advice.color, size: 25)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Timing', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.forest)),
                Text(advice.source, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: VisualInfoTile(icon: CupertinoIcons.drop, label: 'Spray', value: advice.sprayTitle.replaceFirst('Spray review: ', ''), color: advice.color, background: C.card)),
              const SizedBox(width: 8),
              Expanded(child: VisualInfoTile(icon: CupertinoIcons.leaf_arrow_circlepath, label: 'Feed', value: advice.feedTitle.replaceFirst('Feed review: ', ''), color: C.purple, background: C.card)),
            ]),
            const SizedBox(height: 8),
            VisualInfoTile(icon: CupertinoIcons.wind, label: 'Weather', value: advice.riskLine, color: C.blue, background: C.card),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: PrimaryButton(label: 'Spray log', icon: CupertinoIcons.drop, onPressed: onPlanSpray)), const SizedBox(width: 10), Expanded(child: SecondaryButton(label: 'Feed log', onPressed: onLogFeed))]),
          ],
        ),
      );
}

'@
  $src = [regex]::Replace($src, 'class OnlineTimingAdvisorCard extends StatelessWidget \{[\s\S]*?\r?\nclass SprayAdvisorCard extends StatelessWidget \{', $onlineCard + 'class SprayAdvisorCard extends StatelessWidget {', 1)
}

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('VisualInfoTile', 'VisualScoreBadge', 'GardenTodayTile', 'Timing', 'maxLines: 1')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing visual marker: $marker" }
}

Write-Host 'Applied more visual Home/advisor cards.'
Write-Host 'Reduced text rows into visual tiles, score badge, compact Garden Today tiles, and visual timing card if present.'
Write-Host 'Next: flutter analyze; flutter run'
