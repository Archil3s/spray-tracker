part of '../../../main.dart';

enum ProtectionTarget { pest, fungus, feed }

enum ProtectionStatus { due, soon, scheduled, blocked }

class PreventativeCalendarItem {
  const PreventativeCalendarItem({
    required this.bed,
    required this.crop,
    required this.target,
    required this.status,
    required this.dueDate,
    required this.intervalDays,
    required this.title,
    required this.body,
    required this.issues,
    this.product,
    this.lastRecord,
  });

  final GardenBed bed;
  final VegetableDefinition crop;
  final ProtectionTarget target;
  final ProtectionStatus status;
  final DateTime dueDate;
  final int intervalDays;
  final String title;
  final String body;
  final List<String> issues;
  final SprayProduct? product;
  final SprayRecord? lastRecord;
}

class CropIssueProfile {
  const CropIssueProfile({
    required this.name,
    required this.target,
    required this.crops,
    required this.preventativeTips,
    required this.products,
  });

  final String name;
  final ProtectionTarget target;
  final List<VegetableDefinition> crops;
  final List<String> preventativeTips;
  final List<SprayProduct> products;
}

List<PreventativeCalendarItem> generatePreventativeCalendar({
  required List<GardenBed> beds,
  required Map<int, List<VegetableDefinition>> bedCrops,
  required Iterable<SprayRecord> records,
  required List<SprayProduct> products,
  GardenRiskSummary? risks,
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final items = <PreventativeCalendarItem>[];
  for (final bed in beds) {
    final crops = bedCrops[bed.number] ?? const <VegetableDefinition>[];
    if (crops.isEmpty) continue;
    final hold = bedSpraySummary(records, bed.number, now: today);

    for (final crop in crops) {
      items.add(
        _calendarItem(
          bed: bed,
          crop: crop,
          target: ProtectionTarget.fungus,
          records: records,
          products: products,
          risks: risks,
          now: today,
          hold: hold,
        ),
      );
      items.add(
        _calendarItem(
          bed: bed,
          crop: crop,
          target: ProtectionTarget.pest,
          records: records,
          products: products,
          risks: risks,
          now: today,
          hold: hold,
        ),
      );
      items.add(
        _calendarItem(
          bed: bed,
          crop: crop,
          target: ProtectionTarget.feed,
          records: records,
          products: products,
          risks: risks,
          now: today,
          hold: hold,
        ),
      );
    }
  }

  items.sort((a, b) {
    final status = _statusRank(a.status).compareTo(_statusRank(b.status));
    if (status != 0) return status;
    final date = a.dueDate.compareTo(b.dueDate);
    if (date != 0) return date;
    return a.bed.number.compareTo(b.bed.number);
  });
  return items;
}

List<CropIssueProfile> buildCropIssueProfiles({
  required ProtectionTarget target,
  required Iterable<VegetableDefinition> crops,
  required List<SprayProduct> products,
}) {
  final index = <String, List<VegetableDefinition>>{};
  final tips = <String, Set<String>>{};
  for (final crop in crops) {
    final issues = target == ProtectionTarget.fungus
        ? crop.commonDiseases
        : crop.commonPests;
    for (final issue in issues) {
      final key = _normalIssue(issue);
      index.putIfAbsent(key, () => []).add(crop);
      tips.putIfAbsent(key, () => <String>{}).addAll(crop.preventativeTips);
    }
  }

  final profiles = [
    for (final entry in index.entries)
      CropIssueProfile(
        name: entry.key,
        target: target,
        crops: entry.value..sort((a, b) => a.name.compareTo(b.name)),
        preventativeTips: (tips[entry.key] ?? const <String>{})
            .take(5)
            .toList(growable: false),
        products: _productsForIssue(
          products: products,
          target: target,
          issue: entry.key,
          crops: entry.value,
        ),
      ),
  ]..sort((a, b) {
      final cropCount = b.crops.length.compareTo(a.crops.length);
      if (cropCount != 0) return cropCount;
      return a.name.compareTo(b.name);
    });
  return profiles;
}

PreventativeCalendarItem _calendarItem({
  required GardenBed bed,
  required VegetableDefinition crop,
  required ProtectionTarget target,
  required Iterable<SprayRecord> records,
  required List<SprayProduct> products,
  required GardenRiskSummary? risks,
  required DateTime now,
  required BedSpraySummary hold,
}) {
  final targetId = _targetId(target);
  final last = _latestRecordForBedTarget(records, bed.number, targetId);
  final interval = _protectionInterval(target, crop, risks);
  final due = _dateOnly(
    last == null ? now : last.date.add(Duration(days: interval)),
  );
  final blocked = hold.onHold && target != ProtectionTarget.feed;
  final status = blocked
      ? ProtectionStatus.blocked
      : !due.isAfter(now)
          ? ProtectionStatus.due
          : due.difference(now).inDays <= 3
              ? ProtectionStatus.soon
              : ProtectionStatus.scheduled;
  final issues = target == ProtectionTarget.fungus
      ? crop.commonDiseases
      : target == ProtectionTarget.pest
          ? crop.commonPests
          : crop.maintenanceTips;
  final product = _bestProtectionProduct(
    products: products,
    target: target,
    crop: crop,
    issues: issues,
    avoidRecord: last,
  );

  return PreventativeCalendarItem(
    bed: bed,
    crop: crop,
    target: target,
    status: status,
    dueDate: due,
    intervalDays: interval,
    title: _calendarTitle(target, crop),
    body: _calendarBody(
      target: target,
      crop: crop,
      interval: interval,
      risks: risks,
      blocked: blocked,
      hold: hold,
    ),
    issues: issues,
    product: product,
    lastRecord: last,
  );
}

SprayRecord? _latestRecordForBedTarget(
  Iterable<SprayRecord> records,
  int bed,
  String targetId,
) {
  SprayRecord? latest;
  for (final record in records) {
    if (!record.beds.contains(bed) || record.targetId != targetId) continue;
    if (latest == null ||
        record.date.isAfter(latest.date) ||
        (record.date.isAtSameMomentAs(latest.date) && record.id > latest.id)) {
      latest = record;
    }
  }
  return latest;
}

int _protectionInterval(
  ProtectionTarget target,
  VegetableDefinition crop,
  GardenRiskSummary? risks,
) {
  if (target == ProtectionTarget.feed) {
    return _heavyFeeder(crop) ? 14 : 28;
  }
  if (target == ProtectionTarget.fungus) {
    return switch (risks?.pestPressureRisk) {
      GardenRiskLevel.high => 7,
      GardenRiskLevel.moderate => 10,
      _ => _fungusProne(crop) ? 14 : 21,
    };
  }
  return switch (risks?.pestPressureRisk) {
    GardenRiskLevel.high => 7,
    GardenRiskLevel.moderate => 10,
    _ => 14,
  };
}

SprayProduct? _bestProtectionProduct({
  required List<SprayProduct> products,
  required ProtectionTarget target,
  required VegetableDefinition crop,
  required List<String> issues,
  SprayRecord? avoidRecord,
}) {
  final targetId = _targetId(target);
  final scored = products
      .where((product) => product.targets.contains(targetId))
      .where(
        (product) =>
            avoidRecord == null ||
            product.id != avoidRecord.productId ||
            product.reSprayIntervalDays <= 0,
      )
      .map((product) => (
            product: product,
            score: _protectionProductScore(
              product,
              crop,
              issues,
            )
          ))
      .where((item) => item.score > 0)
      .toList(growable: false)
    ..sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.product.withholdingDays.compareTo(b.product.withholdingDays);
    });
  if (scored.isEmpty) return null;
  return scored.first.product;
}

