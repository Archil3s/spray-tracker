import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(const SprayTrackerApp());

class AppColor {
  static const background = Color(0xFFF6F5F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF1EFE8);
  static const ink = Color(0xFF1F241F);
  static const muted = Color(0xFF697067);
  static const line = Color(0xFFE0DDD4);
  static const primary = Color(0xFF315F3A);
  static const primarySoft = Color(0xFFE6EFE8);
  static const warning = Color(0xFFC9822B);
  static const warningSoft = Color(0xFFFFF0D8);
  static const danger = Color(0xFFB84B44);
  static const dangerSoft = Color(0xFFF9E6E3);
  static const earth = Color(0xFF7A5230);
  static const path = Color(0xFFB8B4AA);
}

class SprayTrackerApp extends StatelessWidget {
  const SprayTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Spray Tracker',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColor.primary,
        scaffoldBackgroundColor: AppColor.background,
        textTheme: CupertinoTextThemeData(textStyle: TextStyle(color: AppColor.ink, fontSize: 16)),
      ),
      home: SprayTrackerHome(),
    );
  }
}

class GardenBed {
  const GardenBed(this.number, this.bounds, this.group);
  final int number;
  final Rect bounds;
  final String group;
}

class SpraySuggestion {
  const SpraySuggestion({required this.name, required this.category, required this.target, required this.whenToUse});
  final String name;
  final String category;
  final String target;
  final String whenToUse;
}

class CropProfile {
  const CropProfile({
    required this.name,
    required this.iconPath,
    required this.pestPressure,
    required this.fungusPressure,
    required this.preventative,
    required this.maintenance,
    required this.suggestions,
  });

  final String name;
  final String iconPath;
  final String pestPressure;
  final String fungusPressure;
  final List<String> preventative;
  final List<String> maintenance;
  final List<SpraySuggestion> suggestions;
}

class SprayProduct {
  const SprayProduct({required this.id, required this.name, required this.type, required this.withholdingDays});
  final int id;
  final String name;
  final String type;
  final int withholdingDays;
}

class SprayRecord {
  const SprayRecord({
    required this.id,
    required this.bedNumbers,
    required this.product,
    required this.reason,
    required this.notes,
    required this.sprayedAt,
    required this.withholdingDays,
  });

  final int id;
  final List<int> bedNumbers;
  final String product;
  final String reason;
  final String notes;
  final DateTime sprayedAt;
  final int withholdingDays;

  DateTime get safeDate => sprayedAt.add(Duration(days: withholdingDays));
}

class BedStatus {
  const BedStatus({required this.status, required this.summary, required this.daysRemaining});
  final String status;
  final String summary;
  final int daysRemaining;
}

const gardenBeds = [
  GardenBed(1, Rect.fromLTWH(.06, .08, .20, .12), 'Compound Area'),
  GardenBed(2, Rect.fromLTWH(.36, .08, .15, .31), 'Compound Area'),
  GardenBed(3, Rect.fromLTWH(.55, .08, .10, .085), 'Top Beds'),
  GardenBed(4, Rect.fromLTWH(.70, .08, .25, .07), 'Right Side'),
  GardenBed(5, Rect.fromLTWH(.70, .18, .25, .07), 'Right Side'),
  GardenBed(6, Rect.fromLTWH(.70, .28, .25, .07), 'Right Side'),
  GardenBed(7, Rect.fromLTWH(.70, .38, .25, .07), 'Right Side'),
  GardenBed(8, Rect.fromLTWH(.70, .48, .25, .07), 'Right Side'),
  GardenBed(9, Rect.fromLTWH(.70, .58, .25, .07), 'Right Side'),
  GardenBed(10, Rect.fromLTWH(.70, .68, .25, .07), 'Right Side'),
  GardenBed(11, Rect.fromLTWH(.70, .78, .25, .08), 'Right Side'),
  GardenBed(12, Rect.fromLTWH(.04, .42, .46, .07), 'Left Side'),
  GardenBed(13, Rect.fromLTWH(.04, .53, .46, .07), 'Left Side'),
  GardenBed(14, Rect.fromLTWH(.04, .64, .46, .07), 'Left Side'),
  GardenBed(15, Rect.fromLTWH(.04, .75, .46, .07), 'Left Side'),
  GardenBed(16, Rect.fromLTWH(.04, .92, .91, .045), 'Long Beds'),
  GardenBed(17, Rect.fromLTWH(.04, .01, .91, .04), 'Long Beds'),
];

