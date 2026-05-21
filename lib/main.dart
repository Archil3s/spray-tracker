import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'crop_library.dart';
import 'data/acvm_product_repository.dart';
import 'data/openfarm_service.dart';
import 'models/openfarm_crop.dart';
import 'models/spray_product.dart';

void main() => runApp(const SprayTrackerApp());

class SprayTrackerApp extends StatelessWidget {
  const SprayTrackerApp({super.key});

  @override
  Widget build(BuildContext context) => const CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'Spray Tracker',
        theme: CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: C.forest,
          scaffoldBackgroundColor: C.canvas,
          textTheme: CupertinoTextThemeData(textStyle: TextStyle(color: C.ink)),
        ),
        home: SprayTrackerHome(),
      );
}

class C {
  static const canvas = Color(0xFFF8F6F0);
  static const card = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF3EFE6);
  static const ink = Color(0xFF172018);
  static const muted = Color(0xFF667064);
  static const line = Color(0xFFE1DBCF);
  static const forest = Color(0xFF173F2A);
  static const forestSoft = Color(0xFFE8F0EA);
  static const soil = Color(0xFF735235);
  static const amber = Color(0xFFC77618);
  static const amberSoft = Color(0xFFFFEFD7);
  static const red = Color(0xFFB94A42);
  static const redSoft = Color(0xFFF8E4E1);
  static const blue = Color(0xFF2B6777);
  static const blueSoft = Color(0xFFE1F0F3);
  static const greySoft = Color(0xFFEDECE7);
}

final softShadow = [
  BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: .07),
      blurRadius: 18,
      offset: const Offset(0, 7))
];

BoxDecoration cardDecoration({Color color = C.card, double radius = 22}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: C.line),
      boxShadow: softShadow,
    );

String monthName(int month) => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][month - 1];
String shortDate(DateTime d) => '${d.day} ${monthName(d.month)}';

class GardenBed {
  const GardenBed(this.number, this.rect);
  final int number;
  final Rect rect;
}

const gardenBeds = [
  GardenBed(1, Rect.fromLTWH(.06, .08, .20, .12)),
  GardenBed(2, Rect.fromLTWH(.36, .08, .15, .31)),
  GardenBed(3, Rect.fromLTWH(.55, .08, .10, .085)),
  GardenBed(4, Rect.fromLTWH(.70, .08, .25, .07)),
  GardenBed(5, Rect.fromLTWH(.70, .18, .25, .07)),
  GardenBed(6, Rect.fromLTWH(.70, .28, .25, .07)),
  GardenBed(7, Rect.fromLTWH(.70, .38, .25, .07)),
  GardenBed(8, Rect.fromLTWH(.70, .48, .25, .07)),
  GardenBed(9, Rect.fromLTWH(.70, .58, .25, .07)),
  GardenBed(10, Rect.fromLTWH(.70, .68, .25, .07)),
  GardenBed(11, Rect.fromLTWH(.70, .78, .25, .08)),
  GardenBed(12, Rect.fromLTWH(.04, .42, .46, .07)),
  GardenBed(13, Rect.fromLTWH(.04, .53, .46, .07)),
  GardenBed(14, Rect.fromLTWH(.04, .64, .46, .07)),
  GardenBed(15, Rect.fromLTWH(.04, .75, .46, .07)),
  GardenBed(16, Rect.fromLTWH(.04, .92, .91, .045)),
  GardenBed(17, Rect.fromLTWH(.04, .01, .91, .04)),
];

class SprayTarget {
  const SprayTarget(
      this.id, this.title, this.short, this.color, this.softColor, this.icon);
  final String id;
  final String title;
  final String short;
  final Color color;
  final Color softColor;
  final IconData icon;
}

const sprayTargets = [
  SprayTarget('pest', 'Pest pressure', 'Pest', C.red, C.redSoft,
      CupertinoIcons.exclamationmark_triangle),
  SprayTarget('fungus', 'Fungal pressure', 'Fungus', C.blue, C.blueSoft,
      CupertinoIcons.drop),
  SprayTarget('prevent', 'Preventative', 'Prevent', C.forest, C.forestSoft,
      CupertinoIcons.shield),
  SprayTarget('maintain', 'Plant support', 'Support', C.amber, C.amberSoft,
      CupertinoIcons.leaf_arrow_circlepath),
];

SprayTarget targetById(String id) => sprayTargets
    .firstWhere((target) => target.id == id, orElse: () => sprayTargets.first);

class SprayRecord {
  const SprayRecord({
    required this.id,
    required this.beds,
    required this.crops,
    required this.cropProfiles,
    required this.targetId,
    required this.product,
    required this.productId,
    required this.reason,
    required this.notes,
    required this.date,
    required this.days,
  });

  final int id;
  final List<int> beds;
  final List<String> crops;
  final Map<String, OpenFarmCrop> cropProfiles;
  final String targetId;
  final String product;
  final String productId;
  final String reason;
  final String notes;
  final DateTime date;
  final int days;

  DateTime get safeDate => date.add(Duration(days: days));
  bool get onHold => safeDate.isAfter(DateTime.now());
}

class SprayTrackerHome extends StatefulWidget {
  const SprayTrackerHome({super.key});

  @override
  State<SprayTrackerHome> createState() => _SprayTrackerHomeState();
}

class _SprayTrackerHomeState extends State<SprayTrackerHome> {
  int tab = 0;
  int selectedBed = 4;
  int nextRecordId = 1;
  String message = '';

  List<SprayProduct> products = const [];
  bool productsLoading = true;
  final Map<int, List<VegetableDefinition>> bedCrops = {};
  List<SprayRecord> records = [];