List<SprayProduct> _productsForIssue({
  required List<SprayProduct> products,
  required ProtectionTarget target,
  required String issue,
  required List<VegetableDefinition> crops,
}) {
  final targetId = _targetId(target);
  final scored = products
      .where((product) => product.targets.contains(targetId))
      .map((product) {
        var score = _textScore(product.searchText, issue);
        for (final crop in crops.take(4)) {
          score += _textScore(product.searchText, crop.name);
          score +=
              _textScore(product.searchText, familyById(crop.familyId).name);
        }
        return (product: product, score: score);
      })
      .where((item) => item.score > 0)
      .toList(growable: false)
    ..sort((a, b) => b.score.compareTo(a.score));
  return scored.take(3).map((item) => item.product).toList(growable: false);
}

int _protectionProductScore(
  SprayProduct product,
  VegetableDefinition crop,
  List<String> issues,
) {
  var score = 0;
  final text = product.searchText;
  score += _textScore(text, crop.name) * 4;
  score += _textScore(text, familyById(crop.familyId).name) * 2;
  if (text.contains('vegetable')) score += 1;
  for (final issue in issues) {
    score += _textScore(text, issue) * 3;
  }
  return score;
}

int _textScore(String text, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return 0;
  if (text.contains(q)) return 3;
  return q
      .split(RegExp(r'\s+'))
      .where((part) => part.length > 3 && text.contains(part))
      .length;
}