const cropProfiles = [
  CropProfile(
    name: 'Tomatoes',
    iconPath: 'assets/veg_icons/tomato.svg',
    pestPressure: 'Aphids, whitefly, caterpillars, mites',
    fungusPressure: 'Early blight, late blight, powdery mildew, leaf spot',
    preventative: ['Check leaf undersides weekly', 'Avoid wetting leaves late in the day', 'Prune lower leaves for airflow'],
    maintenance: ['Stake and prune regularly', 'Remove diseased leaves quickly', 'Keep mulch off stems'],
    suggestions: [
      SpraySuggestion(name: 'Neem Oil', category: 'Pest pressure', target: 'Aphids, mites, whitefly', whenToUse: 'Use only when active pest pressure is seen.'),
      SpraySuggestion(name: 'Copper Spray', category: 'Fungal pressure', target: 'Blight and leaf spot risk', whenToUse: 'Use preventatively during wet, humid periods if label allows.'),
      SpraySuggestion(name: 'Seaweed Tonic', category: 'Maintenance', target: 'Plant stress support', whenToUse: 'Use after heat, transplant stress, or heavy fruiting.'),
    ],
  ),
  CropProfile(
    name: 'Leafy greens',
    iconPath: 'assets/veg_icons/leafy.svg',
    pestPressure: 'Aphids, slugs, caterpillars, flea beetle',
    fungusPressure: 'Downy mildew, damping off, leaf spot',
    preventative: ['Use netting where possible', 'Thin crowded plants', 'Keep foliage as dry as practical'],
    maintenance: ['Harvest outer leaves often', 'Remove damaged leaves', 'Improve airflow between rows'],
    suggestions: [
      SpraySuggestion(name: 'Neem Oil', category: 'Pest pressure', target: 'Aphids and soft-bodied insects', whenToUse: 'Use carefully when pests are present; avoid spraying stressed leaves.'),
      SpraySuggestion(name: 'Copper Spray', category: 'Fungal pressure', target: 'Downy mildew and leaf spot pressure', whenToUse: 'Use only when disease pressure is high and label permits edible greens.'),
      SpraySuggestion(name: 'Seaweed Tonic', category: 'Maintenance', target: 'Growth support', whenToUse: 'Use lightly after picking or weather stress.'),
    ],
  ),
  CropProfile(
    name: 'Onions / alliums',
    iconPath: 'assets/veg_icons/onion.svg',
    pestPressure: 'Thrips, onion fly',
    fungusPressure: 'Rust, downy mildew, neck rot',
    preventative: ['Monitor thrips in dry weather', 'Avoid excess nitrogen', 'Keep weeds down'],
    maintenance: ['Water consistently', 'Remove badly rusted leaves', 'Rotate allium beds yearly'],
    suggestions: [
      SpraySuggestion(name: 'Neem Oil', category: 'Pest pressure', target: 'Thrips suppression', whenToUse: 'Use when thrips are visible and plants are not drought stressed.'),
      SpraySuggestion(name: 'Copper Spray', category: 'Fungal pressure', target: 'Rust and downy mildew pressure', whenToUse: 'Use when humid weather and rust symptoms appear, if label allows.'),
    ],
  ),
  CropProfile(
    name: 'Berries',
    iconPath: 'assets/veg_icons/berry.svg',
    pestPressure: 'Aphids, mites, fruit fly, birds',
    fungusPressure: 'Botrytis, cane spot, mildew',
    preventative: ['Keep fruit off wet soil', 'Improve cane airflow', 'Net fruit before ripening'],
    maintenance: ['Remove old fruit', 'Prune crowded canes', 'Remove infected canes'],
    suggestions: [
      SpraySuggestion(name: 'Neem Oil', category: 'Pest pressure', target: 'Aphids and mites', whenToUse: 'Use before flowering or after harvest if label allows.'),
      SpraySuggestion(name: 'Copper Spray', category: 'Fungal pressure', target: 'Cane disease pressure', whenToUse: 'Best considered in dormant or label-approved windows.'),
      SpraySuggestion(name: 'Seaweed Tonic', category: 'Maintenance', target: 'Post-harvest recovery', whenToUse: 'Use after pruning or harvest stress.'),
    ],
  ),
  CropProfile(
    name: 'Root vegetables',
    iconPath: 'assets/veg_icons/root.svg',
    pestPressure: 'Aphids, carrot fly, soil pests',
    fungusPressure: 'Root rot, leaf blight',
    preventative: ['Avoid overwatering', 'Use fine mesh for carrot fly pressure', 'Rotate beds between seasons'],
    maintenance: ['Thin early', 'Keep soil evenly moist', 'Avoid heavy fresh manure'],
    suggestions: [
      SpraySuggestion(name: 'Neem Oil', category: 'Pest pressure', target: 'Leaf aphids', whenToUse: 'Use only for visible above-ground pest pressure.'),
      SpraySuggestion(name: 'Seaweed Tonic', category: 'Maintenance', target: 'Root crop establishment', whenToUse: 'Use lightly during early growth or after stress.'),
    ],
  ),
];

const compoundOuter = Rect.fromLTWH(.04, .07, .47, .33);
const compoundPath = Rect.fromLTWH(.275, .08, .045, .31);
const compoundLowerLeft = Rect.fromLTWH(.06, .24, .20, .15);
const mainPath = Rect.fromLTWH(.55, .17, .045, .72);

String dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
String shortDate(DateTime date) => '${date.day} ${monthName(date.month)}';
String monthName(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
Rect scaleRect(Rect r, Size size) => Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);

class SprayTrackerHome extends StatefulWidget {
  const SprayTrackerHome({super.key});

  @override
  State<SprayTrackerHome> createState() => _SprayTrackerHomeState();
}

class _SprayTrackerHomeState extends State<SprayTrackerHome> {
  int currentTab = 0;
  int selectedBed = 4;
  int nextRecordId = 1;
  int nextProductId = 4;
  Set<int> selectedBeds = {4};
  String? actionMessage;

  final Map<int, List<CropProfile>> bedCrops = {};
  late List<SprayProduct> products;
  List<SprayRecord> records = [];

  @override
  void initState() {
    super.initState();
    products = const [
      SprayProduct(id: 1, name: 'Neem Oil', type: 'Pest control', withholdingDays: 3),
      SprayProduct(id: 2, name: 'Copper Spray', type: 'Fungicide', withholdingDays: 7),
      SprayProduct(id: 3, name: 'Seaweed Tonic', type: 'Plant tonic', withholdingDays: 1),
    ].toList();
  }

  BedStatus statusForBed(int bedNumber) {
    final latest = records.where((record) => record.bedNumbers.contains(bedNumber)).firstOrNull;
    if (latest == null) return const BedStatus(status: 'Safe', summary: 'No recent spray', daysRemaining: 0);

    final waiting = latest.safeDate.isAfter(DateTime.now());
    final remaining = latest.safeDate.difference(DateTime.now()).inDays + 1;
    return BedStatus(
      status: waiting ? 'Wait' : 'Safe',
      summary: '${latest.product} · safe ${shortDate(latest.safeDate)}',
      daysRemaining: waiting ? remaining.clamp(1, 999).toInt() : 0,
    );
  }

  int get waitCount => gardenBeds.where((bed) => statusForBed(bed.number).status == 'Wait').length;
  int get safeCount => gardenBeds.length - waitCount;
  int get plantedBedCount => bedCrops.values.where((crops) => crops.isNotEmpty).length;
  int get cropAssignmentCount => bedCrops.values.fold(0, (sum, crops) => sum + crops.length);
  List<SprayRecord> get waitingRecords => records.where((record) => record.safeDate.isAfter(DateTime.now())).toList();

  void changeTab(int index) => setState(() => currentTab = index);
  void selectBedOnMap(int bedNumber) => setState(() => selectedBed = bedNumber);

  void openLog(Set<int> beds) {
    setState(() {
      selectedBeds = beds.isEmpty ? {selectedBed} : {...beds};
      currentTab = 2;
    });
  }

