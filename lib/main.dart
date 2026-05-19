import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'crop_library.dart';

void main() => runApp(const FieldbookApp());

class FieldbookApp extends StatelessWidget {
  const FieldbookApp({super.key});

  @override
  Widget build(BuildContext context) => const CupertinoApp(
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

class C {
  static const canvas = Color(0xFFF8F6F0);
  static const card = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF3EFE6);
  static const ink = Color(0xFF172018);
  static const muted = Color(0xFF667064);
  static const line = Color(0xFFE1DBCF);
  static const forest = Color(0xFF173F2A);
  static const forestDark = Color(0xFF0F3B26);
  static const forestSoft = Color(0xFFE8F0EA);
  static const soil = Color(0xFF735235);
  static const amber = Color(0xFFC77618);
  static const amberSoft = Color(0xFFFFEFD7);
  static const red = Color(0xFFB94A42);
  static const redSoft = Color(0xFFF8E4E1);
  static const blue = Color(0xFF2B6777);
  static const blueSoft = Color(0xFFE1F0F3);
  static const purple = Color(0xFF6E5AAE);
  static const purpleSoft = Color(0xFFECE8F7);
}

final softShadow = [BoxShadow(color: const Color(0xFF000000).withValues(alpha: .07), blurRadius: 22, offset: const Offset(0, 9))];
final navShadow = [BoxShadow(color: const Color(0xFF000000).withValues(alpha: .10), blurRadius: 28, offset: const Offset(0, 10))];

BoxDecoration cardDecoration({Color color = C.card, double radius = 22, bool border = true}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border ? Border.all(color: C.line) : null,
      boxShadow: softShadow,
    );

double clampDouble(double value, double min, double max) => value.clamp(min, max).toDouble();

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String monthName(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
String shortDate(DateTime d) => '${d.day} ${monthName(d.month)}';
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
String daysLabel(int days) => '$days ${days == 1 ? 'day' : 'days'}';

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
  const SprayTarget(this.id, this.title, this.short, this.description, this.color, this.softColor, this.icon);
  final String id;
  final String title;
  final String short;
  final String description;
  final Color color;
  final Color softColor;
  final IconData icon;
}

const sprayTargets = [
  SprayTarget('pest', 'Pest pressure', 'Pest', 'Visible insects, chewing damage, webbing, sticky residue or larvae.', C.red, C.redSoft, CupertinoIcons.exclamationmark_triangle),
  SprayTarget('fungus', 'Fungal pressure', 'Fungus', 'Mildew, rust, leaf spots, blight risk, or humid disease pressure.', C.blue, C.blueSoft, CupertinoIcons.drop),
  SprayTarget('prevent', 'Preventative', 'Prevent', 'Use before pressure builds, especially before wet or humid weather.', C.forest, C.forestSoft, CupertinoIcons.shield),
  SprayTarget('maintain', 'Maintenance', 'Support', 'Plant support, stress recovery, pruning, airflow, and general crop care.', C.purple, C.purpleSoft, CupertinoIcons.leaf_arrow_circlepath),
];

SprayTarget targetById(String id) => sprayTargets.firstWhere((t) => t.id == id, orElse: () => sprayTargets.first);
VegetableDefinition vegetableById(String id) => vegetableLibrary.firstWhere((v) => v.id == id, orElse: () => vegetableLibrary.first);
VegetableFamilyDefinition familyByCrop(VegetableDefinition crop) => familyById(crop.familyId);

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

class FeedProductPreset {
  const FeedProductPreset({required this.name, required this.method, required this.intervalDays, required this.note, required this.color, required this.background});
  final String name;
  final String method;
  final int intervalDays;
  final String note;
  final Color color;
  final Color background;
}

const feedProductPresets = [
  FeedProductPreset(name: 'Seasol / seaweed tonic', method: 'Tonic', intervalDays: 14, note: 'Good after cold, wind, transplanting, pruning or general stress. Not a complete fertiliser.', color: C.purple, background: C.purpleSoft),
  FeedProductPreset(name: 'Yates Thrive Vegie & Herb', method: 'Liquid feed', intervalDays: 14, note: 'Useful while leafy crops are actively growing. Use lighter in cold weather.', color: C.forest, background: C.forestSoft),
  FeedProductPreset(name: 'Tomato & vegie liquid feed', method: 'Fruit feed', intervalDays: 10, note: 'Best for warm-season fruiting crops when they are flowering or cropping.', color: C.amber, background: C.amberSoft),
  FeedProductPreset(name: 'Compost / slow release', method: 'Soil feed', intervalDays: 42, note: 'Good baseline feeding. Less weather-sensitive than foliar sprays.', color: C.soil, background: C.soft),
];

class FeedRecord {
  const FeedRecord({required this.id, required this.beds, required this.product, required this.method, required this.note, required this.date});
  final int id;
  final List<int> beds;
  final String product;
  final String method;
  final String note;
  final DateTime date;
}

class GardenWeatherSnapshot {
  const GardenWeatherSnapshot({required this.rainLikelyTonight, required this.humidityPercent, required this.windKph, required this.temperatureC, required this.bestSprayWindow, required this.source});
  final bool rainLikelyTonight;
  final int humidityPercent;
  final int windKph;
  final int temperatureC;
  final String bestSprayWindow;
  final String source;
}

class GardenTodayItem {
  const GardenTodayItem({required this.title, required this.detail, required this.color, required this.background});
  final String title;
  final String detail;
  final Color color;
  final Color background;
}

class GardenTodayReport {
  const GardenTodayReport({required this.items, required this.source});
  final List<GardenTodayItem> items;
  final String source;
}

class SprayAdvisorReport {
  const SprayAdvisorReport({required this.score, required this.status, required this.warning, required this.bestWindow, required this.pressure, required this.productSuggestion, required this.harvestWarning, required this.bedsToCheck, required this.color, required this.background});
  final int score;
  final String status;
  final String warning;
  final String bestWindow;
  final String pressure;
  final String productSuggestion;
  final String harvestWarning;
  final String bedsToCheck;
  final Color color;
  final Color background;
}

class FeedingAdvisorReport {
  const FeedingAdvisorReport({required this.score, required this.status, required this.feedWindow, required this.productSuggestion, required this.dueBeds, required this.recentFeed, required this.weatherNote, required this.color, required this.background});
  final int score;
  final String status;
  final String feedWindow;
  final String productSuggestion;
  final String dueBeds;
  final String recentFeed;
  final String weatherNote;
  final Color color;
  final Color background;
}

String southernSeason(DateTime date) {
  final month = date.month;
  if (month == 12 || month <= 2) return 'summer';
  if (month >= 3 && month <= 5) return 'autumn';
  if (month >= 6 && month <= 8) return 'winter';
  return 'spring';
}

bool isWarmSeasonCrop(VegetableDefinition crop) => const {
      'tomato', 'capsicum', 'chilli', 'eggplant', 'potato', 'cucumber', 'zucchini', 'pumpkin', 'melon', 'sweetcorn', 'okra', 'kumara',
    }.contains(crop.id);

bool isCropInMarlboroughSeason(VegetableDefinition crop, DateTime now) {
  final season = southernSeason(now);
  if (isWarmSeasonCrop(crop)) return season == 'spring' || season == 'summer';
  if (crop.familyId == 'brassicas' || crop.familyId == 'leafy_greens' || crop.familyId == 'root_vegetables' || crop.familyId == 'alliums' || crop.familyId == 'apiaceae') return season == 'autumn' || season == 'winter' || season == 'spring';
  if (crop.familyId == 'legumes') return season == 'autumn' || season == 'spring' || crop.id == 'broad_beans';
  return true;
}

bool hasDiseasePressureRisk(VegetableDefinition crop) => crop.commonDiseases.any((disease) {
      final d = disease.toLowerCase();
      return d.contains('mildew') || d.contains('blight') || d.contains('rust') || d.contains('rot') || d.contains('spot');
    });

String pluralCropName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('cucumber')) return 'cucumbers';
  if (lower.endsWith('s')) return lower;
  return '${lower}s';
}

String seasonalDiseaseTarget(List<VegetableDefinition> crops, DateTime now) {
  final inSeason = crops.where((crop) => isCropInMarlboroughSeason(crop, now)).where(hasDiseasePressureRisk).toList();
  final families = inSeason.map((crop) => crop.familyId).toSet();
  if (families.contains('brassicas') && families.contains('leafy_greens')) return 'brassicas and leafy greens';
  if (families.contains('brassicas')) return 'brassicas';
  if (families.contains('leafy_greens')) return 'leafy greens';
  if (families.contains('alliums')) return 'alliums';
  if (families.contains('root_vegetables')) return 'root crops';
  if (families.contains('legumes')) return 'peas and beans';
  final first = inSeason.firstOrNull;
  if (first != null) return pluralCropName(first.name);
  return 'current-season beds';
}

String seasonalLine(DateTime now) {
  final season = southernSeason(now);
  if (season == 'autumn') return 'Autumn focus: brassicas, leafy greens, peas, roots and alliums';
  if (season == 'winter') return 'Winter focus: brassicas, leafy greens, broad beans, peas and alliums';
  if (season == 'spring') return 'Spring transition: warm crops coming, protect new growth';
  return 'Summer focus: warm crops, regular checks, heat-safe spray windows';
}

