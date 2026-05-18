import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'crop_library.dart';

void main() => runApp(const FieldbookApp());

class FieldbookApp extends StatelessWidget {
  const FieldbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Fieldbook',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: C.forest,
        scaffoldBackgroundColor: C.canvas,
        textTheme: CupertinoTextThemeData(textStyle: TextStyle(color: C.ink)),
      ),
      home: FieldbookHome(),
    );
  }
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
}

const shadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 7))];

BoxDecoration cardDecoration({Color color = C.card}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: C.line),
      boxShadow: shadow,
    );

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
  const SprayTarget(this.id, this.title, this.short, this.description, this.color, this.softColor);
  final String id;
  final String title;
  final String short;
  final String description;
  final Color color;
  final Color softColor;
}

const sprayTargets = [
  SprayTarget('pest', 'Pest pressure', 'Pest', 'Insects, mites, chewing damage, webbing, sticky residue, or larvae.', C.red, C.redSoft),
  SprayTarget('fungus', 'Fungal pressure', 'Fungus', 'Mildew, rust, leaf spots, blight risk, or humid disease pressure.', C.blue, C.blueSoft),
  SprayTarget('prevent', 'Preventative', 'Prevent', 'Use before pressure builds, especially before wet or humid weather.', C.amber, C.amberSoft),
  SprayTarget('maintain', 'Maintenance', 'Maintain', 'Plant support, stress recovery, pruning, airflow, and general crop care.', C.forest, C.forestSoft),
];

SprayTarget targetById(String id) => sprayTargets.firstWhere((t) => t.id == id, orElse: () => sprayTargets.first);

class SprayProduct {
  const SprayProduct({required this.id, required this.name, required this.type, required this.days, required this.targets});
  final int id;
  final String name;
  final String type;
  final int days;
  final List<String> targets;
}