  void saveSpray({required Set<int> beds, required SprayProduct product, required String reason, required String notes, required int withholdingDays}) {
    if (beds.isEmpty) {
      setState(() => actionMessage = 'Choose at least one bed before saving.');
      return;
    }
    final sortedBeds = beds.toList()..sort();
    setState(() {
      records.insert(0, SprayRecord(id: nextRecordId++, bedNumbers: sortedBeds, product: product.name, reason: reason.trim().isEmpty ? 'General spray' : reason.trim(), notes: notes.trim(), sprayedAt: DateTime.now(), withholdingDays: withholdingDays));
      selectedBeds = sortedBeds.toSet();
      selectedBed = sortedBeds.first;
      actionMessage = 'Spray saved for Bed ${sortedBeds.join(', ')}';
      currentTab = 0;
    });
  }

  void addCropToBed(int bedNumber, CropProfile crop) {
    setState(() {
      final current = [...bedCrops[bedNumber] ?? <CropProfile>[]];
      if (!current.any((existing) => existing.name == crop.name)) current.add(crop);
      bedCrops[bedNumber] = current;
      selectedBed = bedNumber;
      actionMessage = current.any((existing) => existing.name == crop.name) ? '${crop.name} added to Bed $bedNumber' : 'Crop already assigned to Bed $bedNumber';
    });
  }

  void removeCropFromBed(int bedNumber, CropProfile crop) {
    setState(() {
      final current = [...bedCrops[bedNumber] ?? <CropProfile>[]]..removeWhere((existing) => existing.name == crop.name);
      if (current.isEmpty) {
        bedCrops.remove(bedNumber);
      } else {
        bedCrops[bedNumber] = current;
      }
      selectedBed = bedNumber;
      actionMessage = '${crop.name} removed from Bed $bedNumber';
    });
  }

  void clearCropsForBed(int bedNumber) {
    setState(() {
      bedCrops.remove(bedNumber);
      selectedBed = bedNumber;
      actionMessage = 'All vegetables cleared from Bed $bedNumber';
    });
  }

  void clearBedSprays(int bedNumber) {
    setState(() {
      final before = records.length;
      records = records.where((record) => !record.bedNumbers.contains(bedNumber)).toList();
      selectedBed = bedNumber;
      actionMessage = before == records.length ? 'Bed $bedNumber has no spray records' : 'Spray records cleared from Bed $bedNumber';
    });
  }

  void removeRecord(int id) {
    setState(() {
      records = records.where((record) => record.id != id).toList();
      actionMessage = 'Spray record removed';
    });
  }

  void clearAllHistory() {
    setState(() {
      records = [];
      actionMessage = 'All spray history cleared';
    });
  }

  void addProduct(SprayProduct product) {
    setState(() {
      products.add(SprayProduct(id: nextProductId++, name: product.name, type: product.type, withholdingDays: product.withholdingDays));
      actionMessage = '${product.name} added';
    });
  }

  void removeProduct(int id) {
    setState(() {
      final removed = products.where((product) => product.id == id).map((product) => product.name).firstOrNull;
      products = products.where((product) => product.id != id).toList();
      if (products.isEmpty) products.add(SprayProduct(id: nextProductId++, name: 'General Spray', type: 'Custom product', withholdingDays: 1));
      actionMessage = removed == null ? 'Product not found' : '$removed removed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(safeCount: safeCount, waitCount: waitCount, records: records, waitingRecords: waitingRecords, plantedBedCount: plantedBedCount, cropAssignmentCount: cropAssignmentCount, actionMessage: actionMessage, onOpenLog: () => openLog(selectedBeds)),
      VisualMapScreen(selectedBed: selectedBed, bedCrops: bedCrops, actionMessage: actionMessage, bedStatus: statusForBed, onSelectBed: selectBedOnMap, onAddCrop: addCropToBed, onRemoveCrop: removeCropFromBed, onClearCrops: clearCropsForBed, onLogBed: (bedNumber) => openLog({bedNumber}), onClearSprays: clearBedSprays),
      LogSprayScreen(key: ValueKey('${selectedBeds.join(',')}-${products.length}-${cropAssignmentCount}'), initialBeds: selectedBeds, products: products, bedCrops: bedCrops, onSave: saveSpray),
      HistoryScreen(records: records, actionMessage: actionMessage, onRemove: removeRecord, onClearAll: clearAllHistory),
      ProductsScreen(products: products, actionMessage: actionMessage, onAdd: addProduct, onRemove: removeProduct),
    ];

    return CupertinoPageScaffold(
      backgroundColor: AppColor.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: IndexedStack(index: currentTab, children: pages)),
            DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFCFFFFFF), border: Border(top: BorderSide(color: AppColor.line))),
              child: CupertinoTabBar(
                currentIndex: currentTab,
                onTap: changeTab,
                backgroundColor: const Color(0xFCFFFFFF),
                activeColor: AppColor.primary,
                inactiveColor: AppColor.muted,
                items: const [
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Dashboard'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.map), label: 'Map'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.plus_circle_fill), label: 'Log'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: 'History'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube_box), label: 'Products'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.safeCount, required this.waitCount, required this.records, required this.waitingRecords, required this.plantedBedCount, required this.cropAssignmentCount, required this.actionMessage, required this.onOpenLog, super.key});
  final int safeCount;
  final int waitCount;
  final List<SprayRecord> records;
  final List<SprayRecord> waitingRecords;
  final int plantedBedCount;
  final int cropAssignmentCount;
  final String? actionMessage;
  final VoidCallback onOpenLog;

  @override
  Widget build(BuildContext context) {
    final nextSafe = waitingRecords.isEmpty ? null : waitingRecords.reduce((a, b) => a.safeDate.isBefore(b.safeDate) ? a : b);
    return AppPage(title: 'Spray Tracker', subtitle: 'Spray records, withholding periods, and bed status.', children: [
      if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)],
      DashboardHero(safeCount: safeCount, waitCount: waitCount, plantedBedCount: plantedBedCount, cropAssignmentCount: cropAssignmentCount),
      const SizedBox(height: 18),
      NextSafeCard(record: nextSafe),
      const SizedBox(height: 22),
      const SectionHeader(title: 'Recent sprays'),
      const SizedBox(height: 10),
      if (records.isEmpty) const EmptyCard('No spray records yet.') else ...records.take(3).map((record) => SprayRecordCard(record: record)),
      const SizedBox(height: 12),
      PrimaryButton(title: 'Log spray', onPressed: onOpenLog),
    ]);
  }
}