List<SprayProduct> defaultProducts() => const [
      SprayProduct(id: 1, name: 'Neem Oil', type: 'Pest control', days: 3, targets: ['pest', 'prevent']),
      SprayProduct(id: 2, name: 'Copper Hydroxide', type: 'Fungicide', days: 7, targets: ['fungus', 'prevent']),
      SprayProduct(id: 3, name: 'Seaweed Tonic', type: 'Plant tonic', days: 1, targets: ['maintain', 'prevent']),
      SprayProduct(id: 4, name: 'Pyrethrin', type: 'Insecticide', days: 3, targets: ['pest']),
    ].toList();

GardenTodayReport buildGardenTodayReport({required Map<int, List<VegetableDefinition>> bedCrops, required List<SprayRecord> activeRecords, required GardenWeatherSnapshot weather, required DateTime now}) {
  final crops = bedCrops.values.expand((items) => items).toList();
  final target = seasonalDiseaseTarget(crops, now);
  final firstHold = activeRecords.firstOrNull;
  final harvestLine = firstHold == null ? 'No active harvest holds' : 'Bed ${firstHold.beds.join('/')} safe in ${daysLabel(dayOnly(firstHold.safeDate).difference(dayOnly(now)).inDays.clamp(0, 999).toInt())}';
  return GardenTodayReport(
    source: weather.source,
    items: [
      GardenTodayItem(title: weather.rainLikelyTonight ? 'Today: do not spray — rain likely tonight' : 'Today: spray weather looks usable', detail: 'Rain, wind and humidity are read from the Marlborough forecast.', color: weather.rainLikelyTonight ? C.red : C.forest, background: weather.rainLikelyTonight ? C.redSoft : C.forestSoft),
      GardenTodayItem(title: weather.humidityPercent >= 80 ? 'Fungus risk: high for $target' : 'Fungus risk: moderate for $target', detail: '${weather.humidityPercent}% humidity. Warm-season crops are ignored out of season unless planted.', color: C.blue, background: C.blueSoft),
      GardenTodayItem(title: 'Best spray window: ${weather.bestSprayWindow}', detail: 'Chosen to avoid rain, wind and heat stress.', color: C.forest, background: C.forestSoft),
      GardenTodayItem(title: seasonalLine(now), detail: 'Season is used to filter bad recommendations like off-season cucumbers.', color: C.purple, background: C.purpleSoft),
      GardenTodayItem(title: harvestLine, detail: 'Calculated from spray records and withholding days.', color: C.amber, background: C.amberSoft),
    ],
  );
}

SprayAdvisorReport buildSprayAdvisorReport({required Map<int, List<VegetableDefinition>> bedCrops, required List<SprayRecord> activeRecords, required List<SprayProduct> products, required GardenWeatherSnapshot weather, required DateTime now}) {
  var score = 100;
  final reasons = <String>[];
  if (weather.rainLikelyTonight) { score -= 35; reasons.add('rain likely tonight'); }
  if (weather.windKph >= 24) { score -= 30; reasons.add('wind too high'); } else if (weather.windKph >= 16) { score -= 14; reasons.add('wind borderline'); }
  if (weather.humidityPercent >= 88) { score -= 14; reasons.add('very high humidity'); } else if (weather.humidityPercent >= 80) { score -= 8; reasons.add('high humidity'); }
  if (activeRecords.length >= 4) { score -= 8; reasons.add('several beds on harvest hold'); }
  score = score.clamp(0, 100).toInt();
  final blocked = score < 55 || weather.rainLikelyTonight || weather.windKph >= 24;
  final crops = bedCrops.values.expand((items) => items).toList();
  final target = seasonalDiseaseTarget(crops, now);
  final fungal = products.where((product) => product.targets.contains('fungus')).firstOrNull;
  final pest = products.where((product) => product.targets.contains('pest')).firstOrNull;
  final sortedHolds = [...activeRecords]..sort((a, b) => a.safeDate.compareTo(b.safeDate));
  final checkBeds = <int>{};
  for (final entry in bedCrops.entries) {
    if (entry.value.any((crop) => isCropInMarlboroughSeason(crop, now) && hasDiseasePressureRisk(crop))) checkBeds.add(entry.key);
  }
  final color = blocked ? C.red : score < 75 ? C.amber : C.forest;
  final background = blocked ? C.redSoft : score < 75 ? C.amberSoft : C.forestSoft;
  return SprayAdvisorReport(
    score: score,
    status: blocked ? 'Do not spray' : score < 75 ? 'Spray only if needed' : 'Good spray window',
    warning: blocked ? 'Do not spray: ${reasons.isEmpty ? 'conditions are not suitable' : reasons.join(', ')}.' : 'No hard weather block. Inspect plants first and only spray if pressure is visible.',
    bestWindow: 'Best spray window: ${weather.bestSprayWindow}',
    pressure: weather.humidityPercent >= 80 ? 'Disease pressure: fungal risk in $target.' : 'Pest/disease pressure: inspect current planted beds before choosing a product.',
    productSuggestion: blocked ? 'Product suggestion: none today — delay until ${weather.bestSprayWindow}.' : weather.humidityPercent >= 80 && fungal != null ? 'Product suggestion: ${fungal.name} only if disease signs are present.' : pest != null ? 'Product suggestion: ${pest.name} only if insect pressure is visible.' : 'Product suggestion: no matching product configured.',
    harvestWarning: sortedHolds.isEmpty ? 'Harvest holds: no active withholding periods.' : 'Harvest holds: ${sortedHolds.take(3).map((record) => 'Bed ${record.beds.join('/')} safe in ${daysLabel(dayOnly(record.safeDate).difference(dayOnly(now)).inDays.clamp(0, 999).toInt())}').join(' · ')}',
    bedsToCheck: checkBeds.isEmpty ? 'Beds to check: inspect any bed with visible pest or disease pressure.' : 'Beds to check: ${checkBeds.take(5).map((bed) => 'Bed $bed').join(', ')}.',
    color: color,
    background: background,
  );
}

FeedProductPreset feedingPresetForSeason(DateTime now, GardenWeatherSnapshot weather) {
  final season = southernSeason(now);
  if (season == 'autumn' || season == 'winter') return feedProductPresets[0];
  if (weather.humidityPercent >= 85 || weather.rainLikelyTonight) return feedProductPresets[3];
  return feedProductPresets[1];
}

FeedingAdvisorReport buildFeedingAdvisorReport({required Map<int, List<VegetableDefinition>> bedCrops, required List<FeedRecord> feedRecords, required GardenWeatherSnapshot weather, required DateTime now}) {
  final season = southernSeason(now);
  final preset = feedingPresetForSeason(now, weather);
  var score = 100;
  final reasons = <String>[];
  if (weather.rainLikelyTonight) { score -= 25; reasons.add('rain likely tonight'); }
  if (weather.windKph >= 24) { score -= 22; reasons.add('wind too high for foliar feeding'); }
  if (weather.humidityPercent >= 90) { score -= 12; reasons.add('very high humidity'); }
  if (season == 'winter') { score -= 14; reasons.add('slow winter growth'); }
  score = score.clamp(0, 100).toInt();
  final color = score < 55 ? C.red : score < 75 ? C.amber : C.forest;
  final background = score < 55 ? C.redSoft : score < 75 ? C.amberSoft : C.forestSoft;
  final lastFeedByBed = <int, FeedRecord>{};
  for (final record in feedRecords) {
    for (final bed in record.beds) {
      final current = lastFeedByBed[bed];
      if (current == null || record.date.isAfter(current.date)) lastFeedByBed[bed] = record;
    }
  }
  final due = <int>[];
  for (final bed in bedCrops.keys) {
    final last = lastFeedByBed[bed];
    if (last == null || dayOnly(now).difference(dayOnly(last.date)).inDays >= preset.intervalDays) due.add(bed);
  }
  due.sort();
  final sortedFeeds = [...feedRecords]..sort((a, b) => b.date.compareTo(a.date));
  return FeedingAdvisorReport(
    score: score,
    status: score < 55 ? 'Delay feeding' : score < 75 ? 'Feed lightly if needed' : 'Good feed window',
    feedWindow: weather.rainLikelyTonight ? 'Best feed window: after rain clears, preferably a calm morning.' : weather.windKph >= 24 ? 'Best feed window: next calm morning.' : season == 'winter' ? 'Best feed window: mild morning, light rate only.' : 'Best feed window: morning or late afternoon, avoid heat and wind.',
    productSuggestion: 'Suggestion: ${preset.name} · ${preset.note}',
    dueBeds: due.isEmpty ? 'Due beds: no planted beds are clearly due.' : 'Due beds: ${due.take(6).map((bed) => 'Bed $bed').join(', ')}.',
    recentFeed: sortedFeeds.isEmpty ? 'Recent feed: none logged yet.' : 'Recent feed: ${sortedFeeds.first.product} on Bed ${sortedFeeds.first.beds.join('/')} · ${daysLabel(dayOnly(now).difference(dayOnly(sortedFeeds.first.date)).inDays)} ago.',
    weatherNote: reasons.isEmpty ? 'Weather note: feeding conditions are acceptable. Water soil first if dry.' : 'Weather note: ${reasons.join(', ')}.',
    color: color,
    background: background,
  );
}

