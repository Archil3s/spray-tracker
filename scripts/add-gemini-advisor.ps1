param([switch]$Run, [switch]$Push)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
$path = Join-Path $repo 'lib/main.dart'
$content = Get-Content $path -Raw

Write-Host "==> Wiring Gemini Advisor tab into main.dart" -ForegroundColor Cyan

# Add imports.
if ($content -notmatch "features/advisor/advisor_screen.dart") {
  $content = $content.Replace(
    "import 'crop_library.dart';",
    "import 'crop_library.dart';`nimport 'features/advisor/advisor_screen.dart';`nimport 'features/advisor/gemini_service.dart';"
  )
}

# Products button on Home should still open Products after Advisor tab is inserted.
$content = $content.Replace("onOpenProducts: () => setState(() => tab = 4)", "onOpenProducts: () => setState(() => tab = 5)")

# Insert AdvisorScreen before ProductsScreen in the pages list.
$oldProductsPage = @'
      ProductsScreen(products: products, message: message, onAdd: addProduct, onDelete: removeProduct, onResetDemo: () => resetToDemoData(), onClearAll: clearAllTestingData),
'@

$newProductsPage = @'
      AdvisorScreen(
        products: products
            .map((product) => AdvisorProduct(
                  name: product.name,
                  type: product.type,
                  withholdingDays: product.days,
                ))
            .toList(),
        canvasColor: C.canvas,
        cardColor: C.card,
        softColor: C.soft,
        inkColor: C.ink,
        mutedColor: C.muted,
        lineColor: C.line,
        primaryColor: C.forest,
        errorColor: C.red,
      ),
      ProductsScreen(products: products, message: message, onAdd: addProduct, onDelete: removeProduct, onResetDemo: () => resetToDemoData(), onClearAll: clearAllTestingData),
'@

if ($content.Contains($oldProductsPage)) {
  $content = $content.Replace($oldProductsPage, $newProductsPage)
} elseif ($content -notmatch "AdvisorScreen\(") {
  throw "Could not find ProductsScreen page line to replace."
}

# Replace the bottom nav items with a 6-tab version.
$oldNavItems = @'
    final items = const [NavSpec('Home', CupertinoIcons.home), NavSpec('Garden', CupertinoIcons.square_grid_2x2), NavSpec('Spray', CupertinoIcons.drop), NavSpec('Feed', CupertinoIcons.leaf_arrow_circlepath), NavSpec('Products', CupertinoIcons.cube_box)];
'@

$newNavItems = @'
    final items = const [
      NavSpec('Home', CupertinoIcons.home),
      NavSpec('Garden', CupertinoIcons.square_grid_2x2),
      NavSpec('Spray', CupertinoIcons.drop),
      NavSpec('Feed', CupertinoIcons.leaf_arrow_circlepath),
      NavSpec('Advisor', CupertinoIcons.stethoscope),
      NavSpec('Products', CupertinoIcons.cube_box),
    ];
'@

if ($content.Contains($oldNavItems)) {
  $content = $content.Replace($oldNavItems, $newNavItems)
} elseif ($content -notmatch "NavSpec\('Advisor'") {
  throw "Could not find bottom nav item list to replace."
}

[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "==> Formatting" -ForegroundColor Cyan
dart format lib/main.dart lib/features/advisor/advisor_screen.dart lib/features/advisor/gemini_service.dart lib/config/api_config.dart

Write-Host "==> Analyzing" -ForegroundColor Cyan
flutter analyze

if ($Run) {
  Write-Host "==> Running app" -ForegroundColor Cyan
  flutter clean
  flutter pub get
  flutter run
}

if ($Push) {
  Write-Host "==> Committing and pushing" -ForegroundColor Cyan
  git add lib/main.dart lib/features/advisor/advisor_screen.dart lib/features/advisor/gemini_service.dart lib/config/api_config.dart scripts/add-gemini-advisor.ps1
  git commit -m "Add Gemini AI spray advisor tab"
  git push
}