class DashboardHero extends StatelessWidget {
  const DashboardHero({required this.safeCount, required this.waitCount, required this.plantedBedCount, required this.cropAssignmentCount, super.key});
  final int safeCount;
  final int waitCount;
  final int plantedBedCount;
  final int cropAssignmentCount;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(24), boxShadow: shadow), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Current status', style: TextStyle(color: CupertinoColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
    const SizedBox(height: 16),
    Row(children: [Expanded(child: BigMetric(title: 'Safe', value: safeCount)), const SizedBox(width: 12), Expanded(child: BigMetric(title: 'Withholding', value: waitCount))]),
    const SizedBox(height: 14),
    Text('$plantedBedCount beds planted · $cropAssignmentCount vegetable assignments', style: const TextStyle(color: Color(0xEFFFFFFF), fontWeight: FontWeight.w700)),
  ]));
}

class BigMetric extends StatelessWidget {
  const BigMetric({required this.title, required this.value, super.key});
  final String title;
  final int value;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(16)), child: Column(children: [Text(title, style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text('$value', style: const TextStyle(color: CupertinoColors.white, fontSize: 34, fontWeight: FontWeight.w900)), const Text('beds', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w600))]));
}

class NextSafeCard extends StatelessWidget {
  const NextSafeCard({required this.record, super.key});
  final SprayRecord? record;
  @override
  Widget build(BuildContext context) {
    if (record == null) return const InfoCard(title: 'No active withholding period', subtitle: 'All spray records are currently safe.', icon: CupertinoIcons.check_mark_circled);
    final days = record!.safeDate.difference(DateTime.now()).inDays + 1;
    return InfoCard(title: 'Next safe harvest', subtitle: 'Bed ${record!.bedNumbers.join(', ')} · ${shortDate(record!.safeDate)}', trailing: '$days days', icon: CupertinoIcons.calendar);
  }
}

class VisualMapScreen extends StatelessWidget {
  const VisualMapScreen({required this.selectedBed, required this.bedCrops, required this.actionMessage, required this.bedStatus, required this.onSelectBed, required this.onAddCrop, required this.onRemoveCrop, required this.onClearCrops, required this.onLogBed, required this.onClearSprays, super.key});
  final int selectedBed;
  final Map<int, List<CropProfile>> bedCrops;
  final String? actionMessage;
  final BedStatus Function(int) bedStatus;
  final ValueChanged<int> onSelectBed;
  final void Function(int bedNumber, CropProfile crop) onAddCrop;
  final void Function(int bedNumber, CropProfile crop) onRemoveCrop;
  final ValueChanged<int> onClearCrops;
  final ValueChanged<int> onLogBed;
  final ValueChanged<int> onClearSprays;

  @override
  Widget build(BuildContext context) {
    final crops = bedCrops[selectedBed] ?? const <CropProfile>[];
    final status = bedStatus(selectedBed);
    return AppPage(title: 'Garden Map', subtitle: 'Assign multiple vegetables and view spray suggestions.', children: [
      if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)],
      GardenVisualMap(selectedBed: selectedBed, bedCrops: bedCrops, bedStatus: bedStatus, onSelectBed: onSelectBed),
      const SizedBox(height: 14),
      SelectedBedPanel(bedNumber: selectedBed, crops: crops, status: status, onAddCrop: () => showCropPicker(context, selectedBed, crops, onAddCrop), onRemoveCrop: (crop) => onRemoveCrop(selectedBed, crop), onClearCrops: crops.isEmpty ? null : () => onClearCrops(selectedBed), onSuggestedSprays: crops.isEmpty ? null : () => showSuggestedSprayMenu(context, selectedBed, crops), onLog: () => onLogBed(selectedBed), onClearSprays: () => onClearSprays(selectedBed)),
    ]);
  }
}

class GardenVisualMap extends StatelessWidget {
  const GardenVisualMap({required this.selectedBed, required this.bedCrops, required this.bedStatus, required this.onSelectBed, super.key});
  final int selectedBed;
  final Map<int, List<CropProfile>> bedCrops;
  final BedStatus Function(int) bedStatus;
  final ValueChanged<int> onSelectBed;
  @override
  Widget build(BuildContext context) => Container(height: 560, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColor.line), boxShadow: subtleShadow), child: LayoutBuilder(builder: (context, constraints) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    return Stack(children: [
      Positioned.fill(child: CustomPaint(painter: GridPainter())),
      MapOutline(rect: compoundOuter, size: size),
      MapOutline(rect: compoundLowerLeft, size: size),
      MapPath(rect: compoundPath, size: size),
      MapPath(rect: mainPath, size: size),
      ...gardenBeds.map((bed) => MapBedTile(bed: bed, rect: scaleRect(bed.bounds, size), selected: bed.number == selectedBed, crops: bedCrops[bed.number] ?? const <CropProfile>[], status: bedStatus(bed.number), onTap: () => onSelectBed(bed.number))),
    ]);
  }));
}

class MapBedTile extends StatelessWidget {
  const MapBedTile({required this.bed, required this.rect, required this.selected, required this.crops, required this.status, required this.onTap, super.key});
  final GardenBed bed;
  final Rect rect;
  final bool selected;
  final List<CropProfile> crops;
  final BedStatus status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final waiting = status.status == 'Wait';
    return Positioned.fromRect(rect: rect, child: CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Stack(clipBehavior: Clip.none, children: [
      AnimatedContainer(duration: const Duration(milliseconds: 140), alignment: Alignment.center, decoration: BoxDecoration(color: waiting ? AppColor.warningSoft : crops.isEmpty ? const Color(0xFFFCFBF7) : AppColor.primarySoft, borderRadius: BorderRadius.circular(7), border: Border.all(color: selected ? CupertinoColors.activeBlue : waiting ? AppColor.warning : AppColor.earth, width: selected ? 3 : 1.7)), child: Text('${bed.number}', style: const TextStyle(color: AppColor.ink, fontSize: 13, fontWeight: FontWeight.w900))),
      if (crops.isNotEmpty) Positioned(top: -10, right: -10, child: CropIconStack(crops: crops)),
    ])));
  }
}

class CropIconStack extends StatelessWidget {
  const CropIconStack({required this.crops, super.key});
  final List<CropProfile> crops;
  @override
  Widget build(BuildContext context) {
    final visible = crops.take(3).toList();
    return SizedBox(width: 30.0 + (visible.length - 1) * 16, height: 32, child: Stack(children: [
      for (int i = 0; i < visible.length; i++) Positioned(left: i * 16, child: HoverCropIcon(crop: visible[i])),
      if (crops.length > 3) Positioned(right: 0, bottom: 0, child: CountBadge(count: crops.length)),
    ]));
  }
}