  @override
  void initState() {
    super.initState();
    _seedBeds();
    _loadProducts();
  }

  void _seedBeds() {
    VegetableDefinition byId(String id) =>
        vegetableLibrary.firstWhere((crop) => crop.id == id,
            orElse: () => vegetableLibrary.first);
    bedCrops[4] = [byId('tomato'), byId('chilli'), byId('capsicum')];
    bedCrops[5] = [byId('onion'), byId('garlic')];
    bedCrops[9] = [byId('zucchini')];
    bedCrops[2] = [byId('lettuce')];
  }

  Future<void> _loadProducts() async {
    try {
      final loaded = await AcvmProductRepository.instance.getAll();
      if (!mounted) return;
      setState(() {
        products = loaded;
        productsLoading = false;
        message = 'Loaded ${loaded.length} NZ spray products';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        products = fallbackProducts();
        productsLoading = false;
        message = 'Using fallback products â€” asset failed to load';
      });
    }
  }

  void addCrop(int bed, VegetableDefinition crop) {
    final next = [...bedCrops[bed] ?? <VegetableDefinition>[]];
    if (!next.any((item) => item.id == crop.id)) next.add(crop);
    setState(() {
      bedCrops[bed] = next;
      selectedBed = bed;
      message = '${crop.name} added to Bed $bed';
    });
  }

  void removeCrop(int bed, VegetableDefinition crop) {
    final next = [...bedCrops[bed] ?? <VegetableDefinition>[]]
      ..removeWhere((item) => item.id == crop.id);
    setState(() {
      if (next.isEmpty) {
        bedCrops.remove(bed);
      } else {
        bedCrops[bed] = next;
      }
      message = '${crop.name} removed from Bed $bed';
    });
  }

  void saveSpray({
    required Set<int> beds,
    required Set<String> crops,
    required Map<String, OpenFarmCrop> cropProfiles,
    required String targetId,
    required SprayProduct product,
    required String reason,
    required String notes,
    required int days,
  }) {
    if (beds.isEmpty) return;
    final sortedBeds = beds.toList()..sort();
    final sortedCrops = crops.toList()..sort();
    setState(() {
      records.insert(
        0,
        SprayRecord(
          id: nextRecordId++,
          beds: sortedBeds,
          crops: sortedCrops.isEmpty ? ['Whole bed'] : sortedCrops,
          cropProfiles: Map.unmodifiable(cropProfiles),
          targetId: targetId,
          product: product.name,
          productId: product.id,
          reason: reason.trim(),
          notes: notes.trim(),
          date: DateTime.now(),
          days: days,
        ),
      );
      selectedBed = sortedBeds.first;
      message = 'Spray record saved';
      tab = 0;
    });
  }

  void deleteRecord(int id) => setState(() {
        records = records.where((record) => record.id != id).toList();
        message = 'Record removed';
      });

  bool bedOnHold(int bed) =>
      records.any((record) => record.beds.contains(bed) && record.onHold);

  int get clearBeds => gardenBeds.where((bed) => !bedOnHold(bed.number)).length;
  int get holdBeds => gardenBeds.length - clearBeds;
  int get plantedBeds =>
      bedCrops.values.where((items) => items.isNotEmpty).length;
  int get cropPlacements =>
      bedCrops.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        clearBeds: clearBeds,
        holdBeds: holdBeds,
        plantedBeds: plantedBeds,
        cropPlacements: cropPlacements,
        records: records,
        products: products,
        message: message,
        onPlanSpray: () => setState(() => tab = 2),
        onOpenProducts: () => setState(() => tab = 4),
      ),
      GardenScreen(
        selectedBed: selectedBed,
        bedCrops: bedCrops,
        isHold: bedOnHold,
        message: message,
        onSelectBed: (bed) => setState(() => selectedBed = bed),
        onAddCrop: addCrop,
        onRemoveCrop: removeCrop,
        onStartSpray: () => setState(() => tab = 2),
      ),
      SprayLogScreen(
        key: ValueKey('${products.length}-${records.length}'),
        initialBeds: {selectedBed},
        initialCrops: (bedCrops[selectedBed] ?? const <VegetableDefinition>[])
            .map((crop) => crop.name)
            .toSet(),
        products: products,
        productsLoading: productsLoading,
        onSave: saveSpray,
      ),
      RecordsScreen(records: records, message: message, onDelete: deleteRecord),
      ProductsScreen(
          products: products, loading: productsLoading, message: message),
    ];

    return CupertinoPageScaffold(
      backgroundColor: C.canvas,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: IndexedStack(index: tab, children: pages)),
            BottomNav(tab: tab, onTap: (value) => setState(() => tab = value)),
          ],
        ),
      ),
    );
  }
}

