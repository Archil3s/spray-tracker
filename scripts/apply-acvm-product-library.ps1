param([switch]$Run, [switch]$Push)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
$path = Join-Path $repo 'lib/main.dart'
$content = Get-Content $path -Raw

Write-Host "==> Integrating bundled NZ spray product dataset" -ForegroundColor Cyan

# Imports
if ($content -notmatch "data/acvm_product_repository.dart") {
  $content = $content.Replace(
    "import 'crop_library.dart';",
    "import 'crop_library.dart';`nimport 'data/acvm_product_repository.dart';`nimport 'models/spray_product.dart';"
  )
}

# Remove old local SprayProduct class so the app uses lib/models/spray_product.dart.
$content = [regex]::Replace(
  $content,
  "class SprayProduct \{\s*const SprayProduct\(\{required this\.id, required this\.name, required this\.type, required this\.days, required this\.targets\}\);\s*final int id;\s*final String name;\s*final String type;\s*final int days;\s*final List<String> targets;\s*\}\s*",
  "",
  [System.Text.RegularExpressions.RegexOptions]::Singleline
)

# Replace default hardcoded product samples with expanded fallback objects. Asset data loads over this after startup.
$content = [regex]::Replace(
  $content,
  "List<SprayProduct> defaultProducts\(\) => const \[.*?\]\s*\.toList\(\);",
@'
List<SprayProduct> defaultProducts() => const [
      SprayProduct(
        id: 'fallback_neem_oil',
        name: 'Neem Oil',
        brand: 'Fallback',
        type: 'Pest control',
        activeIngredient: 'Neem oil / Azadirachtin',
        withholdingDays: 0,
        withholdingNote: 'Fallback only — check label before harvest',
        reEntryHours: 1,
        category: 'organic',
        commonUses: ['aphids', 'mites', 'whitefly', 'scale'],
        suitableCrops: ['vegetables', 'herbs', 'fruit trees'],
        reSprayIntervalDays: 7,
        acvmRegistrationNumber: '',
        source: 'Fallback sample',
        notes: 'Bundled ACVM dataset loads from assets after startup.',
      ),
      SprayProduct(
        id: 'fallback_copper_hydroxide',
        name: 'Copper Hydroxide',
        brand: 'Fallback',
        type: 'Fungicide',
        activeIngredient: 'Copper hydroxide',
        withholdingDays: 0,
        withholdingNote: 'Fallback only — check label before harvest',
        reEntryHours: 1,
        category: 'chemical',
        commonUses: ['blight', 'leaf spot', 'rust', 'fungal disease'],
        suitableCrops: ['vegetables', 'fruit trees'],
        reSprayIntervalDays: 7,
        acvmRegistrationNumber: '',
        source: 'Fallback sample',
        notes: 'Bundled ACVM dataset loads from assets after startup.',
      ),
      SprayProduct(
        id: 'fallback_seaweed_tonic',
        name: 'Seaweed Tonic',
        brand: 'Fallback',
        type: 'Plant tonic',
        activeIngredient: 'Seaweed extract',
        withholdingDays: 0,
        withholdingNote: '0 day placeholder — check label',
        reEntryHours: 0,
        category: 'organic',
        commonUses: ['plant stress', 'transplant shock', 'general plant health'],
        suitableCrops: ['vegetables', 'herbs', 'fruit trees'],
        reSprayIntervalDays: 14,
        acvmRegistrationNumber: '',
        source: 'Fallback sample',
        notes: 'Plant tonic, not a pesticide.',
      ),
    ].toList();
'@,
  [System.Text.RegularExpressions.RegexOptions]::Singleline
)

# Load asset products on startup.
$content = $content.Replace(
"    products = defaultProducts();`n    resetToDemoData(silent: true);`n    fetchLiveWeather();",
"    products = defaultProducts();`n    resetToDemoData(silent: true);`n    loadBundledProducts();`n    fetchLiveWeather();"
)

