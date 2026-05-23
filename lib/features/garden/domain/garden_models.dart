part of '../../../main.dart';

class GardenPlot {
  const GardenPlot({
    required this.widthMeters,
    required this.lengthMeters,
  });

  final double widthMeters;
  final double lengthMeters;

  String get sizeLabel =>
      '${meterLabel(widthMeters)} x ${meterLabel(lengthMeters)} m';
}

const defaultGardenPlot = GardenPlot(
  widthMeters: gardenMapWidthMeters,
  lengthMeters: gardenMapLengthMeters,
);

class GardenBed {
  const GardenBed(
    this.number,
    this.rect, {
    this.name = '',
    double? widthMeters,
    double? lengthMeters,
  })  : _widthMeters = widthMeters,
        _lengthMeters = lengthMeters;
  final int number;
  final Rect rect;
  final String name;
  final double? _widthMeters;
  final double? _lengthMeters;

  String get label => name.trim().isEmpty ? 'Bed $number' : name.trim();
  double get widthMeters => _widthMeters ?? rect.width * gardenMapWidthMeters;
  double get lengthMeters =>
      _lengthMeters ?? rect.height * gardenMapLengthMeters;
  String get sizeLabel =>
      '${meterLabel(widthMeters)} x ${meterLabel(lengthMeters)} m';

  GardenBed copyWith({
    Rect? rect,
    String? name,
    double? widthMeters,
    double? lengthMeters,
  }) =>
      GardenBed(
        number,
        rect ?? this.rect,
        name: name ?? this.name,
        widthMeters: widthMeters ?? _widthMeters,
        lengthMeters: lengthMeters ?? _lengthMeters,
      );

  GardenBed move(Offset delta) {
    final left = (rect.left + delta.dx).clamp(0.01, 0.99 - rect.width);
    final top = (rect.top + delta.dy).clamp(0.01, 0.99 - rect.height);
    return copyWith(rect: Rect.fromLTWH(left, top, rect.width, rect.height));
  }

  GardenBed resize(
    Offset delta, {
    GardenPlot plot = defaultGardenPlot,
  }) {
    final width = (rect.width + delta.dx).clamp(0.07, 0.99 - rect.left);
    final height = (rect.height + delta.dy).clamp(0.045, 0.99 - rect.top);
    return copyWith(
      rect: Rect.fromLTWH(rect.left, rect.top, width, height),
      widthMeters: width * plot.widthMeters,
      lengthMeters: height * plot.lengthMeters,
    );
  }

  GardenBed sizeToMeters(
    double widthMeters,
    double lengthMeters, {
    GardenPlot plot = defaultGardenPlot,
  }) {
    final width = (widthMeters / plot.widthMeters).clamp(0.01, 0.98);
    final height = (lengthMeters / plot.lengthMeters).clamp(0.01, 0.98);
    final left = rect.left.clamp(0.01, 0.99 - width);
    final top = rect.top.clamp(0.01, 0.99 - height);
    return copyWith(
      rect: Rect.fromLTWH(left, top, width, height),
      widthMeters: width * plot.widthMeters,
      lengthMeters: height * plot.lengthMeters,
    );
  }

  GardenBed rotate({GardenPlot plot = defaultGardenPlot}) =>
      sizeToMeters(lengthMeters, widthMeters, plot: plot);
}

class GardenPlant {
  const GardenPlant({
    required this.id,
    required this.bed,
    required this.crop,
    required this.position,
  });

  final int id;
  final int bed;
  final VegetableDefinition crop;
  final Offset position;

  GardenPlant copyWith({Offset? position}) => GardenPlant(
        id: id,
        bed: bed,
        crop: crop,
        position: _boundedPlantPosition(position ?? this.position),
      );
}

Offset _boundedPlantPosition(Offset position) => Offset(
      position.dx.clamp(.05, .95).toDouble(),
      position.dy.clamp(.08, .92).toDouble(),
    );

Offset defaultPlantPosition(int index) {
  const columns = 4;
  final column = index % columns;
  final row = (index ~/ columns) % 3;
  return Offset(.18 + column * .21, .25 + row * .25);
}