class BunningsSprayProduct {
  const BunningsSprayProduct({required this.name, required this.brand, required this.target, required this.type, required this.note, required this.url, required this.fallbackUrl, required this.color, required this.background});
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
  BunningsSprayProduct(name: 'Yates 500ml Liquid Copper Concentrate', brand: 'Yates', target: 'Fungus', type: 'Copper fungicide', note: 'Direct Bunnings product card for fungal pressure. Always check edible-crop label directions and withholding periods.', url: 'https://www.bunnings.co.nz/yates-liquid-copper-500ml_p0253771', fallbackUrl: bunningsFungicideUrl, color: C.blue, background: C.blueSoft),
  BunningsSprayProduct(name: 'Yates 200g Copper Oxychloride Fungicide', brand: 'Yates', target: 'Fungus', type: 'Copper fungicide', note: 'Copper oxychloride reference for fungal pressure. Use only when the product label supports your crop.', url: 'https://www.bunnings.co.nz/yates-200g-copper-oxychloride-fungicide_p0595263', fallbackUrl: bunningsFungicideUrl, color: C.blue, background: C.blueSoft),
  BunningsSprayProduct(name: "Yates 200g Nature's Way Fungus Spray", brand: "Yates Nature's Way", target: 'Fungus', type: 'Copper + sulphur', note: 'Copper and sulphur fungus product card. Check temperature limits and crop label before spraying.', url: 'https://www.bunnings.co.nz/yates-200g-natures-way-fungus-spray_p0571701', fallbackUrl: bunningsFungicideUrl, color: C.blue, background: C.blueSoft),
  BunningsSprayProduct(name: 'OCP Eco-Fungicide RTU 750ml', brand: 'OCP', target: 'Fungus', type: 'RTU fungicide', note: 'Ready-to-use fungus option. Good card for small jobs and spot checks when humidity risk is high.', url: 'https://www.bunnings.co.nz/ocp-eco-fungicide-rtu-750ml_p0338689', fallbackUrl: bunningsFungicideUrl, color: C.blue, background: C.blueSoft),
  BunningsSprayProduct(name: 'Yates 750ml Mavrik Insect Spray', brand: 'Yates', target: 'Pest', type: 'RTU insecticide', note: 'Insect-pressure product card. Only consider when pests are visible and avoid spraying when bees are active.', url: 'https://www.bunnings.co.nz/yates-750ml-mavrik-insect-spray_p0307179', fallbackUrl: bunningsInsecticideUrl, color: C.red, background: C.redSoft),
  BunningsSprayProduct(name: 'Yates 200ml Success Ultra Insect Control', brand: 'Yates', target: 'Pest', type: 'Insect control', note: 'Useful pest-control card for caterpillar/thrips decisions when the label supports your crop.', url: 'https://www.bunnings.co.nz/yates-200ml-success-ultra-insect-control_p0281582', fallbackUrl: bunningsInsecticideUrl, color: C.red, background: C.redSoft),
  BunningsSprayProduct(name: "Yates 200ml Nature's Way Vegie Insect Concentrate", brand: "Yates Nature's Way", target: 'Pest', type: 'Vegie insect concentrate', note: 'Vegetable-focused insect product card. Best linked to visible pest pressure, not routine spraying.', url: 'https://www.bunnings.co.nz/yates-200ml-nature-s-way-vegie-insect-concentrate_p0296370', fallbackUrl: bunningsInsecticideUrl, color: C.red, background: C.redSoft),
  BunningsSprayProduct(name: 'OCP Eco-Oil RTU 750ml', brand: 'OCP', target: 'Pest / preventative', type: 'Oil spray', note: 'Oil spray card for soft-bodied insects. Avoid heat stress and follow label restrictions.', url: 'https://www.bunnings.co.nz/ocp-750ml-eco-oil-rtu_p0338691', fallbackUrl: bunningsInsecticideUrl, color: C.forest, background: C.forestSoft),
  BunningsSprayProduct(name: 'Yates Sprayfix 200ml', brand: 'Yates', target: 'Spray support', type: 'Wetting agent', note: 'Spray helper, not a pesticide. Only use when compatible with the product label.', url: 'https://www.bunnings.co.nz/yates-sprayfix-200ml_p0116798', fallbackUrl: bunningsInsecticideUrl, color: C.purple, background: C.purpleSoft),
  BunningsSprayProduct(name: 'Roundup 1L Advance Liquid Concentrate', brand: 'Roundup', target: 'Weed control', type: 'Herbicide', note: 'Keep separate from edible-crop spray decisions and follow all label safety directions.', url: 'https://www.bunnings.co.nz/roundup-1l-advance-liquid-concentrate-weedkiller_p0725147', fallbackUrl: bunningsHerbicideUrl, color: C.amber, background: C.amberSoft),
  BunningsSprayProduct(name: 'Seasol 1L Complete Garden Health Treatment', brand: 'Seasol', target: 'Maintenance', type: 'Seaweed tonic', note: 'Seaweed tonic for stress recovery and general plant support. Not an insecticide or fungicide.', url: 'https://www.bunnings.co.nz/seasol-1l-complete-garden-health-treatment_p3012812', fallbackUrl: bunningsFertiliserUrl, color: C.purple, background: C.purpleSoft),
  BunningsSprayProduct(name: 'Yates 1L Thrive Natural Vegie & Herb', brand: 'Yates Thrive', target: 'Maintenance', type: 'Liquid fertiliser', note: 'Liquid feed card for garden support. Not a pesticide; keep separate from pest/fungus spray logs.', url: 'https://www.bunnings.co.nz/yates-1l-thrive-natural-vegie-and-herb-liquid-fertiliser_p2962094', fallbackUrl: bunningsFertiliserUrl, color: C.purple, background: C.purpleSoft),
];

Future<void> openBunningsUrl(String url, String fallbackUrl) async {
  final uri = Uri.parse(url);
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
}

class FieldbookHome extends StatefulWidget {
  const FieldbookHome({super.key});

  @override
  State<FieldbookHome> createState() => _FieldbookHomeState();
}

class _FieldbookHomeState extends State<FieldbookHome> {
  int tab = 0;
  int selectedBed = 4;
  int nextRecordId = 1;
  int nextFeedId = 1;
  int nextProductId = 5;
  String message = '';
  Set<int> sprayBeds = {4};
  Set<String> sprayCrops = {'Tomato', 'Chilli'};
  String sprayTarget = 'pest';

  final Map<int, List<VegetableDefinition>> bedCrops = {};
  List<SprayRecord> sprayRecords = [];
  List<FeedRecord> feedRecords = [];
  late List<SprayProduct> products;
  GardenWeatherSnapshot weather = const GardenWeatherSnapshot(rainLikelyTonight: true, humidityPercent: 86, windKph: 18, temperatureC: 14, bestSprayWindow: 'tomorrow morning', source: 'Using offline Marlborough fallback until live weather loads');

  @override
  void initState() {
    super.initState();
    products = defaultProducts();
    resetToDemoData(silent: true);
    fetchLiveWeather();
  }