if ($content -notmatch "Future<void> loadBundledProducts") {
$content = $content.Replace(
"  DateTime ago(int days) {",
@'
  Future<void> loadBundledProducts() async {
    try {
      final loaded = await AcvmProductRepository.instance.getAll();
      if (!mounted || loaded.isEmpty) return;
      setState(() {
        products = loaded;
        message = 'Loaded ${loaded.length} bundled NZ spray products';
      });
    } catch (_) {
      // Keep fallback products if the asset cannot be loaded.
    }
  }

  DateTime ago(int days) {
'@
)
}

# Make custom product IDs strings and expanded model fields.
$content = $content.Replace(
"  void removeProduct(int id) => setState(() {",
"  void removeProduct(String id) => setState(() {"
)
$content = [regex]::Replace(
  $content,
  "products\.add\(SprayProduct\(id: nextProductId\+\+, name: name, type: type, days: days, targets: const \['pest', 'fungus', 'prevent', 'maintain'\]\)\);",
@'
products.add(SprayProduct(
          id: 'custom_${nextProductId++}',
          name: name,
          brand: 'Custom',
          type: type,
          activeIngredient: '',
          withholdingDays: days,
          withholdingNote: 'Custom product — check label before harvest',
          reEntryHours: 0,
          category: 'chemical',
          commonUses: const ['pest', 'fungus', 'prevent', 'maintain'],
          suitableCrops: const ['vegetables'],
          reSprayIntervalDays: 0,
          acvmRegistrationNumber: '',
          source: 'User added',
          notes: '',
        ));
'@,
  [System.Text.RegularExpressions.RegexOptions]::Singleline
)

# Fix empty fallback product in spray log.
$content = $content.Replace(
"const SprayProduct(id: 0, name: 'No product', type: 'None', days: 0, targets: [])",
"const SprayProduct(id: 'none', name: 'No product', brand: '', type: 'None', activeIngredient: '', withholdingDays: 0, withholdingNote: '', reEntryHours: 0, category: 'homemade', commonUses: [], suitableCrops: [], reSprayIntervalDays: 0, acvmRegistrationNumber: '', source: '', notes: '')"
)

# Add helper notes under withholding stepper on Log Spray.
$content = $content.Replace(
"Stepper(label: 'Withholding days', value: days, minus: days > 0 ? () => setState(() => days--) : null, plus: () => setState(() => days++)),`n      const SizedBox(height: 18), PrimaryButton(label: 'Save spray record'",
"Stepper(label: 'Withholding days', value: days, minus: days > 0 ? () => setState(() => days--) : null, plus: () => setState(() => days++)),`n      const SizedBox(height: 8), SprayProductHelperNotes(product: product),`n      const SizedBox(height: 18), PrimaryButton(label: 'Save spray record'"
)

# Replace ProductsScreen with searchable ACVM library screen.
$content = [regex]::Replace(
  $content,
  "class ProductsScreen extends StatelessWidget \{.*?\n\}\s*\nclass TestingToolsCard",
@'
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({required this.products, required this.message, required this.onAdd, required this.onDelete, required this.onResetDemo, required this.onClearAll, super.key});
  final List<SprayProduct> products;
  final String message;
  final void Function(String name, String type, int days) onAdd;
  final ValueChanged<String> onDelete;
  final VoidCallback onResetDemo;
  final VoidCallback onClearAll;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim();
    final filtered = widget.products.where((product) => product.matchesQuery(query)).toList();
    return AppPage(
      title: 'Products',
      subtitle: 'Bundled NZ spray product library. Verify labels before use.',
      message: widget.message,
      trailing: CupertinoButton(padding: EdgeInsets.zero, minimumSize: Size.zero, onPressed: () => showProductDialog(context, widget.onAdd), child: const Text('+', style: TextStyle(color: C.forest, fontSize: 28, fontWeight: FontWeight.w900))),
      children: [
        TestingToolsCard(onResetDemo: widget.onResetDemo, onClearAll: widget.onClearAll),
        CupertinoTextField(
          controller: search,
          placeholder: 'Search product, pest, crop, active ingredient...',
          prefix: const Padding(padding: EdgeInsets.only(left: 12), child: Icon(CupertinoIcons.search, color: C.muted, size: 19)),
          padding: const EdgeInsets.all(13),
          onChanged: (_) => setState(() {}),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
        ),
        const SizedBox(height: 12),
        const SectionTitle('NZ spray products'),
        const SizedBox(height: 8),
        if (filtered.isEmpty) const EmptyCard('No products match that search.') else ...filtered.map((p) => ProductTile(product: p, onDelete: () => widget.onDelete(p.id))),
      ],
    );
  }
}