class SprayRecord {
  const SprayRecord({required this.id, required this.beds, required this.crops, required this.targetId, required this.product, required this.reason, required this.notes, required this.date, required this.days});
  final int id;
  final List<int> beds;
  final List<String> crops;
  final String targetId;
  final String product;
  final String reason;
  final String notes;
  final DateTime date;
  final int days;
  DateTime get safeDate => date.add(Duration(days: days));
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String monthName(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
String shortDate(DateTime d) => '${d.day} ${monthName(d.month)}';
String fullDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

class FieldbookHome extends StatefulWidget {
  const FieldbookHome({super.key});

  @override
  State<FieldbookHome> createState() => _FieldbookHomeState();
}

class _FieldbookHomeState extends State<FieldbookHome> {
  int tab = 0;
  int selectedBed = 4;
  int nextRecordId = 1;
  int nextProductId = 4;
  String message = '';
  Set<int> sprayBeds = {4};
  Set<String> sprayCrops = {};
  String sprayTarget = 'pest';

  final Map<int, List<VegetableDefinition>> bedCrops = {};
  List<SprayRecord> records = [];
  late List<SprayProduct> products;

  @override
  void initState() {
    super.initState();
    products = const [
      SprayProduct(id: 1, name: 'Neem Oil', type: 'Pest control', days: 3, targets: ['pest']),
      SprayProduct(id: 2, name: 'Copper Spray', type: 'Fungicide', days: 7, targets: ['fungus', 'prevent']),
      SprayProduct(id: 3, name: 'Seaweed Tonic', type: 'Plant tonic', days: 1, targets: ['maintain', 'prevent']),
    ].toList();
  }

  int get holdBeds => gardenBeds.where((b) => bedOnHold(b.number)).length;
  int get clearBeds => gardenBeds.length - holdBeds;
  int get plantedBeds => bedCrops.values.where((v) => v.isNotEmpty).length;
  int get cropPlacements => bedCrops.values.fold(0, (sum, list) => sum + list.length);
  List<SprayRecord> get activeRecords => records.where((r) => r.safeDate.isAfter(DateTime.now())).toList();

  bool bedOnHold(int bed) => records.any((r) => r.beds.contains(bed) && r.safeDate.isAfter(DateTime.now()));

  List<VegetableDefinition> cropsForBeds(Set<int> beds) {
    final map = <String, VegetableDefinition>{};
    for (final bed in beds) {
      for (final crop in bedCrops[bed] ?? const <VegetableDefinition>[]) {
        map[crop.name] = crop;
      }
    }
    return map.values.toList();
  }

  Set<String> defaultCropNames(Set<int> beds) {
    final names = cropsForBeds(beds).map((c) => c.name).toSet();
    return names.isEmpty ? {'Whole bed'} : names;
  }

  void addCrop(int bed, VegetableDefinition crop) {
    final next = [...bedCrops[bed] ?? <VegetableDefinition>[]];
    if (!next.any((c) => c.id == crop.id)) next.add(crop);
    setState(() {
      bedCrops[bed] = next;
      selectedBed = bed;
      message = '${crop.name} added to Bed $bed';
    });
  }

  void removeCrop(int bed, VegetableDefinition crop) {
    final next = [...bedCrops[bed] ?? <VegetableDefinition>[]]..removeWhere((c) => c.id == crop.id);
    setState(() {
      if (next.isEmpty) {
        bedCrops.remove(bed);
      } else {
        bedCrops[bed] = next;
      }
      message = '${crop.name} removed from Bed $bed';
    });
  }

  void clearCrops(int bed) {
    setState(() {
      bedCrops.remove(bed);
      message = 'Crops cleared from Bed $bed';
    });
  }

  void clearSprays(int bed) {
    setState(() {
      records = records.where((r) => !r.beds.contains(bed)).toList();
      message = 'Spray records cleared from Bed $bed';
    });
  }

  void startSpray({required Set<int> beds, String targetId = 'pest', Set<String>? crops}) {
    final safeBeds = beds.isEmpty ? {selectedBed} : beds;
    setState(() {
      sprayBeds = safeBeds;
      sprayTarget = targetId;
      sprayCrops = crops == null || crops.isEmpty ? defaultCropNames(safeBeds) : crops;
      tab = 2;
    });
  }

  void saveSpray({required Set<int> beds, required Set<String> crops, required String targetId, required SprayProduct product, required String reason, required String notes, required int days}) {
    if (beds.isEmpty) {
      setState(() => message = 'Choose at least one bed.');
      return;
    }
    final sortedBeds = beds.toList()..sort();
    final sortedCrops = crops.toList()..sort();
    setState(() {
      records.insert(0, SprayRecord(id: nextRecordId++, beds: sortedBeds, crops: sortedCrops, targetId: targetId, product: product.name, reason: reason.trim(), notes: notes.trim(), date: DateTime.now(), days: days));
      selectedBed = sortedBeds.first;
      message = 'Spray record saved';
      tab = 0;
    });
  }

  void deleteRecord(int id) => setState(() {
        records = records.where((r) => r.id != id).toList();
        message = 'Record removed';
      });

  void addProduct(String name, String type, int days) => setState(() {
        products.add(SprayProduct(id: nextProductId++, name: name, type: type, days: days, targets: const ['pest', 'fungus', 'prevent', 'maintain']));
        message = '$name added';
      });

  void removeProduct(int id) => setState(() {
        products = products.where((p) => p.id != id).toList();
        message = 'Product removed';
      });

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, records: records, activeRecords: activeRecords, message: message, onPlanSpray: () => startSpray(beds: {selectedBed})),
      GardenScreen(selectedBed: selectedBed, bedCrops: bedCrops, records: records, message: message, onSelectBed: (v) => setState(() => selectedBed = v), onAddCrop: addCrop, onRemoveCrop: removeCrop, onClearCrops: clearCrops, onClearSprays: clearSprays, onStartSpray: (bed, target, crops) => startSpray(beds: {bed}, targetId: target, crops: crops)),
      SprayLogScreen(key: ValueKey('${sprayBeds.join(',')}-${sprayCrops.join(',')}-$sprayTarget-${records.length}'), initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, onSave: saveSpray),
      RecordsScreen(records: records, message: message, onDelete: deleteRecord, onClear: () => setState(() { records.clear(); message = 'All records cleared'; })),
      ProductsScreen(products: products, message: message, onAdd: addProduct, onDelete: removeProduct),
    ];