  DateTime ago(int days) {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day).subtract(Duration(days: days));
  }

  void seedDemoData() {
    bedCrops.addAll({
      1: [vegetableById('peas'), vegetableById('broad_beans')],
      2: [vegetableById('lettuce'), vegetableById('rocket')],
      3: [vegetableById('capsicum'), vegetableById('eggplant')],
      4: [vegetableById('tomato'), vegetableById('chilli')],
      5: [vegetableById('carrot'), vegetableById('beetroot'), vegetableById('radish')],
      6: [vegetableById('onion'), vegetableById('garlic'), vegetableById('leek')],
      7: [vegetableById('kale'), vegetableById('broccoli')],
      9: [vegetableById('cucumber'), vegetableById('zucchini'), vegetableById('pumpkin')],
    });
    sprayRecords = [
      SprayRecord(id: nextRecordId++, beds: const [4], crops: const ['Tomato', 'Chilli'], targetId: 'pest', product: 'Neem Oil', reason: 'Aphids on tomato tips', notes: '', date: ago(1), days: 3),
      SprayRecord(id: nextRecordId++, beds: const [9, 10], crops: const ['Cucumber'], targetId: 'fungus', product: 'Copper Hydroxide', reason: 'Powdery mildew risk', notes: '', date: ago(1), days: 7),
      SprayRecord(id: nextRecordId++, beds: const [2], crops: const ['Lettuce', 'Rocket'], targetId: 'prevent', product: 'Neem Oil', reason: 'Preventative spray', notes: '', date: ago(4), days: 3),
    ];
    feedRecords = [
      FeedRecord(id: nextFeedId++, beds: const [2, 7], product: 'Seasol / seaweed tonic', method: 'Tonic', note: 'Cool weather support', date: ago(10)),
      FeedRecord(id: nextFeedId++, beds: const [5, 6], product: 'Compost / slow release', method: 'Soil feed', note: 'Root and allium beds', date: ago(35)),
    ];
  }

  Future<void> fetchLiveWeather() async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '-41.5134',
        'longitude': '173.9612',
        'hourly': 'precipitation_probability,relative_humidity_2m,wind_speed_10m,temperature_2m',
        'forecast_days': '2',
        'timezone': 'Pacific/Auckland',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly = data['hourly'] as Map<String, dynamic>;
      final rain = (hourly['precipitation_probability'] as List).whereType<num>().map((v) => v.toInt()).toList();
      final humidity = (hourly['relative_humidity_2m'] as List).whereType<num>().map((v) => v.toInt()).toList();
      final wind = (hourly['wind_speed_10m'] as List).whereType<num>().map((v) => v.round()).toList();
      final temp = (hourly['temperature_2m'] as List).whereType<num>().map((v) => v.round()).toList();
      int maxOf(List<int> values, int count) => values.take(count).fold(0, (a, b) => a > b ? a : b);
      int avgOf(List<int> values, int count) {
        final sample = values.take(count).toList();
        if (sample.isEmpty) return 0;
        return (sample.fold<int>(0, (a, b) => a + b) / sample.length).round();
      }
      final rainTonight = maxOf(rain, 18) >= 40;
      final maxHumidity = maxOf(humidity, 24);
      final maxWind = maxOf(wind, 12);
      final avgTemp = avgOf(temp, 12);
      final bestWindow = rainTonight || maxWind > 22 ? 'tomorrow morning' : 'this evening';
      if (!mounted) return;
      setState(() {
        weather = GardenWeatherSnapshot(rainLikelyTonight: rainTonight, humidityPercent: maxHumidity, windKph: maxWind, temperatureC: avgTemp, bestSprayWindow: bestWindow, source: 'Live weather: Marlborough region · Open-Meteo forecast');
      });
    } catch (_) {
      // Keep offline fallback.
    }
  }

  int get holdBeds => gardenBeds.where((b) => bedOnHold(b.number)).length;
  int get clearBeds => gardenBeds.length - holdBeds;
  int get plantedBeds => bedCrops.values.where((v) => v.isNotEmpty).length;
  int get cropPlacements => bedCrops.values.fold(0, (sum, list) => sum + list.length);
  List<SprayRecord> get activeSprays {
    final active = sprayRecords.where((r) => r.safeDate.isAfter(DateTime.now())).toList();
    active.sort((a, b) => a.safeDate.compareTo(b.safeDate));
    return active;
  }

  bool bedOnHold(int bed) => sprayRecords.any((r) => r.beds.contains(bed) && r.safeDate.isAfter(DateTime.now()));
  List<VegetableDefinition> cropsForBeds(Set<int> beds) => beds.expand((bed) => bedCrops[bed] ?? const <VegetableDefinition>[]).toSet().toList();
  Set<String> defaultCropNames(Set<int> beds) {
    final names = cropsForBeds(beds).map((crop) => crop.name).toSet();
    return names.isEmpty ? {'Whole bed'} : names;
  }

  void resetToDemoData({bool silent = false}) {
    void run() {
      bedCrops.clear();
      sprayRecords.clear();
      feedRecords.clear();
      nextRecordId = 1;
      nextFeedId = 1;
      nextProductId = 5;
      selectedBed = 4;
      sprayBeds = {4};
      sprayCrops = {'Tomato', 'Chilli'};
      sprayTarget = 'pest';
      products = defaultProducts();
      seedDemoData();
      message = 'Test data reset to demo garden';
      tab = 0;
    }
    if (silent) {
      run();
    } else {
      setState(run);
    }
  }

  void clearAllTestingData() => setState(() {
        bedCrops.clear();
        sprayRecords.clear();
        feedRecords.clear();
        products.clear();
        nextRecordId = 1;
        nextFeedId = 1;
        nextProductId = 1;
        selectedBed = 1;
        sprayBeds = {1};
        sprayCrops = {'Whole bed'};
        sprayTarget = 'pest';
        message = 'All test data cleared';
        tab = 0;
      });

  void addCrop(int bed, VegetableDefinition crop) => setState(() {
        final next = [...bedCrops[bed] ?? <VegetableDefinition>[]];
        if (!next.any((c) => c.id == crop.id)) next.add(crop);
        bedCrops[bed] = next;
        selectedBed = bed;
        message = '${crop.name} added to Bed $bed';
      });

  void removeCrop(int bed, VegetableDefinition crop) => setState(() {
        final next = [...bedCrops[bed] ?? <VegetableDefinition>[]]..removeWhere((c) => c.id == crop.id);
        next.isEmpty ? bedCrops.remove(bed) : bedCrops[bed] = next;
        message = '${crop.name} removed from Bed $bed';
      });

  void startSpray({required Set<int> beds, String targetId = 'pest', Set<String>? crops}) => setState(() {
        sprayBeds = beds.isEmpty ? {selectedBed} : beds;
        sprayTarget = targetId;
        sprayCrops = crops == null || crops.isEmpty ? defaultCropNames(sprayBeds) : crops;
        tab = 2;
      });

  void saveSpray({required Set<int> beds, required Set<String> crops, required String targetId, required SprayProduct product, required String reason, required String notes, required int days}) {
    if (beds.isEmpty) return;
    final sortedBeds = beds.toList()..sort();
    final sortedCrops = crops.toList()..sort();
    setState(() {
      sprayRecords.insert(0, SprayRecord(id: nextRecordId++, beds: sortedBeds, crops: sortedCrops, targetId: targetId, product: product.name, reason: reason.trim(), notes: notes.trim(), date: DateTime.now(), days: days));
      selectedBed = sortedBeds.first;
      message = 'Spray record saved for Bed ${sortedBeds.join(', ')}';
      tab = 1;
    });
  }

  void saveFeed({required Set<int> beds, required FeedProductPreset preset, required String note}) {
    if (beds.isEmpty) return;
    final sortedBeds = beds.toList()..sort();
    setState(() {
      feedRecords.insert(0, FeedRecord(id: nextFeedId++, beds: sortedBeds, product: preset.name, method: preset.method, note: note.trim(), date: DateTime.now()));
      selectedBed = sortedBeds.first;
      message = '${preset.name} logged for Bed ${sortedBeds.join(', ')}';
      tab = 1;
    });
  }

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
    final today = buildGardenTodayReport(bedCrops: bedCrops, activeRecords: activeSprays, weather: weather, now: DateTime.now());
    final sprayAdvisor = buildSprayAdvisorReport(bedCrops: bedCrops, activeRecords: activeSprays, products: products, weather: weather, now: DateTime.now());
    final feedingAdvisor = buildFeedingAdvisorReport(bedCrops: bedCrops, feedRecords: feedRecords, weather: weather, now: DateTime.now());
    final pages = [
      HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, sprayRecords: sprayRecords, feedRecords: feedRecords, today: today, sprayAdvisor: sprayAdvisor, feedingAdvisor: feedingAdvisor, message: message, onPlanSpray: () => startSpray(beds: {selectedBed}), onLogFeed: () => setState(() => tab = 3), onOpenGarden: () => setState(() => tab = 1), onOpenProducts: () => setState(() => tab = 4)),
      GardenScreen(selectedBed: selectedBed, bedCrops: bedCrops, sprayRecords: sprayRecords, feedRecords: feedRecords, message: message, onSelectBed: (bed) => setState(() => selectedBed = bed), onAddCrop: addCrop, onRemoveCrop: removeCrop, onStartSpray: (bed, target, crops) => startSpray(beds: {bed}, targetId: target, crops: crops), onStartFeed: (bed) => setState(() { selectedBed = bed; tab = 3; })),
      SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, onSave: saveSpray),
      FeedLogScreen(initialBeds: {selectedBed}, onSave: saveFeed),
      ProductsScreen(products: products, message: message, onAdd: addProduct, onDelete: removeProduct, onResetDemo: () => resetToDemoData(), onClearAll: clearAllTestingData),
    ];

    return CupertinoPageScaffold(
      backgroundColor: C.canvas,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: IndexedStack(index: tab, children: pages)),
            FieldbookBottomNav(tab: tab, onTap: (v) => setState(() => tab = v)),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.sprayRecords, required this.feedRecords, required this.today, required this.sprayAdvisor, required this.feedingAdvisor, required this.message, required this.onPlanSpray, required this.onLogFeed, required this.onOpenGarden, required this.onOpenProducts, super.key});
  final int clearBeds;
  final int holdBeds;
  final int plantedBeds;
  final int cropPlacements;
  final List<SprayRecord> sprayRecords;
  final List<FeedRecord> feedRecords;
  final GardenTodayReport today;
  final SprayAdvisorReport sprayAdvisor;
  final FeedingAdvisorReport feedingAdvisor;
  final String message;
  final VoidCallback onPlanSpray;
  final VoidCallback onLogFeed;
  final VoidCallback onOpenGarden;
  final VoidCallback onOpenProducts;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width < 360 ? 14.0 : 20.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 26),
      children: [
        const FieldbookHeader(),
        const SizedBox(height: 18),
        if (message.isNotEmpty) ...[MessageBanner(message), const SizedBox(height: 14)],
        StatusHeroCard(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, onPlanSpray: onPlanSpray, onOpenGarden: onOpenGarden),
        const SizedBox(height: 18),
        SprayAdvisorCard(report: sprayAdvisor, onPlanSpray: onPlanSpray, onOpenProducts: onOpenProducts),
        const SizedBox(height: 14),
        FeedingAdvisorCard(report: feedingAdvisor, onLogFeed: onLogFeed, onOpenProducts: onOpenProducts),
        const SizedBox(height: 14),
        GardenTodayCard(report: today),
        const SizedBox(height: 22),
        const SectionTitle('Recent linked activity', large: true),
        const SizedBox(height: 10),
        if (sprayRecords.isEmpty && feedRecords.isEmpty) const EmptyCard('No activity yet.') else LinkedActivityList(sprayRecords: sprayRecords, feedRecords: feedRecords),
      ],
    );
  }
}

