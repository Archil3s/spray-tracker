import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'crop_library.dart';

void main() => runApp(const SprayTrackerApp());

class SprayTrackerApp extends StatelessWidget {
  const SprayTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Garden Spray',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColor.forest,
        scaffoldBackgroundColor: AppColor.canvas,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(color: AppColor.ink, fontSize: 16),
        ),
      ),
      home: SprayTrackerHome(),
    );
  }
}

class AppColor {
  static const canvas = Color(0xFFF5F2EA);
  static const panel = Color(0xFFFFFFFF);
  static const panelAlt = Color(0xFFF0ECE3);
  static const ink = Color(0xFF182019);
  static const muted = Color(0xFF6C746B);
  static const faint = Color(0xFF9AA196);
  static const line = Color(0xFFE2DED3);
  static const forest = Color(0xFF1F4F33);
  static const forest2 = Color(0xFF2F6B46);
  static const forestSoft = Color(0xFFE5EFE8);
  static const soil = Color(0xFF7B5430);
  static const path = Color(0xFFB7B3AA);
  static const amber = Color(0xFFC87A22);
  static const amberSoft = Color(0xFFFFF0D8);
  static const red = Color(0xFFB84B44);
  static const redSoft = Color(0xFFF8E5E2);
  static const blue = Color(0xFF2C6270);
  static const blueSoft = Color(0xFFE4F0F2);
}

const softShadow = [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10))];
const smallShadow = [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))];

BoxDecoration get panelDecoration => BoxDecoration(
      color: AppColor.panel,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColor.line),
      boxShadow: smallShadow,
    );

BoxDecoration get insetDecoration => BoxDecoration(
      color: AppColor.panelAlt,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColor.line),
    );

class GardenBed {
  const GardenBed(this.number, this.bounds);
  final int number;
  final Rect bounds;
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

class SprayTarget {
  const SprayTarget({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.color,
    required this.softColor,
    required this.icon,
  });

  final String id;
  final String title;
  final String shortTitle;
  final String description;
  final Color color;
  final Color softColor;
  final IconData icon;
}

class SpraySuggestion {
  const SpraySuggestion({required this.name, required this.targetId, required this.target, required this.whenToUse});
  final String name;
  final String targetId;
  final String target;
  final String whenToUse;
}

class SprayProduct {
  const SprayProduct({required this.id, required this.name, required this.type, required this.withholdingDays, required this.targetIds});
  final int id;
  final String name;
  final String type;
  final int withholdingDays;
  final List<String> targetIds;
}

class SprayRecord {
  const SprayRecord({
    required this.id,
    required this.bedNumbers,
    required this.cropNames,
    required this.product,
    required this.targetId,
    required this.reason,
    required this.notes,
    required this.sprayedAt,
    required this.withholdingDays,
  });

  final int id;
  final List<int> bedNumbers;
  final List<String> cropNames;
  final String product;
  final String targetId;
  final String reason;
  final String notes;
  final DateTime sprayedAt;
  final int withholdingDays;