    return CupertinoPageScaffold(
      backgroundColor: C.canvas,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: IndexedStack(index: tab, children: pages)),
            BottomNav(tab: tab, onTap: (v) => setState(() => tab = v)),
          ],
        ),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({required this.tab, required this.onTap, super.key});
  final int tab;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final labels = ['Home', 'Garden', 'Spray', 'Records', 'Products'];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      padding: const EdgeInsets.all(6),
      decoration: cardDecoration(),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == tab;
          return Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: selected ? C.forest : CupertinoColors.transparent, borderRadius: BorderRadius.circular(16)),
                child: Text(labels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: selected ? CupertinoColors.white : C.muted)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.records, required this.activeRecords, required this.message, required this.onPlanSpray, super.key});
  final int clearBeds;
  final int holdBeds;
  final int plantedBeds;
  final int cropPlacements;
  final List<SprayRecord> records;
  final List<SprayRecord> activeRecords;
  final String message;
  final VoidCallback onPlanSpray;

  @override
  Widget build(BuildContext context) {
    final next = activeRecords.firstOrNull;
    return Page(title: 'Fieldbook', subtitle: 'Your garden, protected.', message: message, children: [
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: C.forest)),
        const SizedBox(height: 6),
        const Text('Spray status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        Row(children: [Expanded(child: Metric('CLEAR BEDS', '$clearBeds', C.forest)), const SizedBox(width: 10), Expanded(child: Metric('ON HOLD', '$holdBeds', C.amber))]),
        const SizedBox(height: 14),
        Text('$plantedBeds beds planted  •  $cropPlacements crop placements', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Plan a spray', onPressed: onPlanSpray),
      ])),
      const SizedBox(height: 18),
      const SectionTitle('Next safe harvest'),
      const SizedBox(height: 8),
      if (next == null) const EmptyCard('No active withholding periods.') else RecordCard(record: next, compact: true),
      const SizedBox(height: 18),
      const SectionTitle('Recent activity'),
      const SizedBox(height: 8),
      if (records.isEmpty) const EmptyCard('No spray records yet.') else ...records.take(3).map((r) => RecordCard(record: r)),
    ]);
  }
}

class Metric extends StatelessWidget {
  const Metric(this.label, this.value, this.color, {super.key});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900))]),
      );
}

class GardenScreen extends StatelessWidget {
  const GardenScreen({required this.selectedBed, required this.bedCrops, required this.records, required this.message, required this.onSelectBed, required this.onAddCrop, required this.onRemoveCrop, required this.onClearCrops, required this.onClearSprays, required this.onStartSpray, super.key});
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final String message;
  final ValueChanged<int> onSelectBed;
  final void Function(int bed, VegetableDefinition crop) onAddCrop;
  final void Function(int bed, VegetableDefinition crop) onRemoveCrop;
  final ValueChanged<int> onClearCrops;
  final ValueChanged<int> onClearSprays;
  final void Function(int bed, String target, Set<String> crops) onStartSpray;

  bool bedOnHold(int bed) => records.any((r) => r.beds.contains(bed) && r.safeDate.isAfter(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final crops = bedCrops[selectedBed] ?? const <VegetableDefinition>[];
    final hold = bedOnHold(selectedBed);
    return Page(title: 'Garden', subtitle: 'Tap a bed to view crops and actions.', message: message, children: [
      Panel(padding: const EdgeInsets.all(12), child: SizedBox(height: 500, child: GardenMap(selectedBed: selectedBed, bedCrops: bedCrops, isHold: bedOnHold, onTap: onSelectBed))),
      const SizedBox(height: 14),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('Bed $selectedBed', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), Pill(hold ? 'HOLD' : 'CLEAR', hold ? C.amber : C.forest, hold ? C.amberSoft : C.forestSoft)]),
        const SizedBox(height: 4),
        Text(crops.isEmpty ? 'No crops assigned' : crops.map((c) => c.name).join(' • '), style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        if (crops.isEmpty) const EmptyInline('Add crops to unlock crop-specific spray guidance.') else CropWrap(crops: crops, onRemove: (crop) => onRemoveCrop(selectedBed, crop)),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: SecondaryButton(label: 'Add crop', onPressed: () => showCropPicker(context, selectedBed, crops, onAddCrop))), const SizedBox(width: 10), Expanded(child: PrimaryButton(label: 'Spray plan', onPressed: crops.isEmpty ? null : () => showSprayPlan(context, selectedBed, crops, onStartSpray)))]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: DangerButton(label: 'Clear sprays', onPressed: () => onClearSprays(selectedBed))), const SizedBox(width: 10), Expanded(child: DangerButton(label: 'Clear crops', onPressed: crops.isEmpty ? null : () => onClearCrops(selectedBed)))]),
      ])),
    ]);
  }
}

