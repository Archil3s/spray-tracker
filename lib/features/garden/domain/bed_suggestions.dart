part of '../../../main.dart';

enum BedSuggestionLevel { info, due, warning }

enum BedSuggestionKind { log, spray, feed, rotate, protect }

class BedSuggestion {
  const BedSuggestion({
    required this.kind,
    required this.level,
    required this.title,
    required this.body,
    this.product,
  });

  final BedSuggestionKind kind;
  final BedSuggestionLevel level;
  final String title;
  final String body;
  final SprayProduct? product;
}

List<BedSuggestion> bedActionSuggestions({
  required GardenBed bed,
  required List<VegetableDefinition> crops,
  required Iterable<SprayRecord> records,
  required List<SprayProduct> products,
  GardenRiskSummary? risks,
  DateTime? now,
}) {
  final checkedAt = now ?? DateTime.now();
  final suggestions = <BedSuggestion>[];
  final spray = bedSpraySummary(records, bed.number, now: checkedAt);

  if (crops.isEmpty) {
    suggestions.add(
      const BedSuggestion(
        kind: BedSuggestionKind.log,
        level: BedSuggestionLevel.due,
        title: 'Log what is in this bed',
        body:
            'Add the vegetables currently growing here so spray holds, feeding, and rotation advice can be targeted.',
      ),
    );
    return suggestions;
  }

  if (risks?.frostRisk == GardenRiskLevel.high) {
    suggestions.add(
      const BedSuggestion(
        kind: BedSuggestionKind.protect,
        level: BedSuggestionLevel.warning,
        title: 'Frost protection needed',
        body:
            'Avoid spraying or feeding before a frost. Cover tender crops and water soil earlier in the day if dry.',
      ),
    );
  }

  if (spray.onHold) {
    suggestions.add(
      BedSuggestion(
        kind: BedSuggestionKind.spray,
        level: BedSuggestionLevel.warning,
        title: 'Do not re-spray yet',
        body:
            'This bed is on withholding hold until ${shortDate(spray.record!.safeDate)} unless the product label says otherwise.',
      ),
    );
  } else {
    final spraySuggestion = _spraySuggestion(
      crops: crops,
      products: products,
      latestRecord: spray.record,
      risks: risks,
      now: checkedAt,
    );
    if (spraySuggestion != null) suggestions.add(spraySuggestion);
  }

  suggestions.add(
    _feedingSuggestion(
      crops: crops,
      products: products,
      risks: risks,
    ),
  );
  suggestions.add(_rotationSuggestion(crops));

  return suggestions;
}

BedSuggestion? _spraySuggestion({
  required List<VegetableDefinition> crops,
  required List<SprayProduct> products,
  required SprayRecord? latestRecord,
  required GardenRiskSummary? risks,
  required DateTime now,
}) {
  final latestProduct = latestRecord == null
      ? null
      : _productById(products, latestRecord.productId);
  if (latestRecord != null && latestProduct?.reSprayIntervalDays != null) {
    final interval = latestProduct!.reSprayIntervalDays;
    if (interval > 0) {
      final dueDate = latestRecord.date.add(Duration(days: interval));
      if (dueDate.isAfter(now)) {
        return BedSuggestion(
          kind: BedSuggestionKind.spray,
          level: BedSuggestionLevel.info,
          title: 'No spray due yet',
          body:
              'Last spray was ${shortDate(latestRecord.date)}. Re-check from ${shortDate(dueDate)} based on the product interval.',
          product: latestProduct,
        );
      }

      final rotated = _bestProductForCrops(
        crops: crops,
        products: products,
        targetId: latestRecord.targetId,
        avoidRecord: latestRecord,
      );
      return BedSuggestion(
        kind: BedSuggestionKind.rotate,
        level: BedSuggestionLevel.due,
        title: 'Rotate spray mode',
        body: rotated == null
            ? 'A re-spray check is due. Inspect the bed and avoid repeating the same active ingredient unless the label requires it.'
            : 'A re-spray check is due. Consider ${rotated.name} if symptoms still justify treatment.',
        product: rotated,
      );
    }
  }

  final highPestPressure = risks?.pestPressureRisk == GardenRiskLevel.high;
  final highDiseaseWeather = risks?.pestPressureRisk == GardenRiskLevel.high &&
      (risks?.rainNext24HoursMm ?? 0) > 0;
  if (highDiseaseWeather) {
    final product = _bestProductForCrops(
      crops: crops,
      products: products,
      targetId: 'fungus',
      avoidRecord: latestRecord,
    );
    return BedSuggestion(
      kind: BedSuggestionKind.spray,
      level: BedSuggestionLevel.due,
      title: 'Disease pressure check',
      body: product == null
          ? 'Wet mild weather raises fungal risk. Inspect leaves before choosing a product.'
          : 'Wet mild weather raises fungal risk. Inspect leaves; ${product.name} may fit if disease is present.',
      product: product,
    );
  }

  if (highPestPressure || latestRecord == null) {
    final product = _bestProductForCrops(
      crops: crops,
      products: products,
      targetId: 'pest',
      avoidRecord: latestRecord,
    );
    return BedSuggestion(
      kind: BedSuggestionKind.spray,
      level:
          highPestPressure ? BedSuggestionLevel.due : BedSuggestionLevel.info,
      title: highPestPressure ? 'Pest pressure check' : 'Scout before spraying',
      body: product == null
          ? 'Check leaf undersides and new growth. Only spray when pests or disease are actually present.'
          : 'Check leaf undersides and new growth. If treatment is needed, ${product.name} is a likely match.',
      product: product,
    );
  }

  return null;
}

