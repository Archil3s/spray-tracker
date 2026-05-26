part of '../../../main.dart';

enum PlantingRecommendationType {
  startIndoors,
  directSow,
  plantOut,
  wait,
  late,
}

String plantingRecommendationLabel(PlantingRecommendationType type) =>
    switch (type) {
      PlantingRecommendationType.startIndoors => 'Start indoors',
      PlantingRecommendationType.directSow => 'Direct sow',
      PlantingRecommendationType.plantOut => 'Plant out',
      PlantingRecommendationType.wait => 'Too early',
      PlantingRecommendationType.late => 'Late season',
    };

class CropCalendarRule {
  const CropCalendarRule({
    required this.cropId,
    required this.startIndoorsMonths,
    required this.directSowMonths,
    required this.plantOutMonths,
    required this.harvestMonths,
    required this.frostSensitive,
    required this.preferredStartMethod,
    required this.notes,
  });

  final String cropId;
  final List<int> startIndoorsMonths;
  final List<int> directSowMonths;
  final List<int> plantOutMonths;
  final List<int> harvestMonths;
  final bool frostSensitive;
  final String preferredStartMethod;
  final String notes;
}

class CropPlantingRecommendation {
  const CropPlantingRecommendation({
    required this.crop,
    required this.rule,
    required this.type,
    required this.action,
    required this.detail,
    required this.frostWarning,
  });

  final VegetableDefinition crop;
  final CropCalendarRule rule;
  final PlantingRecommendationType type;
  final String action;
  final String detail;
  final String frostWarning;
}

List<CropPlantingRecommendation> plantingRecommendationsForNow({
  required DateTime now,
  bool frostRisk = false,
}) {
  final month = now.month;
  final recommendations = <CropPlantingRecommendation>[];
  final rules = {for (final rule in cropCalendarRules) rule.cropId: rule};

  for (final crop in vegetableLibrary) {
    final rule = rules[crop.id] ?? fallbackCalendarRuleFor(crop);
    final type = _recommendationTypeFor(rule, month);
    final frostWarning = rule.frostSensitive && frostRisk
        ? 'Frost risk: keep protected until nights are warmer.'
        : '';
    recommendations.add(
      CropPlantingRecommendation(
        crop: crop,
        rule: rule,
        type: type,
        action: plantingRecommendationLabel(type),
        detail: _recommendationDetail(rule, type),
        frostWarning: frostWarning,
      ),
    );
  }

  recommendations.sort((a, b) {
    final priority = _recommendationPriority(a.type).compareTo(
      _recommendationPriority(b.type),
    );
    if (priority != 0) return priority;
    return a.crop.name.compareTo(b.crop.name);
  });
  return recommendations;
}

PlantingRecommendationType _recommendationTypeFor(
  CropCalendarRule rule,
  int month,
) {
  if (rule.startIndoorsMonths.contains(month)) {
    return PlantingRecommendationType.startIndoors;
  }
  if (rule.directSowMonths.contains(month)) {
    return PlantingRecommendationType.directSow;
  }
  if (rule.plantOutMonths.contains(month)) {
    return PlantingRecommendationType.plantOut;
  }

  final allPlantingMonths = [
    ...rule.startIndoorsMonths,
    ...rule.directSowMonths,
    ...rule.plantOutMonths,
  ];
  if (allPlantingMonths.isEmpty) return PlantingRecommendationType.wait;

  final nextPlanting = allPlantingMonths.any((item) => item > month);
  return nextPlanting
      ? PlantingRecommendationType.wait
      : PlantingRecommendationType.late;
}

int _recommendationPriority(PlantingRecommendationType type) => switch (type) {
      PlantingRecommendationType.startIndoors => 0,
      PlantingRecommendationType.directSow => 1,
      PlantingRecommendationType.plantOut => 2,
      PlantingRecommendationType.wait => 3,
      PlantingRecommendationType.late => 4,
    };