class GardenMap extends StatelessWidget {
  const GardenMap({required this.selectedBed, required this.bedCrops, required this.isHold, required this.onTap, super.key});
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final bool Function(int bed) isHold;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          ...gardenBeds.map((bed) {
            final r = Rect.fromLTWH(bed.rect.left * size.width, bed.rect.top * size.height, bed.rect.width * size.width, bed.rect.height * size.height);
            return Positioned.fromRect(rect: r, child: BedButton(number: bed.number, selected: selectedBed == bed.number, hold: isHold(bed.number), crops: bedCrops[bed.number] ?? const <VegetableDefinition>[], onTap: () => onTap(bed.number)));
          }),
        ]);
      });
}

class BedButton extends StatelessWidget {
  const BedButton({required this.number, required this.selected, required this.hold, required this.crops, required this.onTap, super.key});
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
          decoration: BoxDecoration(color: hold ? C.amberSoft : crops.isEmpty ? C.card : C.forestSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? C.forest : C.soil, width: selected ? 2.6 : 1.3)),
          child: Stack(clipBehavior: Clip.none, children: [
            Center(child: Text('$number', style: TextStyle(fontWeight: FontWeight.w900, color: selected ? C.forest : C.ink, fontSize: 12))),
            if (crops.isNotEmpty) Positioned(top: -12, right: -12, child: IconCluster(crops: crops)),
          ]),
        ),
      );
}

class IconCluster extends StatelessWidget {
  const IconCluster({required this.crops, super.key});
  final List<VegetableDefinition> crops;

  @override
  Widget build(BuildContext context) {
    final visible = crops.take(4).toList();
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.line), boxShadow: shadow),
      child: Wrap(spacing: 2, runSpacing: 2, children: [...visible.map((c) => CropIcon(c.iconPath, size: 22)), if (crops.length > 4) CountDot(crops.length - 4)]),
    );
  }
}

class CropWrap extends StatelessWidget {
  const CropWrap({required this.crops, this.onRemove, super.key});
  final List<VegetableDefinition> crops;
  final ValueChanged<VegetableDefinition>? onRemove;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: crops.map((crop) => CropChip(crop: crop, onRemove: onRemove == null ? null : () => onRemove!(crop))).toList());
}

class CropChip extends StatelessWidget {
  const CropChip({required this.crop, this.onRemove, super.key});
  final VegetableDefinition crop;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [CropIcon(crop.iconPath, size: 22), const SizedBox(width: 7), Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)), if (onRemove != null) CupertinoButton(padding: EdgeInsets.zero, minSize: 24, onPressed: onRemove, child: const Text('×', style: TextStyle(fontSize: 18, color: C.muted)))]),
      );
}

void showCropPicker(BuildContext context, int bed, List<VegetableDefinition> assigned, void Function(int bed, VegetableDefinition crop) onAdd) {
  showCupertinoModalPopup<void>(context: context, builder: (_) => Sheet(child: CropPicker(bed: bed, assigned: assigned, onAdd: onAdd)));
}

class CropPicker extends StatefulWidget {
  const CropPicker({required this.bed, required this.assigned, required this.onAdd, super.key});
  final int bed;
  final List<VegetableDefinition> assigned;
  final void Function(int bed, VegetableDefinition crop) onAdd;

  @override
  State<CropPicker> createState() => _CropPickerState();
}

class _CropPickerState extends State<CropPicker> {
  String familyId = vegetableFamilies.first.id;

  @override
  Widget build(BuildContext context) {
    final family = familyById(familyId);
    final veg = vegetablesForFamily(familyId);
    return ListView(padding: const EdgeInsets.all(20), children: [
      SheetHeader(title: 'Add Crop', subtitle: 'Bed ${widget.bed}'),
      const SizedBox(height: 14),
      const SectionTitle('Filter by family'),
      const SizedBox(height: 10),
      SizedBox(height: 88, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: vegetableFamilies.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => FamilyChip(family: vegetableFamilies[i], selected: vegetableFamilies[i].id == familyId, onTap: () => setState(() => familyId = vegetableFamilies[i].id)))),
      const SizedBox(height: 12),
      Panel(color: C.soft, child: Text('${family.name}\n${family.description}', style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35))),
      const SizedBox(height: 12),
      ...veg.map((crop) {
        final added = widget.assigned.any((c) => c.id == crop.id);
        return CropOption(crop: crop, added: added, onTap: () { if (!added) widget.onAdd(widget.bed, crop); Navigator.pop(context); });
      }),
    ]);
  }
}

class FamilyChip extends StatelessWidget {
  const FamilyChip({required this.family, required this.selected, required this.onTap, super.key});
  final VegetableFamilyDefinition family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(width: 108, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: selected ? C.forest : C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? C.forest : C.line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CropIcon(family.iconPath, size: 30), const Spacer(), Text(family.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, color: selected ? CupertinoColors.white : C.ink, fontSize: 12))])));
}