  DateTime get safeDate => sprayedAt.add(Duration(days: withholdingDays));
}

class BedStatus {
  const BedStatus({required this.label, required this.summary, required this.daysRemaining});
  final String label;
  final String summary;
  final int daysRemaining;
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

const sprayTargets = [
  SprayTarget(
    id: 'pest',
    title: 'Pest pressure',
    shortTitle: 'Pest',
    description: 'Insects, mites, chewing damage, webbing, sticky residue, or visible larvae.',
    color: AppColor.red,
    softColor: AppColor.redSoft,
    icon: CupertinoIcons.ant,
  ),
  SprayTarget(
    id: 'fungus',
    title: 'Fungal pressure',
    shortTitle: 'Fungus',
    description: 'Mildew, rust, leaf spots, blight risk, or humid disease pressure.',
    color: AppColor.blue,
    softColor: AppColor.blueSoft,
    icon: CupertinoIcons.cloud_rain,
  ),
  SprayTarget(
    id: 'prevent',
    title: 'Preventative',
    shortTitle: 'Prevent',
    description: 'No outbreak yet. Use this for risk reduction before pressure builds.',
    color: AppColor.amber,
    softColor: AppColor.amberSoft,
    icon: CupertinoIcons.shield,
  ),
  SprayTarget(
    id: 'maintain',
    title: 'Maintenance',
    shortTitle: 'Maintain',
    description: 'Plant support, stress recovery, pruning, airflow, and general crop care.',
    color: AppColor.forest,
    softColor: AppColor.forestSoft,
    icon: CupertinoIcons.leaf_arrow_circlepath,
  ),
];

const compoundOuter = Rect.fromLTWH(.04, .07, .47, .33);
const compoundPath = Rect.fromLTWH(.275, .08, .045, .31);
const compoundLowerLeft = Rect.fromLTWH(.06, .24, .20, .15);
const mainPath = Rect.fromLTWH(.55, .17, .045, .72);

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String monthName(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
String shortDate(DateTime date) => '${date.day} ${monthName(date.month)}';
String fullDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
Rect scaleRect(Rect r, Size size) => Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);
SprayTarget targetById(String id) => sprayTargets.firstWhere((target) => target.id == id, orElse: () => sprayTargets.first);

CropProfile cropFromVegetable(VegetableDefinition vegetable) {
  return CropProfile(
    name: vegetable.name,
    iconPath: vegetable.iconPath,
    pestPressure: vegetable.commonPests.join(', '),
    fungusPressure: vegetable.commonDiseases.join(', '),
    preventative: vegetable.preventativeTips,
    maintenance: vegetable.maintenanceTips,
    suggestions: suggestionsFor(vegetable),
  );
}

List<SpraySuggestion> suggestionsFor(VegetableDefinition vegetable) {
  final pests = vegetable.commonPests.take(3).join(', ');
  final diseases = vegetable.commonDiseases.take(3).join(', ');
  return [
    SpraySuggestion(name: 'Neem Oil', targetId: 'pest', target: pests.isEmpty ? 'Pest pressure' : pests, whenToUse: 'Use when visible pest pressure is present and the product label supports this crop.'),
    SpraySuggestion(name: 'Copper Spray', targetId: 'fungus', target: diseases.isEmpty ? 'Fungal pressure' : diseases, whenToUse: 'Use for supported fungal pressure during wet or humid conditions.'),
    const SpraySuggestion(name: 'Copper Spray', targetId: 'prevent', target: 'Disease prevention', whenToUse: 'Consider before extended wet weather where label directions support use.'),
    const SpraySuggestion(name: 'Seaweed Tonic', targetId: 'maintain', target: 'Plant stress support', whenToUse: 'Use after transplanting, pruning, heavy cropping, wind, heat, or cold stress.'),
  ];
}

class CropIcon extends StatelessWidget {
  const CropIcon(this.path, {this.size = 28, super.key});
  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, width: size, height: size, fit: BoxFit.contain);
    }
    return Image.asset(path, width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.high);
  }
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
  int nextProductId = 4;
  String lastMessage = '';
  Set<int> sprayBeds = {4};
  Set<String> sprayCrops = {};
  String sprayTargetId = 'pest';

  final Map<int, List<CropProfile>> bedCrops = {};
  List<SprayRecord> records = [];
  late List<SprayProduct> products;

  @override
  void initState() {
    super.initState();
    products = const [
      SprayProduct(id: 1, name: 'Neem Oil', type: 'Pest control', withholdingDays: 3, targetIds: ['pest']),
      SprayProduct(id: 2, name: 'Copper Spray', type: 'Fungicide', withholdingDays: 7, targetIds: ['fungus', 'prevent']),
      SprayProduct(id: 3, name: 'Seaweed Tonic', type: 'Plant tonic', withholdingDays: 1, targetIds: ['maintain', 'prevent']),
    ].toList();
  }

  BedStatus statusForBed(int bedNumber) {
    final latest = records.where((record) => record.bedNumbers.contains(bedNumber)).firstOrNull;
    if (latest == null) return const BedStatus(label: 'Clear', summary: 'No spray record', daysRemaining: 0);
    final remaining = latest.safeDate.difference(DateTime.now()).inDays + 1;
    final target = targetById(latest.targetId).shortTitle;
    final cropText = latest.cropNames.isEmpty ? 'Whole bed' : latest.cropNames.join(', ');
    if (latest.safeDate.isAfter(DateTime.now())) {
      return BedStatus(label: 'Hold', summary: '$cropText · ${latest.product} · $target · ${shortDate(latest.safeDate)}', daysRemaining: remaining.clamp(1, 999).toInt());
    }
    return BedStatus(label: 'Clear', summary: '$cropText · last ${latest.product}', daysRemaining: 0);
  }

  List<CropProfile> cropsForBeds(Set<int> beds) {
    final byName = <String, CropProfile>{};
    for (final bed in beds) {
      for (final crop in bedCrops[bed] ?? const <CropProfile>[]) {
        byName[crop.name] = crop;
      }
    }
    return byName.values.toList();
  }

  Set<String> defaultCropNames(Set<int> beds) {
    final names = cropsForBeds(beds).map((crop) => crop.name).toSet();
    return names.isEmpty ? {'Whole bed'} : names;
  }

  int get plantedBeds => bedCrops.values.where((crops) => crops.isNotEmpty).length;
  int get totalCrops => bedCrops.values.fold(0, (sum, crops) => sum + crops.length);
  int get holdBeds => gardenBeds.where((bed) => statusForBed(bed.number).label == 'Hold').length;
  int get clearBeds => gardenBeds.length - holdBeds;
  List<SprayRecord> get activeRecords => records.where((record) => record.safeDate.isAfter(DateTime.now())).toList();

  void showMessage(String message) => setState(() => lastMessage = message);

  void addCrop(int bed, CropProfile crop) {
    final existing = [...bedCrops[bed] ?? <CropProfile>[]];
    final alreadyAdded = existing.any((item) => item.name == crop.name);
    if (!alreadyAdded) existing.add(crop);
    setState(() {
      bedCrops[bed] = existing;
      selectedBed = bed;
      lastMessage = alreadyAdded ? '${crop.name} is already in Bed $bed' : '${crop.name} added to Bed $bed';
    });
  }

  void removeCrop(int bed, CropProfile crop) {
    final next = [...bedCrops[bed] ?? <CropProfile>[]]..removeWhere((item) => item.name == crop.name);
    setState(() {
      if (next.isEmpty) {
        bedCrops.remove(bed);
      } else {
        bedCrops[bed] = next;
      }
      lastMessage = '${crop.name} removed from Bed $bed';
    });
  }

  void clearCrops(int bed) {
    setState(() {
      bedCrops.remove(bed);
      lastMessage = 'Vegetables cleared from Bed $bed';
    });
  }

  void clearSpraysForBed(int bed) {
    final before = records.length;
    setState(() {
      records = records.where((record) => !record.bedNumbers.contains(bed)).toList();
      lastMessage = before == records.length ? 'No spray records on Bed $bed' : 'Spray records cleared from Bed $bed';
    });
  }

  void startSpray({required Set<int> beds, String targetId = 'pest', Set<String>? cropNames}) {
    final safeBeds = beds.isEmpty ? {selectedBed} : beds;
    setState(() {
      sprayBeds = safeBeds;
      sprayTargetId = targetId;
      sprayCrops = cropNames == null || cropNames.isEmpty ? defaultCropNames(safeBeds) : cropNames;
      tab = 2;
    });
  }

  void saveSpray({
    required Set<int> beds,
    required Set<String> cropNames,
    required SprayProduct product,
    required String targetId,
    required String reason,
    required String notes,
    required int withholdingDays,
  }) {
    if (beds.isEmpty) {
      showMessage('Choose at least one bed.');
      return;
    }
    final sortedBeds = beds.toList()..sort();
    final sortedCrops = cropNames.toList()..sort();
    setState(() {
      records.insert(
        0,
        SprayRecord(
          id: nextRecordId++,
          bedNumbers: sortedBeds,
          cropNames: sortedCrops,
          product: product.name,
          targetId: targetId,
          reason: reason.trim().isEmpty ? targetById(targetId).title : reason.trim(),
          notes: notes.trim(),
          sprayedAt: DateTime.now(),
          withholdingDays: withholdingDays,
        ),
      );
      selectedBed = sortedBeds.first;
      lastMessage = 'Spray saved for ${sortedCrops.join(', ')}';
      tab = 0;
    });
  }

  void deleteRecord(int id) {
    setState(() {
      records = records.where((record) => record.id != id).toList();
      lastMessage = 'Spray record removed';
    });
  }

  void clearHistory() {
    setState(() {
      records.clear();
      lastMessage = 'All spray history cleared';
    });
  }

  void addProduct(SprayProduct product) {
    setState(() {
      products.add(SprayProduct(id: nextProductId++, name: product.name, type: product.type, withholdingDays: product.withholdingDays, targetIds: product.targetIds));
      lastMessage = '${product.name} added';
    });
  }

  void removeProduct(int id) {
    setState(() {
      final removed = products.where((product) => product.id == id).map((product) => product.name).firstOrNull;
      products = products.where((product) => product.id != id).toList();
      if (products.isEmpty) {
        products.add(SprayProduct(id: nextProductId++, name: 'General Spray', type: 'Custom product', withholdingDays: 1, targetIds: const ['pest', 'fungus', 'prevent', 'maintain']));
      }
      lastMessage = removed == null ? 'Product not found' : '$removed removed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        clearBeds: clearBeds,
        holdBeds: holdBeds,
        plantedBeds: plantedBeds,
        totalCrops: totalCrops,
        activeRecords: activeRecords,
        recentRecords: records,
        message: lastMessage,
        onPlanSpray: () => startSpray(beds: {selectedBed}, cropNames: defaultCropNames({selectedBed})),
      ),
      GardenScreen(
        selectedBed: selectedBed,
        bedCrops: bedCrops,
        message: lastMessage,
        statusForBed: statusForBed,
        onSelectBed: (bed) => setState(() => selectedBed = bed),
        onAddCrop: addCrop,
        onRemoveCrop: removeCrop,
        onClearCrops: clearCrops,
        onClearSprays: clearSpraysForBed,
        onStartSpray: (bed, target, crops) => startSpray(beds: {bed}, targetId: target, cropNames: crops),
      ),
      SprayScreen(
        key: ValueKey('${sprayBeds.join('-')}-${sprayCrops.join('-')}-$sprayTargetId-${products.length}-${totalCrops}'),
        initialBeds: sprayBeds,
        initialCrops: sprayCrops,
        initialTarget: sprayTargetId,
        products: products,
        bedCrops: bedCrops,
        onSave: saveSpray,
      ),
      RecordsScreen(records: records, message: lastMessage, onDelete: deleteRecord, onClear: clearHistory),
      ProductsScreen(products: products, message: lastMessage, onAdd: addProduct, onDelete: removeProduct),
    ];

    return CupertinoPageScaffold(
      backgroundColor: AppColor.canvas,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: IndexedStack(index: tab, children: pages)),
            AppTabBar(currentIndex: tab, onTap: (index) => setState(() => tab = index)),
          ],
        ),
      ),
    );
  }
}

