part of '../../../main.dart';

class SprayIssueSuggestion {
  const SprayIssueSuggestion({
    required this.issue,
    required this.targetId,
    required this.crops,
    required this.score,
    this.product,
  });

  final String issue;
  final String targetId;
  final List<VegetableDefinition> crops;
  final int score;
  final SprayProduct? product;

  String get cropSummary =>
      crops.take(3).map((crop) => crop.name).join(', ') +
      (crops.length > 3 ? ' +${crops.length - 3}' : '');
}

class SprayCoverageSummary {
  const SprayCoverageSummary({
    required this.targetMatched,
    required this.coveredCrops,
    required this.unmatchedCrops,
  });

  final bool targetMatched;
  final List<VegetableDefinition> coveredCrops;
  final List<VegetableDefinition> unmatchedCrops;

  bool get coversAllCrops => unmatchedCrops.isEmpty;
}

class SprayRotationAdvice {
  const SprayRotationAdvice({
    required this.caution,
    required this.title,
    required this.body,
    this.nextAllowedDate,
  });

  final bool caution;
  final String title;
  final String body;
  final DateTime? nextAllowedDate;
}

List<SprayIssueSuggestion> buildSprayAgainstSuggestions({
  required Iterable<VegetableDefinition> crops,
  required String targetId,
  required List<SprayProduct> products,
  int limit = 8,
}) {
  final issueCrops = <String, Set<VegetableDefinition>>{};
  for (final crop in crops) {
    for (final issue in _issuesForSprayTarget(crop, targetId)) {
      final normal = _normalSprayIssue(issue);
      issueCrops.putIfAbsent(normal, () => <VegetableDefinition>{}).add(crop);
    }
  }

  final suggestions = [
    for (final entry in issueCrops.entries)
      SprayIssueSuggestion(
        issue: entry.key,
        targetId: targetId,
        crops: entry.value.toList()..sort((a, b) => a.name.compareTo(b.name)),
        product: bestSprayProductForIssue(
          targetId: targetId,
          issue: entry.key,
          crops: entry.value,
          products: products,
        ),
        score: _issueScore(
          issue: entry.key,
          crops: entry.value,
          products: products,
          targetId: targetId,
        ),
      ),
  ]..sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      final cropCount = b.crops.length.compareTo(a.crops.length);
      if (cropCount != 0) return cropCount;
      return a.issue.compareTo(b.issue);
    });

  return suggestions.take(limit).toList(growable: false);
}

SprayProduct? bestSprayProductForIssue({
  required String targetId,
  required String issue,
  required Iterable<VegetableDefinition> crops,
  required List<SprayProduct> products,
}) {
  final ranked = rankedSprayProductsForSpray(
    targetId: targetId,
    issue: issue,
    crops: crops,
    products: products,
  );
  return ranked.isEmpty ? null : ranked.first;
}

List<SprayProduct> rankedSprayProductsForSpray({
  required String targetId,
  required String issue,
  required Iterable<VegetableDefinition> crops,
  required List<SprayProduct> products,
}) {
  final scored = products
      .map(
        (product) => (
          product: product,
          score: _sprayProductScore(
            product: product,
            targetId: targetId,
            issue: issue,
            crops: crops,
          ),
        ),
      )
      .where((item) => item.score > 0)
      .toList(growable: false)
    ..sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      final whp = a.product.withholdingDays.compareTo(
        b.product.withholdingDays,
      );
      if (whp != 0) return whp;
      return a.product.name.compareTo(b.product.name);
    });
  return scored.map((item) => item.product).toList(growable: false);
}

SprayCoverageSummary summarizeSprayCoverage({
  required SprayProduct product,
  required String targetId,
  required Iterable<VegetableDefinition> crops,
}) {
  final targetMatched = _productMatchesSprayTarget(product, targetId);
  final covered = <VegetableDefinition>[];
  final unmatched = <VegetableDefinition>[];

  for (final crop in crops) {
    if (_sprayProductLikelyCoversCrop(product, crop)) {
      covered.add(crop);
    } else {
      unmatched.add(crop);
    }
  }

  return SprayCoverageSummary(
    targetMatched: targetMatched,
    coveredCrops: covered,
    unmatchedCrops: unmatched,
  );
}