class FieldbookHeader extends StatelessWidget {
  const FieldbookHeader({super.key});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Fieldbook', style: TextStyle(fontSize: 44, height: .98, fontWeight: FontWeight.w900, letterSpacing: -1.8, color: C.forest)), SizedBox(height: 7), Text('Spray, feed, weather and beds linked.', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, color: C.muted, fontWeight: FontWeight.w700))])),
          const SizedBox(width: 10),
          Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: C.forestSoft, shape: BoxShape.circle, border: Border.all(color: C.line)), child: const Icon(CupertinoIcons.leaf_arrow_circlepath, color: C.forest, size: 22)),
        ],
      );
}

class StatusHeroCard extends StatelessWidget {
  const StatusHeroCard({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.onPlanSpray, required this.onOpenGarden, super.key});
  final int clearBeds;
  final int holdBeds;
  final int plantedBeds;
  final int cropPlacements;
  final VoidCallback onPlanSpray;
  final VoidCallback onOpenGarden;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [C.forest, C.forestDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: C.forest.withValues(alpha: .22), blurRadius: 28, offset: const Offset(0, 13))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Connected status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFE1EFE5))),
          const SizedBox(height: 6),
          const Text('Beds drive everything', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: CupertinoColors.white, letterSpacing: -.3)),
          const SizedBox(height: 22),
          Row(children: [Expanded(child: HeroMetric(label: 'CLEAR BEDS', value: '$clearBeds', labelColor: const Color(0xFFD7E7DA), valueColor: CupertinoColors.white)), Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 18), color: CupertinoColors.white.withValues(alpha: .18)), Expanded(child: HeroMetric(label: 'ON HOLD', value: '$holdBeds', labelColor: C.amberSoft, valueColor: const Color(0xFFFFC774)))]),
          const SizedBox(height: 18),
          Text('$plantedBeds beds planted · $cropPlacements crop placements', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: CupertinoColors.white.withValues(alpha: .78), fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          Row(children: [Expanded(child: PrimaryButton(label: 'Plan spray', icon: CupertinoIcons.drop, inverted: true, onPressed: onPlanSpray)), const SizedBox(width: 10), Expanded(child: SecondaryButton(label: 'Open beds', onPressed: onOpenGarden))]),
        ]),
      );
}

class HeroMetric extends StatelessWidget {
  const HeroMetric({required this.label, required this.value, required this.labelColor, required this.valueColor, super.key});
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8))), const SizedBox(height: 6), FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(color: valueColor, fontSize: 40, height: .95, fontWeight: FontWeight.w900)))]);
}

class SprayAdvisorCard extends StatelessWidget {
  const SprayAdvisorCard({required this.report, required this.onPlanSpray, required this.onOpenProducts, super.key});
  final SprayAdvisorReport report;
  final VoidCallback onPlanSpray;
  final VoidCallback onOpenProducts;
  @override
  Widget build(BuildContext context) => ConnectedAdvisorCard(title: 'Spray Advisor', subtitle: report.status, score: report.score, color: report.color, background: report.background, icon: CupertinoIcons.drop, rows: [report.warning, report.bestWindow, report.pressure, report.productSuggestion, report.harvestWarning, report.bedsToCheck], primaryLabel: 'Log spray', primaryAction: onPlanSpray, secondaryLabel: 'Products', secondaryAction: onOpenProducts);
}

class FeedingAdvisorCard extends StatelessWidget {
  const FeedingAdvisorCard({required this.report, required this.onLogFeed, required this.onOpenProducts, super.key});
  final FeedingAdvisorReport report;
  final VoidCallback onLogFeed;
  final VoidCallback onOpenProducts;
  @override
  Widget build(BuildContext context) => ConnectedAdvisorCard(title: 'Feeding Tracker', subtitle: report.status, score: report.score, color: report.color, background: report.background, icon: CupertinoIcons.leaf_arrow_circlepath, rows: [report.feedWindow, report.productSuggestion, report.dueBeds, report.recentFeed, report.weatherNote], primaryLabel: 'Log feed', primaryAction: onLogFeed, secondaryLabel: 'Feed products', secondaryAction: onOpenProducts);
}

class ConnectedAdvisorCard extends StatelessWidget {
  const ConnectedAdvisorCard({required this.title, required this.subtitle, required this.score, required this.color, required this.background, required this.icon, required this.rows, required this.primaryLabel, required this.primaryAction, required this.secondaryLabel, required this.secondaryAction, super.key});
  final String title;
  final String subtitle;
  final int score;
  final Color color;
  final Color background;
  final IconData icon;
  final List<String> rows;
  final String primaryLabel;
  final VoidCallback primaryAction;
  final String secondaryLabel;
  final VoidCallback secondaryAction;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(radius: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 22)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.forest)), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13))])), Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)), child: Text('$score/100', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)))]),
          const SizedBox(height: 14),
          ...rows.map((text) => AdvisorRow(text: text, color: color, background: background)),
          const SizedBox(height: 6),
          Row(children: [Expanded(child: PrimaryButton(label: primaryLabel, onPressed: primaryAction)), const SizedBox(width: 10), Expanded(child: SecondaryButton(label: secondaryLabel, onPressed: secondaryAction))]),
        ]),
      );
}

class AdvisorRow extends StatelessWidget {
  const AdvisorRow({required this.text, required this.color, required this.background, super.key});
  final String text;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(17), border: Border.all(color: C.line)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(CupertinoIcons.circle_fill, size: 9, color: color), const SizedBox(width: 9), Expanded(child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.25)))]));
}

class GardenTodayCard extends StatelessWidget {
  const GardenTodayCard({required this.report, super.key});
  final GardenTodayReport report;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: cardDecoration(radius: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Garden Today', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: C.forest)), const SizedBox(height: 4), Text(report.source, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 12), ...report.items.map((item) => GardenTodayRow(item: item))]));
}

class GardenTodayRow extends StatelessWidget {
  const GardenTodayRow({required this.item, super.key});
  final GardenTodayItem item;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: item.background, borderRadius: BorderRadius.circular(17), border: Border.all(color: C.line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: item.color, fontWeight: FontWeight.w900, fontSize: 14)), const SizedBox(height: 3), Text(item.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w700, fontSize: 12))]));
}

class LinkedActivityList extends StatelessWidget {
  const LinkedActivityList({required this.sprayRecords, required this.feedRecords, super.key});
  final List<SprayRecord> sprayRecords;
  final List<FeedRecord> feedRecords;
  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      ...sprayRecords.take(3).map((r) => ActivityCard(icon: CupertinoIcons.drop, color: targetById(r.targetId).color, background: targetById(r.targetId).softColor, title: 'Spray · Bed ${r.beds.join(', ')}', detail: '${r.product} · ${r.crops.join(', ')} · safe ${shortDate(r.safeDate)}')),
      ...feedRecords.take(3).map((r) => ActivityCard(icon: CupertinoIcons.leaf_arrow_circlepath, color: C.purple, background: C.purpleSoft, title: 'Feed · Bed ${r.beds.join(', ')}', detail: '${r.product} · ${shortDate(r.date)}')),
    ];
    return Column(children: items.take(5).toList());
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({required this.icon, required this.color, required this.background, required this.title, required this.detail, super.key});
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: cardDecoration(radius: 20), child: Row(children: [Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 21)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12))]))]));
}

class GardenScreen extends StatelessWidget {
  const GardenScreen({required this.selectedBed, required this.bedCrops, required this.sprayRecords, required this.feedRecords, required this.message, required this.onSelectBed, required this.onAddCrop, required this.onRemoveCrop, required this.onStartSpray, required this.onStartFeed, super.key});
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> sprayRecords;
  final List<FeedRecord> feedRecords;
  final String message;
  final ValueChanged<int> onSelectBed;
  final void Function(int bed, VegetableDefinition crop) onAddCrop;
  final void Function(int bed, VegetableDefinition crop) onRemoveCrop;
  final void Function(int bed, String target, Set<String> crops) onStartSpray;
  final ValueChanged<int> onStartFeed;