class AppTabBar extends StatelessWidget {
  const AppTabBar({required this.currentIndex, required this.onTap, super.key});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _TabItem(CupertinoIcons.house_fill, 'Home'),
      _TabItem(CupertinoIcons.map_fill, 'Garden'),
      _TabItem(CupertinoIcons.drop_fill, 'Spray'),
      _TabItem(CupertinoIcons.list_bullet_below_rectangle, 'Records'),
      _TabItem(CupertinoIcons.cube_box_fill, 'Products'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: const Color(0xF7FFFFFF), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColor.line), boxShadow: softShadow),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == currentIndex;
          final item = items[index];
          return Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: selected ? AppColor.forest : CupertinoColors.transparent, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 18, color: selected ? CupertinoColors.white : AppColor.muted),
                    const SizedBox(height: 3),
                    Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? CupertinoColors.white : AppColor.muted)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.totalCrops, required this.activeRecords, required this.recentRecords, required this.message, required this.onPlanSpray, super.key});
  final int clearBeds;
  final int holdBeds;
  final int plantedBeds;
  final int totalCrops;
  final List<SprayRecord> activeRecords;
  final List<SprayRecord> recentRecords;
  final String message;
  final VoidCallback onPlanSpray;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: 'Garden spray log',
      title: 'Overview',
      subtitle: 'Beds, crops, withholding periods, and spray pressure.',
      message: message,
      children: [
        StatusHero(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, totalCrops: totalCrops, onPlanSpray: onPlanSpray),
        const SizedBox(height: 18),
        if (activeRecords.isEmpty) const CalmInfoCard(title: 'No active withholding', subtitle: 'All beds with spray records are currently clear.', icon: CupertinoIcons.check_mark_circled) else ActiveHoldCard(record: activeRecords.first),
        const SizedBox(height: 22),
        const SectionTitle('Recent activity'),
        const SizedBox(height: 10),
        if (recentRecords.isEmpty) const EmptyPanel('No spray records yet.') else ...recentRecords.take(4).map((record) => RecordTile(record: record)),
      ],
    );
  }
}

