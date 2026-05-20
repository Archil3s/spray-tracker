$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

$newTargetClasses = @'
class TargetGrid extends StatelessWidget {
  const TargetGrid({required this.selected, required this.onSelect, super.key});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TargetReviewPanel(target: targetById(selected)),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width < 430 ? 1 : 2;
            final spacing = 10.0;
            final tileWidth = columns == 1 ? width : (width - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: sprayTargets.map((target) => SizedBox(
                    width: tileWidth,
                    child: TargetButton(
                      target: target,
                      selected: selected == target.id,
                      onTap: () => onSelect(target.id),
                    ),
                  )).toList(),
            );
          }),
        ],
      );
}

class TargetReviewPanel extends StatelessWidget {
  const TargetReviewPanel({required this.target, super.key});
  final SprayTarget target;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: target.softColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.line)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(15)), child: Icon(target.icon, color: target.color, size: 23)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Currently reviewing', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: target.color, fontWeight: FontWeight.w900, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(target.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(target.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12, height: 1.25)),
                ],
              ),
            ),
          ],
        ),
      );
}

class TargetButton extends StatelessWidget {
  const TargetButton({required this.target, required this.selected, required this.onTap, super.key});
  final SprayTarget target;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? target.softColor : C.card,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: selected ? target.color : C.line, width: selected ? 2 : 1),
            boxShadow: selected ? softShadow : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: selected ? target.color : target.softColor, borderRadius: BorderRadius.circular(15)),
                child: Icon(target.icon, color: selected ? CupertinoColors.white : target.color, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(target.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontSize: 15, fontWeight: FontWeight.w900))),
                        const SizedBox(width: 6),
                        Icon(selected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle, size: 18, color: selected ? target.color : C.muted),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(target.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.2)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: selected ? C.card : target.softColor, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.line)),
                      child: Text(target.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: target.color, fontSize: 10.5, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

'@

$pattern = 'class TargetGrid extends StatelessWidget \{[\s\S]*?\r?\nclass ProductChoice extends StatelessWidget \{'
if ($src -notmatch $pattern) { throw 'Could not find TargetGrid block to replace.' }
$src = [regex]::Replace($src, $pattern, $newTargetClasses + 'class ProductChoice extends StatelessWidget {', 1)

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('TargetReviewPanel', 'Currently reviewing', 'target.description', 'tileWidth', 'check_mark_circled_solid')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing spraying-against UI marker: $marker" }
}

$targetGridCount = ([regex]::Matches($check, 'class TargetGrid extends StatelessWidget')).Count
$targetReviewCount = ([regex]::Matches($check, 'class TargetReviewPanel extends StatelessWidget')).Count
if ($targetGridCount -ne 1) { throw "Expected one TargetGrid class, found $targetGridCount" }
if ($targetReviewCount -ne 1) { throw "Expected one TargetReviewPanel class, found $targetReviewCount" }

Write-Host 'Applied improved Spraying against UI.'
Write-Host 'Verified markers: TargetReviewPanel, Currently reviewing, description cards, selected check state.'
Write-Host 'Next: flutter analyze; flutter run'