class CropOption extends StatelessWidget {
  const CropOption({required this.crop, required this.added, required this.onTap, super.key});
  final VegetableDefinition crop;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: cardDecoration(), child: Row(children: [Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(14)), child: CropIcon(crop.iconPath, size: 38)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w900)), Text('Pest: ${crop.commonPests.take(3).join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12)), Text('Disease: ${crop.commonDiseases.take(3).join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12))])), Pill(added ? 'ADDED' : 'ADD', added ? C.muted : C.forest, added ? C.soft : C.forestSoft)])));
}

void showSprayPlan(BuildContext context, int bed, List<VegetableDefinition> crops, void Function(int bed, String target, Set<String> crops) onStart) {
  showCupertinoModalPopup<void>(context: context, builder: (_) => Sheet(child: SprayPlanSheet(bed: bed, crops: crops, onStart: onStart)));
}

class SprayPlanSheet extends StatefulWidget {
  const SprayPlanSheet({required this.bed, required this.crops, required this.onStart, super.key});
  final int bed;
  final List<VegetableDefinition> crops;
  final void Function(int bed, String target, Set<String> crops) onStart;

  @override
  State<SprayPlanSheet> createState() => _SprayPlanSheetState();
}

class _SprayPlanSheetState extends State<SprayPlanSheet> {
  String targetId = 'pest';
  late Set<String> cropNames = widget.crops.map((c) => c.name).toSet();

  @override
  Widget build(BuildContext context) {
    final target = targetById(targetId);
    final active = widget.crops.where((c) => cropNames.contains(c.name)).toList();
    final suggestion = suggestionText(active, targetId);
    return ListView(padding: const EdgeInsets.all(20), children: [
      SheetHeader(title: 'Spray Plan', subtitle: 'Bed ${widget.bed}'),
      const SizedBox(height: 14),
      const SectionTitle('Crops in bed'),
      const SizedBox(height: 8),
      SelectableCrops(crops: widget.crops, selected: cropNames, onChanged: (v) => setState(() => cropNames = v)),
      const SizedBox(height: 16),
      const SectionTitle('Target'),
      const SizedBox(height: 8),
      TargetGrid(selected: targetId, onSelect: (id) => setState(() => targetId = id)),
      const SizedBox(height: 12),
      Panel(color: target.softColor, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(target.title, style: TextStyle(color: target.color, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(target.description, style: const TextStyle(fontWeight: FontWeight.w700))])),
      const SizedBox(height: 14),
      const SectionTitle('Suggested product'),
      const SizedBox(height: 8),
      Panel(child: Text(suggestion, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35))),
      const SizedBox(height: 16),
      PrimaryButton(label: 'Create spray record', onPressed: () { Navigator.pop(context); widget.onStart(widget.bed, targetId, cropNames); }),
    ]);
  }
}

String suggestionText(List<VegetableDefinition> crops, String target) {
  if (crops.isEmpty) return 'Select at least one crop.';
  if (target == 'pest') return 'Neem Oil — targets ${crops.expand((c) => c.commonPests).take(4).join(', ')}. Use when visible pest pressure is present and label supports crop.';
  if (target == 'fungus') return 'Copper Spray — targets ${crops.expand((c) => c.commonDiseases).take(4).join(', ')}. Use for supported fungal pressure during wet or humid conditions.';
  if (target == 'prevent') return 'Copper Spray or Seaweed Tonic — use before pressure builds, especially before wet weather.';
  return 'Seaweed Tonic — use after transplanting, pruning, heavy cropping, heat, wind, or cold stress.';
}

class SprayLogScreen extends StatefulWidget {
  const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.onSave, super.key});
  final Set<int> initialBeds;
  final Set<String> initialCrops;
  final String initialTarget;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayProduct> products;
  final void Function({required Set<int> beds, required Set<String> crops, required String targetId, required SprayProduct product, required String reason, required String notes, required int days}) onSave;

  @override
  State<SprayLogScreen> createState() => _SprayLogScreenState();
}

class _SprayLogScreenState extends State<SprayLogScreen> {
  late Set<int> beds = {...widget.initialBeds};
  late Set<String> crops = {...widget.initialCrops};
  late String targetId = widget.initialTarget;
  late SprayProduct product = widget.products.firstWhere((p) => p.targets.contains(targetId), orElse: () => widget.products.first);
  late int days = product.days;
  final reason = TextEditingController();
  final notes = TextEditingController();