class HoverCropIcon extends StatelessWidget {
  const HoverCropIcon({required this.crop, super.key});
  final CropProfile crop;
  @override
  Widget build(BuildContext context) => Container(width: 30, height: 30, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColor.surface, shape: BoxShape.circle, border: Border.all(color: AppColor.line), boxShadow: subtleShadow), child: SvgPicture.asset(crop.iconPath));
}

class CountBadge extends StatelessWidget {
  const CountBadge({required this.count, super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(99)), child: Text('$count', style: const TextStyle(color: CupertinoColors.white, fontSize: 10, fontWeight: FontWeight.w900)));
}

class SelectedBedPanel extends StatelessWidget {
  const SelectedBedPanel({required this.bedNumber, required this.crops, required this.status, required this.onAddCrop, required this.onRemoveCrop, required this.onClearCrops, required this.onSuggestedSprays, required this.onLog, required this.onClearSprays, super.key});
  final int bedNumber;
  final List<CropProfile> crops;
  final BedStatus status;
  final VoidCallback onAddCrop;
  final ValueChanged<CropProfile> onRemoveCrop;
  final VoidCallback? onClearCrops;
  final VoidCallback? onSuggestedSprays;
  final VoidCallback onLog;
  final VoidCallback onClearSprays;
  @override
  Widget build(BuildContext context) => PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text('Bed $bedNumber', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), StatusPill(status: status.status)]),
    const SizedBox(height: 8),
    Text(crops.isEmpty ? 'No vegetables assigned' : '${crops.length} vegetables assigned', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
    const SizedBox(height: 4),
    Text(status.summary, style: const TextStyle(color: AppColor.muted)),
    const SizedBox(height: 12),
    if (crops.isEmpty) const Text('Add one or more vegetables to this bed to unlock targeted spray suggestions.', style: TextStyle(color: AppColor.muted, fontSize: 13)) else CropChipWrap(crops: crops, onRemoveCrop: onRemoveCrop),
    const SizedBox(height: 14),
    Row(children: [Expanded(child: PrimaryButton(title: 'Add vegetable', onPressed: onAddCrop)), const SizedBox(width: 10), Expanded(child: SecondaryButton(title: 'Suggested sprays', icon: CupertinoIcons.list_bullet, onPressed: onSuggestedSprays))]),
    const SizedBox(height: 10),
    Row(children: [Expanded(child: SecondaryButton(title: 'Log spray', icon: CupertinoIcons.drop_fill, onPressed: onLog)), const SizedBox(width: 10), Expanded(child: DestructiveButton(title: 'Clear spray', onPressed: onClearSprays))]),
    const SizedBox(height: 10),
    DestructiveButton(title: 'Clear all vegetables from bed', onPressed: onClearCrops),
  ]));
}

class CropChipWrap extends StatelessWidget {
  const CropChipWrap({required this.crops, required this.onRemoveCrop, super.key});
  final List<CropProfile> crops;
  final ValueChanged<CropProfile> onRemoveCrop;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: crops.map((crop) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: AppColor.primarySoft, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColor.line)), child: Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 18, height: 18, child: SvgPicture.asset(crop.iconPath)), const SizedBox(width: 6), Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w800)), CupertinoButton(padding: EdgeInsets.zero, minSize: 20, onPressed: () => onRemoveCrop(crop), child: const Icon(CupertinoIcons.xmark_circle_fill, size: 16, color: AppColor.muted))]))).toList());
}

void showCropPicker(BuildContext context, int bedNumber, List<CropProfile> assigned, void Function(int, CropProfile) onSave) {
  showCupertinoModalPopup<void>(context: context, builder: (_) => CupertinoActionSheet(
    title: Text('Add vegetable to Bed $bedNumber'),
    message: const Text('Choose one or more crop profiles. The bed can contain mixed vegetables.'),
    actions: cropProfiles.map((crop) {
      final alreadyAdded = assigned.any((item) => item.name == crop.name);
      return CupertinoActionSheetAction(onPressed: alreadyAdded ? null : () { onSave(bedNumber, crop); Navigator.pop(context); }, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 24, height: 24, child: SvgPicture.asset(crop.iconPath)), const SizedBox(width: 10), Text(alreadyAdded ? '${crop.name} added' : crop.name)]));
    }).toList(),
    cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), child: const Text('Done')),
  ));
}

void showSuggestedSprayMenu(BuildContext context, int bedNumber, List<CropProfile> crops) {
  showCupertinoModalPopup<void>(context: context, builder: (_) => CupertinoPopupSurface(child: SafeArea(top: false, child: Container(height: MediaQuery.of(context).size.height * .78, color: AppColor.background, child: SuggestedSprayMenu(bedNumber: bedNumber, crops: crops)))));
}

class SuggestedSprayMenu extends StatelessWidget {
  const SuggestedSprayMenu({required this.bedNumber, required this.crops, super.key});
  final int bedNumber;
  final List<CropProfile> crops;

  List<SpraySuggestion> get suggestions {
    final byKey = <String, SpraySuggestion>{};
    for (final crop in crops) {
      for (final suggestion in crop.suggestions) {
        byKey['${suggestion.name}-${suggestion.category}-${suggestion.target}'] = suggestion;
      }
    }
    return byKey.values.toList();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), children: [
    Row(children: [Expanded(child: Text('Suggested sprays · Bed $bedNumber', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColor.muted))]),
    const SizedBox(height: 6),
    Text(crops.map((crop) => crop.name).join(' + '), style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700)),
    const SizedBox(height: 18),
    const InfoCard(title: 'Use as guidance only', subtitle: 'Apply sprays only when needed and always follow the product label, crop suitability, weather limits, and withholding period.', icon: CupertinoIcons.exclamationmark_triangle),
    const SizedBox(height: 18),
    const SectionHeader(title: 'Suggested spray options'),
    const SizedBox(height: 10),
    ...suggestions.map((suggestion) => SpraySuggestionCard(suggestion: suggestion)),
    const SizedBox(height: 18),
    const SectionHeader(title: 'Combined pressure notes'),
    const SizedBox(height: 10),
    ...crops.map((crop) => CropPressureCard(crop: crop)),
  ]);
}