BedSuggestion _feedingSuggestion({
  required List<VegetableDefinition> crops,
  required List<SprayProduct> products,
  required GardenRiskSummary? risks,
}) {
  final heavyFeeders = crops
      .where(
        (crop) => const {
          'solanaceae',
          'brassicas',
          'cucurbits',
          'corn_grasses',
        }.contains(crop.familyId),
      )
      .toList(growable: false);
  final product = _bestFeedingProduct(products);
  final dry = risks?.soilEvaporationRisk == GardenRiskLevel.high ||
      risks?.soilEvaporationRisk == GardenRiskLevel.moderate;

  if (heavyFeeders.isNotEmpty) {
    return BedSuggestion(
      kind: BedSuggestionKind.feed,
      level: dry ? BedSuggestionLevel.due : BedSuggestionLevel.info,
      title: 'Feed heavy feeders',
      body:
          '${_cropListText(heavyFeeders)} will use more nutrients. Apply compost or liquid feed, then water in well${dry ? ' because soil drying risk is elevated' : ''}.',
      product: product,
    );
  }

  return BedSuggestion(
    kind: BedSuggestionKind.feed,
    level: dry ? BedSuggestionLevel.due : BedSuggestionLevel.info,
    title: dry ? 'Water before feeding' : 'Light feeding only',
    body: dry
        ? 'Soil drying risk is elevated. Water the bed before adding liquid feed or compost tea.'
        : 'Use compost top-up or a light liquid feed only if growth is pale or slow.',
    product: product,
  );
}

BedSuggestion _rotationSuggestion(List<VegetableDefinition> crops) {
  final familyNames = crops
      .map((crop) => familyById(crop.familyId).name)
      .toSet()
      .toList(growable: false)
    ..sort();
  return BedSuggestion(
    kind: BedSuggestionKind.rotate,
    level: BedSuggestionLevel.info,
    title: 'Next-season rotation',
    body:
        'After harvest, rotate away from ${familyNames.join(', ')} in this bed to reduce soil disease and pest carry-over.',
  );
}

SprayProduct? _bestProductForCrops({
  required List<VegetableDefinition> crops,
  required List<SprayProduct> products,
  required String targetId,
  SprayRecord? avoidRecord,
}) {
  final scored = products
      .where((product) => product.targets.contains(targetId))
      .where(
        (product) =>
            avoidRecord == null ||
            (product.id != avoidRecord.productId &&
                product.activeIngredient.toLowerCase() !=
                    _productActiveIngredient(products, avoidRecord)
                        .toLowerCase()),
      )
      .map(
        (product) => (
          product: product,
          score: _productCropScore(product, crops),
        ),
      )
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

SprayProduct? _bestFeedingProduct(List<SprayProduct> products) {
  final candidates = products.where((product) {
    final text =
        '${product.name} ${product.type} ${product.commonUses.join(' ')} ${product.notes}'
            .toLowerCase();
    return product.targets.contains('maintain') ||
        text.contains('feed') ||
        text.contains('fert') ||
        text.contains('tonic') ||
        text.contains('seaweed');
  }).toList(growable: false)
    ..sort((a, b) => a.withholdingDays.compareTo(b.withholdingDays));
  if (candidates.isEmpty) return null;
  return candidates.first;
}

SprayProduct? _productById(List<SprayProduct> products, String productId) {
  for (final product in products) {
    if (product.id == productId) return product;
  }
  return null;
}

String _productActiveIngredient(
  List<SprayProduct> products,
  SprayRecord record,
) =>
    _productById(products, record.productId)?.activeIngredient ??
    record.product;

int _productCropScore(SprayProduct product, List<VegetableDefinition> crops) {
  final text = [
    product.name,
    product.type,
    product.activeIngredient,
    product.category,
    ...product.commonUses,
    ...product.suitableCrops,
  ].join(' ').toLowerCase();
  var score = 0;
  if (text.contains('vegetable')) score += 1;
  for (final crop in crops) {
    if (text.contains(crop.name.toLowerCase())) score += 6;
    if (text.contains(familyById(crop.familyId).name.toLowerCase())) score += 3;
    for (final pest in crop.commonPests) {
      if (text.contains(pest.toLowerCase())) score += 2;
    }
    for (final disease in crop.commonDiseases) {
      if (text.contains(disease.toLowerCase())) score += 2;
    }
  }
  return score;
}

String _cropListText(List<VegetableDefinition> crops) {
  final names = crops.map((crop) => crop.name).toList(growable: false);
  if (names.length <= 2) return names.join(' and ');
  return '${names.take(2).join(', ')} and ${names.length - 2} more';
}