List<SprayProduct> fallbackProducts() => const [
      SprayProduct(
        id: 'fallback_neem_oil',
        name: 'Neem Oil',
        brand: 'Fallback',
        type: 'Pest control',
        activeIngredient: 'Neem oil / Azadirachtin',
        withholdingDays: 0,
        withholdingNote: 'Fallback only â€” check label before harvest',
        reEntryHours: 1,
        category: 'organic',
        commonUses: ['aphids', 'mites', 'whitefly', 'scale'],
        suitableCrops: ['vegetables', 'herbs', 'fruit trees'],
        reSprayIntervalDays: 7,
        acvmRegistrationNumber: '',
        source: 'Fallback sample',
        notes: 'ACVM product dataset did not load.',
      ),
    ];

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.clearBeds,
    required this.holdBeds,
    required this.plantedBeds,
    required this.cropPlacements,
    required this.records,
    required this.products,
    required this.message,
    required this.onPlanSpray,
    required this.onOpenProducts,
    super.key,
  });

  final int clearBeds;
  final int holdBeds;
  final int plantedBeds;
  final int cropPlacements;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final String message;
  final VoidCallback onPlanSpray;
  final VoidCallback onOpenProducts;

  @override
  Widget build(BuildContext context) {
    final active = records.where((record) => record.onHold).toList();
    return AppPage(
      title: 'Fieldbook',
      subtitle: 'Spray records, product safety, and harvest holds.',
      message: message,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: C.forest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: softShadow),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Today',
                style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Spray status',
                style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: HeroMetric(
                      label: 'CLEAR BEDS',
                      value: '$clearBeds',
                      color: CupertinoColors.white)),
              const SizedBox(width: 10),
              Expanded(
                  child: HeroMetric(
                      label: 'ON HOLD', value: '$holdBeds', color: C.amber)),
            ]),
            const SizedBox(height: 14),
            Text(
                '$plantedBeds beds planted Â· $cropPlacements crop placements Â· ${products.length} NZ products',
                style: const TextStyle(
                    color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: CupertinoButton(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: onPlanSpray,
                      child: const Text('Plan a spray',
                          style: TextStyle(
                              color: C.forest, fontWeight: FontWeight.w900)))),
              const SizedBox(width: 10),
              Expanded(
                  child: CupertinoButton(
                      color: const Color(0x18FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      onPressed: onOpenProducts,
                      child: const Text('Products',
                          style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w900)))),
            ]),
          ]),
        ),
        const SizedBox(height: 18),
        const SectionTitle('Next safe harvest'),
        const SizedBox(height: 8),
        if (active.isEmpty)
          const EmptyCard('No active withholding periods.')
        else
          RecordCard(record: active.first),
        const SizedBox(height: 18),
        const SectionTitle('Recent activity'),
        const SizedBox(height: 8),
        if (records.isEmpty)
          const EmptyCard(
              'No spray records yet. Use Spray Log to test the new product library.')
        else
          ...records.take(3).map((record) => RecordCard(record: record)),
      ],
    );
  }
}

class HeroMetric extends StatelessWidget {
  const HeroMetric(
      {required this.label,
      required this.value,
      required this.color,
      super.key});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0x12FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x28FFFFFF))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w900, color: color)),
        ]),
      );
}

class GardenScreen extends StatelessWidget {
  const GardenScreen(
      {required this.selectedBed,
      required this.bedCrops,
      required this.isHold,
      required this.message,
      required this.onSelectBed,
      required this.onAddCrop,
      required this.onRemoveCrop,
      required this.onStartSpray,
      super.key});
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final bool Function(int bed) isHold;
  final String message;
  final ValueChanged<int> onSelectBed;
  final void Function(int bed, VegetableDefinition crop) onAddCrop;
  final void Function(int bed, VegetableDefinition crop) onRemoveCrop;
  final VoidCallback onStartSpray;

  @override
  Widget build(BuildContext context) {
    final crops = bedCrops[selectedBed] ?? const <VegetableDefinition>[];
    return AppPage(
      title: 'Garden',
      subtitle: 'Tap a bed, assign crops, then log sprays against that bed.',
      message: message,
      children: [
        Panel(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
                height: 500,
                child: GardenMap(
                    selectedBed: selectedBed,
                    bedCrops: bedCrops,
                    isHold: isHold,
                    onTap: onSelectBed))),
        const SizedBox(height: 14),
        Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('Bed $selectedBed',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: C.forest))),
            StatusPill(isHold(selectedBed) ? 'HOLD' : 'CLEAR',
                hold: isHold(selectedBed))
          ]),
          const SizedBox(height: 4),
          Text(
              crops.isEmpty
                  ? 'No crops assigned'
                  : crops.map((crop) => crop.name).join(' Â· '),
              style:
                  const TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (crops.isEmpty)
            const EmptyInline(
                'Add crops to unlock crop-specific spray logging.')
          else
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: crops
                    .map((crop) => CropChip(
                        crop: crop,
                        onRemove: () => onRemoveCrop(selectedBed, crop)))
                    .toList()),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: SecondaryButton(
                    label: 'Add crop',
                    onPressed: () => showCropPicker(
                        context, selectedBed, crops, onAddCrop))),
            const SizedBox(width: 10),
            Expanded(
                child:
                    PrimaryButton(label: 'Spray log', onPressed: onStartSpray)),
          ]),
        ])),
      ],
    );
  }
}

class GardenMap extends StatelessWidget {
  const GardenMap(
      {required this.selectedBed,
      required this.bedCrops,
      required this.isHold,
      required this.onTap,
      super.key});
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final bool Function(int bed) isHold;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          ...gardenBeds.map((bed) {
            final rect = Rect.fromLTWH(
                bed.rect.left * size.width,
                bed.rect.top * size.height,
                bed.rect.width * size.width,
                bed.rect.height * size.height);
            return Positioned.fromRect(
                rect: rect,
                child: BedButton(
                    number: bed.number,
                    selected: selectedBed == bed.number,
                    hold: isHold(bed.number),
                    crops:
                        bedCrops[bed.number] ?? const <VegetableDefinition>[],
                    onTap: () => onTap(bed.number)));
          }),
        ]);
      });
}