  @override
  void dispose() {
    reason.dispose();
    notes.dispose();
    super.dispose();
  }

  List<VegetableDefinition> currentCrops() {
    final map = <String, VegetableDefinition>{};
    for (final bed in beds) {
      for (final crop in widget.bedCrops[bed] ?? const <VegetableDefinition>[]) {
        map[crop.name] = crop;
      }
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeCrops = currentCrops();
    return Page(title: 'Spray Log', subtitle: 'Create a new spray record.', children: [
      const SectionTitle('Beds sprayed'),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: gardenBeds.map((b) => NumberChip(label: '${b.number}', selected: beds.contains(b.number), onTap: () => setState(() { beds.contains(b.number) ? beds.remove(b.number) : beds.add(b.number); final names = currentCrops().map((c) => c.name).toSet(); crops = names.isEmpty ? {'Whole bed'} : names; }))).toList()),
      const SizedBox(height: 18),
      const SectionTitle('Crops affected'),
      const SizedBox(height: 8),
      if (activeCrops.isEmpty) const EmptyCard('Whole bed spray — no crops assigned to selected beds.') else SelectableCrops(crops: activeCrops, selected: crops, onChanged: (v) => setState(() => crops = v)),
      const SizedBox(height: 18),
      const SectionTitle('Spraying against'),
      const SizedBox(height: 8),
      TargetGrid(selected: targetId, onSelect: (id) => setState(() { targetId = id; final match = widget.products.where((p) => p.targets.contains(id)).firstOrNull; if (match != null) { product = match; days = match.days; } })),
      const SizedBox(height: 18),
      const SectionTitle('Product'),
      const SizedBox(height: 8),
      ...widget.products.map((p) => ProductChoice(product: p, selected: p.id == product.id, suggested: p.targets.contains(targetId), onTap: () => setState(() { product = p; days = p.days; }))),
      const SizedBox(height: 18),
      const SectionTitle('Details'),
      const SizedBox(height: 8),
      Field(controller: reason, placeholder: 'Specific issue, e.g. aphids on tomato tips'),
      const SizedBox(height: 8),
      Field(controller: notes, placeholder: 'Notes optional', maxLines: 3),
      const SizedBox(height: 12),
      Stepper(label: 'Withholding days', value: days, minus: days > 0 ? () => setState(() => days--) : null, plus: () => setState(() => days++)),
      const SizedBox(height: 18),
      PrimaryButton(label: 'Save spray record', onPressed: () => widget.onSave(beds: beds, crops: crops, targetId: targetId, product: product, reason: reason.text, notes: notes.text, days: days)),
    ]);
  }
}

class SelectableCrops extends StatelessWidget {
  const SelectableCrops({required this.crops, required this.selected, required this.onChanged, super.key});
  final List<VegetableDefinition> crops;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [NumberChip(label: 'All crops', selected: selected.length == crops.length, onTap: () => onChanged(crops.map((c) => c.name).toSet())), ...crops.map((crop) => CropSelectChip(crop: crop, selected: selected.contains(crop.name), onTap: () { final next = {...selected}; next.contains(crop.name) ? next.remove(crop.name) : next.add(crop.name); if (next.isEmpty) next.add(crop.name); onChanged(next); }))]);
}

class CropSelectChip extends StatelessWidget {
  const CropSelectChip({required this.crop, required this.selected, required this.onTap, super.key});
  final VegetableDefinition crop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: selected ? C.forest : C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? C.forest : C.line)), child: Row(mainAxisSize: MainAxisSize.min, children: [CropIcon(crop.iconPath, size: 20), const SizedBox(width: 6), Text(crop.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: selected ? CupertinoColors.white : C.ink))])));
}

class TargetGrid extends StatelessWidget {
  const TargetGrid({required this.selected, required this.onSelect, super.key});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => GridView.count(crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, childAspectRatio: .92, children: sprayTargets.map((t) => TargetButton(target: t, selected: selected == t.id, onTap: () => onSelect(t.id))).toList());
}

class TargetButton extends StatelessWidget {
  const TargetButton({required this.target, required this.selected, required this.onTap, super.key});
  final SprayTarget target;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: selected ? target.softColor : C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? target.color : C.line, width: selected ? 1.8 : 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(target.short.substring(0, 1), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: target.color)), const SizedBox(height: 4), Text(target.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))])));
}