class StatusHero extends StatelessWidget {
  const StatusHero({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.totalCrops, required this.onPlanSpray, super.key});
  final int clearBeds;
  final int holdBeds;
  final int plantedBeds;
  final int totalCrops;
  final VoidCallback onPlanSpray;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColor.forest,
        borderRadius: BorderRadius.circular(30),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today', style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w800, letterSpacing: .6)),
          const SizedBox(height: 8),
          const Text('Garden spray status', style: TextStyle(color: CupertinoColors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -.5)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: HeroMetric(value: '$clearBeds', label: 'clear beds')),
              const SizedBox(width: 10),
              Expanded(child: HeroMetric(value: '$holdBeds', label: 'on hold')),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0x18FFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x22FFFFFF))),
            child: Row(
              children: [
                const Icon(CupertinoIcons.leaf_arrow_circlepath, color: CupertinoColors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('$plantedBeds beds planted · $totalCrops crop placements', style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            onPressed: onPlanSpray,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.drop_fill, color: AppColor.forest, size: 17),
                SizedBox(width: 8),
                Text('Plan a spray', style: TextStyle(color: AppColor.forest, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeroMetric extends StatelessWidget {
  const HeroMetric({required this.value, required this.label, super.key});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x1FFFFFFF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: CupertinoColors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text(label, style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class ActiveHoldCard extends StatelessWidget {
  const ActiveHoldCard({required this.record, super.key});
  final SprayRecord record;

  @override
  Widget build(BuildContext context) {
    final days = record.safeDate.difference(DateTime.now()).inDays + 1;
    return Panel(
      child: Row(
        children: [
          const StatusIcon(icon: CupertinoIcons.clock_fill, color: AppColor.amber, background: AppColor.amberSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Next safe harvest', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 3),
              Text('Bed ${record.bedNumbers.join(', ')} · ${record.cropNames.join(', ')} · ${shortDate(record.safeDate)}', style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700)),
            ]),
          ),
          Pill(label: '$days d', color: AppColor.amber, background: AppColor.amberSoft),
        ],
      ),
    );
  }
}

class GardenScreen extends StatelessWidget {
  const GardenScreen({required this.selectedBed, required this.bedCrops, required this.message, required this.statusForBed, required this.onSelectBed, required this.onAddCrop, required this.onRemoveCrop, required this.onClearCrops, required this.onClearSprays, required this.onStartSpray, super.key});
  final int selectedBed;
  final Map<int, List<CropProfile>> bedCrops;
  final String message;
  final BedStatus Function(int bed) statusForBed;
  final ValueChanged<int> onSelectBed;
  final void Function(int bed, CropProfile crop) onAddCrop;
  final void Function(int bed, CropProfile crop) onRemoveCrop;
  final ValueChanged<int> onClearCrops;
  final ValueChanged<int> onClearSprays;
  final void Function(int bed, String targetId, Set<String> cropNames) onStartSpray;

  @override
  Widget build(BuildContext context) {
    final crops = bedCrops[selectedBed] ?? const <CropProfile>[];
    final status = statusForBed(selectedBed);
    return PageShell(
      eyebrow: 'Garden map',
      title: 'Beds',
      subtitle: 'Add crops to beds and start crop-specific spray records.',
      message: message,
      children: [
        GardenMapCard(selectedBed: selectedBed, bedCrops: bedCrops, statusForBed: statusForBed, onSelectBed: onSelectBed),
        const SizedBox(height: 16),
        BedCommandPanel(
          bedNumber: selectedBed,
          crops: crops,
          status: status,
          onAddCrop: () => showCropPicker(context, selectedBed, crops, onAddCrop),
          onRemoveCrop: (crop) => onRemoveCrop(selectedBed, crop),
          onClearCrops: crops.isEmpty ? null : () => onClearCrops(selectedBed),
          onClearSprays: () => onClearSprays(selectedBed),
          onStartSpray: () => showSprayGuide(context, selectedBed, crops, onStartSpray),
        ),
      ],
    );
  }
}

class GardenMapCard extends StatelessWidget {
  const GardenMapCard({required this.selectedBed, required this.bedCrops, required this.statusForBed, required this.onSelectBed, super.key});
  final int selectedBed;
  final Map<int, List<CropProfile>> bedCrops;
  final BedStatus Function(int bed) statusForBed;
  final ValueChanged<int> onSelectBed;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 540,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return RepaintBoundary(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: CustomPaint(painter: SoftGridPainter())),
                  MapOutline(rect: compoundOuter, size: size),
                  MapOutline(rect: compoundLowerLeft, size: size),
                  MapPath(rect: compoundPath, size: size),
                  MapPath(rect: mainPath, size: size),
                  ...gardenBeds.map((bed) => BedMapButton(bed: bed, rect: scaleRect(bed.bounds, size), selected: bed.number == selectedBed, crops: bedCrops[bed.number] ?? const <CropProfile>[], status: statusForBed(bed.number), onTap: () => onSelectBed(bed.number))),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class BedMapButton extends StatelessWidget {
  const BedMapButton({required this.bed, required this.rect, required this.selected, required this.crops, required this.status, required this.onTap, super.key});
  final GardenBed bed;
  final Rect rect;
  final bool selected;
  final List<CropProfile> crops;
  final BedStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hold = status.label == 'Hold';
    return Positioned.fromRect(
      rect: rect,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: hold ? AppColor.amberSoft : crops.isEmpty ? const Color(0xFFFCFBF6) : AppColor.forestSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColor.forest : hold ? AppColor.amber : AppColor.soil, width: selected ? 2.8 : 1.4),
            boxShadow: selected ? smallShadow : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Text('${bed.number}', style: TextStyle(fontSize: 12, color: selected ? AppColor.forest : AppColor.ink, fontWeight: FontWeight.w900))),
              if (crops.isNotEmpty) Positioned(top: -12, right: -12, child: CropIconCluster(crops: crops)),
            ],
          ),
        ),
      ),
    );
  }
}

class CropIconCluster extends StatelessWidget {
  const CropIconCluster({required this.crops, super.key});
  final List<CropProfile> crops;

  @override
  Widget build(BuildContext context) {
    final visible = crops.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(maxWidth: 118),
      decoration: BoxDecoration(color: AppColor.panel, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColor.line), boxShadow: smallShadow),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          ...visible.map((crop) => CropIcon(crop.iconPath, size: 21)),
          if (crops.length > 4) CountDot(count: crops.length - 4),
        ],
      ),
    );
  }
}

class BedCommandPanel extends StatelessWidget {
  const BedCommandPanel({required this.bedNumber, required this.crops, required this.status, required this.onAddCrop, required this.onRemoveCrop, required this.onClearCrops, required this.onClearSprays, required this.onStartSpray, super.key});
  final int bedNumber;
  final List<CropProfile> crops;
  final BedStatus status;
  final VoidCallback onAddCrop;
  final ValueChanged<CropProfile> onRemoveCrop;
  final VoidCallback? onClearCrops;
  final VoidCallback onClearSprays;
  final VoidCallback onStartSpray;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Bed $bedNumber', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.4))),
              Pill(label: status.label.toUpperCase(), color: status.label == 'Hold' ? AppColor.amber : AppColor.forest, background: status.label == 'Hold' ? AppColor.amberSoft : AppColor.forestSoft),
            ],
          ),
          const SizedBox(height: 4),
          Text(status.summary, style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          if (crops.isEmpty)
            const EmptyInline(icon: CupertinoIcons.leaf, title: 'No crops assigned', subtitle: 'Add vegetables to unlock crop-specific spray guidance.')
          else
            CropChips(crops: crops, onRemove: onRemoveCrop),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: PrimaryAction(label: 'Add crop', icon: CupertinoIcons.plus, onPressed: onAddCrop)),
              const SizedBox(width: 10),
              Expanded(child: SecondaryAction(label: 'Spray plan', icon: CupertinoIcons.scope, onPressed: crops.isEmpty ? null : onStartSpray)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: DestructiveAction(label: 'Clear sprays', onPressed: onClearSprays)),
              const SizedBox(width: 10),
              Expanded(child: DestructiveAction(label: 'Clear crops', onPressed: onClearCrops)),
            ],
          ),
        ],
      ),
    );
  }
}

