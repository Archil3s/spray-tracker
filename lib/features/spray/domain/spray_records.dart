part of '../../../main.dart';

class SprayTarget {
  const SprayTarget(
    this.id,
    this.title,
    this.short,
    this.color,
    this.softColor,
    this.icon,
  );
  final String id;
  final String title;
  final String short;
  final Color color;
  final Color softColor;
  final IconData icon;
}

const sprayTargets = [
  SprayTarget(
    'pest',
    'Pest pressure',
    'Pest',
    C.red,
    C.redSoft,
    CupertinoIcons.exclamationmark_triangle,
  ),
  SprayTarget(
    'fungus',
    'Fungal pressure',
    'Fungus',
    C.blue,
    C.blueSoft,
    CupertinoIcons.drop,
  ),
  SprayTarget(
    'prevent',
    'Preventative',
    'Prevent',
    C.forest,
    C.forestSoft,
    CupertinoIcons.shield,
  ),
  SprayTarget(
    'maintain',
    'Plant support',
    'Support',
    C.amber,
    C.amberSoft,
    CupertinoIcons.leaf_arrow_circlepath,
  ),
];

SprayTarget targetById(String id) => sprayTargets.firstWhere(
      (target) => target.id == id,
      orElse: () => sprayTargets.first,
    );

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
  bool get onHold => onHoldAt(DateTime.now());

  bool onHoldAt(DateTime dateTime) => safeDate.isAfter(dateTime);
}

enum BedSprayState { neverSprayed, clear, hold }

class BedSpraySummary {
  const BedSpraySummary({
    required this.state,
    required this.record,
    required this.checkedAt,
  });

  final BedSprayState state;
  final SprayRecord? record;
  final DateTime checkedAt;

  bool get onHold => state == BedSprayState.hold;
  bool get hasSpray => record != null;
}

List<String> cropNamesForBeds(
  Map<int, List<VegetableDefinition>> bedCrops,
  Iterable<int> beds,
) {
  final cropNames = <String>{};

  for (final bed in beds) {
    final crops = bedCrops[bed] ?? const <VegetableDefinition>[];
    cropNames.addAll(crops.map((crop) => crop.name));
  }

  return cropNames.toList()..sort();
}

SprayRecord? nextActiveSprayRecord(
  Iterable<SprayRecord> records, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  SprayRecord? nextRecord;

  for (final record in records) {
    if (!record.onHoldAt(currentTime)) continue;

    if (nextRecord == null || record.safeDate.isBefore(nextRecord.safeDate)) {
      nextRecord = record;
    }
  }

  return nextRecord;
}

SprayRecord? latestSprayRecordForBed(
  Iterable<SprayRecord> records,
  int bed,
) {
  SprayRecord? latestRecord;

  for (final record in records) {
    if (!record.beds.contains(bed)) continue;

    final newerDate =
        latestRecord == null || record.date.isAfter(latestRecord.date);
    final sameDateNewerId = latestRecord != null &&
        record.date.isAtSameMomentAs(latestRecord.date) &&
        record.id > latestRecord.id;
    if (newerDate || sameDateNewerId) {
      latestRecord = record;
    }
  }

  return latestRecord;
}

BedSpraySummary bedSpraySummary(
  Iterable<SprayRecord> records,
  int bed, {
  DateTime? now,
}) {
  final checkedAt = now ?? DateTime.now();
  final record = latestSprayRecordForBed(records, bed);
  if (record == null) {
    return BedSpraySummary(
      state: BedSprayState.neverSprayed,
      record: null,
      checkedAt: checkedAt,
    );
  }

  return BedSpraySummary(
    state:
        record.onHoldAt(checkedAt) ? BedSprayState.hold : BedSprayState.clear,
    record: record,
    checkedAt: checkedAt,
  );
}

Set<String> sprayRecordTargetCoverage(
  SprayRecord record,
  List<SprayProduct> products,
) {
  final targets = <String>{record.targetId};
  final product = _sprayRecordProduct(record, products);
  if (product != null) {
    targets.addAll(product.targets);
  }

  final text = [
    record.targetId,
    record.product,
    record.reason,
    record.notes,
    product?.type ?? '',
    product?.activeIngredient ?? '',
    product?.commonUses.join(' ') ?? '',
  ].join(' ').toLowerCase();
  if (_containsAny(text, const [
    'fung',
    'mildew',
    'rust',
    'blight',
    'botrytis',
    'rot',
  ])) {
    targets.add('fungus');
  }
  if (_containsAny(text, const [
    'pest',
    'insect',
    'aphid',
    'mite',
    'whitefly',
    'thrip',
    'scale',
    'caterpillar',
    'slug',
  ])) {
    targets.add('pest');
  }
  if (_containsAny(text, const [
    'feed',
    'fert',
    'tonic',
    'seaweed',
    'stress',
    'plant health',
  ])) {
    targets.add('maintain');
  }
  if (targets.contains('prevent')) {
    targets.addAll(const ['pest', 'fungus']);
  }
  return targets;
}

bool sprayRecordCoversTarget({
  required SprayRecord record,
  required List<SprayProduct> products,
  required String targetId,
  VegetableDefinition? crop,
}) =>
    sprayRecordTargetCoverage(record, products).contains(targetId) &&
    (crop == null || sprayRecordCoversCrop(record, crop));

bool sprayRecordCoversCrop(SprayRecord record, VegetableDefinition crop) {
  final recordCrops = record.crops.map((name) => name.toLowerCase()).toSet();
  if (recordCrops.contains('whole bed')) return true;
  if (recordCrops.contains(crop.name.toLowerCase())) return true;
  return recordCrops.contains(crop.id.replaceAll('_', ' ').toLowerCase());
}

SprayProduct? _sprayRecordProduct(
  SprayRecord record,
  List<SprayProduct> products,
) {
  for (final product in products) {
    if (product.id == record.productId) return product;
  }
  return null;
}

bool _containsAny(String text, Iterable<String> needles) =>
    needles.any(text.contains);