String _calendarTitle(ProtectionTarget target, VegetableDefinition crop) =>
    switch (target) {
      ProtectionTarget.pest => 'Pest scout / spray check',
      ProtectionTarget.fungus => 'Fungus prevention check',
      ProtectionTarget.feed =>
        _heavyFeeder(crop) ? 'Feed check' : 'Soil support',
    };

String _calendarBody({
  required ProtectionTarget target,
  required VegetableDefinition crop,
  required int interval,
  required GardenRiskSummary? risks,
  required bool blocked,
  required BedSpraySummary hold,
}) {
  if (blocked) {
    return 'Bed is on withholding hold until ${shortDate(hold.record!.safeDate)}. Inspect only unless the label requires action.';
  }
  if (target == ProtectionTarget.feed) {
    return _heavyFeeder(crop)
        ? 'Top up compost or liquid feed roughly every $interval days while actively growing.'
        : 'Check colour and growth. Feed only if pale, slow, or soil is depleted.';
  }
  final pressure = risks?.pestPressureRisk == GardenRiskLevel.high
      ? 'High weather pressure: '
      : risks?.pestPressureRisk == GardenRiskLevel.moderate
          ? 'Moderate weather pressure: '
          : '';
  final issueText = (target == ProtectionTarget.fungus
          ? crop.commonDiseases
          : crop.commonPests)
      .take(3)
      .join(', ');
  return '$pressure inspect for $issueText every $interval days. Spray only when pressure or symptoms justify it.';
}

String _targetId(ProtectionTarget target) => switch (target) {
      ProtectionTarget.pest => 'pest',
      ProtectionTarget.fungus => 'fungus',
      ProtectionTarget.feed => 'maintain',
    };

String protectionTargetLabel(ProtectionTarget target) => switch (target) {
      ProtectionTarget.pest => 'Pest',
      ProtectionTarget.fungus => 'Fungus',
      ProtectionTarget.feed => 'Feed',
    };

bool _heavyFeeder(VegetableDefinition crop) => const {
      'solanaceae',
      'brassicas',
      'cucurbits',
      'corn_grasses',
    }.contains(crop.familyId);

bool _fungusProne(VegetableDefinition crop) => crop.commonDiseases.any(
      (disease) {
        final lower = disease.toLowerCase();
        return lower.contains('mildew') ||
            lower.contains('blight') ||
            lower.contains('rust') ||
            lower.contains('botrytis');
      },
    );

String _normalIssue(String issue) {
  final trimmed = issue.trim();
  if (trimmed.isEmpty) return 'Unknown';
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int _statusRank(ProtectionStatus status) => switch (status) {
      ProtectionStatus.due => 0,
      ProtectionStatus.blocked => 1,
      ProtectionStatus.soon => 2,
      ProtectionStatus.scheduled => 3,
    };