class SpraySuggestionCard extends StatelessWidget {
  const SpraySuggestionCard({required this.suggestion, super.key});
  final SpraySuggestion suggestion;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: cardDecoration, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(suggestion.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), StatusChip(text: suggestion.category, color: AppColor.primary, bg: AppColor.primarySoft)]),
    const SizedBox(height: 8),
    Text('Target: ${suggestion.target}', style: const TextStyle(color: AppColor.ink, fontWeight: FontWeight.w700)),
    const SizedBox(height: 4),
    Text(suggestion.whenToUse, style: const TextStyle(color: AppColor.muted, fontSize: 13)),
  ]));
}

class CropPressureCard extends StatelessWidget {
  const CropPressureCard({required this.crop, super.key});
  final CropProfile crop;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: cardDecoration, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [SizedBox(width: 28, height: 28, child: SvgPicture.asset(crop.iconPath)), const SizedBox(width: 10), Expanded(child: Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w900)))]),
    const SizedBox(height: 8),
    Text('Pest: ${crop.pestPressure}', style: const TextStyle(color: AppColor.muted, fontSize: 13)),
    const SizedBox(height: 4),
    Text('Fungus: ${crop.fungusPressure}', style: const TextStyle(color: AppColor.muted, fontSize: 13)),
    const SizedBox(height: 8),
    ...crop.preventative.take(2).map((item) => Text('• $item', style: const TextStyle(color: AppColor.muted, fontSize: 13))),
  ]));
}

class MapOutline extends StatelessWidget {
  const MapOutline({required this.rect, required this.size, super.key});
  final Rect rect;
  final Size size;
  @override
  Widget build(BuildContext context) => Positioned.fromRect(rect: scaleRect(rect, size), child: IgnorePointer(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColor.earth, width: 1.7)))));
}

class MapPath extends StatelessWidget {
  const MapPath({required this.rect, required this.size, super.key});
  final Rect rect;
  final Size size;
  @override
  Widget build(BuildContext context) => Positioned.fromRect(rect: scaleRect(rect, size), child: IgnorePointer(child: Container(decoration: BoxDecoration(color: AppColor.path, borderRadius: BorderRadius.circular(3)))));
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEDEAE2)..strokeWidth = .45;
    for (double x = 0; x < size.width; x += 12) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 12) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LogSprayScreen extends StatefulWidget {
  const LogSprayScreen({required this.initialBeds, required this.products, required this.bedCrops, required this.onSave, super.key});
  final Set<int> initialBeds;
  final List<SprayProduct> products;
  final Map<int, List<CropProfile>> bedCrops;
  final void Function({required Set<int> beds, required SprayProduct product, required String reason, required String notes, required int withholdingDays}) onSave;
  @override
  State<LogSprayScreen> createState() => _LogSprayScreenState();
}

class _LogSprayScreenState extends State<LogSprayScreen> {
  int step = 0;
  late Set<int> selectedBeds;
  late SprayProduct selectedProduct;
  late int withholdingDays;
  final reasonController = TextEditingController();
  final notesController = TextEditingController();
  @override
  void initState() { super.initState(); selectedBeds = {...widget.initialBeds}; selectedProduct = widget.products.first; withholdingDays = selectedProduct.withholdingDays; }
  @override
  void dispose() { reasonController.dispose(); notesController.dispose(); super.dispose(); }
  void goNext() => setState(() => step = (step + 1).clamp(0, 3));
  void goBack() => setState(() => step = (step - 1).clamp(0, 3));
  void save() => widget.onSave(beds: selectedBeds, product: selectedProduct, reason: reasonController.text, notes: notesController.text, withholdingDays: withholdingDays);
  @override
  Widget build(BuildContext context) => AppPage(title: 'Log Spray', subtitle: ['Select beds', 'Select product', 'Add details', 'Review and save'][step], leading: step == 0 ? null : CupertinoButton(padding: EdgeInsets.zero, onPressed: goBack, child: const Icon(CupertinoIcons.back, color: AppColor.ink)), children: [
    StepProgress(step: step), const SizedBox(height: 22),
    if (step == 0) SelectBedsStep(selectedBeds: selectedBeds, bedCrops: widget.bedCrops, onChanged: (beds) => setState(() => selectedBeds = beds)),
    if (step == 1) SelectProductStep(products: widget.products, selected: selectedProduct, onSelected: (product) => setState(() { selectedProduct = product; withholdingDays = product.withholdingDays; })),
    if (step == 2) DetailsStep(reasonController: reasonController, notesController: notesController, withholdingDays: withholdingDays, onDecrease: withholdingDays > 0 ? () => setState(() => withholdingDays--) : null, onIncrease: () => setState(() => withholdingDays++)),
    if (step == 3) ReviewStep(beds: selectedBeds, product: selectedProduct, reason: reasonController.text, notes: notesController.text, withholdingDays: withholdingDays),
    const SizedBox(height: 20),
    Row(children: [if (step > 0) Expanded(child: SecondaryButton(title: 'Back', icon: CupertinoIcons.back, onPressed: goBack)), if (step > 0) const SizedBox(width: 12), Expanded(child: PrimaryButton(title: step == 3 ? 'Save Spray' : ['Next: Product', 'Next: Details', 'Next: Review'][step], onPressed: step == 3 ? save : goNext))]),
  ]);
}

class StepProgress extends StatelessWidget {
  const StepProgress({required this.step, super.key});
  final int step;
  @override
  Widget build(BuildContext context) => Row(children: List.generate(4, (index) => Expanded(child: Row(children: [Expanded(child: Container(height: 3, color: index <= step ? AppColor.primary : AppColor.line)), Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: index <= step ? AppColor.primary : AppColor.surfaceSoft, shape: BoxShape.circle), child: Text('${index + 1}', style: TextStyle(color: index <= step ? CupertinoColors.white : AppColor.muted, fontWeight: FontWeight.w900, fontSize: 12)))]))));
}

class SelectBedsStep extends StatelessWidget {
  const SelectBedsStep({required this.selectedBeds, required this.bedCrops, required this.onChanged, super.key});
  final Set<int> selectedBeds;
  final Map<int, List<CropProfile>> bedCrops;
  final ValueChanged<Set<int>> onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHeader(title: 'Select beds'), const SizedBox(height: 6), Text('${selectedBeds.length} selected', style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700)), const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: gardenBeds.map((bed) => BedChip(number: bed.number, selected: selectedBeds.contains(bed.number), iconPath: (bedCrops[bed.number]?.isNotEmpty ?? false) ? bedCrops[bed.number]!.first.iconPath : null, count: bedCrops[bed.number]?.length ?? 0, onTap: () { final next = {...selectedBeds}; next.contains(bed.number) ? next.remove(bed.number) : next.add(bed.number); onChanged(next); })).toList())]);
}

