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
    required this.url,
    required this.fallbackUrl,
    required this.color,
    required this.background,
  });

  final String name;
  final String brand;
  final String target;
  final String type;
  final String note;
  final String url;
  final String fallbackUrl;
  final Color color;
  final Color background;
}

const bunningsFungicideUrl = 'https://www.bunnings.co.nz/products/garden/pest-control/garden-pest-weed-control/fungicides';
const bunningsInsecticideUrl = 'https://www.bunnings.co.nz/products/garden/pest-control/garden-pest-weed-control/insecticides';
const bunningsHerbicideUrl = 'https://www.bunnings.co.nz/products/garden/pest-control/garden-pest-weed-control/herbicides';
const bunningsFertiliserUrl = 'https://www.bunnings.co.nz/products/garden/gardening/fertilisers';

const bunningsSprayProducts = [
  BunningsSprayProduct(
    name: "Yates 500ml Liquid Copper Concentrate",
    brand: "Yates",
    target: "Fungus",
    type: "Copper fungicide",
    note: "Direct Bunnings product card for fungal pressure. Always check edible-crop label directions and withholding periods.",
    url: "https://www.bunnings.co.nz/yates-liquid-copper-500ml_p0253771",
    fallbackUrl: bunningsFungicideUrl,
    color: C.blue,
    background: C.blueSoft,
  ),
  BunningsSprayProduct(
    name: "Yates 200ml Liquid Copper Concentrate",
    brand: "Yates",
    target: "Fungus",
    type: "Copper fungicide",
    note: "Smaller liquid copper option for mildew, blight and leaf-spot decisions where the product label supports the crop.",
    url: "https://www.bunnings.co.nz/yates-200ml-liquid-copper_p0201886",
    fallbackUrl: bunningsFungicideUrl,
    color: C.blue,
    background: C.blueSoft,
  ),
  BunningsSprayProduct(
    name: "Yates 200g Copper Oxychloride Fungicide",
    brand: "Yates",
    target: "Fungus",
    type: "Copper fungicide powder",
    note: "Direct product card for copper oxychloride. Useful as a fungicide reference, not an automatic spray recommendation.",
    url: "https://www.bunnings.co.nz/yates-200g-copper-oxychloride-fungicide_p0595263",
    fallbackUrl: bunningsFungicideUrl,
    color: C.blue,
    background: C.blueSoft,
  ),
  BunningsSprayProduct(
    name: "Yates 200g Nature's Way Fungus Spray",
    brand: "Yates Nature's Way",
    target: "Fungus",
    type: "Copper + sulphur",
    note: "Copper and sulphur fungus product card. Check temperature limits and crop label before spraying.",
    url: "https://www.bunnings.co.nz/yates-200g-natures-way-fungus-spray_p0571701",
    fallbackUrl: bunningsFungicideUrl,
    color: C.blue,
    background: C.blueSoft,
  ),
  BunningsSprayProduct(
    name: "OCP Eco-Fungicide RTU 750ml",
    brand: "OCP",
    target: "Fungus",
    type: "Ready-to-use fungicide",
    note: "Ready-to-use fungus option. Good card for small jobs and spot checks when humidity risk is high.",
    url: "https://www.bunnings.co.nz/ocp-eco-fungicide-rtu-750ml_p0338689",
    fallbackUrl: bunningsFungicideUrl,
    color: C.blue,
    background: C.blueSoft,
  ),
  BunningsSprayProduct(
    name: "Kiwicare Plant Health Fungus Control RTU 750ml",
    brand: "Kiwicare",
    target: "Fungus",
    type: "Ready-to-use fungus control",
    note: "Bunnings fungus-control card for disease pressure. Confirm crop suitability on the label.",
    url: "https://www.bunnings.co.nz/kiwicare-750ml-plant-health-ready-to-use-fungus-control_p0203440",
    fallbackUrl: bunningsFungicideUrl,
    color: C.blue,
    background: C.blueSoft,
  ),
  BunningsSprayProduct(
    name: "Yates 750ml Fungus Gun RTU",
    brand: "Yates",
    target: "Fungus",
    type: "Ready-to-use fungicide",
    note: "RTU disease-control card. Useful for checking Bunnings availability and label details.",
    url: "https://www.bunnings.co.nz/yates-750ml-fungus-gun_p0771763",
    fallbackUrl: bunningsFungicideUrl,
    color: C.blue,
    background: C.blueSoft,
  ),
  BunningsSprayProduct(
    name: "Yates 750ml Mavrik Insect Spray",
    brand: "Yates",
    target: "Pest",
    type: "Ready-to-use insecticide",
    note: "Insect-pressure product card. Only consider when pests are visible and avoid spraying when bees are active.",
    url: "https://www.bunnings.co.nz/yates-750ml-mavrik-insect-spray_p0307179",
    fallbackUrl: bunningsInsecticideUrl,
    color: C.red,
    background: C.redSoft,
  ),
  BunningsSprayProduct(
    name: "Yates 200ml Mavrik Insect Spray",
    brand: "Yates",
    target: "Pest",
    type: "Insecticide concentrate",
    note: "Concentrate insecticide card for visible pest pressure. Check label, PPE and withholding guidance.",
    url: "https://www.bunnings.co.nz/yates-200ml-mavrik-insect-spray_p0641297",
    fallbackUrl: bunningsInsecticideUrl,
    color: C.red,
    background: C.redSoft,
  ),
  BunningsSprayProduct(
    name: "Yates 200ml Success Ultra Insect Control",
    brand: "Yates",
    target: "Pest",
    type: "Insect control",
    note: "Useful pest-control card for caterpillar/thrips-type decisions when label supports your crop.",
    url: "https://www.bunnings.co.nz/yates-200ml-success-ultra-insect-control_p0281582",
    fallbackUrl: bunningsInsecticideUrl,
    color: C.red,
    background: C.redSoft,
  ),
  BunningsSprayProduct(
    name: "Yates 200ml Nature's Way Vegie Insect Concentrate",
    brand: "Yates Nature's Way",
    target: "Pest",
    type: "Vegetable insect concentrate",
    note: "Vegetable-focused insect product card. Best linked to visible pest pressure, not routine spraying.",
    url: "https://www.bunnings.co.nz/yates-200ml-nature-s-way-vegie-insect-concentrate_p0296370",
    fallbackUrl: bunningsInsecticideUrl,
    color: C.red,
    background: C.redSoft,
  ),
  BunningsSprayProduct(
    name: "OCP Eco-Oil RTU 750ml",
    brand: "OCP",
    target: "Pest / preventative",
    type: "Ready-to-use oil spray",
    note: "Oil spray card for soft-bodied insects. Avoid heat stress and follow label restrictions.",
    url: "https://www.bunnings.co.nz/ocp-750ml-eco-oil-rtu_p0338691",
    fallbackUrl: bunningsInsecticideUrl,
    color: C.forest,
    background: C.forestSoft,
  ),
  BunningsSprayProduct(
    name: "Yates Sprayfix 200ml",
    brand: "Yates",
    target: "Spray support",
    type: "Wetting agent",
    note: "Wetting-agent card. This is a spray helper, not a pesticide; only use when compatible with the product label.",
    url: "https://www.bunnings.co.nz/yates-sprayfix-200ml_p0116798",
    fallbackUrl: bunningsInsecticideUrl,
    color: C.purple,
    background: C.purpleSoft,
  ),
  BunningsSprayProduct(
    name: "Roundup 1L Advance Liquid Concentrate",
    brand: "Roundup",
    target: "Weed control",
    type: "Herbicide concentrate",
    note: "Weed-control card. Keep separate from edible-crop spray decisions and follow all label safety directions.",
    url: "https://www.bunnings.co.nz/roundup-1l-advance-liquid-concentrate-weedkiller_p0725147",
    fallbackUrl: bunningsHerbicideUrl,
    color: C.amber,
    background: C.amberSoft,
  ),
  BunningsSprayProduct(
    name: "Roundup 5L Fast Action Spray Ready",
    brand: "Roundup",
    target: "Weed control",
    type: "Ready-to-use herbicide",
    note: "Ready-to-use weed-control card. Keep drift well away from beds and food crops.",
    url: "https://www.bunnings.co.nz/roundup-5l-fast-action-spray-ready-weedkiller_p0310329",
    fallbackUrl: bunningsHerbicideUrl,
    color: C.amber,
    background: C.amberSoft,
  ),
  BunningsSprayProduct(
    name: "Yates 1L Thrive Natural Vegie & Herb",
    brand: "Yates Thrive",
    target: "Maintenance",
    type: "Liquid fertiliser",
    note: "Liquid feed card for garden support. Not a pesticide; keep separate from pest/fungus spray logs.",
    url: "https://www.bunnings.co.nz/yates-1l-thrive-natural-vegie-and-herb-liquid-fertiliser_p2962094",
    fallbackUrl: bunningsFertiliserUrl,
    color: C.purple,
    background: C.purpleSoft,
  ),
  BunningsSprayProduct(
    name: "Yates 1L Thrive Natural Tomato & Vegie",
    brand: "Yates Thrive",
    target: "Maintenance",
    type: "Liquid fertiliser",
    note: "Liquid vegie feed card. Use as plant support rather than disease/pest treatment.",
    url: "https://www.bunnings.co.nz/yates-thrive-1l-natural-tomato-and-vegie-liquid-fertiliser_p2962090",
    fallbackUrl: bunningsFertiliserUrl,
    color: C.purple,
    background: C.purpleSoft,
  ),
  BunningsSprayProduct(
    name: "Seasol 1L Complete Garden Health Treatment",
    brand: "Seasol",
    target: "Maintenance",
    type: "Seaweed tonic",
    note: "Seaweed tonic card for stress recovery and general plant support. Not an insecticide or fungicide.",
    url: "https://www.bunnings.co.nz/seasol-1l-complete-garden-health-treatment_p3012812",
    fallbackUrl: bunningsFertiliserUrl,
    color: C.purple,
    background: C.purpleSoft,
  ),
  BunningsSprayProduct(
    name: "Seasol 2L Complete Garden Health Treatment",
    brand: "Seasol",
    target: "Maintenance",
    type: "Seaweed tonic",
    note: "Larger seaweed tonic card for garden support after weather stress or transplanting.",
    url: "https://www.bunnings.co.nz/seasol-2l-complete-garden-health-treatment_p3010405",
    fallbackUrl: bunningsFertiliserUrl,
    color: C.purple,
    background: C.purpleSoft,
  ),
];

Future<void> openBunningsUrl(String url, String fallbackUrl) async {
  final uri = Uri.parse(url);
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
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
            'Direct Bunnings NZ product cards for spray decisions. Prices and stock stay on Bunnings.',
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
                      Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.ink)),
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
                Expanded(child: Text(product.url.replaceFirst('https://www.bunnings.co.nz/', ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 11))),
                const SizedBox(width: 10),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minSize: 0,
                  color: C.forest,
                  borderRadius: BorderRadius.circular(999),
                  onPressed: () => openBunningsUrl(product.url, product.fallbackUrl),
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
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10.5)),
      );
}

'@

# Replace the whole previous Bunnings catalog block if it exists; otherwise insert it.
$pattern = 'class BunningsSprayProduct \{[\s\S]*?\r?\nclass ProductsScreen extends StatelessWidget \{'
if ($src -match $pattern) {
  $src = [regex]::Replace($src, $pattern, $catalogBlock + 'class ProductsScreen extends StatelessWidget {', 1)
} else {
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
Write-Host 'Applied direct Bunnings NZ product cards to Products screen.'
Write-Host 'Product cards now open actual Bunnings product URLs with category fallbacks.'
Write-Host 'Next: flutter pub get; flutter analyze; flutter run'