class CropSpacing {
  const CropSpacing({
    required this.plantCm,
    required this.rowCm,
    required this.source,
  });

  final double plantCm;
  final double rowCm;
  final String source;

  String get label =>
      '${meterLabel(plantCm)} cm plants | ${meterLabel(rowCm)} cm rows';
}

enum AutoBedFoodStyle {
  quick,
  balanced,
  longHold,
  salad,
}

enum GardenSeason {
  spring,
  summer,
  autumn,
  winter,
}

extension GardenSeasonDetails on GardenSeason {
  String get label => switch (this) {
        GardenSeason.spring => 'Spring',
        GardenSeason.summer => 'Summer',
        GardenSeason.autumn => 'Autumn',
        GardenSeason.winter => 'Winter',
      };
}

GardenSeason gardenSeasonForDate(DateTime date) => switch (date.month) {
      12 || 1 || 2 => GardenSeason.summer,
      3 || 4 || 5 => GardenSeason.autumn,
      6 || 7 || 8 => GardenSeason.winter,
      _ => GardenSeason.spring,
    };

const Map<GardenSeason, Set<String>> seasonalCropIds = {
  GardenSeason.spring: {
    'tomato',
    'capsicum',
    'chilli',
    'eggplant',
    'cucumber',
    'zucchini',
    'beans',
    'peas',
    'lettuce',
    'spinach',
    'silverbeet',
    'carrot',
    'beetroot',
    'radish',
    'spring_onion',
    'parsley',
    'coriander',
    'chives',
    'basil',
    'mint',
    'oregano',
    'rosemary',
    'sage',
    'thyme',
    'dill',
    'strawberry',
  },
  GardenSeason.summer: {
    'tomato',
    'capsicum',
    'chilli',
    'eggplant',
    'cucumber',
    'zucchini',
    'pumpkin',
    'melon',
    'beans',
    'lettuce',
    'silverbeet',
    'carrot',
    'beetroot',
    'radish',
    'spring_onion',
    'parsley',
    'chives',
    'basil',
    'mint',
    'oregano',
    'rosemary',
    'sage',
    'thyme',
    'dill',
    'strawberry',
  },
  GardenSeason.autumn: {
    'lettuce',
    'spinach',
    'silverbeet',
    'rocket',
    'bok_choy',
    'broccoli',
    'cauliflower',
    'cabbage',
    'kale',
    'carrot',
    'beetroot',
    'radish',
    'onion',
    'garlic',
    'leek',
    'spring_onion',
    'peas',
    'broad_beans',
    'celery',
    'parsley',
    'coriander',
    'chives',
    'mint',
    'oregano',
    'rosemary',
    'sage',
    'thyme',
    'dill',
    'strawberry',
  },
  GardenSeason.winter: {
    'lettuce',
    'spinach',
    'silverbeet',
    'rocket',
    'bok_choy',
    'broccoli',
    'cauliflower',
    'cabbage',
    'kale',
    'carrot',
    'beetroot',
    'radish',
    'onion',
    'garlic',
    'leek',
    'spring_onion',
    'peas',
    'broad_beans',
    'celery',
    'parsley',
    'coriander',
    'chives',
    'mint',
    'rosemary',
    'sage',
    'thyme',
  },
};

extension AutoBedFoodStyleDetails on AutoBedFoodStyle {
  String get label => switch (this) {
        AutoBedFoodStyle.quick => 'Quick turnover',
        AutoBedFoodStyle.balanced => 'Balanced',
        AutoBedFoodStyle.longHold => 'Long holds',
        AutoBedFoodStyle.salad => 'Fresh eating',
      };

  String get shortLabel => switch (this) {
        AutoBedFoodStyle.quick => 'Quick',
        AutoBedFoodStyle.balanced => 'Mixed',
        AutoBedFoodStyle.longHold => 'Store',
        AutoBedFoodStyle.salad => 'Salad',
      };
}

class AutoBedCropWeight {
  const AutoBedCropWeight(this.cropId, this.weight);