class CropChips extends StatelessWidget {
  const CropChips({required this.crops, this.onRemove, super.key});
  final List<CropProfile> crops;
  final ValueChanged<CropProfile>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: crops.map((crop) {
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          decoration: BoxDecoration(color: AppColor.panelAlt, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColor.line)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CropIcon(crop.iconPath, size: 22),
              const SizedBox(width: 7),
              Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              if (onRemove != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 24,
                  onPressed: () => onRemove!(crop),
                  child: const Icon(CupertinoIcons.xmark_circle_fill, size: 17, color: AppColor.faint),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

void showCropPicker(BuildContext context, int bedNumber, List<CropProfile> assigned, void Function(int bed, CropProfile crop) onAddCrop) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .88,
          child: CropPickerSheet(bedNumber: bedNumber, assigned: assigned, onAddCrop: onAddCrop),
        ),
      ),
    ),
  );
}

class CropPickerSheet extends StatefulWidget {
  const CropPickerSheet({required this.bedNumber, required this.assigned, required this.onAddCrop, super.key});
  final int bedNumber;
  final List<CropProfile> assigned;
  final void Function(int bed, CropProfile crop) onAddCrop;

  @override
  State<CropPickerSheet> createState() => _CropPickerSheetState();
}

class _CropPickerSheetState extends State<CropPickerSheet> {
  String familyId = vegetableFamilies.first.id;

  @override
  Widget build(BuildContext context) {
    final family = familyById(familyId);
    final vegetables = vegetablesForFamily(familyId);
    return Container(
      color: AppColor.canvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          SheetHeader(title: 'Add crop', subtitle: 'Bed ${widget.bedNumber}'),
          const SizedBox(height: 18),
          const SectionTitle('Family'),
          const SizedBox(height: 10),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final item = vegetableFamilies[index];
                return FamilyCard(family: item, selected: item.id == familyId, onTap: () => setState(() => familyId = item.id));
              },
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: vegetableFamilies.length,
            ),
          ),
          const SizedBox(height: 16),
          CalmInfoCard(title: family.name, subtitle: family.description, icon: CupertinoIcons.square_grid_2x2),
          const SizedBox(height: 18),
          const SectionTitle('Vegetables'),
          const SizedBox(height: 10),
          ...vegetables.map((vegetable) {
            final alreadyAdded = widget.assigned.any((crop) => crop.name == vegetable.name);
            return VegetableOptionCard(
              vegetable: vegetable,
              alreadyAdded: alreadyAdded,
              onTap: () {
                if (alreadyAdded) return;
                widget.onAddCrop(widget.bedNumber, cropFromVegetable(vegetable));
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}

class FamilyCard extends StatelessWidget {
  const FamilyCard({required this.family, required this.selected, required this.onTap, super.key});
  final VegetableFamilyDefinition family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColor.forest : AppColor.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? AppColor.forest : AppColor.line),
          boxShadow: smallShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CropIcon(family.iconPath, size: 34),
            const Spacer(),
            Text(family.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: selected ? CupertinoColors.white : AppColor.ink)),
          ],
        ),
      ),
    );
  }
}

class VegetableOptionCard extends StatelessWidget {
  const VegetableOptionCard({required this.vegetable, required this.alreadyAdded, required this.onTap, super.key});
  final VegetableDefinition vegetable;
  final bool alreadyAdded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: panelDecoration,
        child: Row(
          children: [
            Container(width: 50, height: 50, alignment: Alignment.center, decoration: insetDecoration, child: CropIcon(vegetable.iconPath, size: 38)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vegetable.name, style: TextStyle(color: alreadyAdded ? AppColor.faint : AppColor.ink, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Pest: ${vegetable.commonPests.take(3).join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColor.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                Text('Disease: ${vegetable.commonDiseases.take(3).join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColor.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
            Pill(label: alreadyAdded ? 'ADDED' : 'ADD', color: alreadyAdded ? AppColor.faint : AppColor.forest, background: alreadyAdded ? AppColor.panelAlt : AppColor.forestSoft),
          ],
        ),
      ),
    );
  }
}

void showSprayGuide(BuildContext context, int bedNumber, List<CropProfile> crops, void Function(int bed, String targetId, Set<String> cropNames) onStartSpray) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .86,
          child: SprayGuideSheet(bedNumber: bedNumber, crops: crops, onStartSpray: onStartSpray),
        ),
      ),
    ),
  );
}

class SprayGuideSheet extends StatefulWidget {
  const SprayGuideSheet({required this.bedNumber, required this.crops, required this.onStartSpray, super.key});
  final int bedNumber;
  final List<CropProfile> crops;
  final void Function(int bed, String targetId, Set<String> cropNames) onStartSpray;

  @override
  State<SprayGuideSheet> createState() => _SprayGuideSheetState();
}

class _SprayGuideSheetState extends State<SprayGuideSheet> {
  late Set<String> selectedCrops;
  String selectedTarget = 'pest';

  @override
  void initState() {
    super.initState();
    selectedCrops = widget.crops.map((crop) => crop.name).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final activeCrops = widget.crops.where((crop) => selectedCrops.contains(crop.name)).toList();
    final target = targetById(selectedTarget);
    final suggestions = <String, SpraySuggestion>{};
    for (final crop in activeCrops) {
      for (final suggestion in crop.suggestions.where((item) => item.targetId == selectedTarget)) {
        suggestions['${suggestion.name}-${suggestion.target}'] = suggestion;
      }
    }

    return Container(
      color: AppColor.canvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          SheetHeader(title: 'Spray plan', subtitle: 'Bed ${widget.bedNumber}'),
          const SizedBox(height: 18),
          const SectionTitle('Affected crops'),
          const SizedBox(height: 10),
          SelectableCropWrap(crops: widget.crops, selected: selectedCrops, onChanged: (next) => setState(() => selectedCrops = next)),
          const SizedBox(height: 18),
          const SectionTitle('Target'),
          const SizedBox(height: 10),
          TargetGrid(selectedTarget: selectedTarget, onSelected: (id) => setState(() => selectedTarget = id)),
          const SizedBox(height: 14),
          CalmInfoCard(title: target.title, subtitle: target.description, icon: target.icon),
          const SizedBox(height: 18),
          const SectionTitle('Suggested approach'),
          const SizedBox(height: 10),
          if (suggestions.isEmpty) const EmptyPanel('No matching suggestions for this crop and target.') else ...suggestions.values.map((suggestion) => SuggestionTile(suggestion: suggestion)),
          const SizedBox(height: 18),
          PrimaryAction(
            label: 'Continue to spray log',
            icon: CupertinoIcons.arrow_right,
            onPressed: () {
              Navigator.pop(context);
              widget.onStartSpray(widget.bedNumber, selectedTarget, selectedCrops.isEmpty ? widget.crops.map((crop) => crop.name).toSet() : selectedCrops);
            },
          ),
        ],
      ),
    );
  }
}