class SelectProductStep extends StatelessWidget {
  const SelectProductStep({required this.products, required this.selected, required this.onSelected, super.key});
  final List<SprayProduct> products;
  final SprayProduct selected;
  final ValueChanged<SprayProduct> onSelected;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHeader(title: 'Select product'), const SizedBox(height: 12), ...products.map((product) => ProductSelectCard(product: product, selected: product.id == selected.id, onTap: () => onSelected(product)))]);
}

class ProductSelectCard extends StatelessWidget {
  const ProductSelectCard({required this.product, required this.selected, required this.onTap, super.key});
  final SprayProduct product;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: selected ? AppColor.primarySoft : AppColor.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? AppColor.primary : AppColor.line), boxShadow: subtleShadow), child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColor.surfaceSoft, borderRadius: BorderRadius.circular(12)), child: const Icon(CupertinoIcons.drop, color: AppColor.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(color: AppColor.ink, fontWeight: FontWeight.w900)), Text('${product.type} · ${product.withholdingDays} days', style: const TextStyle(color: AppColor.muted, fontSize: 12))])), if (selected) const Icon(CupertinoIcons.check_mark_circled_solid, color: AppColor.primary)])));
}

class DetailsStep extends StatelessWidget {
  const DetailsStep({required this.reasonController, required this.notesController, required this.withholdingDays, required this.onDecrease, required this.onIncrease, super.key});
  final TextEditingController reasonController;
  final TextEditingController notesController;
  final int withholdingDays;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHeader(title: 'Add details'), const SizedBox(height: 14), FieldLabel(label: 'Reason', child: CupertinoTextField(controller: reasonController, placeholder: 'Aphids, mildew, tonic, etc.', padding: const EdgeInsets.all(14), decoration: inputDecoration)), const SizedBox(height: 14), PremiumCard(child: Row(children: [const Expanded(child: Text('Withholding period', style: TextStyle(fontWeight: FontWeight.w900))), StepButton(icon: CupertinoIcons.minus, onPressed: onDecrease), Text('$withholdingDays', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), StepButton(icon: CupertinoIcons.plus, onPressed: onIncrease)])), const SizedBox(height: 14), FieldLabel(label: 'Notes optional', child: CupertinoTextField(controller: notesController, placeholder: 'Application notes', maxLines: 4, padding: const EdgeInsets.all(14), decoration: inputDecoration))]);
}

class ReviewStep extends StatelessWidget {
  const ReviewStep({required this.beds, required this.product, required this.reason, required this.notes, required this.withholdingDays, super.key});
  final Set<int> beds;
  final SprayProduct product;
  final String reason;
  final String notes;
  final int withholdingDays;
  @override
  Widget build(BuildContext context) => PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionHeader(title: 'Summary'), const SizedBox(height: 16), SummaryRow('Beds', beds.toList()..sort()), SummaryRow('Product', product.name), SummaryRow('Date sprayed', dateLabel(DateTime.now())), SummaryRow('Reason', reason.trim().isEmpty ? 'General spray' : reason.trim()), SummaryRow('Withholding', '$withholdingDays days'), SummaryRow('Safe from', dateLabel(DateTime.now().add(Duration(days: withholdingDays)))), if (notes.trim().isNotEmpty) SummaryRow('Notes', notes.trim())]));
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.records, required this.actionMessage, required this.onRemove, required this.onClearAll, super.key});
  final List<SprayRecord> records;
  final String? actionMessage;
  final ValueChanged<int> onRemove;
  final VoidCallback onClearAll;
  @override
  Widget build(BuildContext context) => AppPage(title: 'History', subtitle: 'All spray records.', trailing: const Icon(CupertinoIcons.slider_horizontal_3, color: AppColor.ink), children: [if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)], if (records.isNotEmpty) ...[DestructiveButton(title: 'Clear all history', onPressed: onClearAll), const SizedBox(height: 14)], if (records.isEmpty) const EmptyCard('No spray records yet.') else ...records.map((record) => SprayRecordCard(record: record, onRemove: () => onRemove(record.id)))]);
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({required this.products, required this.actionMessage, required this.onAdd, required this.onRemove, super.key});
  final List<SprayProduct> products;
  final String? actionMessage;
  final ValueChanged<SprayProduct> onAdd;
  final ValueChanged<int> onRemove;
  @override
  Widget build(BuildContext context) => AppPage(title: 'Products', subtitle: 'Spray product library.', trailing: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => showAddProductDialog(context, onAdd), child: const Icon(CupertinoIcons.plus, color: AppColor.ink)), children: [if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)], ...products.map((product) => ProductLibraryCard(product: product, onRemove: () => onRemove(product.id)))]);
}

void showAddProductDialog(BuildContext context, ValueChanged<SprayProduct> onAdd) {
  final name = TextEditingController();
  final type = TextEditingController(text: 'Custom product');
  final days = TextEditingController(text: '1');
  showCupertinoDialog<void>(context: context, builder: (_) => CupertinoAlertDialog(title: const Text('Add product'), content: Column(children: [const SizedBox(height: 12), CupertinoTextField(controller: name, placeholder: 'Name'), const SizedBox(height: 8), CupertinoTextField(controller: type, placeholder: 'Type'), const SizedBox(height: 8), CupertinoTextField(controller: days, placeholder: 'Withholding days', keyboardType: TextInputType.number)]), actions: [CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)), CupertinoDialogAction(isDefaultAction: true, child: const Text('Add'), onPressed: () { final parsedDays = int.tryParse(days.text) ?? 1; if (name.text.trim().isNotEmpty) onAdd(SprayProduct(id: 0, name: name.text.trim(), type: type.text.trim().isEmpty ? 'Custom product' : type.text.trim(), withholdingDays: parsedDays)); Navigator.pop(context); })]));
}

class AppPage extends StatelessWidget {
  const AppPage({required this.title, required this.subtitle, required this.children, this.leading, this.trailing, super.key});
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? leading;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 34), children: [Row(children: [if (leading != null) ...[leading!, const SizedBox(width: 8)], Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColor.ink)), Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColor.muted))])), if (trailing != null) trailing!]), const SizedBox(height: 24), ...children]);
}

