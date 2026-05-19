$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

$src = $src.Replace(
"return AppPage(title: 'Spray Log', subtitle: 'Sprays link to beds, crops, products and withholding.', children: [",
"return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Bunnings link.', children: ["
)

$summary = @'
      Panel(
        color: C.forestSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Linked review', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.forest)),
            const SizedBox(height: 8),
            Text('Bed sprayed: ${beds.map((b) => 'Bed $b').join(', ')}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: C.ink)),
            const SizedBox(height: 4),
            Text('Crops affected: ${crops.join(' · ')}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
            const SizedBox(height: 4),
            Text('Spraying against: ${targetById(targetId).title}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
            const SizedBox(height: 4),
            Text('Product selected: ${product.name} · $days day withholding', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
            const SizedBox(height: 10),
            const Text('Check the product label before use. This screen records what you applied after review.', style: TextStyle(fontWeight: FontWeight.w700, color: C.muted, fontSize: 12)),
          ],
        ),
      ),
      const SizedBox(height: 18),
'@

if ($src -notmatch 'Linked review') {
  $src = $src.Replace(
"return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Bunnings link.', children: [",
"return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Bunnings link.', children: [`r`n$summary"
  )
}

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Applied UI-only Spray Log review card.'
Write-Host 'Next: flutter clean; flutter pub get; flutter analyze; flutter run'