  final String cropId;
  final double weight;
}

class AutoBedPlanResult {
  const AutoBedPlanResult(this.placements);

  final Map<VegetableDefinition, List<Offset>> placements;

  int get totalPlants => placements.values.fold(
        0,
        (total, positions) => total + positions.length,
      );

  List<VegetableDefinition> get crops => placements.keys.toList();
}

List<AutoBedCropWeight> autoBedCropMix(AutoBedFoodStyle style) =>
    switch (style) {
      AutoBedFoodStyle.quick => const [
          AutoBedCropWeight('lettuce', 3),
          AutoBedCropWeight('radish', 3),
          AutoBedCropWeight('carrot', 2),
          AutoBedCropWeight('spring_onion', 2),
          AutoBedCropWeight('spinach', 2),
          AutoBedCropWeight('bok_choy', 2),
          AutoBedCropWeight('rocket', 2),
        ],
      AutoBedFoodStyle.balanced => const [
          AutoBedCropWeight('tomato', 2),
          AutoBedCropWeight('lettuce', 2),
          AutoBedCropWeight('carrot', 2),
          AutoBedCropWeight('beans', 2),
          AutoBedCropWeight('broccoli', 1.4),
          AutoBedCropWeight('spring_onion', 1.3),
          AutoBedCropWeight('silverbeet', 1.2),
        ],
      AutoBedFoodStyle.longHold => const [
          AutoBedCropWeight('potato', 3),
          AutoBedCropWeight('onion', 3),
          AutoBedCropWeight('garlic', 2.2),
          AutoBedCropWeight('leek', 2),
          AutoBedCropWeight('cabbage', 1.8),
          AutoBedCropWeight('carrot', 1.6),
          AutoBedCropWeight('beetroot', 1.6),
        ],
      AutoBedFoodStyle.salad => const [
          AutoBedCropWeight('lettuce', 3),
          AutoBedCropWeight('tomato', 2),
          AutoBedCropWeight('cucumber', 1.8),
          AutoBedCropWeight('capsicum', 1.5),
          AutoBedCropWeight('carrot', 1.8),
          AutoBedCropWeight('radish', 1.8),
          AutoBedCropWeight('spring_onion', 1.4),
          AutoBedCropWeight('basil', 1),
        ],
    };

List<String> companionCropIdsFor(String cropId) => switch (cropId) {
      'tomato' => const ['basil', 'parsley', 'chives', 'lettuce', 'carrot'],
      'capsicum' || 'chilli' || 'eggplant' => const [
          'basil',
          'parsley',
          'chives',
          'lettuce',
        ],
      'cucumber' || 'zucchini' => const [
          'radish',
          'spring_onion',
          'lettuce',
        ],
      'broccoli' ||
      'cauliflower' ||
      'cabbage' ||
      'kale' ||
      'bok_choy' =>
        const ['onion', 'celery', 'spinach'],
      'carrot' || 'parsnip' => const ['onion', 'leek', 'chives', 'lettuce'],
      'lettuce' || 'spinach' || 'silverbeet' => const [
          'carrot',
          'radish',
          'spring_onion',
          'chives',
        ],
      'beans' || 'peas' || 'broad_beans' => const [
          'carrot',
          'radish',
          'lettuce',
        ],
      'potato' => const ['beans', 'cabbage'],
      'strawberry' => const ['chives', 'lettuce'],
      'basil' ||
      'oregano' ||
      'rosemary' ||
      'sage' ||
      'thyme' ||
      'dill' ||
      'mint' =>
        const ['tomato', 'capsicum', 'lettuce'],
      _ => const <String>[],
    };

List<AutoBedCropWeight> companionAwareAutoBedCropMix(
  AutoBedFoodStyle style,
) {
  final weights = <String, double>{};
  void add(String cropId, double weight) {
    if (vegetableLibrary.any((crop) => crop.id == cropId)) {
      weights[cropId] = (weights[cropId] ?? 0) + weight;
    }
  }

  final base = autoBedCropMix(style);
  for (final item in base) {
    add(item.cropId, item.weight);
  }

  for (final item in base.take(5)) {
    for (final companionId in companionCropIdsFor(item.cropId).take(3)) {
      add(companionId, .48);
    }
  }

  return weights.entries
      .map((entry) => AutoBedCropWeight(entry.key, entry.value))
      .toList(growable: false)
    ..sort((a, b) => b.weight.compareTo(a.weight));
}