class BedButton extends StatelessWidget {
  const BedButton(
      {required this.number,
      required this.selected,
      required this.hold,
      required this.crops,
      required this.onTap,
      super.key});
  final int number;
  final bool selected;
  final bool hold;
  final List<VegetableDefinition> crops;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
              color: hold
                  ? C.amberSoft
                  : crops.isEmpty
                      ? C.card
                      : C.forestSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? C.forest : C.soil,
                  width: selected ? 2.4 : 1.2)),
          child: Stack(clipBehavior: Clip.none, children: [
            Center(
                child: Text('$number',
                    style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12))),
            if (crops.isNotEmpty)
              Positioned(
                  top: -12, right: -12, child: IconCluster(crops: crops)),
          ]),
        ),
      );
}

class IconCluster extends StatelessWidget {
  const IconCluster({required this.crops, super.key});
  final List<VegetableDefinition> crops;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 104),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: C.line),
            boxShadow: softShadow),
        child: Wrap(spacing: 2, runSpacing: 2, children: [
          ...crops.take(3).map((crop) => CropIcon(crop.iconPath, size: 20)),
          if (crops.length > 3) CountDot(crops.length - 3),
        ]),
      );
}

class SprayLogScreen extends StatefulWidget {
  const SprayLogScreen(
      {required this.initialBeds,
      required this.initialCrops,
      required this.products,
      required this.productsLoading,
      required this.onSave,
      super.key});
  final Set<int> initialBeds;
  final Set<String> initialCrops;
  final List<SprayProduct> products;
  final bool productsLoading;
  final void Function(
      {required Set<int> beds,
      required Set<String> crops,
      required Map<String, OpenFarmCrop> cropProfiles,
      required String targetId,
      required SprayProduct product,
      required String reason,
      required String notes,
      required int days}) onSave;

  @override
  State<SprayLogScreen> createState() => _SprayLogScreenState();
}

class _SprayLogScreenState extends State<SprayLogScreen> {
  late Set<int> beds = {...widget.initialBeds};
  late Set<String> crops = {...widget.initialCrops};
  final Map<String, OpenFarmCrop> cropProfiles = {};
  String targetId = 'pest';
  SprayProduct? selectedProduct;
  int days = 0;
  final reason = TextEditingController();
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.products.isNotEmpty)
      _selectProduct(_bestProductForTarget('pest'));
  }

  @override
  void dispose() {
    reason.dispose();
    notes.dispose();
    super.dispose();
  }

  SprayProduct _bestProductForTarget(String target) {
    return widget.products.firstWhere(
        (product) => product.targets.contains(target),
        orElse: () => widget.products.first);
  }

  void _selectProduct(SprayProduct product) {
    selectedProduct = product;
    days = product.withholdingDays;
  }

  @override
  Widget build(BuildContext context) {
    final product = selectedProduct;
    return AppPage(
      title: 'Spray Log',
      subtitle:
          'Choose product, then withholding and re-entry notes fill automatically.',
      children: [
        const SectionTitle('Beds sprayed'),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: gardenBeds
                .map((bed) => NumberChip(
                    label: '${bed.number}',
                    selected: beds.contains(bed.number),
                    onTap: () => setState(() => beds.contains(bed.number)
                        ? beds.remove(bed.number)
                        : beds.add(bed.number))))
                .toList()),
        const SizedBox(height: 18),
        const SectionTitle('Crops affected'),
        const SizedBox(height: 8),
        if (crops.isEmpty)
          const EmptyCard('No crops assigned to selected bed yet.')
        else
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: crops.map((crop) => TextChip(label: crop)).toList()),
        const SizedBox(height: 18),
        const SectionTitle('Spraying against'),
        const SizedBox(height: 8),
        TargetGrid(
            selected: targetId,
            onSelect: (id) => setState(() {
                  targetId = id;
                  if (widget.products.isNotEmpty)
                    _selectProduct(_bestProductForTarget(id));
                })),
        const SizedBox(height: 18),
        const SectionTitle('NZ product library'),
        const SizedBox(height: 8),
        if (widget.productsLoading)
          const Center(child: CupertinoActivityIndicator())
        else if (widget.products.isEmpty)
          const EmptyCard('No products loaded.')
        else
          ...widget.products.map((item) => ProductChoice(
              product: item,
              selected: product?.id == item.id,
              suggested: item.targets.contains(targetId),
              onTap: () => setState(() => _selectProduct(item)))),
        const SizedBox(height: 18),
        Field(
            controller: reason,
            placeholder: 'Issue or reason, e.g. aphids on tomato tips'),
        const SizedBox(height: 8),
        Field(controller: notes, placeholder: 'Notes optional', maxLines: 3),
        const SizedBox(height: 12),
        Stepper(
            label: 'Withholding days',
            value: days,
            minus: days > 0 ? () => setState(() => days--) : null,
            plus: () => setState(() => days++)),
        if (product != null) ...[
          const SizedBox(height: 8),
          SprayProductHelperNotes(product: product),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
            label: 'Save spray record',
            onPressed: product == null || beds.isEmpty
                ? null
                : () => widget.onSave(
                    beds: beds,
                    crops: crops,
                    cropProfiles: cropProfiles,
                    targetId: targetId,
                    product: product,
                    reason: reason.text,
                    notes: notes.text,
                    days: days)),
      ],
    );
  }
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen(
      {required this.products,
      required this.loading,
      required this.message,
      super.key});
  final List<SprayProduct> products;
  final bool loading;
  final String message;

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
    final filtered = widget.products
        .where((product) => product.matchesQuery(query))
        .toList();
    return AppPage(
      title: 'Products',
      subtitle:
          'Bundled NZ spray products. Verify labels and ACVM details before use.',
      message: widget.message,
      children: [
        CupertinoTextField(
          controller: search,
          placeholder: 'Search product, pest, crop, active ingredient...',
          prefix: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(CupertinoIcons.search, color: C.muted, size: 19)),
          padding: const EdgeInsets.all(13),
          onChanged: (_) => setState(() {}),
          decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.line)),
        ),
        const SizedBox(height: 12),
        SectionTitle('NZ spray product library',
            trailing: Text('${filtered.length}',
                style: const TextStyle(
                    color: C.muted, fontWeight: FontWeight.w900))),
        const SizedBox(height: 8),
        if (widget.loading)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CupertinoActivityIndicator()))
        else if (filtered.isEmpty)
          const EmptyCard('No products match that search.')
        else
          ...filtered.map((product) => ProductTile(product: product)),
      ],
    );
  }
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen(
      {required this.records,
      required this.message,
      required this.onDelete,
      super.key});
  final List<SprayRecord> records;
  final String message;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Records',
        subtitle: 'Saved sprays, target, product, and safe harvest date.',
        message: message,
        children: [
          if (records.isEmpty)
            const EmptyCard('No spray records yet.')
          else
            ...records.map((record) => RecordCard(
                record: record, onDelete: () => onDelete(record.id))),
        ],
      );
}

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, super.key});
  final SprayProduct product;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => showSprayProductDetail(context, product),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: C.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16))),
              CategoryPill(category: product.category),
            ]),
            const SizedBox(height: 4),
            Text('${product.brand} Â· ${product.type}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: C.muted, fontWeight: FontWeight.w700)),
            Text(product.activeIngredient,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: C.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              ProductTag(
                  label: '${product.withholdingDays} day WHP',
                  color: C.forest,
                  background: C.forestSoft),
              ProductTag(
                  label: 'Re-entry: ${product.reEntryHours} hr',
                  color: C.blue,
                  background: C.blueSoft),
              if (product.reSprayIntervalDays > 0)
                ProductTag(
                    label: 'Re-spray: ${product.reSprayIntervalDays} days',
                    color: C.amber,
                    background: C.amberSoft),
            ]),
            if (product.commonUses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Uses: ${product.commonUses.take(5).join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: C.ink, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
      );
}

