$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw

if ($src -notmatch "package:url_launcher/url_launcher.dart") {
  $src = $src.Replace("import 'package:flutter_svg/flutter_svg.dart';", "import 'package:flutter_svg/flutter_svg.dart';`r`nimport 'package:url_launcher/url_launcher.dart';")
}

if ($src -notmatch 'String bunningsSearchTerm') {
  $helper = @'
String bunningsSearchTerm(SprayProduct product) {
  final name = product.name.toLowerCase();
  if (name.contains('neem')) return 'neem oil garden spray';
  if (name.contains('copper')) return 'copper fungicide garden spray';
  if (name.contains('pyreth')) return 'pyrethrum garden spray';
  if (name.contains('seaweed')) return 'seaweed plant tonic';
  return '${product.name} garden spray';
}

Uri bunningsSearchUri(SprayProduct product) {
  return Uri.https('www.bunnings.co.nz', '/search/products', {'q': bunningsSearchTerm(product)});
}

Future<void> openBunningsForProduct(SprayProduct product) async {
  final uri = bunningsSearchUri(product);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}

'@
  $src = $src.Replace('class ProductsScreen extends StatelessWidget {', $helper + 'class ProductsScreen extends StatelessWidget {')
}

if ($src -notmatch "Open Bunnings") {
  $old = "CupertinoButton(padding: EdgeInsets.zero, minSize: 34, onPressed: onDelete, child: const Text('Delete', maxLines: 1, style: TextStyle(color: C.red, fontWeight: FontWeight.w900, fontSize: 12))),"
  $new = "Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [`r`n            CupertinoButton(padding: EdgeInsets.zero, minSize: 32, onPressed: () => openBunningsForProduct(product), child: const Text('Bunnings', maxLines: 1, style: TextStyle(color: C.forest, fontWeight: FontWeight.w900, fontSize: 12))),`r`n            CupertinoButton(padding: EdgeInsets.zero, minSize: 32, onPressed: onDelete, child: const Text('Delete', maxLines: 1, style: TextStyle(color: C.red, fontWeight: FontWeight.w900, fontSize: 12))),`r`n          ]),"
  if ($src.Contains($old)) {
    $src = $src.Replace($old, $new)
  } else {
    $fallbackOld = "CupertinoButton(padding: EdgeInsets.zero, minSize: 34, onPressed: onDelete, child: const Text('Delete', style: TextStyle(color: C.red, fontWeight: FontWeight.w900, fontSize: 12)))"
    $fallbackNew = "Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [`r`n            CupertinoButton(padding: EdgeInsets.zero, minSize: 32, onPressed: () => openBunningsForProduct(product), child: const Text('Bunnings', maxLines: 1, style: TextStyle(color: C.forest, fontWeight: FontWeight.w900, fontSize: 12))),`r`n            CupertinoButton(padding: EdgeInsets.zero, minSize: 32, onPressed: onDelete, child: const Text('Delete', maxLines: 1, style: TextStyle(color: C.red, fontWeight: FontWeight.w900, fontSize: 12))),`r`n          ])"
    if ($src.Contains($fallbackOld)) {
      $src = $src.Replace($fallbackOld, $fallbackNew)
    } else {
      throw 'Could not find ProductTile Delete button to replace. Reset lib/main.dart or patch manually.'
    }
  }
}

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Applied Bunnings product search links to Products screen.'
Write-Host 'Each product now opens a Bunnings NZ search for the product/category.'
Write-Host 'Next: flutter pub get; flutter analyze; flutter run'