class ProductChoice extends StatelessWidget {
  const ProductChoice({required this.product, required this.selected, required this.suggested, required this.onTap, super.key});
  final SprayProduct product;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: selected ? C.forestSoft : C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? C.forest : C.line)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900)), Text('${product.type} · ${product.days} day withholding', style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700))])), if (suggested) const Pill('MATCH', C.forest, C.forestSoft), const SizedBox(width: 8), Text(selected ? '✓' : '○', style: TextStyle(color: selected ? C.forest : C.muted, fontSize: 22, fontWeight: FontWeight.w900))])));
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({required this.records, required this.message, required this.onDelete, required this.onClear, super.key});
  final List<SprayRecord> records;
  final String message;
  final ValueChanged<int> onDelete;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Page(title: 'Records', subtitle: 'All spray records.', message: message, trailing: records.isEmpty ? null : CupertinoButton(padding: EdgeInsets.zero, minSize: 32, onPressed: onClear, child: const Text('Clear all', style: TextStyle(color: C.red, fontWeight: FontWeight.w900))), children: [if (records.isEmpty) const EmptyCard('No spray records yet.') else ...records.map((r) => RecordCard(record: r, onDelete: () => onDelete(r.id)))]);
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({required this.products, required this.message, required this.onAdd, required this.onDelete, super.key});
  final List<SprayProduct> products;
  final String message;
  final void Function(String name, String type, int days) onAdd;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) => Page(title: 'Products', subtitle: 'Manage your spray products.', message: message, trailing: CupertinoButton(padding: EdgeInsets.zero, minSize: 32, onPressed: () => showProductDialog(context, onAdd), child: const Text('+', style: TextStyle(color: C.forest, fontSize: 28, fontWeight: FontWeight.w900))), children: products.map((p) => ProductTile(product: p, onDelete: () => onDelete(p.id))).toList());
}

void showProductDialog(BuildContext context, void Function(String name, String type, int days) onAdd) {
  final name = TextEditingController();
  final type = TextEditingController(text: 'Custom product');
  final days = TextEditingController(text: '1');
  showCupertinoDialog<void>(context: context, builder: (_) => CupertinoAlertDialog(title: const Text('Add product'), content: Column(children: [const SizedBox(height: 12), CupertinoTextField(controller: name, placeholder: 'Name'), const SizedBox(height: 8), CupertinoTextField(controller: type, placeholder: 'Type'), const SizedBox(height: 8), CupertinoTextField(controller: days, placeholder: 'Withholding days', keyboardType: TextInputType.number)]), actions: [CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)), CupertinoDialogAction(isDefaultAction: true, child: const Text('Add'), onPressed: () { if (name.text.trim().isNotEmpty) onAdd(name.text.trim(), type.text.trim().isEmpty ? 'Custom product' : type.text.trim(), int.tryParse(days.text) ?? 1); Navigator.pop(context); })]));
}

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, required this.onDelete, super.key});
  final SprayProduct product;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: cardDecoration(), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text(product.type, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)), Text('${product.days} day withholding · ${product.targets.map((id) => targetById(id).short).join(', ')}', style: const TextStyle(color: C.muted, fontSize: 12))])), CupertinoButton(padding: EdgeInsets.zero, minSize: 34, onPressed: onDelete, child: const Text('Delete', style: TextStyle(color: C.red, fontWeight: FontWeight.w900, fontSize: 12)))]));
}

class RecordCard extends StatelessWidget {
  const RecordCard({required this.record, this.compact = false, this.onDelete, super.key});
  final SprayRecord record;
  final bool compact;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final target = targetById(record.targetId);
    final hold = record.safeDate.isAfter(DateTime.now());
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: cardDecoration(), child: Row(children: [Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: target.softColor, borderRadius: BorderRadius.circular(14)), child: Text(target.short.substring(0, 1), style: TextStyle(color: target.color, fontWeight: FontWeight.w900, fontSize: 20))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bed ${record.beds.join(', ')} · ${target.short}', style: const TextStyle(fontWeight: FontWeight.w900)), Text(record.crops.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontSize: 13, fontWeight: FontWeight.w700)), Text('${record.product} · sprayed ${shortDate(record.date)} · safe ${shortDate(record.safeDate)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12))])), Pill(hold ? 'HOLD' : 'SAFE', hold ? C.amber : C.forest, hold ? C.amberSoft : C.forestSoft), if (onDelete != null) CupertinoButton(padding: EdgeInsets.zero, minSize: 34, onPressed: onDelete, child: const Text('×', style: TextStyle(color: C.red, fontSize: 20, fontWeight: FontWeight.w900)))]));
  }
}