class TestingToolsCard
'@,
  [System.Text.RegularExpressions.RegexOptions]::Singleline
)

# Replace ProductTile with ACVM product card and detail sheet.
$content = [regex]::Replace(
  $content,
  "class ProductTile extends StatelessWidget \{.*?\n\}\s*\nclass FeedPresetChoice",
@'
class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, required this.onDelete, super.key});
  final SprayProduct product;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => showSprayProductDetail(context, product),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: C.ink))),
              CategoryPill(category: product.category),
            ]),
            const SizedBox(height: 4),
            Text('${product.brand} · ${product.type}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
            Text(product.activeIngredient, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              ProductTag(label: '${product.withholdingDays} day WHP', color: C.forest, background: C.forestSoft),
              ProductTag(label: 'Re-entry: ${product.reEntryHours} hr', color: C.blue, background: C.blueSoft),
              if (product.reSprayIntervalDays > 0) ProductTag(label: 'Re-spray: ${product.reSprayIntervalDays} days', color: C.amber, background: C.amberSoft),
            ]),
          ]),
        ),
      );
}

class CategoryPill extends StatelessWidget {
  const CategoryPill({required this.category, super.key});
  final String category;
  @override
  Widget build(BuildContext context) {
    final lower = category.toLowerCase();
    final color = lower == 'organic' ? C.forest : lower == 'chemical' ? C.amber : C.muted;
    final background = lower == 'organic' ? C.forestSoft : lower == 'chemical' ? C.amberSoft : C.soft;
    return ProductTag(label: category.isEmpty ? 'unknown' : category, color: color, background: background);
  }
}

class SprayProductHelperNotes extends StatelessWidget {
  const SprayProductHelperNotes({required this.product, super.key});
  final SprayProduct product;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (product.withholdingNote.isNotEmpty) Text(product.withholdingNote, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
        if (product.reSprayIntervalDays > 0) Padding(padding: const EdgeInsets.only(top: 3), child: Text('Re-spray interval: ${product.reSprayIntervalDays} days', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12))),
      ]);
}

void showSprayProductDetail(BuildContext context, SprayProduct product) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(title: product.name, subtitle: '${product.brand} · ${product.type}'),
          const SizedBox(height: 12),
          Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DetailLine('Category', product.category),
            DetailLine('Active ingredient', product.activeIngredient),
            DetailLine('Withholding days', '${product.withholdingDays}'),
            DetailLine('Withholding note', product.withholdingNote),
            DetailLine('Re-entry hours', '${product.reEntryHours}'),
            DetailLine('Re-spray interval', product.reSprayIntervalDays > 0 ? '${product.reSprayIntervalDays} days' : 'Not set'),
            DetailLine('Common uses', product.commonUses.join(', ')),
            DetailLine('Suitable crops', product.suitableCrops.join(', ')),
            DetailLine('ACVM number', product.acvmRegistrationNumber.isEmpty ? 'Not filled yet' : product.acvmRegistrationNumber),
            DetailLine('Source', product.source),
            DetailLine('Notes', product.notes.isEmpty ? 'None' : product.notes),
          ])),
        ],
      ),
    ),
  );
}

class DetailLine extends StatelessWidget {
  const DetailLine(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: C.forest, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '—' : value, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w700, height: 1.25)),
        ]),
      );
}

class FeedPresetChoice
'@,
  [System.Text.RegularExpressions.RegexOptions]::Singleline
)

[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "==> Formatting" -ForegroundColor Cyan
dart format lib/main.dart lib/models/spray_product.dart lib/data/acvm_product_repository.dart

Write-Host "==> Analyzing" -ForegroundColor Cyan
flutter analyze

if ($Run) {
  Write-Host "==> Running" -ForegroundColor Cyan
  flutter clean
  flutter pub get
  flutter run
}

if ($Push) {
  Write-Host "==> Committing and pushing" -ForegroundColor Cyan
  git add lib/main.dart lib/models/spray_product.dart lib/data/acvm_product_repository.dart assets/data/acvm_products.json pubspec.yaml scripts/apply-acvm-product-library.ps1
  git commit -m "Integrate bundled NZ spray product library"
  git push
}