String _recommendationDetail(
  CropCalendarRule rule,
  PlantingRecommendationType type,
) =>
    switch (type) {
      PlantingRecommendationType.startIndoors =>
        'Use ${rule.preferredStartMethod.toLowerCase()} now. ${rule.notes}',
      PlantingRecommendationType.directSow => 'Sow direct now. ${rule.notes}',
      PlantingRecommendationType.plantOut =>
        'Plant sturdy seedlings into beds now. ${rule.notes}',
      PlantingRecommendationType.wait =>
        'Wait for the next planting window. ${rule.notes}',
      PlantingRecommendationType.late =>
        'Main planting window has likely passed. ${rule.notes}',
    };

CropCalendarRule fallbackCalendarRuleFor(VegetableDefinition crop) {
  final family = crop.familyId;
  if (family == 'brassicas') {
    return CropCalendarRule(
      cropId: crop.id,
      startIndoorsMonths: const [2, 3, 4, 8, 9],
      directSowMonths: const [3, 4, 8, 9, 10],
      plantOutMonths: const [4, 5, 9, 10],
      harvestMonths: const [5, 6, 7, 10, 11, 12],
      frostSensitive: false,
      preferredStartMethod: 'Tray',
      notes:
          'Cool-season crop. Use mesh if whitefly or caterpillars are active.',
    );
  }
  if (family == 'leafy_greens') {
    return CropCalendarRule(
      cropId: crop.id,
      startIndoorsMonths: const [2, 3, 4, 5, 8, 9, 10],
      directSowMonths: const [2, 3, 4, 5, 8, 9, 10],
      plantOutMonths: const [3, 4, 5, 9, 10, 11],
      harvestMonths: const [3, 4, 5, 6, 9, 10, 11, 12],
      frostSensitive: false,
      preferredStartMethod: 'Tray',
      notes: 'Best in cooler weather; use shade during heat.',
    );
  }
  if (family == 'cucurbits') {
    return CropCalendarRule(
      cropId: crop.id,
      startIndoorsMonths: const [9, 10, 11],
      directSowMonths: const [10, 11, 12],
      plantOutMonths: const [10, 11, 12],
      harvestMonths: const [12, 1, 2, 3],
      frostSensitive: true,
      preferredStartMethod: 'Pot',
      notes: 'Warm-season crop. Avoid cold soil and frost.',
    );
  }
  if (family == 'herbs') {
    return CropCalendarRule(
      cropId: crop.id,
      startIndoorsMonths: const [8, 9, 10, 11],
      directSowMonths: const [9, 10, 11, 12],
      plantOutMonths: const [10, 11, 12],
      harvestMonths: const [11, 12, 1, 2, 3, 4],
      frostSensitive: true,
      preferredStartMethod: 'Tray',
      notes: 'Most herbs prefer warmth and shelter while young.',
    );
  }
  return CropCalendarRule(
    cropId: crop.id,
    startIndoorsMonths: const [8, 9, 10],
    directSowMonths: const [9, 10, 11],
    plantOutMonths: const [10, 11, 12],
    harvestMonths: const [12, 1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Tray',
    notes: 'Use local weather and frost risk before planting out.',
  );
}

const cropCalendarRules = [
  CropCalendarRule(
    cropId: 'tomato',
    startIndoorsMonths: [8, 9, 10],
    directSowMonths: [],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [1, 2, 3, 4],
    frostSensitive: true,
    preferredStartMethod: 'Tray',
    notes: 'Start protected. Plant out only after frost risk has passed.',
  ),
  CropCalendarRule(
    cropId: 'chilli',
    startIndoorsMonths: [7, 8, 9],
    directSowMonths: [],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [1, 2, 3, 4],
    frostSensitive: true,
    preferredStartMethod: 'Heat mat',
    notes: 'Slow starter. Warmth improves germination.',
  ),
  CropCalendarRule(
    cropId: 'capsicum',
    startIndoorsMonths: [7, 8, 9],
    directSowMonths: [],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [1, 2, 3, 4],
    frostSensitive: true,
    preferredStartMethod: 'Heat mat',
    notes: 'Needs warmth and a long season.',
  ),
  CropCalendarRule(
    cropId: 'eggplant',
    startIndoorsMonths: [8, 9],
    directSowMonths: [],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Heat mat',
    notes: 'Needs warmth; avoid planting out early.',
  ),
  CropCalendarRule(
    cropId: 'lettuce',
    startIndoorsMonths: [2, 3, 4, 5, 8, 9, 10, 11],
    directSowMonths: [2, 3, 4, 5, 8, 9, 10, 11],
    plantOutMonths: [3, 4, 5, 9, 10, 11],
    harvestMonths: [3, 4, 5, 6, 9, 10, 11, 12],
    frostSensitive: false,
    preferredStartMethod: 'Tray',
    notes: 'Avoid the hottest weeks unless shaded.',
  ),
  CropCalendarRule(
    cropId: 'spinach',
    startIndoorsMonths: [2, 3, 4, 8, 9, 10],
    directSowMonths: [2, 3, 4, 8, 9, 10],
    plantOutMonths: [3, 4, 5, 9, 10],
    harvestMonths: [4, 5, 6, 10, 11, 12],
    frostSensitive: false,
    preferredStartMethod: 'Tray',
    notes: 'Cool-season crop; may bolt in heat.',
  ),
  CropCalendarRule(
    cropId: 'carrot',
    startIndoorsMonths: [],
    directSowMonths: [2, 3, 4, 5, 8, 9, 10, 11],
    plantOutMonths: [],
    harvestMonths: [4, 5, 6, 7, 10, 11, 12],
    frostSensitive: false,
    preferredStartMethod: 'Direct sow',
    notes: 'Direct sow only; avoid transplanting.',
  ),
  CropCalendarRule(
    cropId: 'beetroot',
    startIndoorsMonths: [2, 3, 4, 8, 9, 10],
    directSowMonths: [2, 3, 4, 8, 9, 10],
    plantOutMonths: [3, 4, 5, 9, 10],
    harvestMonths: [4, 5, 6, 10, 11, 12],
    frostSensitive: false,
    preferredStartMethod: 'Cell tray',
    notes: 'Can be sown direct or started in cells.',
  ),
  CropCalendarRule(
    cropId: 'bean',
    startIndoorsMonths: [9, 10],
    directSowMonths: [10, 11, 12, 1],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [12, 1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Direct sow',
    notes: 'Needs warm soil; direct sow after frost.',
  ),
  CropCalendarRule(
    cropId: 'pea',
    startIndoorsMonths: [2, 3, 4, 8, 9],
    directSowMonths: [2, 3, 4, 8, 9],
    plantOutMonths: [3, 4, 9, 10],
    harvestMonths: [4, 5, 6, 10, 11],
    frostSensitive: false,
    preferredStartMethod: 'Direct sow',
    notes: 'Cool-season crop; protect young seedlings from birds.',
  ),
  CropCalendarRule(
    cropId: 'zucchini',
    startIndoorsMonths: [9, 10, 11],
    directSowMonths: [10, 11, 12],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [12, 1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Pot',
    notes: 'Warm-season crop; start in pots for quick plant-out.',
  ),
  CropCalendarRule(
    cropId: 'cucumber',
    startIndoorsMonths: [9, 10, 11],
    directSowMonths: [10, 11, 12],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [12, 1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Pot',
    notes: 'Warmth and steady moisture are important.',
  ),
  CropCalendarRule(
    cropId: 'pumpkin',
    startIndoorsMonths: [9, 10, 11],
    directSowMonths: [10, 11, 12],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [2, 3, 4],
    frostSensitive: true,
    preferredStartMethod: 'Pot',
    notes: 'Needs space and a long warm season.',
  ),
  CropCalendarRule(
    cropId: 'basil',
    startIndoorsMonths: [9, 10, 11],
    directSowMonths: [10, 11, 12],
    plantOutMonths: [11, 12],
    harvestMonths: [12, 1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Tray',
    notes: 'Very frost sensitive. Keep warm and sheltered.',
  ),
];