  bool bedOnHold(int bed) => sprayRecords.any((r) => r.beds.contains(bed) && r.safeDate.isAfter(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final crops = bedCrops[selectedBed] ?? const <VegetableDefinition>[];
    final bedSprays = sprayRecords.where((r) => r.beds.contains(selectedBed)).toList();
    final bedFeeds = feedRecords.where((r) => r.beds.contains(selectedBed)).toList();
    final mapHeight = clampDouble(MediaQuery.of(context).size.height * .50, 330, 500);
    return AppPage(title: 'Garden', subtitle: 'Beds are the hub. Crops, sprays and feeds link here.', message: message, children: [
      Panel(padding: const EdgeInsets.all(12), child: SizedBox(height: mapHeight, child: GardenMap(selectedBed: selectedBed, bedCrops: bedCrops, sprayRecords: sprayRecords, feedRecords: feedRecords, isHold: bedOnHold, onTap: onSelectBed))),
      const SizedBox(height: 14),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('Bed $selectedBed', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), StatusPill(bedOnHold(selectedBed) ? 'HOLD' : 'CLEAR', hold: bedOnHold(selectedBed))]),
        const SizedBox(height: 5),
        Text(crops.isEmpty ? 'No crops assigned' : crops.map((c) => c.name).join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        if (crops.isEmpty) const EmptyInline('Add crops to link crop-specific spray and feed guidance.') else CropWrap(crops: crops, onRemove: (crop) => onRemoveCrop(selectedBed, crop)),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: SecondaryButton(label: 'Add crop', onPressed: () => showCropPicker(context, selectedBed, crops, onAddCrop))), const SizedBox(width: 10), Expanded(child: PrimaryButton(label: 'Spray bed', onPressed: () => onStartSpray(selectedBed, 'pest', crops.map((c) => c.name).toSet())))]),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Feed bed', onPressed: () => onStartFeed(selectedBed)),
      ])),
      const SizedBox(height: 14),
      BedLinkedActivityPanel(bed: selectedBed, sprayRecords: bedSprays, feedRecords: bedFeeds),
    ]);
  }
}

class GardenMap extends StatelessWidget {
  const GardenMap({required this.selectedBed, required this.bedCrops, required this.sprayRecords, required this.feedRecords, required this.isHold, required this.onTap, super.key});
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> sprayRecords;
  final List<FeedRecord> feedRecords;
  final bool Function(int bed) isHold;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(children: [Positioned.fill(child: CustomPaint(painter: GridPainter())), ...gardenBeds.map((bed) {
          final r = Rect.fromLTWH(bed.rect.left * size.width, bed.rect.top * size.height, bed.rect.width * size.width, bed.rect.height * size.height);
          return Positioned.fromRect(rect: r, child: BedButton(number: bed.number, selected: selectedBed == bed.number, hold: isHold(bed.number), crops: bedCrops[bed.number] ?? const <VegetableDefinition>[], sprayCount: sprayRecords.where((record) => record.beds.contains(bed.number)).length, feedCount: feedRecords.where((record) => record.beds.contains(bed.number)).length, onTap: () => onTap(bed.number)));
        })]);
      });
}

class BedButton extends StatelessWidget {
  const BedButton({required this.number, required this.selected, required this.hold, required this.crops, required this.sprayCount, required this.feedCount, required this.onTap, super.key});
  final int number;
  final bool selected;
  final bool hold;
  final List<VegetableDefinition> crops;
  final int sprayCount;
  final int feedCount;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, minimumSize: Size.zero, onPressed: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 160), decoration: BoxDecoration(color: hold ? C.amberSoft : crops.isEmpty ? C.card : C.forestSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? C.forest : C.soil, width: selected ? 2.4 : 1.2)), child: Stack(clipBehavior: Clip.none, children: [Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text('$number', style: TextStyle(fontWeight: FontWeight.w900, color: selected ? C.forest : C.ink, fontSize: 12)))), if (crops.isNotEmpty) Positioned(top: -10, right: -10, child: IconCluster(crops: crops)), if (sprayCount > 0 || feedCount > 0) Positioned(left: -8, bottom: -10, child: BedActivityBadges(sprayCount: sprayCount, feedCount: feedCount))])));
}

class BedActivityBadges extends StatelessWidget {
  const BedActivityBadges({required this.sprayCount, required this.feedCount, super.key});
  final int sprayCount;
  final int feedCount;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.line), boxShadow: softShadow), child: Row(mainAxisSize: MainAxisSize.min, children: [if (sprayCount > 0) BedActivityDot(icon: CupertinoIcons.drop, count: sprayCount, color: C.blue, background: C.blueSoft), if (sprayCount > 0 && feedCount > 0) const SizedBox(width: 3), if (feedCount > 0) BedActivityDot(icon: CupertinoIcons.leaf_arrow_circlepath, count: feedCount, color: C.purple, background: C.purpleSoft)]));
}

class BedActivityDot extends StatelessWidget {
  const BedActivityDot({required this.icon, required this.count, required this.color, required this.background, super.key});
  final IconData icon;
  final int count;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 10, color: color), const SizedBox(width: 2), Text('$count', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900))]));
}

class IconCluster extends StatelessWidget {
  const IconCluster({required this.crops, super.key});
  final List<VegetableDefinition> crops;
  @override
  Widget build(BuildContext context) => Container(constraints: const BoxConstraints(maxWidth: 96), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.line), boxShadow: softShadow), child: Wrap(spacing: 2, runSpacing: 2, children: crops.take(3).map((c) => CropIcon(c.iconPath, size: 20)).toList()));
}

class BedLinkedActivityPanel extends StatelessWidget {
  const BedLinkedActivityPanel({required this.bed, required this.sprayRecords, required this.feedRecords, super.key});
  final int bed;
  final List<SprayRecord> sprayRecords;
  final List<FeedRecord> feedRecords;
  @override
  Widget build(BuildContext context) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bed $bed linked records', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.forest)), const SizedBox(height: 10), if (sprayRecords.isEmpty && feedRecords.isEmpty) const EmptyInline('No sprays or feeds linked to this bed yet.') else ...[...sprayRecords.take(4).map((r) => ActivityCard(icon: CupertinoIcons.drop, color: targetById(r.targetId).color, background: targetById(r.targetId).softColor, title: 'Spray · ${r.product}', detail: '${shortDate(r.date)} · safe ${shortDate(r.safeDate)} · ${r.reason.isEmpty ? r.crops.join(', ') : r.reason}')), ...feedRecords.take(4).map((r) => ActivityCard(icon: CupertinoIcons.leaf_arrow_circlepath, color: C.purple, background: C.purpleSoft, title: 'Feed · ${r.product}', detail: '${shortDate(r.date)} · ${r.method}${r.note.isEmpty ? '' : ' · ${r.note}'}'))]]));
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
  late SprayProduct product = widget.products.where((p) => p.targets.contains(targetId)).firstOrNull ?? (widget.products.isEmpty ? const SprayProduct(id: 0, name: 'No product', type: 'None', days: 0, targets: []) : widget.products.first);
  late int days = product.days;
  final reason = TextEditingController();
  final notes = TextEditingController();
  @override
  void dispose() { reason.dispose(); notes.dispose(); super.dispose(); }
  List<VegetableDefinition> currentCrops() => beds.expand((bed) => widget.bedCrops[bed] ?? const <VegetableDefinition>[]).toSet().toList();
  @override
  Widget build(BuildContext context) {
    final activeCrops = currentCrops();
    return AppPage(title: 'Spray Log', subtitle: 'Sprays link to beds, crops, products and withholding.', children: [
      const SectionTitle('Beds sprayed'), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: gardenBeds.map((b) => NumberChip(label: '${b.number}', selected: beds.contains(b.number), onTap: () => setState(() { beds.contains(b.number) ? beds.remove(b.number) : beds.add(b.number); final names = currentCrops().map((c) => c.name).toSet(); crops = names.isEmpty ? {'Whole bed'} : names; }))).toList()),
      const SizedBox(height: 18), const SectionTitle('Crops affected'), const SizedBox(height: 8), if (activeCrops.isEmpty) const EmptyCard('Whole bed spray — no crops assigned to selected beds.') else SelectableCrops(crops: activeCrops, selected: crops, onChanged: (v) => setState(() => crops = v)),
      const SizedBox(height: 18), const SectionTitle('Spraying against'), const SizedBox(height: 8), TargetGrid(selected: targetId, onSelect: (id) => setState(() { targetId = id; final match = widget.products.where((p) => p.targets.contains(id)).firstOrNull; if (match != null) { product = match; days = match.days; } })),
      const SizedBox(height: 18), const SectionTitle('Product'), const SizedBox(height: 8), if (widget.products.isEmpty) const EmptyCard('No products configured. Add products in the Products tab.') else ...widget.products.map((p) => ProductChoice(product: p, selected: p.id == product.id, suggested: p.targets.contains(targetId), onTap: () => setState(() { product = p; days = p.days; }))),
      const SizedBox(height: 18), Field(controller: reason, placeholder: 'Issue or reason, e.g. aphids on tips'), const SizedBox(height: 8), Field(controller: notes, placeholder: 'Notes optional', maxLines: 3), const SizedBox(height: 12), Stepper(label: 'Withholding days', value: days, minus: days > 0 ? () => setState(() => days--) : null, plus: () => setState(() => days++)),
      const SizedBox(height: 18), PrimaryButton(label: 'Save spray record', onPressed: beds.isEmpty || widget.products.isEmpty ? null : () => widget.onSave(beds: beds, crops: crops, targetId: targetId, product: product, reason: reason.text, notes: notes.text, days: days)),
    ]);
  }
}