SprayRotationAdvice? sprayRotationAdvice({
  required SprayProduct product,
  required Iterable<SprayRecord> records,
  required List<SprayProduct> products,
  required Iterable<int> beds,
  DateTime? now,
}) {
  final selectedBeds = beds.toSet();
  if (selectedBeds.isEmpty) return null;
  final today = now ?? DateTime.now();
  final selectedActive = product.activeIngredient.trim().toLowerCase();
  SprayRecord? latest;

  for (final record in records) {
    if (!record.beds.any(selectedBeds.contains)) continue;
    final previous = _sprayRecordProduct(record, products);
    final sameProduct = record.productId == product.id;
    final sameActive = selectedActive.isNotEmpty &&
        previous != null &&
        previous.activeIngredient.trim().toLowerCase() == selectedActive;
    if (!sameProduct && !sameActive) continue;
    if (latest == null ||
        record.date.isAfter(latest.date) ||
        (record.date.isAtSameMomentAs(latest.date) && record.id > latest.id)) {
      latest = record;
    }
  }

  if (latest == null) return null;
  final daysSince = today.difference(latest.date).inDays;
  final waitDays = product.reSprayIntervalDays;
  if (waitDays > 0 && daysSince < waitDays) {
    final nextAllowed = latest.date.add(Duration(days: waitDays));
    return SprayRotationAdvice(
      caution: true,
      title: 'Re-spray too soon',
      body:
          'Same product or active was logged $daysSince day${daysSince == 1 ? '' : 's'} ago. Wait until ${shortDate(nextAllowed)} unless the label says otherwise.',
      nextAllowedDate: nextAllowed,
    );
  }

  return SprayRotationAdvice(
    caution: false,
    title: 'Rotation check',
    body:
        'Same product or active was last used $daysSince day${daysSince == 1 ? '' : 's'} ago. Consider rotating if you are treating the same issue repeatedly.',
  );
}

Iterable<String> _issuesForSprayTarget(
  VegetableDefinition crop,
  String targetId,
) =>
    switch (targetId) {
      'fungus' => crop.commonDiseases,
      'maintain' => crop.maintenanceTips.isEmpty
          ? const ['Plant stress', 'General plant health']
          : crop.maintenanceTips,
      'prevent' => [
          ...crop.commonPests.take(2),
          ...crop.commonDiseases.take(2),
          ...crop.preventativeTips.take(2),
        ],
      _ => crop.commonPests,
    };

int _issueScore({
  required String issue,
  required Iterable<VegetableDefinition> crops,
  required List<SprayProduct> products,
  required String targetId,
}) {
  var score = crops.length * 4;
  for (final product in products) {
    if (!_productMatchesSprayTarget(product, targetId)) continue;
    score += _sprayTextScore(product.searchText, issue);
  }
  return score;
}

int _sprayProductScore({
  required SprayProduct product,
  required String targetId,
  required String issue,
  required Iterable<VegetableDefinition> crops,
}) {
  var score = 0;
  if (_productMatchesSprayTarget(product, targetId)) score += 8;
  score += _sprayTextScore(product.searchText, issue) * 5;
  for (final crop in crops) {
    score += _sprayTextScore(product.searchText, crop.name) * 3;
    score += _sprayTextScore(
      product.searchText,
      familyById(crop.familyId).name,
    );
    final cropIssues = [
      ...crop.commonPests,
      ...crop.commonDiseases,
      ...crop.maintenanceTips,
    ];
    for (final cropIssue in cropIssues.take(8)) {
      score += _sprayTextScore(product.searchText, cropIssue);
    }
  }
  if (product.withholdingDays == 0) score += 1;
  return score;
}

bool _productMatchesSprayTarget(SprayProduct product, String targetId) {
  if (targetId == 'prevent') {
    return product.targets
        .any((target) => target == 'pest' || target == 'fungus');
  }
  return product.targets.contains(targetId);
}

bool _sprayProductLikelyCoversCrop(
  SprayProduct product,
  VegetableDefinition crop,
) {
  final text = product.searchText;
  if (text.contains(crop.name.toLowerCase())) return true;
  if (text.contains(familyById(crop.familyId).name.toLowerCase())) return true;
  if (text.contains('vegetable') || text.contains('edible')) return true;
  final issues = [
    ...crop.commonPests,
    ...crop.commonDiseases,
    ...crop.maintenanceTips,
  ];
  return issues.any((issue) => _sprayTextScore(text, issue) > 0);
}

int _sprayTextScore(String text, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return 0;
  if (text.contains(q)) return 3;
  return q
      .split(RegExp(r'\s+'))
      .where((part) => part.length > 3 && text.contains(part))
      .length;
}

String _normalSprayIssue(String issue) {
  final trimmed = issue.trim();
  if (trimmed.isEmpty) return 'General check';
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}