class ProductChoice extends StatelessWidget {
  const ProductChoice(
      {required this.product,
      required this.selected,
      required this.suggested,
      required this.onTap,
      super.key});
  final SprayProduct product;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: selected ? C.forestSoft : C.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? C.forest : C.line)),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: C.ink, fontWeight: FontWeight.w900)),
                  Text(
                      '${product.type} Â· ${product.withholdingDays} day WHP Â· Re-entry ${product.reEntryHours} hr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: C.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ])),
            if (suggested) ...[
              const SizedBox(width: 8),
              const StatusPill('MATCH', hold: false)
            ],
            const SizedBox(width: 8),
            Text(selected ? 'âœ“' : 'â—‹',
                style: TextStyle(
                    color: selected ? C.forest : C.muted,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
          ]),
        ),
      );
}

class SprayProductHelperNotes extends StatelessWidget {
  const SprayProductHelperNotes({required this.product, super.key});
  final SprayProduct product;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: C.soft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (product.withholdingNote.isNotEmpty)
            Text(product.withholdingNote,
                style: const TextStyle(
                    color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          Text('Re-entry: ${product.reEntryHours} hr',
              style: const TextStyle(
                  color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          if (product.reSprayIntervalDays > 0)
            Text('Re-spray interval: ${product.reSprayIntervalDays} days',
                style: const TextStyle(
                    color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      );
}

void showSprayProductDetail(BuildContext context, SprayProduct product) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(
              title: product.name,
              subtitle: '${product.brand} Â· ${product.type}'),
          const SizedBox(height: 12),
          Panel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                DetailLine('Category', product.category),
                DetailLine('Active ingredient', product.activeIngredient),
                DetailLine('Withholding days', '${product.withholdingDays}'),
                DetailLine('Withholding note', product.withholdingNote),
                DetailLine('Re-entry hours', '${product.reEntryHours}'),
                DetailLine(
                    'Re-spray interval',
                    product.reSprayIntervalDays > 0
                        ? '${product.reSprayIntervalDays} days'
                        : 'Not set'),
                DetailLine('Common uses', product.commonUses.join(', ')),
                DetailLine('Suitable crops', product.suitableCrops.join(', ')),
                DetailLine(
                    'ACVM number',
                    product.acvmRegistrationNumber.isEmpty
                        ? 'Not filled yet'
                        : product.acvmRegistrationNumber),
                DetailLine('Source', product.source),
                DetailLine(
                    'Notes', product.notes.isEmpty ? 'None' : product.notes),
              ])),
        ],
      ),
    ),
  );
}

void showCropPicker(
    BuildContext context,
    int bed,
    List<VegetableDefinition> assigned,
    void Function(int bed, VegetableDefinition crop) onAdd) {
  showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Sheet(
              child: ListView(padding: const EdgeInsets.all(20), children: [
            SheetHeader(title: 'Add crop', subtitle: 'Bed $bed'),
            const SizedBox(height: 12),
            ...vegetableLibrary.map((crop) {
              final added = assigned.any((item) => item.id == crop.id);
              return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: added
                      ? null
                      : () {
                          onAdd(bed, crop);
                          Navigator.pop(context);
                        },
                  child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: cardDecoration(),
                      child: Row(children: [
                        CropIcon(crop.iconPath, size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(crop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: C.ink,
                                      fontWeight: FontWeight.w900)),
                              Text(crop.familyId,
                                  style: const TextStyle(
                                      color: C.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700))
                            ])),
                        StatusPill(added ? 'ADDED' : 'ADD', hold: false)
                      ])));
            })
          ])));
}

