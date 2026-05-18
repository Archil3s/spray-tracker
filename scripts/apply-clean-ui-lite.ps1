param([switch]$Run)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
$path = Join-Path $repo 'lib/main.dart'
$content = Get-Content $path -Raw

$content = $content.Replace("const EmptyInline(icon: CupertinoIcons.leaf, title: 'No crops assigned', subtitle: 'Add vegetables to unlock crop-specific spray guidance.')", "const EmptyInline(icon: CupertinoIcons.leaf_arrow_circlepath, title: 'No crops assigned', subtitle: 'Add vegetables to unlock crop-specific spray guidance.')")
$content = $content -replace 'Container\(minWidth:\s*20,\s*height:', 'Container(constraints: const BoxConstraints(minWidth: 20), height:'

$content = $content.Replace('static const canvas = Color(0xFFF5F2EA);', 'static const canvas = Color(0xFFF8F6F0);')
$content = $content.Replace('static const panelAlt = Color(0xFFF0ECE3);', 'static const panelAlt = Color(0xFFF3EFE6);')
$content = $content.Replace('static const line = Color(0xFFE2DED3);', 'static const line = Color(0xFFE0DACF);')
$content = $content.Replace('static const forest = Color(0xFF1F4F33);', 'static const forest = Color(0xFF173F2A);')
$content = $content.Replace('static const forestSoft = Color(0xFFE5EFE8);', 'static const forestSoft = Color(0xFFE8F0EA);')
$content = $content.Replace('const softShadow = [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10))];', 'const softShadow = [BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 7))];')
$content = $content.Replace('const smallShadow = [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))];', 'const smallShadow = [BoxShadow(color: Color(0x07000000), blurRadius: 10, offset: Offset(0, 3))];')
$content = $content.Replace('height: 540,', 'height: 500,')
$content = $content.Replace("title: 'Overview',", "title: 'Fieldbook',")

[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
dart format lib/main.dart
flutter analyze lib/main.dart

if ($Run) {
  flutter clean
  flutter pub get
  flutter run
}