int cropHeightScore(VegetableDefinition crop) => switch (crop.id) {
      'peas' ||
      'beans' ||
      'broad_beans' ||
      'tomato' ||
      'cucumber' ||
      'sweetcorn' ||
      'raspberry' ||
      'blueberry' =>
        4,
      'broccoli' ||
      'cauliflower' ||
      'cabbage' ||
      'kale' ||
      'silverbeet' ||
      'celery' ||
      'leek' =>
        3,
      'bok_choy' ||
      'capsicum' ||
      'chilli' ||
      'eggplant' ||
      'potato' ||
      'parsley' ||
      'coriander' =>
        2,
      'lettuce' || 'spinach' || 'rocket' || 'strawberry' || 'chives' => 1,
      _ => 0,
    };

AutoBedPlanResult generateAutoBedPlan({
  required GardenBed bed,
  required AutoBedFoodStyle style,
  required Iterable<GardenPlant> existingPlants,
  required CropSpacing Function(VegetableDefinition crop) spacingForCrop,
  required CropSpacing Function(GardenPlant plant) spacingForPlant,
  DateTime? seasonDate,
}) {
  final season = gardenSeasonForDate(seasonDate ?? DateTime.now());
  final seasonal =
      seasonalCropIds[season] ?? seasonalCropIds[GardenSeason.autumn]!;
  final bedArea = bed.widthMeters * bed.lengthMeters;
  final maxCropTypes = bedArea < 1.4
      ? 3
      : bedArea < 2.8
          ? 4
          : 6;
  final mix = companionAwareAutoBedCropMix(style)
      .where((item) => seasonal.contains(item.cropId))
      .map(
        (item) => (
          crop: vegetableLibrary.firstWhere(
            (crop) => crop.id == item.cropId,
            orElse: () => vegetableLibrary.first,
          ),
          weight: item.weight,
        ),
      )
      .where((item) =>
          item.crop.id != vegetableLibrary.first.id ||
          mixContainsCropId(style, vegetableLibrary.first.id))
      .where((item) {
        final spacing = spacingForCrop(item.crop);
        if (style == AutoBedFoodStyle.longHold) return true;
        return bed.lengthMeters >= 1 || spacing.plantCm <= 35;
      })
      .take(maxCropTypes)
      .toList(growable: false)
    ..sort((a, b) {
      final height = cropHeightScore(a.crop).compareTo(cropHeightScore(b.crop));
      if (height != 0) return height;
      return b.weight.compareTo(a.weight);
    });
  if (mix.isEmpty) return const AutoBedPlanResult({});

  const utilization = 1.0;
  final weightTotal = mix.fold<double>(
    0,
    (total, item) => total + item.weight,
  );
  final planned = <GardenPlant>[...existingPlants];
  final placements = <VegetableDefinition, List<Offset>>{};
  var ghostId = -1;
  var sectionStart = 0.0;

  for (final item in mix) {
    final sectionShare = item.weight / weightTotal;
    final sectionEnd = (sectionStart + sectionShare).clamp(0.0, 1.0);
    final spacing = spacingForCrop(item.crop);
    final grid = plantingGridPositions(bed, spacing);
    final minBandFraction =
        (spacing.rowCm / 100 / bed.lengthMeters).clamp(.04, .18).toDouble();
    final sectionCenter = (sectionStart + sectionEnd) / 2;
    final bandStart =
        (sectionStart < .0001 ? 0.0 : sectionCenter - minBandFraction / 2)
            .clamp(0.0, 1.0);
    final bandEnd =
        (sectionEnd > .9999 ? 1.0 : sectionCenter + minBandFraction / 2)
            .clamp(0.0, 1.0);
    final sectionGrid = grid
        .where(
          (spot) => spot.dy >= bandStart - .0001 && spot.dy <= bandEnd + .0001,
        )
        .toList(growable: false);
    var open = openPlantGridSpots(
      bed,
      sectionGrid,
      spacing,
      planned,
      (plant) =>
          plant.id < 0 ? spacingForCrop(plant.crop) : spacingForPlant(plant),
    )..sort((a, b) {
        final row = a.dy.compareTo(b.dy);
        return row == 0 ? a.dx.compareTo(b.dx) : row;
      });
    sectionStart = sectionEnd;
    if (open.isEmpty) continue;

    final target = (open.length * utilization).round();
    final count = target.clamp(1, open.length).toInt();
    final positions = open.take(count).map(_boundedPlantPosition).toList();
    if (positions.isEmpty) continue;

    placements[item.crop] = positions;
    planned.addAll(
      positions.map(
        (position) => GardenPlant(
          id: ghostId--,
          bed: bed.number,
          crop: item.crop,
          position: position,
        ),
      ),
    );
  }

  return AutoBedPlanResult(placements);
}