class CropLookupField extends StatefulWidget {
  const CropLookupField({required this.onCropChosen, super.key});

  final void Function(String cropName, OpenFarmCrop? crop) onCropChosen;

  @override
  State<CropLookupField> createState() => _CropLookupFieldState();
}

class _CropLookupFieldState extends State<CropLookupField> {
  final controller = TextEditingController();
  Timer? debounce;
  List<OpenFarmCrop> suggestions = const [];
  bool loading = false;
  bool searched = false;

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    debounce?.cancel();

    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        suggestions = const [];
        loading = false;
        searched = false;
      });
      return;
    }

    setState(() {
      loading = true;
      searched = false;
    });

    debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await OpenFarmService.instance.searchCrops(query);
      if (!mounted) return;
      setState(() {
        suggestions = results.take(8).toList();
        loading = false;
        searched = true;
      });
    });
  }

  void _choose(OpenFarmCrop crop) {
    controller.text = crop.name;
    widget.onCropChosen(crop.name, crop);
    setState(() {
      suggestions = const [];
      searched = false;
      loading = false;
    });
  }

  void _addManual() {
    final clean = controller.text.trim();
    if (clean.isEmpty) return;
    widget.onCropChosen(clean, null);
    setState(() {
      controller.clear();
      suggestions = const [];
      searched = false;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canAddManual = controller.text.trim().isNotEmpty;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CupertinoTextField(
        controller: controller,
        placeholder: 'Search crop, e.g. tomato, lettuce, carrot...',
        prefix: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(CupertinoIcons.search, color: C.muted, size: 19),
        ),
        suffix: canAddManual
            ? CupertinoButton(
                padding: const EdgeInsets.only(right: 10),
                minimumSize: Size.zero,
                onPressed: _addManual,
                child: const Text('Add',
                    style: TextStyle(
                        color: C.forest, fontWeight: FontWeight.w900)),
              )
            : null,
        padding: const EdgeInsets.all(13),
        onChanged: _search,
        onSubmitted: (_) => _addManual(),
        decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line)),
      ),
      if (loading)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: C.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.line)),
          child: const Row(children: [
            CupertinoActivityIndicator(),
            SizedBox(width: 10),
            Text('Searching OpenFarm...',
                style: TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
          ]),
        ),
      if (!loading && suggestions.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: cardDecoration(radius: 16),
          child: Column(
            children: suggestions
                .map((crop) => CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _choose(crop),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: C.line))),
                        child: Row(children: [
                          OpenFarmImageBox(imageUrl: crop.imageUrl, size: 42),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(crop.name,
                                      style: const TextStyle(
                                          color: C.ink,
                                          fontWeight: FontWeight.w900)),
                                  Text(
                                    crop.sunRequirements.isEmpty
                                        ? 'OpenFarm crop profile'
                                        : crop.sunRequirements,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: C.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ]),
                          ),
                        ]),
                      ),
                    ))
                .toList(),
          ),
        ),
      if (!loading && searched && suggestions.isEmpty)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: C.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.line)),
          child: const Text('No matches — type to enter manually',
              style: TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
        ),
    ]);
  }
}

class OpenFarmCropInfoSection extends StatefulWidget {
  const OpenFarmCropInfoSection({required this.cropName, super.key});

  final String cropName;

  @override
  State<OpenFarmCropInfoSection> createState() =>
      _OpenFarmCropInfoSectionState();
}

class _OpenFarmCropInfoSectionState extends State<OpenFarmCropInfoSection> {
  Future<OpenFarmCrop?>? future;

  @override
  void initState() {
    super.initState();
    future = OpenFarmService.instance.getCropByName(widget.cropName);
  }

  @override
  void didUpdateWidget(covariant OpenFarmCropInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropName != widget.cropName) {
      future = OpenFarmService.instance.getCropByName(widget.cropName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpenFarmCrop?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: C.soft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.line)),
            child: const Row(children: [
              CupertinoActivityIndicator(),
              SizedBox(width: 10),
              Text('Loading crop info...',
                  style:
                      TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
            ]),
          );
        }

        final crop = snapshot.data;
        if (crop == null) return const SizedBox.shrink();

        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => showOpenFarmCropDetail(context, crop),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: C.forestSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.line)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OpenFarmImageBox(imageUrl: crop.imageUrl, size: 58),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Crop info',
                          style: TextStyle(
                              color: C.forest,
                              fontSize: 12,
                              fontWeight: FontWeight.w900)),
                      Text(crop.name,
                          style: const TextStyle(
                              color: C.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      if (crop.sunRequirements.isNotEmpty)
                        Text(crop.sunRequirements,
                            style: const TextStyle(
                                color: C.muted, fontWeight: FontWeight.w800)),
                      if (crop.description.isNotEmpty)
                        Text(
                          crop.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: C.ink, fontSize: 12, height: 1.25),
                        ),
                      const SizedBox(height: 4),
                      const Text('via OpenFarm',
                          style: TextStyle(
                              color: C.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ]),
              ),
              const Icon(CupertinoIcons.chevron_right,
                  color: C.muted, size: 17),
            ]),
          ),
        );
      },
    );
  }
}