class SelectableCropWrap extends StatelessWidget {
  const SelectableCropWrap({required this.crops, required this.selected, required this.onChanged, super.key});
  final List<CropProfile> crops;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SelectablePill(label: 'All crops', selected: selected.length == crops.length, onTap: () => onChanged(crops.map((crop) => crop.name).toSet())),
        ...crops.map((crop) {
          final isSelected = selected.contains(crop.name);
          return CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              final next = {...selected};
              isSelected ? next.remove(crop.name) : next.add(crop.name);
              if (next.isEmpty) next.add(crop.name);
              onChanged(next);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? AppColor.forestSoft : AppColor.panel, borderRadius: BorderRadius.circular(999), border: Border.all(color: isSelected ? AppColor.forest : AppColor.line, width: isSelected ? 1.7 : 1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [CropIcon(crop.iconPath, size: 22), const SizedBox(width: 7), Text(crop.name, style: TextStyle(color: isSelected ? AppColor.forest : AppColor.ink, fontWeight: FontWeight.w900, fontSize: 13))]),
            ),
          );
        }),
      ],
    );
  }
}

class TargetGrid extends StatelessWidget {
  const TargetGrid({required this.selectedTarget, required this.onSelected, super.key});
  final String selectedTarget;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.35,
      children: sprayTargets.map((target) => TargetCard(target: target, selected: selectedTarget == target.id, onTap: () => onSelected(target.id))).toList(),
    );
  }
}

class TargetCard extends StatelessWidget {
  const TargetCard({required this.target, required this.selected, required this.onTap, super.key});
  final SprayTarget target;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: selected ? target.softColor : AppColor.panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? target.color : AppColor.line, width: selected ? 2 : 1)),
        child: Row(
          children: [
            StatusIcon(icon: target.icon, color: target.color, background: target.softColor, size: 36),
            const SizedBox(width: 9),
            Expanded(child: Text(target.shortTitle, style: TextStyle(color: selected ? target.color : AppColor.ink, fontWeight: FontWeight.w900))),
          ],
        ),
      ),
    );
  }
}

class SprayScreen extends StatefulWidget {
  const SprayScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.products, required this.bedCrops, required this.onSave, super.key});
  final Set<int> initialBeds;
  final Set<String> initialCrops;
  final String initialTarget;
  final List<SprayProduct> products;
  final Map<int, List<CropProfile>> bedCrops;
  final void Function({required Set<int> beds, required Set<String> cropNames, required SprayProduct product, required String targetId, required String reason, required String notes, required int withholdingDays}) onSave;

  @override
  State<SprayScreen> createState() => _SprayScreenState();
}

class _SprayScreenState extends State<SprayScreen> {
  late Set<int> beds;
  late Set<String> cropNames;
  late String targetId;
  late SprayProduct product;
  late int withholdingDays;
  final reason = TextEditingController();
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    beds = {...widget.initialBeds};
    targetId = widget.initialTarget;
    final available = cropsForBeds(beds);
    cropNames = widget.initialCrops.isEmpty ? (available.isEmpty ? {'Whole bed'} : available.map((crop) => crop.name).toSet()) : {...widget.initialCrops};
    product = matchingProducts.firstOrNull ?? widget.products.first;
    withholdingDays = product.withholdingDays;
  }

  @override
  void dispose() {
    reason.dispose();
    notes.dispose();
    super.dispose();
  }

  List<CropProfile> cropsForBeds(Set<int> bedNumbers) {
    final byName = <String, CropProfile>{};
    for (final bed in bedNumbers) {
      for (final crop in widget.bedCrops[bed] ?? const <CropProfile>[]) {
        byName[crop.name] = crop;
      }
    }
    return byName.values.toList();
  }

  List<SprayProduct> get matchingProducts => widget.products.where((item) => item.targetIds.contains(targetId)).toList();

  void syncProduct() {
    final matches = matchingProducts;
    if (!matches.any((item) => item.id == product.id)) {
      product = matches.firstOrNull ?? widget.products.first;
      withholdingDays = product.withholdingDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCrops = cropsForBeds(beds);
    return PageShell(
      eyebrow: 'New spray record',
      title: 'Spray log',
      subtitle: 'One screen. Choose beds, crops, target, product, then save.',
      children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('Beds sprayed'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: gardenBeds.map((bed) {
              final selected = beds.contains(bed.number);
              final firstCrop = widget.bedCrops[bed.number]?.firstOrNull;
              return BedSelectChip(number: bed.number, selected: selected, iconPath: firstCrop?.iconPath, count: widget.bedCrops[bed.number]?.length ?? 0, onTap: () {
                final next = {...beds};
                selected ? next.remove(bed.number) : next.add(bed.number);
                final available = cropsForBeds(next);
                setState(() {
                  beds = next;
                  cropNames = available.isEmpty ? {'Whole bed'} : available.map((crop) => crop.name).toSet();
                });
              });
            }).toList()),
          ]),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('Crops affected'),
            const SizedBox(height: 10),
            if (availableCrops.isEmpty)
              const EmptyInline(icon: CupertinoIcons.square_grid_2x2, title: 'Whole bed spray', subtitle: 'No crops are assigned to the selected beds.')
            else
              SelectableCropWrap(crops: availableCrops, selected: cropNames, onChanged: (next) => setState(() => cropNames = next)),
          ]),
        ),
        const SizedBox(height: 14),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Spraying against'),
          const SizedBox(height: 10),
          TargetGrid(selectedTarget: targetId, onSelected: (id) => setState(() { targetId = id; syncProduct(); })),
        ])),
        const SizedBox(height: 14),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Product'),
          const SizedBox(height: 10),
          ...widget.products.map((item) => ProductChoice(product: item, selected: item.id == product.id, suggested: item.targetIds.contains(targetId), onTap: () => setState(() { product = item; withholdingDays = item.withholdingDays; }))),
        ])),
        const SizedBox(height: 14),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Details'),
          const SizedBox(height: 12),
          AppTextField(controller: reason, placeholder: 'Specific issue, e.g. aphids on tomatoes'),
          const SizedBox(height: 10),
          AppTextField(controller: notes, placeholder: 'Notes optional', maxLines: 3),
          const SizedBox(height: 14),
          StepperRow(label: 'Withholding days', value: withholdingDays, onMinus: withholdingDays > 0 ? () => setState(() => withholdingDays--) : null, onPlus: () => setState(() => withholdingDays++)),
        ])),
        const SizedBox(height: 18),
        PrimaryAction(
          label: 'Save spray record',
          icon: CupertinoIcons.check_mark_circled_solid,
          onPressed: () => widget.onSave(beds: beds, cropNames: cropNames, product: product, targetId: targetId, reason: reason.text, notes: notes.text, withholdingDays: withholdingDays),
        ),
      ],
    );
  }
}