class FeedLogScreen extends StatefulWidget {
  const FeedLogScreen({required this.initialBeds, required this.onSave, super.key});
  final Set<int> initialBeds;
  final void Function({required Set<int> beds, required FeedProductPreset preset, required String note}) onSave;
  @override
  State<FeedLogScreen> createState() => _FeedLogScreenState();
}

class _FeedLogScreenState extends State<FeedLogScreen> {
  late Set<int> beds = {...widget.initialBeds};
  var preset = feedProductPresets.first;
  final note = TextEditingController();
  @override
  void dispose() { note.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AppPage(title: 'Feed Log', subtitle: 'Feeds link to beds and timing advice.', children: [
        const SectionTitle('Beds fed'), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: gardenBeds.map((b) => NumberChip(label: '${b.number}', selected: beds.contains(b.number), onTap: () => setState(() => beds.contains(b.number) ? beds.remove(b.number) : beds.add(b.number)))).toList()),
        const SizedBox(height: 18), const SectionTitle('Feed used'), const SizedBox(height: 8), ...feedProductPresets.map((p) => FeedPresetChoice(preset: p, selected: preset.name == p.name, onTap: () => setState(() => preset = p))),
        const SizedBox(height: 14), Field(controller: note, placeholder: 'Notes optional', maxLines: 3), const SizedBox(height: 18), PrimaryButton(label: 'Save feed record', onPressed: beds.isEmpty ? null : () => widget.onSave(beds: beds, preset: preset, note: note.text)),
      ]);
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({required this.products, required this.message, required this.onAdd, required this.onDelete, required this.onResetDemo, required this.onClearAll, super.key});
  final List<SprayProduct> products;
  final String message;
  final void Function(String name, String type, int days) onAdd;
  final ValueChanged<int> onDelete;
  final VoidCallback onResetDemo;
  final VoidCallback onClearAll;
  @override
  Widget build(BuildContext context) => AppPage(title: 'Products', subtitle: 'Spray products, feed products, Bunnings links and test reset.', message: message, trailing: CupertinoButton(padding: EdgeInsets.zero, minimumSize: Size.zero, onPressed: () => showProductDialog(context, onAdd), child: const Text('+', style: TextStyle(color: C.forest, fontSize: 28, fontWeight: FontWeight.w900))), children: [TestingToolsCard(onResetDemo: onResetDemo, onClearAll: onClearAll), const BunningsSprayProductsPanel(), const SectionTitle('My spray products'), const SizedBox(height: 8), if (products.isEmpty) const EmptyCard('No custom spray products configured.') else ...products.map((p) => ProductTile(product: p, onDelete: () => onDelete(p.id)))]);
}

class TestingToolsCard extends StatelessWidget {
  const TestingToolsCard({required this.onResetDemo, required this.onClearAll, super.key});
  final VoidCallback onResetDemo;
  final VoidCallback onClearAll;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(14), decoration: cardDecoration(radius: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Testing tools', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.forest)), const SizedBox(height: 4), const Text('Reset local demo data while testing screens, sprays, feeds and bed badges.', style: TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 12), Row(children: [Expanded(child: SecondaryButton(label: 'Reset demo', onPressed: onResetDemo)), const SizedBox(width: 10), Expanded(child: DangerButton(label: 'Clear all', onPressed: onClearAll))])]));
}

class BunningsSprayProductsPanel extends StatelessWidget {
  const BunningsSprayProductsPanel({super.key});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionTitle('Bunnings linked products'), const SizedBox(height: 8), const Text('Direct Bunnings NZ cards for spray and feed decisions. Prices and stock stay on Bunnings.', style: TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 10), ...bunningsSprayProducts.map((product) => BunningsSprayProductCard(product: product)), const SizedBox(height: 8)]);
}

class BunningsSprayProductCard extends StatelessWidget {
  const BunningsSprayProductCard({required this.product, super.key});
  final BunningsSprayProduct product;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: cardDecoration(radius: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: product.background, borderRadius: BorderRadius.circular(15)), child: Icon(CupertinoIcons.cube_box, color: product.color, size: 22)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.ink)), const SizedBox(height: 2), Text(product.brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 5), Wrap(spacing: 6, runSpacing: 6, children: [ProductTag(label: product.target, color: product.color, background: product.background), ProductTag(label: product.type, color: C.forest, background: C.forestSoft)])]))]), const SizedBox(height: 10), Text(product.note, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.28)), const SizedBox(height: 10), Row(children: [Expanded(child: Text(product.url.replaceFirst('https://www.bunnings.co.nz/', ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 11))), const SizedBox(width: 10), CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero, color: C.forest, borderRadius: BorderRadius.circular(999), onPressed: () => openBunningsUrl(product.url, product.fallbackUrl), child: const Text('Open', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w900, fontSize: 12)))]) ]));
}

class ProductTag extends StatelessWidget {
  const ProductTag({required this.label, required this.color, required this.background, super.key});
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(constraints: const BoxConstraints(maxWidth: 220), padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)), child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10.5)));
}

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, required this.onDelete, super.key});
  final SprayProduct product;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: cardDecoration(), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text(product.type, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)), Text('${product.days} day withholding · ${product.targets.map((id) => targetById(id).short).join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12))])), CupertinoButton(padding: EdgeInsets.zero, minimumSize: Size.zero, onPressed: onDelete, child: const Text('Delete', style: TextStyle(color: C.red, fontWeight: FontWeight.w900, fontSize: 12)))]));
}

class FeedPresetChoice extends StatelessWidget {
  const FeedPresetChoice({required this.preset, required this.selected, required this.onTap, super.key});
  final FeedProductPreset preset;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: selected ? preset.background : C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? preset.color : C.line)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(preset.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), Text('${preset.method} · every ${preset.intervalDays} days', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700))])), Text(selected ? '✓' : '○', style: TextStyle(color: selected ? preset.color : C.muted, fontSize: 22, fontWeight: FontWeight.w900))])));
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
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(constraints: const BoxConstraints(maxWidth: 250), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: selected ? C.forest : C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? C.forest : C.line)), child: Row(mainAxisSize: MainAxisSize.min, children: [CropIcon(crop.iconPath, size: 20), const SizedBox(width: 6), Flexible(child: Text(crop.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: selected ? CupertinoColors.white : C.ink)))])));
}

class TargetGrid extends StatelessWidget {
  const TargetGrid({required this.selected, required this.onSelect, super.key});
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) { final columns = constraints.maxWidth < 360 ? 2 : 4; return GridView.count(crossAxisCount: columns, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: columns == 2 ? 2.35 : .98, children: sprayTargets.map((t) => TargetButton(target: t, selected: selected == t.id, onTap: () => onSelect(t.id))).toList()); });
}

class TargetButton extends StatelessWidget {
  const TargetButton({required this.target, required this.selected, required this.onTap, super.key});
  final SprayTarget target;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, minimumSize: Size.zero, onPressed: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), decoration: BoxDecoration(color: selected ? target.softColor : C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? target.color : C.line, width: selected ? 1.8 : 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(target.icon, color: target.color, size: 22), const SizedBox(height: 5), Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(target.short, maxLines: 1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900))))])));
}

class ProductChoice extends StatelessWidget {
  const ProductChoice({required this.product, required this.selected, required this.suggested, required this.onTap, super.key});
  final SprayProduct product;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: selected ? C.forestSoft : C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? C.forest : C.line)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), Text('${product.type} · ${product.days} day withholding', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700))])), if (suggested) ...[const SizedBox(width: 8), const StatusPill('MATCH', hold: false)], const SizedBox(width: 8), Text(selected ? '✓' : '○', style: TextStyle(color: selected ? C.forest : C.muted, fontSize: 22, fontWeight: FontWeight.w900))])));
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
  Widget build(BuildContext context) => Container(constraints: const BoxConstraints(maxWidth: 260), padding: const EdgeInsets.fromLTRB(10, 8, 6, 8), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.line)), child: Row(mainAxisSize: MainAxisSize.min, children: [CropIcon(crop.iconPath, size: 22), const SizedBox(width: 7), Flexible(child: Text(crop.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))), if (onRemove != null) CupertinoButton(padding: EdgeInsets.zero, minimumSize: Size.zero, onPressed: onRemove, child: const Text('×', style: TextStyle(fontSize: 18, color: C.muted)))]));
}

void showCropPicker(BuildContext context, int bed, List<VegetableDefinition> assigned, void Function(int bed, VegetableDefinition crop) onAdd) {
  showCupertinoModalPopup<void>(context: context, builder: (_) => Sheet(child: CropPicker(bed: bed, assigned: assigned, onAdd: onAdd)));
}

class CropPicker extends StatelessWidget {
  const CropPicker({required this.bed, required this.assigned, required this.onAdd, super.key});
  final int bed;
  final List<VegetableDefinition> assigned;
  final void Function(int bed, VegetableDefinition crop) onAdd;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [SheetHeader(title: 'Add crop', subtitle: 'Bed $bed'), const SizedBox(height: 12), ...vegetableLibrary.map((crop) { final added = assigned.any((c) => c.id == crop.id); return CupertinoButton(padding: EdgeInsets.zero, onPressed: added ? null : () { onAdd(bed, crop); Navigator.pop(context); }, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: cardDecoration(), child: Row(children: [CropIcon(crop.iconPath, size: 38), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(crop.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), Text(familyByCrop(crop).name, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700))])), StatusPill(added ? 'ADDED' : 'ADD', hold: false)]))); })]);
}