bool mixContainsCropId(AutoBedFoodStyle style, String cropId) =>
    autoBedCropMix(style).any((item) => item.cropId == cropId);

CropSpacing cropSpacingFor(
  VegetableDefinition crop, [
  OpenFarmCrop? profile,
]) {
  final fallback = _fallbackCropSpacing(crop);
  final plantCm = profile?.spread;
  final rowCm = profile?.rowSpacing;
  if (plantCm != null && plantCm > 0) {
    final resolvedPlantCm =
        plantCm < fallback.plantCm ? fallback.plantCm : plantCm;
    final profileRowCm = rowCm != null && rowCm > 0 ? rowCm : plantCm;
    final resolvedRowCm =
        profileRowCm < fallback.rowCm ? fallback.rowCm : profileRowCm;
    return CropSpacing(
      plantCm: resolvedPlantCm,
      rowCm: resolvedRowCm,
      source: 'OpenFarm',
    );
  }
  return fallback;
}

CropSpacing _fallbackCropSpacing(VegetableDefinition crop) {
  final special = switch (crop.id) {
    'carrot' || 'radish' => const CropSpacing(
        plantCm: 8,
        rowCm: 20,
        source: 'Garden guide',
      ),
    'onion' || 'garlic' || 'spring_onion' => const CropSpacing(
        plantCm: 12,
        rowCm: 25,
        source: 'Garden guide',
      ),
    'pumpkin' || 'watermelon' => const CropSpacing(
        plantCm: 120,
        rowCm: 180,
        source: 'Garden guide',
      ),
    'strawberry' => const CropSpacing(
        plantCm: 30,
        rowCm: 45,
        source: 'Garden guide',
      ),
    _ => null,
  };
  if (special != null) return special;

  return switch (crop.familyId) {
    'solanaceae' => const CropSpacing(
        plantCm: 50,
        rowCm: 70,
        source: 'Garden guide',
      ),
    'brassicas' => const CropSpacing(
        plantCm: 45,
        rowCm: 60,
        source: 'Garden guide',
      ),
    'alliums' => const CropSpacing(
        plantCm: 15,
        rowCm: 25,
        source: 'Garden guide',
      ),
    'cucurbits' => const CropSpacing(
        plantCm: 75,
        rowCm: 100,
        source: 'Garden guide',
      ),
    'legumes' => const CropSpacing(
        plantCm: 20,
        rowCm: 45,
        source: 'Garden guide',
      ),
    'leafy_greens' => const CropSpacing(
        plantCm: 25,
        rowCm: 30,
        source: 'Garden guide',
      ),
    'root_vegetables' => const CropSpacing(
        plantCm: 12,
        rowCm: 25,
        source: 'Garden guide',
      ),
    'apiaceae' => const CropSpacing(
        plantCm: 25,
        rowCm: 35,
        source: 'Garden guide',
      ),
    'corn_grasses' => const CropSpacing(
        plantCm: 30,
        rowCm: 75,
        source: 'Garden guide',
      ),
    'berries' => const CropSpacing(
        plantCm: 60,
        rowCm: 90,
        source: 'Garden guide',
      ),
    'herbs' => const CropSpacing(
        plantCm: 25,
        rowCm: 30,
        source: 'Garden guide',
      ),
    _ => const CropSpacing(
        plantCm: 35,
        rowCm: 45,
        source: 'Garden guide',
      ),
  };
}