class ProductChoice extends StatelessWidget {
  const ProductChoice({required this.product, required this.selected, required this.suggested, required this.onTap, super.key});
  final SprayProduct product;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: selected ? AppColor.forestSoft : AppColor.panelAlt, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? AppColor.forest : AppColor.line, width: selected ? 1.7 : 1)),
        child: Row(
          children: [
            const StatusIcon(icon: CupertinoIcons.drop_fill, color: AppColor.forest, background: AppColor.forestSoft, size: 38),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900)), Text('${product.type} · ${product.withholdingDays} day withholding', style: const TextStyle(color: AppColor.muted, fontSize: 12, fontWeight: FontWeight.w700))])),
            if (suggested) const Pill(label: 'MATCH', color: AppColor.forest, background: AppColor.forestSoft),
            if (selected) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.check_mark_circled_solid, color: AppColor.forest, size: 22)),
          ],
        ),
      ),
    );
  }
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({required this.records, required this.message, required this.onDelete, required this.onClear, super.key});
  final List<SprayRecord> records;
  final String message;
  final ValueChanged<int> onDelete;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: 'Spray history',
      title: 'Records',
      subtitle: 'Saved sprays, target, product, and harvest hold dates.',
      message: message,
      trailing: records.isEmpty ? null : DestructiveTextButton(label: 'Clear all', onPressed: onClear),
      children: [
        if (records.isEmpty) const EmptyPanel('No spray records yet.') else ...records.map((record) => RecordTile(record: record, onDelete: () => onDelete(record.id))),
      ],
    );
  }
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({required this.products, required this.message, required this.onAdd, required this.onDelete, super.key});
  final List<SprayProduct> products;
  final String message;
  final ValueChanged<SprayProduct> onAdd;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: 'Spray products',
      title: 'Products',
      subtitle: 'Manage products and default withholding periods.',
      message: message,
      trailing: CupertinoButton(padding: EdgeInsets.zero, minSize: 36, onPressed: () => showAddProductDialog(context, onAdd), child: const Icon(CupertinoIcons.plus_circle_fill, color: AppColor.forest, size: 30)),
      children: products.map((product) => ProductTile(product: product, onDelete: () => onDelete(product.id))).toList(),
    );
  }
}

void showAddProductDialog(BuildContext context, ValueChanged<SprayProduct> onAdd) {
  final name = TextEditingController();
  final type = TextEditingController(text: 'Custom product');
  final days = TextEditingController(text: '1');
  showCupertinoDialog<void>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: const Text('Add product'),
      content: Column(
        children: [
          const SizedBox(height: 12),
          CupertinoTextField(controller: name, placeholder: 'Name'),
          const SizedBox(height: 8),
          CupertinoTextField(controller: type, placeholder: 'Type'),
          const SizedBox(height: 8),
          CupertinoTextField(controller: days, placeholder: 'Withholding days', keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('Add'),
          onPressed: () {
            if (name.text.trim().isNotEmpty) {
              onAdd(SprayProduct(id: 0, name: name.text.trim(), type: type.text.trim().isEmpty ? 'Custom product' : type.text.trim(), withholdingDays: int.tryParse(days.text) ?? 1, targetIds: const ['pest', 'fungus', 'prevent', 'maintain']));
            }
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

class PageShell extends StatelessWidget {
  const PageShell({required this.eyebrow, required this.title, required this.subtitle, required this.children, this.message = '', this.trailing, super.key});
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(eyebrow.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColor.forest, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.1, color: AppColor.ink)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColor.muted, fontWeight: FontWeight.w700, height: 1.25)),
            ])),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 20),
        if (message.trim().isNotEmpty) ...[MessageBanner(message: message), const SizedBox(height: 14)],
        ...children,
      ],
    );
  }
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -.7)),
          Text(subtitle, style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w800)),
        ])),
        CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColor.faint, size: 30)),
      ],
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({required this.child, this.padding = const EdgeInsets.all(16), super.key});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(padding: padding, decoration: panelDecoration, child: child);
}

class MessageBanner extends StatelessWidget {
  const MessageBanner({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: AppColor.forestSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x33315F3A))),
      child: Row(children: [const Icon(CupertinoIcons.check_mark_circled_solid, color: AppColor.forest, size: 20), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: AppColor.forest, fontWeight: FontWeight.w900)))]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -.2));
}

class CalmInfoCard extends StatelessWidget {
  const CalmInfoCard({required this.title, required this.subtitle, required this.icon, super.key});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Row(
        children: [
          StatusIcon(icon: icon, color: AppColor.forest, background: AppColor.forestSoft),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: AppColor.muted, fontSize: 12, fontWeight: FontWeight.w700, height: 1.25))])),
        ],
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Panel(child: Text(message, style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700)));
}

class EmptyInline extends StatelessWidget {
  const EmptyInline({required this.icon, required this.title, required this.subtitle, super.key});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: insetDecoration,
      child: Row(children: [StatusIcon(icon: icon, color: AppColor.faint, background: AppColor.panel), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700, fontSize: 12))]))]),
    );
  }
}

class StatusIcon extends StatelessWidget {
  const StatusIcon({required this.icon, required this.color, required this.background, this.size = 42, super.key});
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * .36)), child: Icon(icon, color: color, size: size * .48));
}

class Pill extends StatelessWidget {
  const Pill({required this.label, required this.color, required this.background, super.key});
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)), child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .3)));
}

class SelectablePill extends StatelessWidget {
  const SelectablePill({required this.label, required this.selected, required this.onTap, super.key});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(color: selected ? AppColor.forest : AppColor.panel, borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? AppColor.forest : AppColor.line)),
        child: Text(label, style: TextStyle(color: selected ? CupertinoColors.white : AppColor.ink, fontWeight: FontWeight.w900, fontSize: 13)),
      ),
    );
  }
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({required this.label, required this.icon, required this.onPressed, super.key});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      color: AppColor.forest,
      disabledColor: AppColor.line,
      borderRadius: BorderRadius.circular(18),
      onPressed: onPressed,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: CupertinoColors.white, size: 18), const SizedBox(width: 8), Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w900)))]),
    );
  }
}