void showProductDialog(BuildContext context, void Function(String name, String type, int days) onAdd) {
  final name = TextEditingController();
  final type = TextEditingController(text: 'Custom product');
  final days = TextEditingController(text: '1');
  showCupertinoDialog<void>(context: context, builder: (_) => CupertinoAlertDialog(title: const Text('Add product'), content: Column(children: [const SizedBox(height: 12), CupertinoTextField(controller: name, placeholder: 'Name'), const SizedBox(height: 8), CupertinoTextField(controller: type, placeholder: 'Type'), const SizedBox(height: 8), CupertinoTextField(controller: days, placeholder: 'Withholding days', keyboardType: TextInputType.number)]), actions: [CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)), CupertinoDialogAction(isDefaultAction: true, child: const Text('Add', style: TextStyle(color: C.forest)), onPressed: () { if (name.text.trim().isNotEmpty) onAdd(name.text.trim(), type.text.trim().isEmpty ? 'Custom product' : type.text.trim(), int.tryParse(days.text) ?? 1); Navigator.pop(context); })]));
}

class FieldbookBottomNav extends StatelessWidget {
  const FieldbookBottomNav({required this.tab, required this.onTap, super.key});
  final int tab;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) {
    final items = const [NavSpec('Home', CupertinoIcons.home), NavSpec('Garden', CupertinoIcons.square_grid_2x2), NavSpec('Spray', CupertinoIcons.drop), NavSpec('Feed', CupertinoIcons.leaf_arrow_circlepath), NavSpec('Products', CupertinoIcons.cube_box)];
    return Container(margin: const EdgeInsets.fromLTRB(14, 6, 14, 12), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(31), border: Border.all(color: C.line), boxShadow: navShadow), child: Row(children: List.generate(items.length, (i) { final selected = i == tab; return Expanded(child: CupertinoButton(padding: EdgeInsets.zero, minimumSize: Size.zero, onPressed: () => onTap(i), child: Column(mainAxisSize: MainAxisSize.min, children: [AnimatedContainer(duration: const Duration(milliseconds: 160), width: 38, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? C.forest : CupertinoColors.transparent, borderRadius: BorderRadius.circular(999)), child: Icon(items[i].icon, size: 18, color: selected ? CupertinoColors.white : C.muted)), const SizedBox(height: 3), FittedBox(fit: BoxFit.scaleDown, child: Text(items[i].label, maxLines: 1, style: TextStyle(color: selected ? C.forest : C.muted, fontSize: 9.5, fontWeight: FontWeight.w800)))]))); })));
  }
}

class NavSpec { const NavSpec(this.label, this.icon); final String label; final IconData icon; }

class AppPage extends StatelessWidget {
  const AppPage({required this.title, required this.subtitle, required this.children, this.message = '', this.trailing, super.key});
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String message;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) { final width = MediaQuery.of(context).size.width; final horizontal = width < 360 ? 14.0 : 20.0; return ListView(padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 26), children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.1, color: C.forest))), const SizedBox(height: 4), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: C.muted, fontWeight: FontWeight.w700))])), if (trailing != null) ...[const SizedBox(width: 8), Flexible(flex: 0, child: trailing!)] ]), const SizedBox(height: 18), if (message.isNotEmpty) ...[MessageBanner(message), const SizedBox(height: 12)], ...children]); }
}

class MessageBanner extends StatelessWidget { const MessageBanner(this.message, {super.key}); final String message; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: C.forestSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)), child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.forest, fontWeight: FontWeight.w900))); }
class Panel extends StatelessWidget { const Panel({required this.child, this.padding = const EdgeInsets.all(16), this.color = C.card, super.key}); final Widget child; final EdgeInsets padding; final Color color; @override Widget build(BuildContext context) => Container(padding: padding, decoration: cardDecoration(color: color), child: child); }
class SectionTitle extends StatelessWidget { const SectionTitle(this.text, {this.trailing, this.large = false, super.key}); final String text; final Widget? trailing; final bool large; @override Widget build(BuildContext context) => Row(children: [Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: large ? 23 : 17, fontWeight: FontWeight.w900, color: C.forest, letterSpacing: large ? -.3 : 0))), if (trailing != null) ...[const SizedBox(width: 8), Flexible(flex: 0, child: trailing!)] ]); }
class EmptyCard extends StatelessWidget { const EmptyCard(this.text, {super.key}); final String text; @override Widget build(BuildContext context) => Panel(child: Text(text, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700))); }
class EmptyInline extends StatelessWidget { const EmptyInline(this.text, {super.key}); final String text; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)), child: Text(text, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700))); }
class Sheet extends StatelessWidget { const Sheet({required this.child, super.key}); final Widget child; @override Widget build(BuildContext context) => CupertinoPopupSurface(child: SafeArea(top: false, child: SizedBox(height: MediaQuery.of(context).size.height * .86, child: Container(color: C.canvas, child: child)))); }
class SheetHeader extends StatelessWidget { const SheetHeader({required this.title, required this.subtitle, super.key}); final String title; final String subtitle; @override Widget build(BuildContext context) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w800))])), CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: const Text('×', style: TextStyle(fontSize: 28, color: C.muted))) ]); }

class PrimaryButton extends StatelessWidget { const PrimaryButton({required this.label, required this.onPressed, this.icon, this.inverted = false, super.key}); final String label; final VoidCallback? onPressed; final IconData? icon; final bool inverted; @override Widget build(BuildContext context) => CupertinoButton(color: inverted ? C.card : C.forest, disabledColor: C.line, borderRadius: BorderRadius.circular(16), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), onPressed: onPressed, child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, color: inverted ? C.forest : CupertinoColors.white, size: 18), const SizedBox(width: 8)], Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: inverted ? C.forest : CupertinoColors.white, fontWeight: FontWeight.w900)))])); }
class SecondaryButton extends StatelessWidget { const SecondaryButton({required this.label, required this.onPressed, super.key}); final String label; final VoidCallback? onPressed; @override Widget build(BuildContext context) => CupertinoButton(color: C.forestSoft, disabledColor: C.soft, borderRadius: BorderRadius.circular(16), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), onPressed: onPressed, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onPressed == null ? C.muted : C.forest, fontWeight: FontWeight.w900))); }
class DangerButton extends StatelessWidget { const DangerButton({required this.label, required this.onPressed, super.key}); final String label; final VoidCallback? onPressed; @override Widget build(BuildContext context) => CupertinoButton(color: C.redSoft, disabledColor: C.soft, borderRadius: BorderRadius.circular(16), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14), onPressed: onPressed, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onPressed == null ? C.muted : C.red, fontWeight: FontWeight.w900))); }
class NumberChip extends StatelessWidget { const NumberChip({required this.label, required this.selected, required this.onTap, super.key}); final String label; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10), decoration: BoxDecoration(color: selected ? C.forest : C.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? C.forest : C.line)), child: Text(label, maxLines: 1, style: TextStyle(color: selected ? CupertinoColors.white : C.ink, fontWeight: FontWeight.w900, fontSize: 13)))); }
class StatusPill extends StatelessWidget { const StatusPill(this.label, {required this.hold, super.key}); final String label; final bool hold; @override Widget build(BuildContext context) => FittedBox(fit: BoxFit.scaleDown, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: hold ? C.amberSoft : C.forestSoft, borderRadius: BorderRadius.circular(999)), child: Text(label, maxLines: 1, style: TextStyle(color: hold ? C.amber : C.forest, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .5)))); }
class Field extends StatelessWidget { const Field({required this.controller, required this.placeholder, this.maxLines = 1, super.key}); final TextEditingController controller; final String placeholder; final int maxLines; @override Widget build(BuildContext context) => CupertinoTextField(controller: controller, placeholder: placeholder, maxLines: maxLines, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line))); }
class Stepper extends StatelessWidget { const Stepper({required this.label, required this.value, required this.minus, required this.plus, super.key}); final String label; final int value; final VoidCallback? minus; final VoidCallback plus; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)), child: Row(children: [Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))), SmallButton('-', minus), Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), SmallButton('+', plus)])); }
class SmallButton extends StatelessWidget { const SmallButton(this.label, this.onPressed, {super.key}); final String label; final VoidCallback? onPressed; @override Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, minimumSize: const Size(34, 34), color: C.card, borderRadius: BorderRadius.circular(999), onPressed: onPressed, child: Text(label, style: const TextStyle(color: C.forest, fontSize: 18, fontWeight: FontWeight.w900))); }
class CropIcon extends StatelessWidget { const CropIcon(this.path, {this.size = 28, super.key}); final String path; final double size; @override Widget build(BuildContext context) => path.toLowerCase().endsWith('.svg') ? SvgPicture.asset(path, width: size, height: size, fit: BoxFit.contain) : Image.asset(path, width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.high); }
class GridPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = const Color(0xFFE9E4D8)..strokeWidth = .55; for (double x = 0; x < size.width; x += 16) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint); } for (double y = 0; y < size.height; y += 16) { canvas.drawLine(Offset(0, y), Offset(size.width, y), paint); } } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
