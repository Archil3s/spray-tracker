param(
  [switch]$Run,
  [switch]$Push
)

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

$path = Join-Path $repo 'lib/main.dart'

if (!(Test-Path $path)) {
  throw "Cannot find lib/main.dart at $path"
}

Write-Host "==> Fixing invalid Cupertino icon" -ForegroundColor Cyan
$content = Get-Content $path -Raw
$content = $content.Replace(
  "const EmptyInline(icon: CupertinoIcons.leaf, title: 'No crops assigned', subtitle: 'Add vegetables to unlock crop-specific spray guidance.')",
  "const EmptyInline(icon: CupertinoIcons.leaf_arrow_circlepath, title: 'No crops assigned', subtitle: 'Add vegetables to unlock crop-specific spray guidance.')"
)

Write-Host "==> Fixing CountDot Container minWidth" -ForegroundColor Cyan
$content = $content.Replace(
  "Container(minWidth: 20, height: 20, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(color: AppColor.forest, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColor.panel, width: 2)), child: Text('+$count', style: const TextStyle(color: CupertinoColors.white, fontSize: 9, fontWeight: FontWeight.w900)))",
  "Container(constraints: const BoxConstraints(minWidth: 20), height: 20, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(color: AppColor.forest, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColor.panel, width: 2)), child: Text('+$count', style: const TextStyle(color: CupertinoColors.white, fontSize: 9, fontWeight: FontWeight.w900)))"
)

[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "==> Verifying fixes" -ForegroundColor Cyan
$badIcon = Select-String -Path $path -Pattern 'CupertinoIcons.leaf,' -SimpleMatch
$badMinWidth = Select-String -Path $path -Pattern 'Container(minWidth' -SimpleMatch

if ($badIcon) {
  throw "Still found CupertinoIcons.leaf in lib/main.dart"
}
if ($badMinWidth) {
  throw "Still found Container(minWidth in lib/main.dart"
}

Write-Host "==> Dart static check" -ForegroundColor Cyan
flutter analyze lib/main.dart

if ($Run) {
  Write-Host "==> Running app" -ForegroundColor Cyan
  flutter clean
  flutter pub get
  flutter run
}

if ($Push) {
  Write-Host "==> Committing and pushing fix" -ForegroundColor Cyan
  git add lib/main.dart
  git commit -m "Fix Fieldbook UI build errors"
  git push
}

Write-Host "Done." -ForegroundColor Green