List<Offset> plantingGridPositions(GardenBed bed, CropSpacing spacing) {
  final columns = _gridAxisPositions(bed.widthMeters, spacing.plantCm);
  final rows = _gridAxisPositions(bed.lengthMeters, spacing.rowCm);
  return [
    for (final row in rows)
      for (final column in columns) Offset(column, row),
  ];
}

List<double> _gridAxisPositions(double sizeMeters, double spacingCm) {
  final stepMeters = spacingCm / 100;
  if (sizeMeters <= 0 || stepMeters <= 0 || sizeMeters <= stepMeters) {
    return const [.5];
  }
  final count = (sizeMeters / stepMeters).floor().clamp(1, 80);
  final usedMeters = (count - 1) * stepMeters;
  final startMeters = (sizeMeters - usedMeters) / 2;
  return [
    for (var index = 0; index < count; index++)
      ((startMeters + index * stepMeters) / sizeMeters).clamp(.04, .96),
  ];
}

Offset snapPlantPosition(Offset target, List<Offset> grid) {
  if (grid.isEmpty) return _boundedPlantPosition(target);
  var nearest = grid.first;
  var distance = (nearest - target).distanceSquared;
  for (final point in grid.skip(1)) {
    final nextDistance = (point - target).distanceSquared;
    if (nextDistance < distance) {
      nearest = point;
      distance = nextDistance;
    }
  }
  return _boundedPlantPosition(nearest);
}

bool plantFootprintsOverlap(
  GardenBed bed,
  Offset firstPosition,
  CropSpacing firstSpacing,
  Offset secondPosition,
  CropSpacing secondSpacing,
) {
  final dx = (firstPosition.dx - secondPosition.dx) * bed.widthMeters;
  final dy = (firstPosition.dy - secondPosition.dy) * bed.lengthMeters;
  final clearanceMeters = (firstSpacing.plantCm + secondSpacing.plantCm) / 200;
  return dx * dx + dy * dy < clearanceMeters * clearanceMeters;
}

bool plantSpotIsOpen(
  GardenBed bed,
  Offset position,
  CropSpacing spacing,
  Iterable<GardenPlant> plants,
  CropSpacing Function(GardenPlant plant) spacingForPlant,
) =>
    plants.every(
      (plant) => !plantFootprintsOverlap(
        bed,
        position,
        spacing,
        plant.position,
        spacingForPlant(plant),
      ),
    );

Offset? nearestOpenPlantSpot(
  GardenBed bed,
  Offset target,
  List<Offset> grid,
  CropSpacing spacing,
  Iterable<GardenPlant> plants,
  CropSpacing Function(GardenPlant plant) spacingForPlant,
) {
  final candidates = grid.isEmpty ? [_boundedPlantPosition(target)] : grid;
  Offset? nearest;
  var nearestDistance = double.infinity;
  for (final candidate in candidates) {
    if (!plantSpotIsOpen(
      bed,
      candidate,
      spacing,
      plants,
      spacingForPlant,
    )) {
      continue;
    }
    final distance = (candidate - target).distanceSquared;
    if (distance < nearestDistance) {
      nearest = candidate;
      nearestDistance = distance;
    }
  }
  return nearest == null ? null : _boundedPlantPosition(nearest);
}

List<Offset> openPlantGridSpots(
  GardenBed bed,
  List<Offset> grid,
  CropSpacing spacing,
  Iterable<GardenPlant> plants,
  CropSpacing Function(GardenPlant plant) spacingForPlant,
) {
  final open = <Offset>[];
  for (final position in grid) {
    final overlapsPlant = !plantSpotIsOpen(
      bed,
      position,
      spacing,
      plants,
      spacingForPlant,
    );
    final overlapsOpen = open.any(
      (accepted) => plantFootprintsOverlap(
        bed,
        position,
        spacing,
        accepted,
        spacing,
      ),
    );
    if (!overlapsPlant && !overlapsOpen) open.add(position);
  }
  return open;
}

