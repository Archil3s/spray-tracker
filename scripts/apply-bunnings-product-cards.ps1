$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw

if ($src -notmatch "package:url_launcher/url_launcher.dart") {
  $src = $src.Replace("import 'package:flutter_svg/flutter_svg.dart';", "import 'package:flutter_svg/flutter_svg.dart';`r`nimport 'package:url_launcher/url_launcher.dart';")
}

$catalogBlock = @'
class BunningsSprayProduct {
  const BunningsSprayProduct({
    required this.name,
    required this.brand,
    required this.target,
    required this.type,
    required this.note,
    required this.searchQuery,
    required this.color,
    required this.background,
  });

  final String name;
  final String brand;
  final String target;
  final String type;
  final String note;
  final String searchQuery;
  final Color color;
  final Color background;
}

const bunningsSprayProducts = [
  BunningsSprayProduct(
    name: 'Nature\'s Way Neem Oil',
    brand: 'Yates / garden spray range',
    target: 'Pest / preventative',
    type: 'Neem oil spray',
    note: 'Good shortlist item for soft-bodied insect pressure. Check the label before edible-crop use.',
    searchQuery: 'neem oil garden spray',
    color: C.forest,
    background: C.forestSoft,
  ),
  BunningsSprayProduct(
    name: 'Liquid Copper Fungicide',
    brand: 'Yates / copper fungicide range',
    target: 'Fungus',
    type: 'Copper fungicide',
    note: 'Useful search card for mildew, blight, leaf spot and fungal-pressure decisions.',
    searchQuery: 'copper fungicide garden spray',
    color: C.blue,
    background: C.blueSoft,
  ),
  BunningsSprayProduct(
    name: 'Pyrethrum Insect Spray',
    brand: 'Yates / pyrethrum range',
    target: 'Pest',
    type: 'Contact insecticide',
    note: 'Use only when insect pressure is visible. Avoid spraying when bees are active.',
    searchQuery: 'pyrethrum garden spray',
    color: C.red,
    background: C.redSoft,
  ),
  BunningsSprayProduct(
    name: 'Fungus Spray',
    brand: 'Yates / garden disease range',
    target: 'Fungus',
    type: 'Garden fungicide',
    note: 'Search card for disease-specific products when humidity risk is high.',
    searchQuery: 'fungus spray garden',
    color: C.blue,
    background: C.blueSoft,
  ),
  BunningsSprayProduct(
    name: 'Organic Super Sulphur',
    brand: 'Kiwicare / organic garden range',
    target: 'Fungus / mites',
    type: 'Sulphur fungicide',
    note: 'Useful for some fungal issues. Check temperature and crop-safety label limits.',
    searchQuery: 'organic sulphur fungicide garden',
    color: C.amber,
    background: C.amberSoft,
  ),
  BunningsSprayProduct(
    name: 'Seaweed Plant Tonic',
    brand: 'Yates / Tui / seaweed range',
    target: 'Maintenance',
    type: 'Plant tonic',
    note: 'Not a pesticide. Useful for stress recovery and post-weather plant support.',
    searchQuery: 'seaweed plant tonic',
    color: C.purple,
    background: C.purpleSoft,
  ),
];

Uri bunningsProductSearchUri(String query) => Uri.https('www.bunnings.co.nz', '/search/products', {'q': query});

Future<void> openBunningsSearch(String query) async {
  final uri = bunningsProductSearchUri(query);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}

class BunningsSprayProductsPanel extends StatelessWidget {
  const BunningsSprayProductsPanel({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Bunnings spray products'),
          const SizedBox(height: 8),
          const Text(
            'Spray-focused product cards. Opens Bunnings NZ searches so current stock and prices stay on Bunnings.',
            style: TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ...bunningsSprayProducts.map((product) => BunningsSprayProductCard(product: product)),
          const SizedBox(height: 8),
        ],
      );
}

class BunningsSprayProductCard extends StatelessWidget {
  const BunningsSprayProductCard({required this.product, super.key});
  final BunningsSprayProduct product;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: product.background, borderRadius: BorderRadius.circular(15)),
                  child: Icon(CupertinoIcons.cube_box, color: product.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.ink)),
                      const SizedBox(height: 2),
                      Text(product.brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ProductTag(label: product.target, color: product.color, background: product.background),
                          ProductTag(label: product.type, color: C.forest, background: C.forestSoft),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(product.note, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.28)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text('Search: ${product.searchQuery}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 11))),
                const SizedBox(width: 10),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minSize: 0,
                  color: C.forest,
                  borderRadius: BorderRadius.circular(999),
                  onPressed: () => openBunningsSearch(product.searchQuery),
                  child: const Text('Open', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      );
}

class ProductTag extends StatelessWidget {
  const ProductTag({required this.label, required this.color, required this.background, super.key});
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10.5)),
      );
}

'@

if ($src -notmatch 'class BunningsSprayProduct') {
  $src = $src.Replace('class ProductsScreen extends StatelessWidget {', $catalogBlock + 'class ProductsScreen extends StatelessWidget {')
}

if ($src -notmatch 'BunningsSprayProductsPanel\(\)') {
  $old = "children: products.map((p) => ProductTile(product: p, onDelete: () => onDelete(p.id))).toList()"
  $new = "children: [const BunningsSprayProductsPanel(), const SectionTitle('My spray products'), const SizedBox(height: 8), ...products.map((p) => ProductTile(product: p, onDelete: () => onDelete(p.id)))]"
  if ($src.Contains($old)) {
    $src = $src.Replace($old, $new)
  } else {
    throw 'Could not find ProductsScreen children expression. Reset lib/main.dart or patch manually.'
  }
}

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Applied Bunnings spray product cards to Products screen.'
Write-Host 'Next: flutter pub get; flutter analyze; flutter run'