class OpenFarmImageBox extends StatelessWidget {
  const OpenFarmImageBox(
      {required this.imageUrl, required this.size, super.key});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line)),
      child: const Icon(CupertinoIcons.leaf_arrow_circlepath, color: C.forest),
    );

    if (imageUrl.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

void showOpenFarmCropDetail(BuildContext context, OpenFarmCrop crop) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: crop.imageUrl.isEmpty
                ? Container(
                    height: 190,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: C.forestSoft,
                        borderRadius: BorderRadius.circular(22)),
                    child: const Icon(CupertinoIcons.leaf_arrow_circlepath,
                        color: C.forest, size: 46),
                  )
                : Image.network(
                    crop.imageUrl,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Container(
                                height: 210,
                                alignment: Alignment.center,
                                color: C.forestSoft,
                                child: const CupertinoActivityIndicator(),
                              ),
                    errorBuilder: (_, __, ___) => Container(
                      height: 210,
                      alignment: Alignment.center,
                      color: C.forestSoft,
                      child: const Icon(CupertinoIcons.leaf_arrow_circlepath,
                          color: C.forest, size: 46),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SheetHeader(title: crop.name, subtitle: 'OpenFarm crop profile'),
          const SizedBox(height: 12),
          Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                crop.description.isEmpty
                    ? 'No OpenFarm description listed.'
                    : crop.description,
                style: const TextStyle(
                    color: C.ink, fontWeight: FontWeight.w700, height: 1.35),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Panel(
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.35,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                OpenFarmFact(label: 'Sun', value: crop.sunRequirements),
                OpenFarmFact(label: 'Sowing', value: crop.sowingMethod),
                OpenFarmFact(label: 'Spread', value: formatCm(crop.spread)),
                OpenFarmFact(
                    label: 'Row spacing', value: formatCm(crop.rowSpacing)),
                OpenFarmFact(label: 'Height', value: formatCm(crop.height)),
              ],
            ),
          ),
          if (crop.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: crop.tags
                  .map((tag) => ProductTag(
                      label: tag, color: C.muted, background: C.greySoft))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          CupertinoButton(
            color: C.forest,
            borderRadius: BorderRadius.circular(16),
            onPressed: () async {
              try {
                await launchUrl(Uri.parse(crop.openFarmUrl),
                    mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: const Text('View on OpenFarm',
                style: TextStyle(
                    color: CupertinoColors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ),
  );
}

class OpenFarmFact extends StatelessWidget {
  const OpenFarmFact({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: C.soft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.line)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: C.forest,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(value.isEmpty ? '—' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: C.ink, fontWeight: FontWeight.w800, fontSize: 12)),
            ]),
      );
}

String formatCm(double? value) {
  if (value == null) return '—';
  final rounded = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$rounded cm';
}

class BottomNav extends StatelessWidget {
  const BottomNav({required this.tab, required this.onTap, super.key});
  final int tab;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = const [
      NavSpec('Home', CupertinoIcons.home),
      NavSpec('Garden', CupertinoIcons.square_grid_2x2),
      NavSpec('Spray', CupertinoIcons.drop),
      NavSpec('Records', CupertinoIcons.list_bullet),
      NavSpec('Products', CupertinoIcons.cube_box),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(31),
          border: Border.all(color: C.line),
          boxShadow: softShadow),
      child: Row(
          children: List.generate(items.length, (index) {
        final selected = index == tab;
        return Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () => onTap(index),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 38,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: selected ? C.forest : CupertinoColors.transparent,
                      borderRadius: BorderRadius.circular(999)),
                  child: Icon(items[index].icon,
                      size: 18,
                      color: selected ? CupertinoColors.white : C.muted)),
              const SizedBox(height: 3),
              FittedBox(
                  child: Text(items[index].label,
                      style: TextStyle(
                          color: selected ? C.forest : C.muted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800))),
            ]),
          ),
        );
      })),
    );
  }
}

class NavSpec {
  const NavSpec(this.label, this.icon);
  final String label;
  final IconData icon;
}

class RecordCard extends StatelessWidget {
  const RecordCard({required this.record, this.onDelete, super.key});
  final SprayRecord record;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final target = targetById(record.targetId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(children: [
        Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: target.softColor,
                borderRadius: BorderRadius.circular(14)),
            child: Icon(target.icon, color: target.color, size: 21)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bed ${record.beds.join(', ')} Â· ${target.short}',
              style:
                  const TextStyle(fontWeight: FontWeight.w900, color: C.ink)),
          Text(record.crops.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: C.ink, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(
              '${record.product} Â· sprayed ${shortDate(record.date)} Â· safe ${shortDate(record.safeDate)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: C.muted, fontSize: 12)),
        ])),
        StatusPill(record.onHold ? 'HOLD' : 'SAFE', hold: record.onHold),
        if (onDelete != null)
          CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: onDelete,
              child: const Text('Ã—',
                  style: TextStyle(
                      color: C.red,
                      fontSize: 22,
                      fontWeight: FontWeight.w900))),
      ]),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage(
      {required this.title,
      required this.subtitle,
      required this.children,
      this.message = '',
      super.key});
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String message;

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 26), children: [
        Text(title,
            style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
                color: C.forest)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 14, color: C.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        if (message.isNotEmpty) ...[
          MessageBanner(message),
          const SizedBox(height: 12)
        ],
        ...children,
      ]);
}

class MessageBanner extends StatelessWidget {
  const MessageBanner(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: C.forestSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line)),
      child: Text(message,
          style:
              const TextStyle(color: C.forest, fontWeight: FontWeight.w900)));
}

class Panel extends StatelessWidget {
  const Panel(
      {required this.child,
      this.padding = const EdgeInsets.all(16),
      super.key});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) =>
      Container(padding: padding, decoration: cardDecoration(), child: child);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: C.forest))),
        if (trailing != null) trailing!
      ]);
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Panel(
      child: Text(text,
          style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)));
}