class Page extends StatelessWidget {
  const Page({required this.title, required this.subtitle, required this.children, this.message = '', this.trailing, super.key});
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 26), children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.1, color: C.forest)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 14, color: C.ink, fontWeight: FontWeight.w600))])), if (trailing != null) trailing!]), const SizedBox(height: 18), if (message.isNotEmpty) ...[Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: C.forestSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)), child: Text(message, style: const TextStyle(color: C.forest, fontWeight: FontWeight.w900))), const SizedBox(height: 12)], ...children]);
}

class Sheet extends StatelessWidget {
  const Sheet({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => CupertinoPopupSurface(child: SafeArea(top: false, child: SizedBox(height: MediaQuery.of(context).size.height * .86, child: Container(color: C.canvas, child: child))));
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w800))])), CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: const Text('×', style: TextStyle(fontSize: 28, color: C.muted)))]);
}

class Panel extends StatelessWidget {
  const Panel({required this.child, this.padding = const EdgeInsets.all(16), this.color = C.card, super.key});
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: padding, decoration: cardDecoration(color: color), child: child);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900));
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Panel(child: Text(text, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)));
}

class EmptyInline extends StatelessWidget {
  const EmptyInline(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)), child: Text(text, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)));
}

class Pill extends StatelessWidget {
  const Pill(this.label, this.color, this.background, {super.key});
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)), child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .4)));
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(color: C.forest, disabledColor: C.line, borderRadius: BorderRadius.circular(16), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), onPressed: onPressed, child: Text(label, style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w900)));
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(color: C.forestSoft, disabledColor: C.soft, borderRadius: BorderRadius.circular(16), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), onPressed: onPressed, child: Text(label, style: TextStyle(color: onPressed == null ? C.muted : C.forest, fontWeight: FontWeight.w900)));
}

class DangerButton extends StatelessWidget {
  const DangerButton({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(color: C.redSoft, disabledColor: C.soft, borderRadius: BorderRadius.circular(16), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), onPressed: onPressed, child: Text(label, style: TextStyle(color: onPressed == null ? C.muted : C.red, fontWeight: FontWeight.w900)));
}

class NumberChip extends StatelessWidget {
  const NumberChip({required this.label, required this.selected, required this.onTap, super.key});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10), decoration: BoxDecoration(color: selected ? C.forest : C.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? C.forest : C.line)), child: Text(label, style: TextStyle(color: selected ? CupertinoColors.white : C.ink, fontWeight: FontWeight.w900, fontSize: 13))));
}

class CountDot extends StatelessWidget {
  const CountDot(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Container(constraints: const BoxConstraints(minWidth: 20), height: 20, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(color: C.forest, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.card, width: 2)), child: Text('+$count', style: const TextStyle(color: CupertinoColors.white, fontSize: 9, fontWeight: FontWeight.w900)));
}

class Field extends StatelessWidget {
  const Field({required this.controller, required this.placeholder, this.maxLines = 1, super.key});
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;
  @override
  Widget build(BuildContext context) => CupertinoTextField(controller: controller, placeholder: placeholder, maxLines: maxLines, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)));
}

class Stepper extends StatelessWidget {
  const Stepper({required this.label, required this.value, required this.minus, required this.plus, super.key});
  final String label;
  final int value;
  final VoidCallback? minus;
  final VoidCallback plus;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))), SmallButton('-', minus), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), SmallButton('+', plus)]));
}

class SmallButton extends StatelessWidget {
  const SmallButton(this.label, this.onPressed, {super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, minSize: 34, color: C.card, borderRadius: BorderRadius.circular(999), onPressed: onPressed, child: Text(label, style: const TextStyle(color: C.forest, fontSize: 18, fontWeight: FontWeight.w900)));
}

class CropIcon extends StatelessWidget {
  const CropIcon(this.path, {this.size = 28, super.key});
  final String path;
  final double size;
  @override
  Widget build(BuildContext context) => path.toLowerCase().endsWith('.svg') ? SvgPicture.asset(path, width: size, height: size, fit: BoxFit.contain) : Image.asset(path, width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.high);
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE9E4D8)..strokeWidth = .55;
    for (double x = 0; x < size.width; x += 16) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint); }
    for (double y = 0; y < size.height; y += 16) { canvas.drawLine(Offset(0, y), Offset(size.width, y), paint); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