List<Offset> rowPlantPreviewSpots(
  GardenBed bed,
  List<Offset> grid,
  Offset start,
  Offset current,
  CropSpacing spacing,
  Iterable<GardenPlant> plants,
  CropSpacing Function(GardenPlant plant) spacingForPlant,
) {
  if (grid.isEmpty) {
    final spot = nearestOpenPlantSpot(
      bed,
      current,
      grid,
      spacing,
      plants,
      spacingForPlant,
    );
    return spot == null ? const [] : [spot];
  }

  final anchor = snapPlantPosition(start, grid);
  final horizontalMeters = (current.dx - start.dx).abs() * bed.widthMeters;
  final verticalMeters = (current.dy - start.dy).abs() * bed.lengthMeters;
  final horizontal = horizontalMeters >= verticalMeters;
  final axisGrid = grid.where((spot) {
    if (horizontal) return (spot.dy - anchor.dy).abs() < .0001;
    return (spot.dx - anchor.dx).abs() < .0001;
  }).toList(growable: false);
  if (axisGrid.isEmpty) return const [];

  final projected = horizontal
      ? Offset(current.dx, anchor.dy)
      : Offset(anchor.dx, current.dy);
  final end = snapPlantPosition(projected, axisGrid);
  final startAxis = horizontal ? anchor.dx : anchor.dy;
  final endAxis = horizontal ? end.dx : end.dy;
  final low = startAxis < endAxis ? startAxis : endAxis;
  final high = startAxis > endAxis ? startAxis : endAxis;
  final direction = endAxis >= startAxis ? 1 : -1;
  final candidates = axisGrid.where((spot) {
    final value = horizontal ? spot.dx : spot.dy;
    return value >= low - .0001 && value <= high + .0001;
  }).toList()
    ..sort((a, b) {
      final first = horizontal ? a.dx : a.dy;
      final second = horizontal ? b.dx : b.dy;
      return direction * first.compareTo(second);
    });

  final open = <Offset>[];
  for (final spot in candidates) {
    final overlapsPlant = !plantSpotIsOpen(
      bed,
      spot,
      spacing,
      plants,
      spacingForPlant,
    );
    final overlapsPreview = open.any(
      (accepted) => plantFootprintsOverlap(
        bed,
        spot,
        spacing,
        accepted,
        spacing,
      ),
    );
    if (!overlapsPlant && !overlapsPreview) open.add(spot);
  }
  return open;
}

Size plantFootprintFractions(GardenBed bed, CropSpacing spacing) => Size(
      spacing.plantCm / 100 / bed.widthMeters,
      spacing.plantCm / 100 / bed.lengthMeters,
    );

Size fittedBedCanvasSize(Size available, GardenBed bed) {
  if (available.isEmpty || bed.widthMeters <= 0 || bed.lengthMeters <= 0) {
    return Size.zero;
  }

  final bedAspect = bed.widthMeters / bed.lengthMeters;
  final availableAspect = available.width / available.height;
  if (availableAspect > bedAspect) {
    return Size(available.height * bedAspect, available.height);
  }
  return Size(available.width, available.width / bedAspect);
}

double plantIconExtent(
  Size canvasSize,
  GardenBed bed,
  CropSpacing spacing,
) {
  final pixelsPerMeter = [
    canvasSize.width / bed.widthMeters,
    canvasSize.height / bed.lengthMeters,
  ].reduce((scale, next) => scale < next ? scale : next);
  return spacing.plantCm / 100 * pixelsPerMeter;
}

double visualPlantIconExtent(
  Size canvasSize,
  GardenBed bed,
  CropSpacing spacing,
) =>
    plantIconExtent(canvasSize, bed, spacing);

const defaultGardenBeds = [
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