class EmptyInline extends StatelessWidget {
  const EmptyInline(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line)),
      child: Text(text,
          style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)));
}

class Sheet extends StatelessWidget {
  const Sheet({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => CupertinoPopupSurface(
      child: SafeArea(
          top: false,
          child: SizedBox(
              height: MediaQuery.of(context).size.height * .86,
              child: Container(color: C.canvas, child: child))));
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: C.ink)),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: C.muted, fontWeight: FontWeight.w800))
        ])),
        CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Text('Ã—',
                style: TextStyle(fontSize: 28, color: C.muted)))
      ]);
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
      color: C.forest,
      disabledColor: C.line,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      onPressed: onPressed,
      child: Text(label,
          style: const TextStyle(
              color: CupertinoColors.white, fontWeight: FontWeight.w900)));
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
      {required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
      color: C.forestSoft,
      disabledColor: C.soft,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      onPressed: onPressed,
      child: Text(label,
          style: TextStyle(
              color: onPressed == null ? C.muted : C.forest,
              fontWeight: FontWeight.w900)));
}

class NumberChip extends StatelessWidget {
  const NumberChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      super.key});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
              color: selected ? C.forest : C.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? C.forest : C.line)),
          child: Text(label,
              style: TextStyle(
                  color: selected ? CupertinoColors.white : C.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 13))));
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {required this.hold, super.key});
  final String label;
  final bool hold;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: hold ? C.amberSoft : C.forestSoft,
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              color: hold ? C.amber : C.forest,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .5)));
}

class ProductTag extends StatelessWidget {
  const ProductTag(
      {required this.label,
      required this.color,
      required this.background,
      super.key});
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w900, fontSize: 10.5)));
}

class CategoryPill extends StatelessWidget {
  const CategoryPill({required this.category, super.key});
  final String category;
  @override
  Widget build(BuildContext context) {
    final lower = category.toLowerCase();
    final color = lower == 'organic'
        ? C.forest
        : lower == 'chemical'
            ? C.amber
            : C.muted;
    final background = lower == 'organic'
        ? C.forestSoft
        : lower == 'chemical'
            ? C.amberSoft
            : C.greySoft;
    return ProductTag(
        label: category.isEmpty ? 'unknown' : category,
        color: color,
        background: background);
  }
}

class Field extends StatelessWidget {
  const Field(
      {required this.controller,
      required this.placeholder,
      this.maxLines = 1,
      super.key});
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;
  @override
  Widget build(BuildContext context) => CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line)));
}

class Stepper extends StatelessWidget {
  const Stepper(
      {required this.label,
      required this.value,
      required this.minus,
      required this.plus,
      super.key});
  final String label;
  final int value;
  final VoidCallback? minus;
  final VoidCallback plus;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line)),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w900))),
        SmallButton('-', minus),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$value',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900))),
        SmallButton('+', plus)
      ]));
}

class SmallButton extends StatelessWidget {
  const SmallButton(this.label, this.onPressed, {super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(34, 34),
      color: C.card,
      borderRadius: BorderRadius.circular(999),
      onPressed: onPressed,
      child: Text(label,
          style: const TextStyle(
              color: C.forest, fontSize: 18, fontWeight: FontWeight.w900)));
}

class TextChip extends StatelessWidget {
  const TextChip({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line)),
      child: Text(label,
          style: const TextStyle(
              color: C.ink, fontWeight: FontWeight.w900, fontSize: 13)));
}

class CropChip extends StatelessWidget {
  const CropChip({required this.crop, required this.onRemove, super.key});
  final VegetableDefinition crop;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CropIcon(crop.iconPath, size: 22),
        const SizedBox(width: 7),
        Text(crop.name,
            style: const TextStyle(
                color: C.ink, fontWeight: FontWeight.w900, fontSize: 13)),
        CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: onRemove,
            child: const Text('Ã—',
                style: TextStyle(fontSize: 18, color: C.muted)))
      ]));
}

class CountDot extends StatelessWidget {
  const CountDot(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
          color: C.forest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.card, width: 2)),
      child: Text('+$count',
          style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900)));
}

class DetailLine extends StatelessWidget {
  const DetailLine(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: C.forest, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value.isEmpty ? 'â€”' : value,
            style: const TextStyle(
                color: C.ink, fontWeight: FontWeight.w700, height: 1.25))
      ]));
}

class TargetGrid extends StatelessWidget {
  const TargetGrid({required this.selected, required this.onSelect, super.key});
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: .98,
      children: sprayTargets
          .map((target) => TargetButton(
              target: target,
              selected: selected == target.id,
              onTap: () => onSelect(target.id)))
          .toList());
}

class TargetButton extends StatelessWidget {
  const TargetButton(
      {required this.target,
      required this.selected,
      required this.onTap,
      super.key});
  final SprayTarget target;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
              color: selected ? target.softColor : C.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: selected ? target.color : C.line,
                  width: selected ? 1.8 : 1)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(target.icon, color: target.color, size: 22),
            const SizedBox(height: 5),
            FittedBox(
                child: Text(target.short,
                    style: const TextStyle(
                        color: C.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)))
          ])));
}

class CropIcon extends StatelessWidget {
  const CropIcon(this.path, {this.size = 28, super.key});
  final String path;
  final double size;
  @override
  Widget build(BuildContext context) => path.toLowerCase().endsWith('.svg')
      ? SvgPicture.asset(path, width: size, height: size, fit: BoxFit.contain)
      : Image.asset(path,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high);
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE9E4D8)
      ..strokeWidth = .55;
    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