class SecondaryAction extends StatelessWidget {
  const SecondaryAction({required this.label, required this.icon, required this.onPressed, super.key});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      color: disabled ? AppColor.panelAlt : AppColor.forestSoft,
      borderRadius: BorderRadius.circular(18),
      onPressed: onPressed,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: disabled ? AppColor.faint : AppColor.forest, size: 18), const SizedBox(width: 7), Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: disabled ? AppColor.faint : AppColor.ink, fontWeight: FontWeight.w900)))]),
    );
  }
}

class DestructiveAction extends StatelessWidget {
  const DestructiveAction({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      color: AppColor.redSoft,
      disabledColor: AppColor.panelAlt,
      borderRadius: BorderRadius.circular(18),
      onPressed: onPressed,
      child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: onPressed == null ? AppColor.faint : AppColor.red, fontWeight: FontWeight.w900)),
    );
  }
}

class DestructiveTextButton extends StatelessWidget {
  const DestructiveTextButton({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, minSize: 32, onPressed: onPressed, child: Text(label, style: const TextStyle(color: AppColor.red, fontWeight: FontWeight.w900)));
}

class BedSelectChip extends StatelessWidget {
  const BedSelectChip({required this.number, required this.selected, required this.onTap, this.iconPath, this.count = 0, super.key});
  final int number;
  final bool selected;
  final VoidCallback onTap;
  final String? iconPath;
  final int count;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: selected ? AppColor.forest : AppColor.panelAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppColor.forest : AppColor.line)),
            child: iconPath == null ? Text('$number', style: TextStyle(color: selected ? CupertinoColors.white : AppColor.ink, fontWeight: FontWeight.w900)) : CropIcon(iconPath!, size: 25),
          ),
          if (count > 1) Positioned(right: -5, top: -5, child: CountDot(count: count)),
        ],
      ),
    );
  }
}

class CountDot extends StatelessWidget {
  const CountDot({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => Container(minWidth: 20, height: 20, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(color: AppColor.forest, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColor.panel, width: 2)), child: Text('+$count', style: const TextStyle(color: CupertinoColors.white, fontSize: 9, fontWeight: FontWeight.w900)));
}

class RecordTile extends StatelessWidget {
  const RecordTile({required this.record, this.onDelete, super.key});
  final SprayRecord record;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final target = targetById(record.targetId);
    final hold = record.safeDate.isAfter(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: panelDecoration,
      child: Row(
        children: [
          StatusIcon(icon: target.icon, color: target.color, background: target.softColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bed ${record.bedNumbers.join(', ')} · ${target.shortTitle}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 3),
              Text(record.cropNames.isEmpty ? 'Whole bed' : record.cropNames.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColor.ink, fontWeight: FontWeight.w700, fontSize: 13)),
              Text('${record.product} · sprayed ${fullDate(record.sprayedAt)} · safe ${shortDate(record.safeDate)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColor.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
          Pill(label: hold ? 'HOLD' : 'CLEAR', color: hold ? AppColor.amber : AppColor.forest, background: hold ? AppColor.amberSoft : AppColor.forestSoft),
          if (onDelete != null) CupertinoButton(padding: EdgeInsets.zero, minSize: 34, onPressed: onDelete, child: const Icon(CupertinoIcons.trash, color: AppColor.red, size: 20)),
        ],
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, required this.onDelete, super.key});
  final SprayProduct product;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: panelDecoration,
      child: Row(
        children: [
          const StatusIcon(icon: CupertinoIcons.cube_box_fill, color: AppColor.forest, background: AppColor.forestSoft),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text(product.type, style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700)), Text('${product.withholdingDays} day withholding · ${product.targetIds.map((id) => targetById(id).shortTitle).join(', ')}', style: const TextStyle(color: AppColor.muted, fontSize: 12, fontWeight: FontWeight.w700))])),
          CupertinoButton(padding: EdgeInsets.zero, minSize: 34, onPressed: onDelete, child: const Icon(CupertinoIcons.trash, color: AppColor.red, size: 20)),
        ],
      ),
    );
  }
}

class SuggestionTile extends StatelessWidget {
  const SuggestionTile({required this.suggestion, super.key});
  final SpraySuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final target = targetById(suggestion.targetId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: panelDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusIcon(icon: target.icon, color: target.color, background: target.softColor),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(suggestion.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text('Target: ${suggestion.target}', style: const TextStyle(color: AppColor.ink, fontWeight: FontWeight.w800, fontSize: 13)), const SizedBox(height: 3), Text(suggestion.whenToUse, style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700, fontSize: 12, height: 1.25))])),
        ],
      ),
    );
  }
}

class StepperRow extends StatelessWidget {
  const StepperRow({required this.label, required this.value, required this.onMinus, required this.onPlus, super.key});
  final String label;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: insetDecoration,
      child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))), RoundIconButton(icon: CupertinoIcons.minus, onPressed: onMinus), Padding(padding: const EdgeInsets.symmetric(horizontal: 13), child: Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))), RoundIconButton(icon: CupertinoIcons.plus, onPressed: onPlus)]),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({required this.icon, required this.onPressed, super.key});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, minSize: 34, color: onPressed == null ? AppColor.line : AppColor.panel, borderRadius: BorderRadius.circular(99), onPressed: onPressed, child: Icon(icon, color: onPressed == null ? AppColor.faint : AppColor.forest, size: 17));
}

class AppTextField extends StatelessWidget {
  const AppTextField({required this.controller, required this.placeholder, this.maxLines = 1, super.key});
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColor.panelAlt, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColor.line)),
    );
  }
}

class MapOutline extends StatelessWidget {
  const MapOutline({required this.rect, required this.size, super.key});
  final Rect rect;
  final Size size;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(rect: scaleRect(rect, size), child: IgnorePointer(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColor.soil, width: 1.4)))));
}

class MapPath extends StatelessWidget {
  const MapPath({required this.rect, required this.size, super.key});
  final Rect rect;
  final Size size;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(rect: scaleRect(rect, size), child: IgnorePointer(child: Container(decoration: BoxDecoration(color: AppColor.path, borderRadius: BorderRadius.circular(6)))));
}

class SoftGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE9E4D8)..strokeWidth = .55;
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