class ActionBanner extends StatelessWidget { const ActionBanner({required this.message, super.key}); final String message; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColor.primarySoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColor.primary.withValues(alpha: .25))), child: Row(children: [const Icon(CupertinoIcons.check_mark_circled_solid, color: AppColor.primary), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.w800)))])); }
class InfoCard extends StatelessWidget { const InfoCard({required this.title, required this.subtitle, required this.icon, this.trailing, super.key}); final String title; final String subtitle; final IconData icon; final String? trailing; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColor.line), boxShadow: subtleShadow), child: Row(children: [Icon(icon, color: AppColor.primary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(color: AppColor.muted, fontSize: 12))])), if (trailing != null) StatusChip(text: trailing!, color: AppColor.primary, bg: AppColor.primarySoft)])); }
class PremiumCard extends StatelessWidget { const PremiumCard({required this.child, super.key}); final Widget child; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: cardDecoration, child: child); }
class EmptyCard extends StatelessWidget { const EmptyCard(this.message, {super.key}); final String message; @override Widget build(BuildContext context) => PremiumCard(child: Text(message, style: const TextStyle(color: AppColor.muted))); }
class SectionHeader extends StatelessWidget { const SectionHeader({required this.title, this.action, super.key}); final String title; final String? action; @override Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), if (action != null) Text(action!, style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.w800))]); }
class FieldLabel extends StatelessWidget { const FieldLabel({required this.label, required this.child, super.key}); final String label; final Widget child; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), child]); }
class SummaryRow extends StatelessWidget { const SummaryRow(this.label, this.value, {super.key}); final String label; final Object value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700))), Expanded(child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)))])); }
class BedChip extends StatelessWidget { const BedChip({required this.number, required this.selected, required this.onTap, this.iconPath, this.count = 0, super.key}); final int number; final bool selected; final String? iconPath; final int count; final VoidCallback onTap; @override Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Stack(clipBehavior: Clip.none, children: [Container(width: 46, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? AppColor.primary : AppColor.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColor.primary : AppColor.line)), child: iconPath == null ? Text('$number', style: TextStyle(color: selected ? CupertinoColors.white : AppColor.ink, fontWeight: FontWeight.w900)) : Padding(padding: const EdgeInsets.all(8), child: SvgPicture.asset(iconPath!))), if (count > 1) Positioned(right: -5, top: -5, child: CountBadge(count: count))])); }
class StatusPill extends StatelessWidget { const StatusPill({required this.status, super.key}); final String status; @override Widget build(BuildContext context) { final waiting = status == 'Wait'; return StatusChip(text: status.toUpperCase(), color: waiting ? AppColor.warning : AppColor.primary, bg: waiting ? AppColor.warningSoft : AppColor.primarySoft); } }
class StatusChip extends StatelessWidget { const StatusChip({required this.text, required this.color, required this.bg, super.key}); final String text; final Color color; final Color bg; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))); }
class StepButton extends StatelessWidget { const StepButton({required this.icon, required this.onPressed, super.key}); final IconData icon; final VoidCallback? onPressed; @override Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onPressed, child: Icon(icon, color: onPressed == null ? AppColor.muted : AppColor.primary)); }
class PrimaryButton extends StatelessWidget { const PrimaryButton({required this.title, required this.onPressed, super.key}); final String title; final VoidCallback? onPressed; @override Widget build(BuildContext context) => CupertinoButton(color: AppColor.primary, borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.symmetric(vertical: 14), onPressed: onPressed, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))); }
class SecondaryButton extends StatelessWidget { const SecondaryButton({required this.title, required this.icon, required this.onPressed, super.key}); final String title; final IconData icon; final VoidCallback? onPressed; @override Widget build(BuildContext context) => CupertinoButton(color: AppColor.surfaceSoft, borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.symmetric(vertical: 10), onPressed: onPressed, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: onPressed == null ? AppColor.muted : AppColor.primary), const SizedBox(width: 6), Text(title, style: TextStyle(color: onPressed == null ? AppColor.muted : AppColor.ink, fontWeight: FontWeight.w800))])); }
class DestructiveButton extends StatelessWidget { const DestructiveButton({required this.title, required this.onPressed, super.key}); final String title; final VoidCallback? onPressed; @override Widget build(BuildContext context) => CupertinoButton(color: AppColor.dangerSoft, borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.symmetric(vertical: 10), onPressed: onPressed, child: Text(title, style: TextStyle(color: onPressed == null ? AppColor.muted : AppColor.danger, fontWeight: FontWeight.w800))); }
class SprayRecordCard extends StatelessWidget { const SprayRecordCard({required this.record, this.onRemove, super.key}); final SprayRecord record; final VoidCallback? onRemove; @override Widget build(BuildContext context) { final waiting = record.safeDate.isAfter(DateTime.now()); return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColor.primarySoft, borderRadius: BorderRadius.circular(14)), child: const Icon(CupertinoIcons.drop, color: AppColor.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bed ${record.bedNumbers.join(', ')}', style: const TextStyle(fontWeight: FontWeight.w900)), Text(record.product, style: const TextStyle(color: AppColor.ink)), Text('${record.withholdingDays} days · ${shortDate(record.sprayedAt)}', style: const TextStyle(color: AppColor.muted, fontSize: 12))])), Column(children: [StatusPill(status: waiting ? 'Wait' : 'Safe'), if (onRemove != null) CupertinoButton(padding: EdgeInsets.zero, minSize: 30, onPressed: onRemove, child: const Icon(CupertinoIcons.trash, color: AppColor.danger, size: 20))]) ])); } }
class ProductLibraryCard extends StatelessWidget { const ProductLibraryCard({required this.product, required this.onRemove, super.key}); final SprayProduct product; final VoidCallback onRemove; @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColor.primarySoft, borderRadius: BorderRadius.circular(15)), child: const Icon(CupertinoIcons.cube_box, color: AppColor.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900)), Text(product.type, style: const TextStyle(color: AppColor.muted)), Text('Withholding: ${product.withholdingDays} days', style: const TextStyle(color: AppColor.ink, fontSize: 12))])), CupertinoButton(padding: EdgeInsets.zero, onPressed: onRemove, child: const Icon(CupertinoIcons.trash, color: AppColor.danger, size: 20))])); }

const shadow = [BoxShadow(color: Color(0x16000000), blurRadius: 18, offset: Offset(0, 8))];
const subtleShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))];
final cardDecoration = BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColor.line), boxShadow: subtleShadow);
final inputDecoration = BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColor.line));
