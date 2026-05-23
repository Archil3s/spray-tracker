import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'crop_library.dart';
import 'data/acvm_product_repository.dart';
import 'data/local_garden_repository.dart';
import 'data/open_meteo_service.dart';
import 'data/openfarm_service.dart';
import 'features/notifications/harvest_reminder_service.dart';
import 'models/garden_snapshot.dart';
import 'models/openfarm_crop.dart';
import 'models/spray_condition.dart';
import 'models/spray_product.dart';

part 'features/garden/domain/bed_suggestions.dart';
part 'features/garden/presentation/pages/garden_screen.dart';
part 'features/garden/presentation/widgets/bed_operations.dart';

void main() => runApp(const SprayTrackerApp());

class SprayTrackerApp extends StatelessWidget {
  const SprayTrackerApp({super.key});

  @override
  Widget build(BuildContext context) => const CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'Spray Tracker',
        theme: CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: C.forest,
          scaffoldBackgroundColor: C.canvas,
          textTheme: CupertinoTextThemeData(textStyle: TextStyle(color: C.ink)),
        ),
        home: SprayTrackerHome(),
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
  static const forestSoft = Color(0xFFE8F0EA);
  static const soil = Color(0xFF735235);
  static const amber = Color(0xFFC77618);
  static const amberSoft = Color(0xFFFFEFD7);
  static const red = Color(0xFFB94A42);
  static const redSoft = Color(0xFFF8E4E1);
  static const blue = Color(0xFF2B6777);
  static const blueSoft = Color(0xFFE1F0F3);
  static const greySoft = Color(0xFFEDECE7);
}

final softShadow = [
  BoxShadow(
    color: const Color(0xFF000000).withValues(alpha: .07),
    blurRadius: 18,
    offset: const Offset(0, 7),
  ),
];

BoxDecoration cardDecoration({Color color = C.card, double radius = 22}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: C.line),
      boxShadow: softShadow,
    );

String monthName(int month) => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][month - 1];
String shortDate(DateTime d) => '${d.day} ${monthName(d.month)}';

const gardenMapWidthMeters = 8.0;
const gardenMapLengthMeters = 12.0;

String meterLabel(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

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
        ],
    };

List<String> companionCropIdsFor(String cropId) => switch (cropId) {
      'tomato' => const ['chives', 'parsley', 'lettuce', 'carrot'],
      'capsicum' || 'chilli' || 'eggplant' => const [
          'chives',
          'parsley',
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
    for (final companionId in companionCropIdsFor(item.cropId).take(2)) {
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

class SprayTrackerHome extends StatefulWidget {
  const SprayTrackerHome({super.key});

  @override
  State<SprayTrackerHome> createState() => _SprayTrackerHomeState();
}

class _SprayTrackerHomeState extends State<SprayTrackerHome> {
  int tab = 0;
  int selectedBed = 4;
  int nextRecordId = 1;
  int nextPlantId = 1;
  String message = '';

  List<SprayProduct> products = const [];
  bool productsLoading = true;
  final Map<int, List<VegetableDefinition>> bedCrops = {};
  final Map<int, List<GardenPlant>> bedPlants = {};
  GardenPlot gardenPlot = defaultGardenPlot;
  List<GardenBed> gardenLayout = [...defaultGardenBeds];
  List<SprayRecord> records = [];
  late final Future<List<SprayForecastHour>> forecastHours;
  late final Future<SprayConditionSummary> sprayConditions;
  late final Future<GardenRiskSummary> gardenRisks;

  @override
  void initState() {
    super.initState();
    forecastHours = OpenMeteoService.instance.getBlenheimForecastHours();
    sprayConditions = _loadSprayConditions(forecastHours);
    gardenRisks = forecastHours.then(summarizeGardenRisks);
    _seedBeds();
    _loadSavedGarden();
    _loadProducts();
  }

  Future<SprayConditionSummary> _loadSprayConditions(
    Future<List<SprayForecastHour>> forecast,
  ) async {
    final summary = summarizeSprayConditions(await forecast);
    unawaited(_scheduleSprayWindowReminder(summary));
    return summary;
  }

  Future<void> _scheduleSprayWindowReminder(
    SprayConditionSummary summary,
  ) async {
    try {
      await HarvestReminderService.instance.scheduleSprayWindow(
        planSprayWindowReminder(
          summary.nextGoodWindow,
          now: DateTime.now(),
        ),
      );
    } catch (_) {
      // Weather guidance remains useful when notification permission is denied.
    }
  }

  void _seedBeds() {
    VegetableDefinition byId(String id) => vegetableLibrary.firstWhere(
          (crop) => crop.id == id,
          orElse: () => vegetableLibrary.first,
        );
    bedCrops[4] = [byId('tomato'), byId('chilli'), byId('capsicum')];
    bedCrops[5] = [byId('onion'), byId('garlic')];
    bedCrops[9] = [byId('zucchini')];
    bedCrops[2] = [byId('lettuce')];
    final seeded = _defaultPlantingsForCrops(bedCrops);
    bedPlants
      ..clear()
      ..addAll(seeded);
    nextPlantId = _nextGardenPlantId(seeded);
  }

  Future<void> _loadSavedGarden() async {
    try {
      final snapshot = await LocalGardenRepository.instance.load();
      if (!mounted || snapshot == null) return;

      final restoredBedCrops = _restoreBedCrops(snapshot.bedCropIds);
      final restoredPlants = snapshot.plants.isEmpty
          ? _defaultPlantingsForCrops(restoredBedCrops)
          : _restoreGardenPlants(snapshot.plants);
      _addPlantCrops(restoredBedCrops, restoredPlants);
      final restoredRecords =
          snapshot.records.map(_recordFromStorage).toList(growable: false);
      final restoredLayout = _restoreGardenLayout(snapshot.beds);
      final restoredPlot = GardenPlot(
        widthMeters: snapshot.plotWidthMeters > 0
            ? snapshot.plotWidthMeters
            : defaultGardenPlot.widthMeters,
        lengthMeters: snapshot.plotLengthMeters > 0
            ? snapshot.plotLengthMeters
            : defaultGardenPlot.lengthMeters,
      );
      setState(() {
        bedCrops
          ..clear()
          ..addAll(restoredBedCrops);
        bedPlants
          ..clear()
          ..addAll(restoredPlants);
        if (restoredLayout.isNotEmpty) {
          gardenLayout = restoredLayout;
        }
        gardenPlot = restoredPlot;
        records = restoredRecords;
        nextRecordId = _nextRecordId(snapshot, restoredRecords);
        nextPlantId = _nextGardenPlantId(restoredPlants);
        message = 'Garden loaded from this phone';
      });
      unawaited(_restoreHarvestReminders(restoredRecords));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        message = 'Saved garden could not be loaded';
      });
    }
  }

  Map<int, List<VegetableDefinition>> _restoreBedCrops(
    Map<int, List<String>> bedCropIds,
  ) {
    final cropsById = {for (final crop in vegetableLibrary) crop.id: crop};
    return {
      for (final entry in bedCropIds.entries)
        entry.key: entry.value
            .map((id) => cropsById[id])
            .whereType<VegetableDefinition>()
            .toList(growable: false),
    }..removeWhere((_, crops) => crops.isEmpty);
  }

  Map<int, List<GardenPlant>> _defaultPlantingsForCrops(
    Map<int, List<VegetableDefinition>> cropsByBed,
  ) {
    var id = 1;
    return {
      for (final entry in cropsByBed.entries)
        entry.key: [
          for (var index = 0; index < entry.value.length; index++)
            GardenPlant(
              id: id++,
              bed: entry.key,
              crop: entry.value[index],
              position: defaultPlantPosition(index),
            ),
        ],
    };
  }

  Map<int, List<GardenPlant>> _restoreGardenPlants(
    List<StoredGardenPlant> storedPlants,
  ) {
    final cropsById = {for (final crop in vegetableLibrary) crop.id: crop};
    final plants = <int, List<GardenPlant>>{};
    for (final plant in storedPlants) {
      final crop = cropsById[plant.cropId];
      if (crop == null) continue;
      plants.putIfAbsent(plant.bed, () => []).add(
            GardenPlant(
              id: plant.id,
              bed: plant.bed,
              crop: crop,
              position: _boundedPlantPosition(Offset(plant.x, plant.y)),
            ),
          );
    }
    return plants;
  }

  void _addPlantCrops(
    Map<int, List<VegetableDefinition>> cropsByBed,
    Map<int, List<GardenPlant>> plantsByBed,
  ) {
    for (final entry in plantsByBed.entries) {
      final crops = [...cropsByBed[entry.key] ?? <VegetableDefinition>[]];
      for (final plant in entry.value) {
        if (!crops.any((crop) => crop.id == plant.crop.id)) {
          crops.add(plant.crop);
        }
      }
      if (crops.isNotEmpty) cropsByBed[entry.key] = crops;
    }
  }

  int _nextGardenPlantId(Map<int, List<GardenPlant>> plantsByBed) {
    var next = 1;
    for (final plants in plantsByBed.values) {
      for (final plant in plants) {
        if (plant.id >= next) next = plant.id + 1;
      }
    }
    return next;
  }

  List<GardenBed> _restoreGardenLayout(List<StoredGardenBed> beds) => beds
      .map(
        (bed) => GardenBed(
          bed.number,
          Rect.fromLTWH(bed.left, bed.top, bed.width, bed.height),
          name: bed.name,
          widthMeters: bed.widthMeters > 0 ? bed.widthMeters : null,
          lengthMeters: bed.lengthMeters > 0 ? bed.lengthMeters : null,
        ),
      )
      .where((bed) => bed.rect.width > 0 && bed.rect.height > 0)
      .toList(growable: false);

  int _nextRecordId(GardenSnapshot snapshot, List<SprayRecord> records) {
    final nextFromRecords = records.fold(
      1,
      (next, record) => record.id >= next ? record.id + 1 : next,
    );
    return snapshot.nextRecordId > nextFromRecords
        ? snapshot.nextRecordId
        : nextFromRecords;
  }

  SprayRecord _recordFromStorage(StoredSprayRecord record) => SprayRecord(
        id: record.id,
        beds: record.beds,
        crops: record.crops.isEmpty ? const ['Whole bed'] : record.crops,
        cropProfiles: const {},
        targetId: record.targetId,
        product: record.product,
        productId: record.productId,
        reason: record.reason,
        notes: record.notes,
        date: record.date,
        days: record.days,
      );

  Future<void> _restoreHarvestReminders(List<SprayRecord> savedRecords) async {
    for (final record in savedRecords) {
      await _scheduleHarvestReminder(record);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final loaded = await AcvmProductRepository.instance.getAll();
      if (!mounted) return;
      setState(() {
        products = loaded;
        productsLoading = false;
        message = 'Loaded ${loaded.length} NZ spray products';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        products = fallbackProducts();
        productsLoading = false;
        message = 'Using fallback products - asset failed to load';
      });
    }
  }

  void addCrop(int bed, VegetableDefinition crop) {
    final next = [...bedCrops[bed] ?? <VegetableDefinition>[]];
    if (!next.any((item) => item.id == crop.id)) next.add(crop);
    setState(() {
      bedCrops[bed] = next;
      selectedBed = bed;
      message = '${crop.name} added to Bed $bed';
    });
    unawaited(_saveGarden());
  }

  void removeCrop(int bed, VegetableDefinition crop) {
    final next = [...bedCrops[bed] ?? <VegetableDefinition>[]]
      ..removeWhere((item) => item.id == crop.id);
    final nextPlants = [...bedPlants[bed] ?? <GardenPlant>[]]
      ..removeWhere((plant) => plant.crop.id == crop.id);
    setState(() {
      if (next.isEmpty) {
        bedCrops.remove(bed);
      } else {
        bedCrops[bed] = next;
      }
      if (nextPlants.isEmpty) {
        bedPlants.remove(bed);
      } else {
        bedPlants[bed] = nextPlants;
      }
      message = '${crop.name} removed from Bed $bed';
    });
    unawaited(_saveGarden());
  }

  GardenPlant addGardenPlant(
    int bed,
    VegetableDefinition crop,
    Offset position,
  ) =>
      addGardenPlants(bed, crop, [position]).single;

  List<GardenPlant> addGardenPlants(
    int bed,
    VegetableDefinition crop,
    List<Offset> positions,
  ) {
    if (positions.isEmpty) return const [];
    final plants = [
      for (var index = 0; index < positions.length; index++)
        GardenPlant(
          id: nextPlantId + index,
          bed: bed,
          crop: crop,
          position: _boundedPlantPosition(positions[index]),
        ),
    ];
    final nextCrops = [...bedCrops[bed] ?? <VegetableDefinition>[]];
    if (!nextCrops.any((item) => item.id == crop.id)) nextCrops.add(crop);
    setState(() {
      nextPlantId += plants.length;
      bedPlants[bed] = [...bedPlants[bed] ?? <GardenPlant>[], ...plants];
      bedCrops[bed] = nextCrops;
      selectedBed = bed;
      message = plants.length == 1
          ? '${crop.name} planted in Bed $bed'
          : '${plants.length} ${crop.name} plants added to Bed $bed';
    });
    unawaited(_saveGarden());
    return plants;
  }

  void removeGardenPlant(int bed, int plantId) {
    final plants = bedPlants[bed] ?? const <GardenPlant>[];
    GardenPlant? removed;
    for (final plant in plants) {
      if (plant.id == plantId) {
        removed = plant;
        break;
      }
    }
    if (removed == null) return;
    final removedPlant = removed;
    final nextPlants = plants.where((plant) => plant.id != plantId).toList();
    final cropStillPlanted =
        nextPlants.any((plant) => plant.crop.id == removedPlant.crop.id);
    final nextCrops = [...bedCrops[bed] ?? <VegetableDefinition>[]];
    if (!cropStillPlanted) {
      nextCrops.removeWhere((crop) => crop.id == removedPlant.crop.id);
    }
    setState(() {
      if (nextPlants.isEmpty) {
        bedPlants.remove(bed);
      } else {
        bedPlants[bed] = nextPlants;
      }
      if (nextCrops.isEmpty) {
        bedCrops.remove(bed);
      } else {
        bedCrops[bed] = nextCrops;
      }
      message = '${removedPlant.crop.name} removed from Bed $bed';
    });
    unawaited(_saveGarden());
  }

  void addGardenBed() {
    final number = gardenLayout.fold(
          0,
          (largest, bed) => bed.number > largest ? bed.number : largest,
        ) +
        1;
    final offset = ((number - 1) % 5) * .045;
    final bed = GardenBed(
      number,
      Rect.fromLTWH(
        .10 + offset,
        .12 + offset,
        1 / gardenPlot.widthMeters,
        2 / gardenPlot.lengthMeters,
      ),
      widthMeters: 1,
      lengthMeters: 2,
    ).sizeToMeters(1, 2, plot: gardenPlot);
    setState(() {
      gardenLayout = [...gardenLayout, bed];
      selectedBed = bed.number;
      message = '${bed.label} added';
    });
    unawaited(_saveGarden());
  }

  void renameGardenBed(int bedNumber, String name) {
    final current = _bedByNumber(bedNumber);
    _updateGardenBed(
      bedNumber,
      (bed) => bed.copyWith(name: name.trim()),
      '${current.label} renamed',
    );
  }

  void moveGardenBed(int bedNumber, Offset delta) {
    _updateGardenBed(bedNumber, (bed) => bed.move(delta));
  }

  void resizeGardenBed(int bedNumber, Offset delta) {
    _updateGardenBed(bedNumber, (bed) => bed.resize(delta, plot: gardenPlot));
  }

  void sizeGardenBed(int bedNumber, double widthMeters, double lengthMeters) {
    _updateGardenBed(
      bedNumber,
      (bed) => bed.sizeToMeters(widthMeters, lengthMeters, plot: gardenPlot),
      'Bed size updated',
    );
  }

  void rotateGardenBed(int bedNumber) {
    _updateGardenBed(
      bedNumber,
      (bed) => bed.rotate(plot: gardenPlot),
      'Bed rotated',
    );
  }

  void duplicateGardenBed(int bedNumber) {
    final source = _bedByNumber(bedNumber);
    final number = gardenLayout.fold(
          0,
          (largest, bed) => bed.number > largest ? bed.number : largest,
        ) +
        1;
    final copy = GardenBed(
      number,
      source.rect,
      name: source.name.isEmpty ? '' : '${source.name} copy',
      widthMeters: source.widthMeters,
      lengthMeters: source.lengthMeters,
    ).move(const Offset(.04, .04));
    setState(() {
      gardenLayout = [...gardenLayout, copy];
      selectedBed = copy.number;
      message = '${copy.label} added';
    });
    unawaited(_saveGarden());
  }

  void sizeGardenPlot(double widthMeters, double lengthMeters) {
    final nextPlot = GardenPlot(
      widthMeters: widthMeters,
      lengthMeters: lengthMeters,
    );
    setState(() {
      gardenPlot = nextPlot;
      gardenLayout = [
        for (final bed in gardenLayout)
          bed.sizeToMeters(bed.widthMeters, bed.lengthMeters, plot: nextPlot),
      ];
      message = 'Garden plot size updated';
    });
    unawaited(_saveGarden());
  }

  void removeGardenBed(int bedNumber) {
    if (gardenLayout.length <= 1) return;
    setState(() {
      gardenLayout =
          gardenLayout.where((bed) => bed.number != bedNumber).toList();
      bedCrops.remove(bedNumber);
      bedPlants.remove(bedNumber);
      selectedBed = gardenLayout.first.number;
      message = 'Bed removed';
    });
    unawaited(_saveGarden());
  }

  void resetGardenLayout() {
    setState(() {
      gardenLayout = [...defaultGardenBeds];
      selectedBed = gardenLayout.first.number;
      message = 'Garden layout reset';
    });
    unawaited(_saveGarden());
  }

  GardenBed _bedByNumber(int number) => gardenLayout.firstWhere(
        (bed) => bed.number == number,
        orElse: () => gardenLayout.first,
      );

  void _updateGardenBed(
    int bedNumber,
    GardenBed Function(GardenBed bed) update, [
    String? nextMessage,
  ]) {
    setState(() {
      gardenLayout = [
        for (final bed in gardenLayout)
          if (bed.number == bedNumber) update(bed) else bed,
      ];
      if (nextMessage != null) {
        message = nextMessage;
      }
    });
    unawaited(_saveGarden());
  }

  void saveSpray({
    required Set<int> beds,
    required Set<String> crops,
    required Map<String, OpenFarmCrop> cropProfiles,
    required String targetId,
    required SprayProduct product,
    required String reason,
    required String notes,
    required int days,
  }) {
    if (beds.isEmpty) return;
    final sortedBeds = beds.toList()..sort();
    final sortedCrops = crops.toList()..sort();
    final record = SprayRecord(
      id: nextRecordId,
      beds: sortedBeds,
      crops: sortedCrops.isEmpty ? ['Whole bed'] : sortedCrops,
      cropProfiles: Map.unmodifiable(cropProfiles),
      targetId: targetId,
      product: product.name,
      productId: product.id,
      reason: reason.trim(),
      notes: notes.trim(),
      date: DateTime.now(),
      days: days,
    );
    setState(() {
      nextRecordId++;
      records.insert(0, record);
      selectedBed = sortedBeds.first;
      message = 'Spray record saved';
      tab = 0;
    });
    unawaited(_saveGarden());
    unawaited(_scheduleHarvestReminder(record));
  }

  Future<void> _scheduleHarvestReminder(SprayRecord record) async {
    if (record.days <= 0) return;

    try {
      await HarvestReminderService.instance.schedule(
        HarvestReminder(
          id: record.id,
          safeAt: record.safeDate,
          beds: record.beds,
          crops: record.crops,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        message = 'Spray record saved. Harvest reminder was not scheduled.';
      });
    }
  }

  void deleteRecord(int id) {
    unawaited(HarvestReminderService.instance.cancel(id));
    setState(() {
      records = records.where((record) => record.id != id).toList();
      message = 'Record removed';
    });
    unawaited(_saveGarden());
  }

  Future<void> _saveGarden() async {
    try {
      await LocalGardenRepository.instance.save(
        GardenSnapshot(
          nextRecordId: nextRecordId,
          bedCropIds: {
            for (final entry in bedCrops.entries)
              entry.key: entry.value.map((crop) => crop.id).toList(),
          },
          records: records.map(_recordToStorage).toList(growable: false),
          beds: gardenLayout.map(_bedToStorage).toList(growable: false),
          plants: bedPlants.values
              .expand((plants) => plants)
              .map(_plantToStorage)
              .toList(growable: false),
          plotWidthMeters: gardenPlot.widthMeters,
          plotLengthMeters: gardenPlot.lengthMeters,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        message = 'Garden change saved for now, but local storage failed';
      });
    }
  }

  StoredSprayRecord _recordToStorage(SprayRecord record) => StoredSprayRecord(
        id: record.id,
        beds: record.beds,
        crops: record.crops,
        targetId: record.targetId,
        product: record.product,
        productId: record.productId,
        reason: record.reason,
        notes: record.notes,
        date: record.date,
        days: record.days,
      );

  StoredGardenBed _bedToStorage(GardenBed bed) => StoredGardenBed(
        number: bed.number,
        name: bed.name,
        left: bed.rect.left,
        top: bed.rect.top,
        width: bed.rect.width,
        height: bed.rect.height,
        widthMeters: bed.widthMeters,
        lengthMeters: bed.lengthMeters,
      );

  StoredGardenPlant _plantToStorage(GardenPlant plant) => StoredGardenPlant(
        id: plant.id,
        bed: plant.bed,
        cropId: plant.crop.id,
        x: plant.position.dx,
        y: plant.position.dy,
      );

  bool bedOnHold(int bed) =>
      records.any((record) => record.beds.contains(bed) && record.onHold);

  int get clearBeds =>
      gardenLayout.where((bed) => !bedOnHold(bed.number)).length;
  int get holdBeds => gardenLayout.length - clearBeds;
  int get plantedBeds =>
      bedCrops.values.where((items) => items.isNotEmpty).length;
  int get cropPlacements =>
      bedCrops.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        clearBeds: clearBeds,
        holdBeds: holdBeds,
        plantedBeds: plantedBeds,
        cropPlacements: cropPlacements,
        records: records,
        products: products,
        message: message,
        sprayConditions: sprayConditions,
        gardenRisks: gardenRisks,
        onPlanSpray: () => setState(() => tab = 2),
        onOpenProducts: () => setState(() => tab = 4),
      ),
      GardenScreen(
        selectedBed: selectedBed,
        plot: gardenPlot,
        gardenBeds: gardenLayout,
        bedCrops: bedCrops,
        bedPlants: bedPlants,
        records: records,
        products: products,
        gardenRisks: gardenRisks,
        isHold: bedOnHold,
        message: message,
        onSelectBed: (bed) => setState(() => selectedBed = bed),
        onAddCrop: addCrop,
        onRemoveCrop: removeCrop,
        onAddPlant: addGardenPlant,
        onAddPlants: addGardenPlants,
        onRemovePlant: removeGardenPlant,
        onAddBed: addGardenBed,
        onRenameBed: renameGardenBed,
        onMoveBed: moveGardenBed,
        onResizeBed: resizeGardenBed,
        onSizeBed: sizeGardenBed,
        onRotateBed: rotateGardenBed,
        onDuplicateBed: duplicateGardenBed,
        onSizePlot: sizeGardenPlot,
        onRemoveBed: removeGardenBed,
        onResetLayout: resetGardenLayout,
        onStartSpray: () => setState(() => tab = 2),
      ),
      SprayLogScreen(
        key: ValueKey('${products.length}-${records.length}'),
        initialBeds: {selectedBed},
        gardenBeds: gardenLayout,
        bedCrops: bedCrops,
        products: products,
        productsLoading: productsLoading,
        sprayConditions: sprayConditions,
        onSave: saveSpray,
      ),
      RecordsScreen(records: records, message: message, onDelete: deleteRecord),
      ProductsScreen(
        products: products,
        loading: productsLoading,
        message: message,
      ),
    ];

    return CupertinoPageScaffold(
      backgroundColor: C.canvas,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(index: tab, children: pages),
            ),
            BottomNav(tab: tab, onTap: (value) => setState(() => tab = value)),
          ],
        ),
      ),
    );
  }
}

List<SprayProduct> fallbackProducts() => const [
      SprayProduct(
        id: 'fallback_neem_oil',
        name: 'Neem Oil',
        brand: 'Fallback',
        type: 'Pest control',
        activeIngredient: 'Neem oil / Azadirachtin',
        withholdingDays: 0,
        withholdingNote: 'Fallback only - check label before harvest',
        reEntryHours: 1,
        category: 'organic',
        commonUses: ['aphids', 'mites', 'whitefly', 'scale'],
        suitableCrops: ['vegetables', 'herbs', 'fruit trees'],
        reSprayIntervalDays: 7,
        acvmRegistrationNumber: '',
        source: 'Fallback sample',
        notes: 'ACVM product dataset did not load.',
      ),
    ];

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.clearBeds,
    required this.holdBeds,
    required this.plantedBeds,
    required this.cropPlacements,
    required this.records,
    required this.products,
    required this.message,
    required this.sprayConditions,
    required this.gardenRisks,
    required this.onPlanSpray,
    required this.onOpenProducts,
    super.key,
  });

  final int clearBeds;
  final int holdBeds;
  final int plantedBeds;
  final int cropPlacements;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final String message;
  final Future<SprayConditionSummary> sprayConditions;
  final Future<GardenRiskSummary> gardenRisks;
  final VoidCallback onPlanSpray;
  final VoidCallback onOpenProducts;

  @override
  Widget build(BuildContext context) {
    final nextActiveRecord = nextActiveSprayRecord(records);
    return AppPage(
      title: 'Fieldbook',
      subtitle: 'Spray records, product safety, and harvest holds.',
      message: message,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: C.forest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Spray status',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: HeroMetric(
                      label: 'CLEAR BEDS',
                      value: '$clearBeds',
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HeroMetric(
                      label: 'ON HOLD',
                      value: '$holdBeds',
                      color: C.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$plantedBeds beds planted | $cropPlacements crop placements | ${products.length} NZ products',
                style: const TextStyle(
                  color: Color(0xDFFFFFFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: onPlanSpray,
                      child: const Text(
                        'Plan a spray',
                        style: TextStyle(
                          color: C.forest,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CupertinoButton(
                      color: const Color(0x18FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      onPressed: onOpenProducts,
                      child: const Text(
                        'Products',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SprayConditionBanner(sprayConditions: sprayConditions),
        const SizedBox(height: 10),
        GardenRiskPanel(gardenRisks: gardenRisks),
        const SizedBox(height: 18),
        const SectionTitle('Next safe harvest'),
        const SizedBox(height: 8),
        if (nextActiveRecord == null)
          const EmptyCard('No active withholding periods.')
        else
          RecordCard(record: nextActiveRecord),
        const SizedBox(height: 18),
        const SectionTitle('Recent activity'),
        const SizedBox(height: 8),
        if (records.isEmpty)
          const EmptyCard(
            'No spray records yet. Use Spray Log to test the new product library.',
          )
        else
          ...records.take(3).map((record) => RecordCard(record: record)),
      ],
    );
  }
}

class SprayConditionBanner extends StatelessWidget {
  const SprayConditionBanner({required this.sprayConditions, super.key});

  final Future<SprayConditionSummary> sprayConditions;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SprayConditionSummary>(
      future: sprayConditions,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SprayConditionPanel(
            title: 'Blenheim spray weather',
            body: 'Checking the next 48 hours...',
            color: C.blue,
            background: C.blueSoft,
            loading: true,
          );
        }

        final summary = snapshot.data;
        if (summary == null) {
          return const _SprayConditionPanel(
            title: 'Blenheim spray weather unavailable',
            body: 'Check conditions before applying a product.',
            color: C.muted,
            background: C.greySoft,
          );
        }

        final nextWindow = summary.nextGoodWindow;
        return _SprayConditionPanel(
          title: _sprayConditionTitle(summary.kind),
          body: _sprayConditionBody(summary),
          nextWindow: nextWindow == null
              ? 'No two-hour good spray window in the next 48 hours.'
              : 'Next good window: ${_sprayWindowText(nextWindow)}.',
          color: _sprayConditionColor(summary.kind),
          background: _sprayConditionBackground(summary.kind),
        );
      },
    );
  }
}

class _SprayConditionPanel extends StatelessWidget {
  const _SprayConditionPanel({
    required this.title,
    required this.body,
    required this.color,
    required this.background,
    this.nextWindow,
    this.loading = false,
  });

  final String title;
  final String body;
  final Color color;
  final Color background;
  final String? nextWindow;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: loading
                  ? const CupertinoActivityIndicator()
                  : Icon(CupertinoIcons.wind, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      color: C.ink,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (nextWindow != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      nextWindow!,
                      style: const TextStyle(
                        color: C.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class GardenRiskPanel extends StatelessWidget {
  const GardenRiskPanel({required this.gardenRisks, super.key});

  final Future<GardenRiskSummary> gardenRisks;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GardenRiskSummary>(
      future: gardenRisks,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _GardenRiskPanelBody(
            title: 'Blenheim garden risks',
            subtitle: 'Checking frost, soil drying, and pest pressure...',
            loading: true,
          );
        }

        final summary = snapshot.data;
        if (summary == null) {
          return const _GardenRiskPanelBody(
            title: 'Garden risk unavailable',
            subtitle: 'Forecast analytics could not be loaded.',
          );
        }

        return _GardenRiskPanelBody(
          title: 'Blenheim garden risks',
          subtitle:
              'Low ${summary.lowestTemperatureC.round()} C | peak ${summary.peakTemperatureC.round()} C | rain ${summary.rainNext24HoursMm.toStringAsFixed(1)} mm',
          risks: [
            _GardenRiskItem('Frost', summary.frostRisk),
            _GardenRiskItem('Soil drying', summary.soilEvaporationRisk),
            _GardenRiskItem('Pest pressure', summary.pestPressureRisk),
          ],
        );
      },
    );
  }
}

class _GardenRiskPanelBody extends StatelessWidget {
  const _GardenRiskPanelBody({
    required this.title,
    required this.subtitle,
    this.risks = const [],
    this.loading = false,
  });

  final String title;
  final String subtitle;
  final List<_GardenRiskItem> risks;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: loading
                      ? const CupertinoActivityIndicator()
                      : const Icon(
                          CupertinoIcons.chart_bar_alt_fill,
                          color: C.forest,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: C.forest,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: C.muted,
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (risks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: risks
                    .map(
                      (risk) => ProductTag(
                        label: '${risk.label}: ${_gardenRiskLabel(risk.level)}',
                        color: _gardenRiskColor(risk.level),
                        background: _gardenRiskBackground(risk.level),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );
}

class _GardenRiskItem {
  const _GardenRiskItem(this.label, this.level);

  final String label;
  final GardenRiskLevel level;
}

String _sprayConditionTitle(SprayConditionKind kind) => switch (kind) {
      SprayConditionKind.good => 'Good spray window',
      SprayConditionKind.wind => 'Wind warning',
      SprayConditionKind.rain => 'Rain warning',
      SprayConditionKind.heat => 'Heat warning',
      SprayConditionKind.cool => 'Temperature warning',
    };

String _sprayConditionBody(SprayConditionSummary summary) {
  final hour = summary.currentHour;
  final wind = hour.windKph.round();
  final temperature = hour.temperatureC.round();
  return switch (summary.kind) {
    SprayConditionKind.good =>
      'Wind $wind km/h, $temperature C, and no forecast rain in 6 hours.',
    SprayConditionKind.wind =>
      'Wind is $wind km/h. Drift can keep spray off target.',
    SprayConditionKind.rain =>
      'Rain is forecast within 6 hours and can wash product off.',
    SprayConditionKind.heat =>
      '$temperature C now. Copper and sulfur can burn foliage above 28 C.',
    SprayConditionKind.cool =>
      '$temperature C now. Wait for a 10-28 C spray window.',
  };
}

Color _sprayConditionColor(SprayConditionKind kind) => switch (kind) {
      SprayConditionKind.good => C.forest,
      SprayConditionKind.wind => C.red,
      SprayConditionKind.rain => C.blue,
      SprayConditionKind.heat => C.amber,
      SprayConditionKind.cool => C.muted,
    };

Color _sprayConditionBackground(SprayConditionKind kind) => switch (kind) {
      SprayConditionKind.good => C.forestSoft,
      SprayConditionKind.wind => C.redSoft,
      SprayConditionKind.rain => C.blueSoft,
      SprayConditionKind.heat => C.amberSoft,
      SprayConditionKind.cool => C.greySoft,
    };

String _gardenRiskLabel(GardenRiskLevel level) => switch (level) {
      GardenRiskLevel.low => 'Low',
      GardenRiskLevel.moderate => 'Moderate',
      GardenRiskLevel.high => 'High',
    };

Color _gardenRiskColor(GardenRiskLevel level) => switch (level) {
      GardenRiskLevel.low => C.forest,
      GardenRiskLevel.moderate => C.amber,
      GardenRiskLevel.high => C.red,
    };

Color _gardenRiskBackground(GardenRiskLevel level) => switch (level) {
      GardenRiskLevel.low => C.forestSoft,
      GardenRiskLevel.moderate => C.amberSoft,
      GardenRiskLevel.high => C.redSoft,
    };

String _sprayWindowText(SprayWindow window) {
  final start = '${shortDate(window.start)} ${_hourLabel(window.start)}';
  return '$start-${_hourLabel(window.end)}';
}

String _hourLabel(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final suffix = date.hour < 12 ? 'am' : 'pm';
  return '$hour$suffix';
}

class HeroMetric extends StatelessWidget {
  const HeroMetric({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x12FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x28FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      );
}

class _GardenBedSelector extends StatelessWidget {
  const _GardenBedSelector({
    required this.beds,
    required this.selectedBed,
    required this.bedCrops,
    required this.records,
    required this.onSelectBed,
  });

  final List<GardenBed> beds;
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final ValueChanged<int> onSelectBed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: beds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final bed = beds[index];
            final crops = bedCrops[bed.number] ?? const <VegetableDefinition>[];
            final summary = bedSpraySummary(records, bed.number);
            final selected = bed.number == selectedBed;
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onSelectBed(bed.number),
              child: Container(
                width: 138,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? C.forest : C.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? C.forest : C.line,
                    width: selected ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bed.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? CupertinoColors.white : C.forest,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      crops.isEmpty
                          ? 'No veg logged'
                          : '${crops.length} veg logged',
                      style: TextStyle(
                        color: selected ? const Color(0xCCFFFFFF) : C.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    StatusPill(
                      _bedSprayStatusLabel(summary.state),
                      hold: summary.onHold,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

class _GardenBedCropPanel extends StatelessWidget {
  const _GardenBedCropPanel({
    required this.bed,
    required this.crops,
    required this.records,
    required this.products,
    required this.gardenRisks,
    required this.spraySummary,
    required this.onAddCrop,
    required this.onRemoveCrop,
    required this.onStartSpray,
  });

  final GardenBed bed;
  final List<VegetableDefinition> crops;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final Future<GardenRiskSummary> gardenRisks;
  final BedSpraySummary spraySummary;
  final VoidCallback onAddCrop;
  final ValueChanged<VegetableDefinition> onRemoveCrop;
  final VoidCallback onStartSpray;

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bed.label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: C.forest,
                    ),
                  ),
                ),
                StatusPill(
                  _bedSprayStatusLabel(spraySummary.state),
                  hold: spraySummary.onHold,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              bed.sizeLabel,
              style:
                  const TextStyle(color: C.muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _BedSprayStatusCard(summary: spraySummary),
            const SizedBox(height: 14),
            const SectionTitle('Current vegetables'),
            const SizedBox(height: 8),
            if (crops.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: crops
                    .map(
                      (crop) => CropChip(
                          crop: crop, onRemove: () => onRemoveCrop(crop)),
                    )
                    .toList(),
              ),
            ] else
              const EmptyCard('No vegetables logged in this bed.'),
            const SizedBox(height: 14),
            _BedSuggestionsPanel(
              bed: bed,
              crops: crops,
              records: records,
              products: products,
              gardenRisks: gardenRisks,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: crops.isEmpty ? 'Log vegetables' : 'Edit veg list',
                    onPressed: onAddCrop,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                      label: 'Log spray', onPressed: onStartSpray),
                ),
              ],
            ),
          ],
        ),
      );
}

class _BedSprayStatusCard extends StatelessWidget {
  const _BedSprayStatusCard({required this.summary});

  final BedSpraySummary summary;

  @override
  Widget build(BuildContext context) {
    final record = summary.record;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bedSprayStatusBackground(summary.state),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _bedSprayStatusIcon(summary.state),
            color: _bedSprayStatusColor(summary.state),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bedSprayStatusTitle(summary),
                  style: TextStyle(
                    color: _bedSprayStatusColor(summary.state),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _bedSprayStatusBody(summary),
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (record != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ProductTag(
                        label: record.product,
                        color: C.forest,
                        background: C.forestSoft,
                      ),
                      ProductTag(
                        label: targetById(record.targetId).short,
                        color: targetById(record.targetId).color,
                        background: targetById(record.targetId).softColor,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _bedSprayStatusLabel(BedSprayState state) => switch (state) {
      BedSprayState.neverSprayed => 'UNSPRAYED',
      BedSprayState.clear => 'CLEAR',
      BedSprayState.hold => 'HOLD',
    };

String _bedSprayStatusTitle(BedSpraySummary summary) => switch (summary.state) {
      BedSprayState.neverSprayed => 'No spray logged for this bed',
      BedSprayState.clear => 'Sprayed and harvest clear',
      BedSprayState.hold => 'Sprayed and still on withholding hold',
    };

String _bedSprayStatusBody(BedSpraySummary summary) {
  final record = summary.record;
  if (record == null) {
    return 'Use Log spray when you apply a product so this bed can track harvest safety.';
  }

  final sprayed = shortDate(record.date);
  final safe = shortDate(record.safeDate);
  if (summary.onHold) {
    return 'Sprayed $sprayed. Safe harvest starts $safe after ${record.days} withholding days.';
  }

  return 'Last sprayed $sprayed. Withholding period ended $safe.';
}

IconData _bedSprayStatusIcon(BedSprayState state) => switch (state) {
      BedSprayState.neverSprayed => CupertinoIcons.circle,
      BedSprayState.clear => CupertinoIcons.check_mark_circled_solid,
      BedSprayState.hold => CupertinoIcons.exclamationmark_triangle_fill,
    };

Color _bedSprayStatusColor(BedSprayState state) => switch (state) {
      BedSprayState.neverSprayed => C.muted,
      BedSprayState.clear => C.forest,
      BedSprayState.hold => C.amber,
    };

Color _bedSprayStatusBackground(BedSprayState state) => switch (state) {
      BedSprayState.neverSprayed => C.greySoft,
      BedSprayState.clear => C.forestSoft,
      BedSprayState.hold => C.amberSoft,
    };

class _BedPlantingCanvas extends StatelessWidget {
  const _BedPlantingCanvas({
    required this.bed,
    required this.crops,
    this.plants = const [],
    this.gridPositions = const [],
    this.previewPositions = const [],
    this.previewCrop,
    this.previewSpacing,
    this.spacingForPlant,
    this.height = 186,
    this.erasing = false,
    this.onPlace,
    this.onPlantTap,
    this.onPaintStart,
    this.onPaintUpdate,
    this.onPaintEnd,
    this.onPaintCancel,
  });

  final GardenBed bed;
  final List<VegetableDefinition> crops;
  final List<GardenPlant> plants;
  final List<Offset> gridPositions;
  final List<Offset> previewPositions;
  final VegetableDefinition? previewCrop;
  final CropSpacing? previewSpacing;
  final CropSpacing Function(GardenPlant plant)? spacingForPlant;
  final double height;
  final bool erasing;
  final ValueChanged<Offset>? onPlace;
  final ValueChanged<GardenPlant>? onPlantTap;
  final ValueChanged<Offset>? onPaintStart;
  final ValueChanged<Offset>? onPaintUpdate;
  final VoidCallback? onPaintEnd;
  final VoidCallback? onPaintCancel;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('bed-planting-canvas'),
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.line),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 34, 12, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = fittedBedCanvasSize(
                      Size(constraints.maxWidth, constraints.maxHeight),
                      bed,
                    );
                    return Center(
                      child: SizedBox(
                        width: size.width,
                        height: size.height,
                        child: _buildBedSurface(size),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: ProductTag(
                label: bed.sizeLabel,
                color: C.forest,
                background: C.forestSoft,
              ),
            ),
          ],
        ),
      );

  Widget _buildBedSurface(Size size) => Container(
        key: const ValueKey('bed-planting-surface'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.soil, width: 1.2),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _BedPlantingPainter(bed)),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: onPlace == null
                    ? null
                    : (details) => onPlace!(
                          Offset(
                            details.localPosition.dx / size.width,
                            details.localPosition.dy / size.height,
                          ),
                        ),
                onPanStart: onPaintStart == null
                    ? null
                    : (details) => _handlePaintPosition(
                          details.localPosition,
                          size,
                          onPaintStart!,
                        ),
                onPanUpdate: onPaintUpdate == null
                    ? null
                    : (details) => _handlePaintPosition(
                          details.localPosition,
                          size,
                          onPaintUpdate!,
                        ),
                onPanEnd: onPaintEnd == null ? null : (_) => onPaintEnd!(),
                onPanCancel: onPaintCancel,
                child: Stack(
                  children: [
                    if (gridPositions.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PlantSpacingGridPainter(gridPositions),
                          ),
                        ),
                      ),
                    if (plants.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PlantingBandPainter(
                              bed: bed,
                              plants: plants,
                              spacingForPlant: spacingForPlant,
                              drawLabels: false,
                            ),
                          ),
                        ),
                      ),
                    if (plants.isEmpty && crops.isEmpty)
                      const Center(
                        child: Icon(
                          CupertinoIcons.leaf_arrow_circlepath,
                          color: C.forest,
                          size: 42,
                        ),
                      ),
                    if (_displayPlants().isNotEmpty)
                      ..._displayPlants().map((plant) {
                        final spacing = spacingForPlant == null
                            ? cropSpacingFor(plant.crop)
                            : spacingForPlant!(plant);
                        final extent =
                            visualPlantIconExtent(size, bed, spacing);
                        final tapExtent =
                            erasing && extent < 44 ? 44.0 : extent;
                        return Positioned(
                          left: plant.position.dx * size.width - tapExtent / 2,
                          top: plant.position.dy * size.height - tapExtent / 2,
                          child: IgnorePointer(
                            ignoring: !erasing,
                            child: _PlacedPlantIcon(
                              plant: plant,
                              extent: extent,
                              tapExtent: tapExtent,
                              erasing: erasing,
                              onTap: onPlantTap == null
                                  ? null
                                  : () => onPlantTap!(plant),
                            ),
                          ),
                        );
                      })
                    else if (crops.isNotEmpty)
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: crops
                              .map(
                                (crop) => _PlantPatch(crop: crop),
                              )
                              .toList(),
                        ),
                      ),
                    if (plants.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PlantingBandPainter(
                              bed: bed,
                              plants: plants,
                              spacingForPlant: spacingForPlant,
                              drawBands: false,
                            ),
                          ),
                        ),
                      ),
                    if (previewPositions.isNotEmpty &&
                        previewCrop != null &&
                        previewSpacing != null)
                      ...previewPositions.map((position) {
                        final extent =
                            visualPlantIconExtent(size, bed, previewSpacing!);
                        return Positioned(
                          left: position.dx * size.width - extent / 2,
                          top: position.dy * size.height - extent / 2,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: .42,
                              child: SizedBox(
                                width: extent,
                                height: extent,
                                child: CropIcon(
                                  previewCrop!.iconPath,
                                  size: extent,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  void _handlePaintPosition(
    Offset localPosition,
    Size size,
    ValueChanged<Offset> onInside,
  ) {
    final outside = localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy > size.height;
    if (outside) {
      onPaintCancel?.call();
      return;
    }
    onInside(
      Offset(
        localPosition.dx / size.width,
        localPosition.dy / size.height,
      ),
    );
  }

  List<GardenPlant> _displayPlants() {
    if (erasing) return plants;
    final grouped = <String, List<GardenPlant>>{};
    for (final plant in plants) {
      grouped.putIfAbsent(plant.crop.id, () => []).add(plant);
    }
    final visible = <GardenPlant>[];
    for (final group in grouped.values) {
      if (group.isEmpty) continue;
      final spacing = spacingForPlant == null
          ? cropSpacingFor(group.first.crop)
          : spacingForPlant!(group.first);
      if (group.length > 12 && spacing.plantCm <= 25) {
        continue;
      }
      final maxVisible = spacing.plantCm <= 12
          ? 10
          : spacing.plantCm <= 20
              ? 12
              : spacing.plantCm <= 35
                  ? 16
                  : 24;
      if (group.length <= maxVisible) {
        visible.addAll(group);
        continue;
      }
      final ordered = [...group]..sort((a, b) {
          final row = a.position.dy.compareTo(b.position.dy);
          return row == 0 ? a.position.dx.compareTo(b.position.dx) : row;
        });
      final step = (ordered.length / maxVisible).ceil();
      for (var index = 0; index < ordered.length; index += step) {
        visible.add(ordered[index]);
      }
    }
    return visible;
  }
}

class _PlacedPlantIcon extends StatelessWidget {
  const _PlacedPlantIcon({
    required this.plant,
    required this.extent,
    required this.tapExtent,
    required this.erasing,
    this.onTap,
  });

  final GardenPlant plant;
  final double extent;
  final double tapExtent;
  final bool erasing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        label: plant.crop.name,
        button: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            key: ValueKey('placed-plant-${plant.id}'),
            width: tapExtent,
            height: tapExtent,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: extent,
                  height: extent,
                  child: CropIcon(plant.crop.iconPath, size: extent),
                ),
                if (erasing)
                  Positioned(
                    top: (tapExtent - extent) / 2 - 5,
                    right: (tapExtent - extent) / 2 - 5,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: C.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: C.card, width: 1.5),
                      ),
                      child: const Icon(
                        CupertinoIcons.clear,
                        color: CupertinoColors.white,
                        size: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _PlantSpacingGridPainter extends CustomPainter {
  const _PlantSpacingGridPainter(this.positions);

  final List<Offset> positions;

  @override
  void paint(Canvas canvas, Size size) {
    final axes = Paint()
      ..color = C.forest.withValues(alpha: .06)
      ..strokeWidth = .65;
    final dotFill = Paint()..color = C.forest.withValues(alpha: .09);
    final columns = positions.map((position) => position.dx).toSet();
    final rows = positions.map((position) => position.dy).toSet();
    for (final column in columns) {
      final x = column * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), axes);
    }
    for (final row in rows) {
      final y = row * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axes);
    }
    if (positions.length <= 90) {
      for (final position in positions) {
        canvas.drawCircle(
          Offset(position.dx * size.width, position.dy * size.height),
          2,
          dotFill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlantSpacingGridPainter oldDelegate) =>
      oldDelegate.positions != positions;
}

class _PlantingBandPainter extends CustomPainter {
  const _PlantingBandPainter({
    required this.bed,
    required this.plants,
    required this.spacingForPlant,
    this.drawBands = true,
    this.drawLabels = true,
  });

  final GardenBed bed;
  final List<GardenPlant> plants;
  final CropSpacing Function(GardenPlant plant)? spacingForPlant;
  final bool drawBands;
  final bool drawLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final plantsByCrop = <String, List<GardenPlant>>{};
    for (final plant in plants) {
      plantsByCrop.putIfAbsent(plant.crop.id, () => []).add(plant);
    }

    for (final cropPlants in plantsByCrop.values) {
      if (cropPlants.isEmpty) continue;
      final crop = cropPlants.first.crop;
      final spacing = spacingForPlant == null
          ? cropSpacingFor(crop)
          : spacingForPlant!(cropPlants.first);
      final band = _cropBandRect(cropPlants, spacing);
      final rect = Rect.fromLTRB(
        band.left * size.width,
        band.top * size.height,
        band.right * size.width,
        band.bottom * size.height,
      );
      if (rect.width < 10 || rect.height < 8) continue;

      final familyColor = _cropBandColor(crop);
      final fill = Paint()..color = familyColor.withValues(alpha: .18);
      final stroke = Paint()
        ..color = familyColor.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final radius = Radius.circular(rect.height < 26 ? 8 : 13);
      final rounded = RRect.fromRectAndRadius(rect, radius);
      if (drawBands) {
        canvas.drawRRect(rounded, fill);
        canvas.drawRRect(rounded, stroke);
        _drawCropTexture(canvas, rect.deflate(3), crop, familyColor);
      }

      if (!drawLabels || rect.width < 56 || rect.height < 14) continue;
      final label = _shortCropLabel(crop.name);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: C.ink.withValues(alpha: .78),
            fontSize: rect.height < 24 ? 9 : 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '',
      )..layout(maxWidth: rect.width - 10);
      final pill = Rect.fromCenter(
        center: rect.center,
        width: textPainter.width + 12,
        height: textPainter.height + 6,
      );
      if (pill.width < rect.width - 2 && pill.height < rect.height + 4) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(pill, const Radius.circular(999)),
          Paint()..color = C.card.withValues(alpha: .74),
        );
        textPainter.paint(
          canvas,
          Offset(
            pill.center.dx - textPainter.width / 2,
            pill.center.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }

  Rect _cropBandRect(List<GardenPlant> cropPlants, CropSpacing spacing) {
    final plantHalfWidth =
        (spacing.plantCm / 100 / bed.widthMeters / 2).clamp(.018, .08);
    final rowHalfHeight =
        (spacing.rowCm / 100 / bed.lengthMeters / 2).clamp(.018, .08);
    var left = 1.0;
    var top = 1.0;
    var right = 0.0;
    var bottom = 0.0;
    for (final plant in cropPlants) {
      left = plant.position.dx - plantHalfWidth < left
          ? plant.position.dx - plantHalfWidth
          : left;
      top = plant.position.dy - rowHalfHeight < top
          ? plant.position.dy - rowHalfHeight
          : top;
      right = plant.position.dx + plantHalfWidth > right
          ? plant.position.dx + plantHalfWidth
          : right;
      bottom = plant.position.dy + rowHalfHeight > bottom
          ? plant.position.dy + rowHalfHeight
          : bottom;
    }
    return Rect.fromLTRB(
      left.clamp(.015, .985),
      top.clamp(.015, .985),
      right.clamp(.015, .985),
      bottom.clamp(.015, .985),
    );
  }

  Color _cropBandColor(VegetableDefinition crop) => switch (crop.familyId) {
        'root_vegetables' => const Color(0xFFE08D3C),
        'alliums' => const Color(0xFF8E8BC8),
        'brassicas' => const Color(0xFF4E9F55),
        'leafy_greens' => const Color(0xFF65A83F),
        'legumes' => const Color(0xFF2B8E73),
        'apiaceae' => const Color(0xFF9AAB4F),
        'berries' => const Color(0xFFC44D62),
        'solanaceae' => const Color(0xFFD65A3A),
        'cucurbits' => const Color(0xFFE3A93B),
        _ => C.forest,
      };

  void _drawCropTexture(
    Canvas canvas,
    Rect rect,
    VegetableDefinition crop,
    Color familyColor,
  ) {
    if (rect.width < 18 || rect.height < 10) return;
    final seed = crop.id.hashCode.abs();
    final columns = (rect.width / 38).floor().clamp(2, 12);
    final rows = (rect.height / 28).floor().clamp(1, 4);
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final jitter = ((seed + row * 7 + column * 11) % 9 - 4) * .7;
        final center = Offset(
          rect.left + (column + .5) * rect.width / columns + jitter,
          rect.top + (row + .5) * rect.height / rows,
        );
        _drawCropMark(canvas, center, crop, familyColor);
      }
    }
  }

  void _drawCropMark(
    Canvas canvas,
    Offset center,
    VegetableDefinition crop,
    Color familyColor,
  ) {
    final leaf = Paint()..color = familyColor.withValues(alpha: .58);
    final dark = Paint()
      ..color = C.forest.withValues(alpha: .45)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final root = Paint()
      ..color = _cropRootColor(crop).withValues(alpha: .72)
      ..style = PaintingStyle.fill;

    if (crop.familyId == 'root_vegetables') {
      canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(0, 3), width: 7, height: 12),
        root,
      );
      canvas.drawLine(center + const Offset(0, -4), center, dark);
      canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(-3, -4), width: 8, height: 4),
        leaf,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(3, -4), width: 8, height: 4),
        leaf,
      );
      return;
    }

    if (crop.familyId == 'alliums' || crop.id == 'leek') {
      for (final offset in const [-4.0, 0.0, 4.0]) {
        canvas.drawLine(
          center + Offset(offset, 6),
          center + Offset(offset * .35, -7),
          dark,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(0, 6), width: 8, height: 5),
        root,
      );
      return;
    }

    if (crop.familyId == 'brassicas' || crop.familyId == 'leafy_greens') {
      for (var index = 0; index < 6; index++) {
        final angle = index * 1.047;
        final offset = Offset(
          6 * math.cos(angle),
          4 * math.sin(angle),
        );
        canvas.drawOval(
          Rect.fromCenter(center: center + offset, width: 10, height: 7),
          leaf,
        );
      }
      canvas.drawCircle(
          center, 3, Paint()..color = familyColor.withValues(alpha: .75));
      return;
    }

    canvas.drawCircle(
        center, 5, Paint()..color = familyColor.withValues(alpha: .62));
    canvas.drawLine(
        center + const Offset(-6, 4), center + const Offset(6, -4), dark);
  }

  Color _cropRootColor(VegetableDefinition crop) => switch (crop.id) {
        'carrot' => const Color(0xFFE8872F),
        'beetroot' => const Color(0xFF9E3152),
        'radish' => const Color(0xFFD94A68),
        'onion' => const Color(0xFFD08A32),
        'garlic' => const Color(0xFFE8D7A7),
        'leek' || 'spring_onion' => const Color(0xFF7AA95D),
        _ => const Color(0xFFC87A38),
      };

  String _shortCropLabel(String name) {
    final slash = name.split('/').first.trim();
    return slash.isEmpty ? name : slash;
  }

  @override
  bool shouldRepaint(covariant _PlantingBandPainter oldDelegate) =>
      oldDelegate.plants != plants || oldDelegate.bed != bed;
}

class _PlantPatch extends StatelessWidget {
  const _PlantPatch({required this.crop});

  final VegetableDefinition crop;

  @override
  Widget build(BuildContext context) => Container(
        width: 86,
        height: 80,
        padding: const EdgeInsets.fromLTRB(7, 8, 7, 6),
        decoration: BoxDecoration(
          color: C.card.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
          boxShadow: softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CropIcon(crop.iconPath, size: 39),
            const SizedBox(height: 4),
            Text(
              crop.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: C.ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _BedPlantingPainter extends CustomPainter {
  const _BedPlantingPainter(this.bed);

  final GardenBed bed;

  @override
  void paint(Canvas canvas, Size size) {
    final soil = Paint()
      ..color = const Color(0xFFB8946A).withValues(alpha: .10)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 25) {
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x + size.height, size.height),
        soil,
      );
    }
    final minor = Paint()
      ..color = C.soil.withValues(alpha: .07)
      ..strokeWidth = .55;
    final major = Paint()
      ..color = C.soil.withValues(alpha: .16)
      ..strokeWidth = .9;
    _drawMeterGrid(canvas, size, bed.widthMeters, true, minor, major);
    _drawMeterGrid(canvas, size, bed.lengthMeters, false, minor, major);
  }

  void _drawMeterGrid(
    Canvas canvas,
    Size size,
    double meters,
    bool vertical,
    Paint minor,
    Paint major,
  ) {
    if (meters <= 0) return;
    const step = .25;
    final steps = (meters / step).floor();
    for (var index = 1; index < steps; index++) {
      final meter = index * step;
      final fraction = meter / meters;
      final paint = index % 4 == 0 ? major : minor;
      if (vertical) {
        final x = fraction * size.width;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      } else {
        final y = fraction * size.height;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BedPlantingPainter oldDelegate) =>
      bed.widthMeters != oldDelegate.bed.widthMeters ||
      bed.lengthMeters != oldDelegate.bed.lengthMeters;
}

class GardenMap extends StatefulWidget {
  const GardenMap({
    required this.selectedBed,
    required this.plot,
    required this.gardenBeds,
    required this.bedCrops,
    required this.isHold,
    required this.designing,
    required this.onTap,
    required this.onMove,
    super.key,
  });
  final int selectedBed;
  final GardenPlot plot;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final bool Function(int bed) isHold;
  final bool designing;
  final ValueChanged<int> onTap;
  final void Function(int bed, Offset delta) onMove;

  @override
  State<GardenMap> createState() => _GardenMapState();
}

class _GardenMapState extends State<GardenMap> {
  int? draggingBed;
  Offset dragDelta = Offset.zero;

  void _startDrag(GardenBed bed) {
    widget.onTap(bed.number);
    setState(() {
      draggingBed = bed.number;
      dragDelta = Offset.zero;
    });
  }

  void _updateDrag(DragUpdateDetails details, Size size) {
    setState(() {
      dragDelta += Offset(
        details.delta.dx / size.width,
        details.delta.dy / size.height,
      );
    });
  }

  void _finishDrag(GardenBed bed) {
    final delta = dragDelta;
    if (delta != Offset.zero) {
      widget.onMove(bed.number, delta);
    }
    setState(() {
      draggingBed = null;
      dragDelta = Offset.zero;
    });
  }

  void _cancelDrag() {
    setState(() {
      draggingBed = null;
      dragDelta = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: GridPainter(widget.plot)),
              ),
              ...widget.gardenBeds.map((bed) {
                final visibleBed =
                    draggingBed == bed.number ? bed.move(dragDelta) : bed;
                final rect = Rect.fromLTWH(
                  visibleBed.rect.left * size.width,
                  visibleBed.rect.top * size.height,
                  visibleBed.rect.width * size.width,
                  visibleBed.rect.height * size.height,
                );
                return Positioned.fromRect(
                  rect: rect,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart:
                        widget.designing ? (_) => _startDrag(bed) : null,
                    onPanUpdate: widget.designing
                        ? (details) => _updateDrag(details, size)
                        : null,
                    onPanEnd: widget.designing ? (_) => _finishDrag(bed) : null,
                    onPanCancel: widget.designing ? _cancelDrag : null,
                    child: BedButton(
                      bed: visibleBed,
                      selected: widget.selectedBed == bed.number,
                      hold: widget.isHold(bed.number),
                      crops: widget.bedCrops[bed.number] ??
                          const <VegetableDefinition>[],
                      designing: widget.designing,
                      onTap: () => widget.onTap(bed.number),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      );
}

class BedButton extends StatelessWidget {
  const BedButton({
    required this.bed,
    required this.selected,
    required this.hold,
    required this.crops,
    required this.designing,
    required this.onTap,
    super.key,
  });
  final GardenBed bed;
  final bool selected;
  final bool hold;
  final bool designing;
  final List<VegetableDefinition> crops;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: hold
                ? C.amberSoft
                : crops.isEmpty
                    ? C.card
                    : C.forestSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? C.forest : C.soil,
              width: selected ? 2.4 : 1.2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      designing
                          ? '${bed.label}\n${bed.sizeLabel}'
                          : '${bed.number}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              if (crops.isNotEmpty && !designing)
                Positioned(
                    top: -12, right: -12, child: IconCluster(crops: crops)),
            ],
          ),
        ),
      );
}

class _GardenIconButton extends StatelessWidget {
  const _GardenIconButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        button: true,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          color: C.card,
          disabledColor: C.greySoft,
          borderRadius: BorderRadius.circular(12),
          onPressed: onPressed,
          child: Icon(icon,
              color: onPressed == null ? C.muted : C.forest, size: 18),
        ),
      );
}

void showBedNameEditor(
  BuildContext context,
  GardenBed bed,
  ValueChanged<String> onSave,
) {
  final controller = TextEditingController(text: bed.name);
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(title: 'Bed name', subtitle: 'Bed ${bed.number}'),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                Field(controller: controller, placeholder: bed.label),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Save name',
                  onPressed: () {
                    onSave(controller.text);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}

void showBedSizeEditor(
  BuildContext context,
  GardenBed bed,
  GardenPlot plot,
  void Function(double widthMeters, double lengthMeters) onSave,
) {
  final width = TextEditingController(text: meterLabel(bed.widthMeters));
  final length = TextEditingController(text: meterLabel(bed.lengthMeters));
  String? error;
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setSheetState) => Sheet(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SheetHeader(title: 'Bed size', subtitle: bed.label),
            const SizedBox(height: 12),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MeterField(
                          label: 'Width',
                          controller: width,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MeterField(
                          label: 'Length',
                          controller: length,
                        ),
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: C.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Save size',
                    onPressed: () {
                      final widthMeters = _readMeterInput(width.text);
                      final lengthMeters = _readMeterInput(length.text);
                      if (widthMeters == null || lengthMeters == null) {
                        setSheetState(
                          () => error = 'Enter width and length in metres.',
                        );
                        return;
                      }
                      if (widthMeters > plot.widthMeters ||
                          lengthMeters > plot.lengthMeters) {
                        setSheetState(
                          () => error = 'Bed must fit inside this plot.',
                        );
                        return;
                      }
                      onSave(widthMeters, lengthMeters);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(() {
    width.dispose();
    length.dispose();
  });
}

void showGardenPlotEditor(
  BuildContext context,
  GardenPlot plot,
  List<GardenBed> beds,
  void Function(double widthMeters, double lengthMeters) onSave,
) {
  final width = TextEditingController(text: meterLabel(plot.widthMeters));
  final length = TextEditingController(text: meterLabel(plot.lengthMeters));
  String? error;
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setSheetState) => Sheet(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SheetHeader(title: 'Plot size', subtitle: 'Garden boundary'),
            const SizedBox(height: 12),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MeterField(
                          label: 'Width',
                          controller: width,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MeterField(
                          label: 'Length',
                          controller: length,
                        ),
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: C.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Save plot',
                    onPressed: () {
                      final widthMeters = _readMeterInput(width.text);
                      final lengthMeters = _readMeterInput(length.text);
                      if (widthMeters == null || lengthMeters == null) {
                        setSheetState(
                          () => error = 'Enter width and length in metres.',
                        );
                        return;
                      }
                      final widestBed = beds.fold(
                        0.0,
                        (widest, bed) =>
                            bed.widthMeters > widest ? bed.widthMeters : widest,
                      );
                      final longestBed = beds.fold(
                        0.0,
                        (longest, bed) => bed.lengthMeters > longest
                            ? bed.lengthMeters
                            : longest,
                      );
                      if (widthMeters < widestBed ||
                          lengthMeters < longestBed) {
                        setSheetState(
                          () => error = 'Plot must fit the largest bed.',
                        );
                        return;
                      }
                      onSave(widthMeters, lengthMeters);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(() {
    width.dispose();
    length.dispose();
  });
}

double? _readMeterInput(String value) {
  final metres = double.tryParse(value.trim().replaceAll(',', '.'));
  return metres != null && metres > 0 ? metres : null;
}

class _MeterField extends StatelessWidget {
  const _MeterField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label (m)',
            style: const TextStyle(
              color: C.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          CupertinoTextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.line),
            ),
          ),
        ],
      );
}

class IconCluster extends StatelessWidget {
  const IconCluster({required this.crops, super.key});
  final List<VegetableDefinition> crops;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 104),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line),
          boxShadow: softShadow,
        ),
        child: Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            ...crops.take(3).map((crop) => CropIcon(crop.iconPath, size: 20)),
            if (crops.length > 3) CountDot(crops.length - 3),
          ],
        ),
      );
}

class SprayLogScreen extends StatefulWidget {
  const SprayLogScreen({
    required this.initialBeds,
    required this.gardenBeds,
    required this.bedCrops,
    required this.products,
    required this.productsLoading,
    required this.sprayConditions,
    required this.onSave,
    super.key,
  });
  final Set<int> initialBeds;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayProduct> products;
  final bool productsLoading;
  final Future<SprayConditionSummary> sprayConditions;
  final void Function({
    required Set<int> beds,
    required Set<String> crops,
    required Map<String, OpenFarmCrop> cropProfiles,
    required String targetId,
    required SprayProduct product,
    required String reason,
    required String notes,
    required int days,
  }) onSave;

  @override
  State<SprayLogScreen> createState() => _SprayLogScreenState();
}

class _SprayLogScreenState extends State<SprayLogScreen> {
  late Set<int> beds = {...widget.initialBeds};
  final Set<String> manualCrops = {};
  final Map<String, OpenFarmCrop> cropProfiles = {};
  String targetId = 'pest';
  SprayProduct? selectedProduct;
  int days = 0;
  final reason = TextEditingController();
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.products.isNotEmpty) {
      _selectProduct(_bestProductForTarget('pest'));
    }
  }

  @override
  void dispose() {
    reason.dispose();
    notes.dispose();
    super.dispose();
  }

  SprayProduct _bestProductForTarget(String target) {
    return widget.products.firstWhere(
      (product) => product.targets.contains(target),
      orElse: () => widget.products.first,
    );
  }

  void _selectProduct(SprayProduct product) {
    selectedProduct = product;
    days = product.withholdingDays;
  }

  @override
  Widget build(BuildContext context) {
    final product = selectedProduct;
    final crops = {
      ...cropNamesForBeds(widget.bedCrops, beds),
      ...manualCrops,
    }.toList()
      ..sort();
    return AppPage(
      title: 'Spray Log',
      subtitle:
          'Choose product, then withholding and re-entry notes fill automatically.',
      children: [
        SprayConditionBanner(sprayConditions: widget.sprayConditions),
        const SizedBox(height: 18),
        const SectionTitle('Beds sprayed'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.gardenBeds
              .map(
                (bed) => NumberChip(
                  label: '${bed.number}',
                  selected: beds.contains(bed.number),
                  onTap: () => setState(
                    () => beds.contains(bed.number)
                        ? beds.remove(bed.number)
                        : beds.add(bed.number),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        const SectionTitle('Crops affected'),
        const SizedBox(height: 8),
        if (crops.isEmpty)
          const EmptyCard('No crops assigned to selected bed yet.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: crops.map((crop) => TextChip(label: crop)).toList(),
          ),
        const SizedBox(height: 8),
        CropLookupField(
          onCropChosen: (name, crop) => setState(() {
            manualCrops.add(name);
            if (crop != null) {
              cropProfiles[name] = crop;
            }
          }),
        ),
        if (crops.isNotEmpty) ...[
          const SizedBox(height: 8),
          OpenFarmCropInfoSection(cropName: crops.first),
        ],
        const SizedBox(height: 18),
        const SectionTitle('Spraying against'),
        const SizedBox(height: 8),
        TargetGrid(
          selected: targetId,
          onSelect: (id) => setState(() {
            targetId = id;
            if (widget.products.isNotEmpty) {
              _selectProduct(_bestProductForTarget(id));
            }
          }),
        ),
        const SizedBox(height: 18),
        const SectionTitle('NZ product library'),
        const SizedBox(height: 8),
        if (widget.productsLoading)
          const Center(child: CupertinoActivityIndicator())
        else if (widget.products.isEmpty)
          const EmptyCard('No products loaded.')
        else
          ...widget.products.map(
            (item) => ProductChoice(
              product: item,
              selected: product?.id == item.id,
              suggested: item.targets.contains(targetId),
              onTap: () => setState(() => _selectProduct(item)),
            ),
          ),
        const SizedBox(height: 18),
        Field(
          controller: reason,
          placeholder: 'Issue or reason, e.g. aphids on tomato tips',
        ),
        const SizedBox(height: 8),
        Field(controller: notes, placeholder: 'Notes optional', maxLines: 3),
        const SizedBox(height: 12),
        Stepper(
          label: 'Withholding days',
          value: days,
          minus: days > 0 ? () => setState(() => days--) : null,
          plus: () => setState(() => days++),
        ),
        if (product != null) ...[
          const SizedBox(height: 8),
          SprayProductHelperNotes(product: product),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Save spray record',
          onPressed: product == null || beds.isEmpty
              ? null
              : () => widget.onSave(
                    beds: beds,
                    crops: crops.toSet(),
                    cropProfiles: cropProfiles,
                    targetId: targetId,
                    product: product,
                    reason: reason.text,
                    notes: notes.text,
                    days: days,
                  ),
        ),
      ],
    );
  }
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({
    required this.products,
    required this.loading,
    required this.message,
    super.key,
  });
  final List<SprayProduct> products;
  final bool loading;
  final String message;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim();
    final filtered = widget.products
        .where((product) => product.matchesQuery(query))
        .toList();
    return AppPage(
      title: 'Products',
      subtitle:
          'Bundled NZ spray products. Verify labels and ACVM details before use.',
      message: widget.message,
      children: [
        CupertinoTextField(
          controller: search,
          placeholder: 'Search product, pest, crop, active ingredient...',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.search, color: C.muted, size: 19),
          ),
          padding: const EdgeInsets.all(13),
          onChanged: (_) => setState(() {}),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line),
          ),
        ),
        const SizedBox(height: 12),
        SectionTitle(
          'NZ spray product library',
          trailing: Text(
            '${filtered.length}',
            style: const TextStyle(color: C.muted, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CupertinoActivityIndicator(),
            ),
          )
        else if (filtered.isEmpty)
          const EmptyCard('No products match that search.')
        else
          ...filtered.map((product) => ProductTile(product: product)),
      ],
    );
  }
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({
    required this.records,
    required this.message,
    required this.onDelete,
    super.key,
  });
  final List<SprayRecord> records;
  final String message;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Records',
        subtitle: 'Saved sprays, target, product, and safe harvest date.',
        message: message,
        children: [
          if (records.isEmpty)
            const EmptyCard('No spray records yet.')
          else
            ...records.map(
              (record) => RecordCard(
                  record: record, onDelete: () => onDelete(record.id)),
            ),
        ],
      );
}

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, super.key});
  final SprayProduct product;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => showSprayProductDetail(context, product),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  CategoryPill(category: product.category),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${product.brand} | ${product.type}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: C.muted, fontWeight: FontWeight.w700),
              ),
              Text(
                product.activeIngredient,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: C.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ProductTag(
                    label: '${product.withholdingDays} day WHP',
                    color: C.forest,
                    background: C.forestSoft,
                  ),
                  ProductTag(
                    label: 'Re-entry: ${product.reEntryHours} hr',
                    color: C.blue,
                    background: C.blueSoft,
                  ),
                  if (product.reSprayIntervalDays > 0)
                    ProductTag(
                      label: 'Re-spray: ${product.reSprayIntervalDays} days',
                      color: C.amber,
                      background: C.amberSoft,
                    ),
                ],
              ),
              if (product.commonUses.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Uses: ${product.commonUses.take(5).join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class ProductChoice extends StatelessWidget {
  const ProductChoice({
    required this.product,
    required this.selected,
    required this.suggested,
    required this.onTap,
    super.key,
  });
  final SprayProduct product;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? C.forestSoft : C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? C.forest : C.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${product.type} | ${product.withholdingDays} day WHP | Re-entry ${product.reEntryHours} hr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (suggested) ...[
                const SizedBox(width: 8),
                const StatusPill('MATCH', hold: false),
              ],
              const SizedBox(width: 8),
              Icon(
                selected
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                color: selected ? C.forest : C.muted,
                size: 22,
              ),
            ],
          ),
        ),
      );
}

class SprayProductHelperNotes extends StatelessWidget {
  const SprayProductHelperNotes({required this.product, super.key});
  final SprayProduct product;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.withholdingNote.isNotEmpty)
              Text(
                product.withholdingNote,
                style: const TextStyle(
                  color: C.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            Text(
              'Re-entry: ${product.reEntryHours} hr',
              style: const TextStyle(
                color: C.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (product.reSprayIntervalDays > 0)
              Text(
                'Re-spray interval: ${product.reSprayIntervalDays} days',
                style: const TextStyle(
                  color: C.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
}

void showSprayProductDetail(BuildContext context, SprayProduct product) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(
            title: product.name,
            subtitle: '${product.brand} | ${product.type}',
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailLine('Category', product.category),
                DetailLine('Active ingredient', product.activeIngredient),
                DetailLine('Withholding days', '${product.withholdingDays}'),
                DetailLine('Withholding note', product.withholdingNote),
                DetailLine('Re-entry hours', '${product.reEntryHours}'),
                DetailLine(
                  'Re-spray interval',
                  product.reSprayIntervalDays > 0
                      ? '${product.reSprayIntervalDays} days'
                      : 'Not set',
                ),
                DetailLine('Common uses', product.commonUses.join(', ')),
                DetailLine('Suitable crops', product.suitableCrops.join(', ')),
                DetailLine(
                  'ACVM number',
                  product.acvmRegistrationNumber.isEmpty
                      ? 'Not filled yet'
                      : product.acvmRegistrationNumber,
                ),
                DetailLine('Source', product.source),
                DetailLine(
                  'Notes',
                  product.notes.isEmpty ? 'None' : product.notes,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void showCropPlanner(
  BuildContext context,
  GardenBed bed,
  List<VegetableDefinition> assigned,
  List<GardenPlant> plants,
  GardenPlant Function(
    int bed,
    VegetableDefinition crop,
    Offset position,
  ) onAdd,
  List<GardenPlant> Function(
    int bed,
    VegetableDefinition crop,
    List<Offset> positions,
  ) onAddMany,
  void Function(int bed, int plantId) onRemove,
) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => _BedCropPlannerSheet(
      bed: bed,
      assigned: assigned,
      plants: plants,
      onAdd: onAdd,
      onAddMany: onAddMany,
      onRemove: onRemove,
    ),
  );
}

class _BedCropPlannerSheet extends StatefulWidget {
  const _BedCropPlannerSheet({
    required this.bed,
    required this.assigned,
    required this.plants,
    required this.onAdd,
    required this.onAddMany,
    required this.onRemove,
  });

  final GardenBed bed;
  final List<VegetableDefinition> assigned;
  final List<GardenPlant> plants;
  final GardenPlant Function(
    int bed,
    VegetableDefinition crop,
    Offset position,
  ) onAdd;
  final List<GardenPlant> Function(
    int bed,
    VegetableDefinition crop,
    List<Offset> positions,
  ) onAddMany;
  final void Function(int bed, int plantId) onRemove;

  @override
  State<_BedCropPlannerSheet> createState() => _BedCropPlannerSheetState();
}

class _BedCropPlannerSheetState extends State<_BedCropPlannerSheet> {
  final search = TextEditingController();
  final plannerScroll = ScrollController();
  final Map<String, CropSpacing> cropSpacings = {};
  final Map<String, Future<CropSpacing>> cropSpacingLookups = {};
  late List<GardenPlant> plants = [...widget.plants];
  late VegetableDefinition selectedCrop =
      widget.assigned.isEmpty ? vegetableLibrary.first : widget.assigned.first;
  late CropSpacing spacing = cropSpacingFor(selectedCrop);
  Offset? rowPaintStart;
  List<Offset> rowPreview = const [];
  bool rowPaintCancelled = false;
  AutoBedFoodStyle generatorStyle = AutoBedFoodStyle.balanced;
  AutoBedPlanResult? lastAutoPlan;
  bool spacingLoading = false;
  bool erasing = false;
  String familyId = 'all';

  @override
  void initState() {
    super.initState();
    _preloadBedSpacings();
    _loadSpacing(selectedCrop);
  }

  @override
  void dispose() {
    search.dispose();
    plannerScroll.dispose();
    super.dispose();
  }

  List<VegetableDefinition> get crops {
    final query = search.text.trim().toLowerCase();
    return vegetableLibrary.where((crop) {
      final family = familyById(crop.familyId);
      final matchesFamily = familyId == 'all' || crop.familyId == familyId;
      final matchesQuery = query.isEmpty ||
          crop.name.toLowerCase().contains(query) ||
          family.name.toLowerCase().contains(query);
      return matchesFamily && matchesQuery;
    }).toList(growable: false);
  }

  int _plantCount(VegetableDefinition crop) =>
      plants.where((plant) => plant.crop.id == crop.id).length;

  List<Offset> get grid => plantingGridPositions(widget.bed, spacing);

  CropSpacing _knownSpacing(VegetableDefinition crop) =>
      cropSpacings[crop.id] ?? cropSpacingFor(crop);

  void _preloadBedSpacings() {
    final cropsById = {
      for (final crop in widget.assigned) crop.id: crop,
      for (final plant in plants) plant.crop.id: plant.crop,
      for (final item in companionAwareAutoBedCropMix(generatorStyle))
        item.cropId: vegetableLibrary.firstWhere(
          (crop) => crop.id == item.cropId,
          orElse: () => vegetableLibrary.first,
        ),
    };
    for (final crop in cropsById.values) {
      unawaited(_lookupSpacing(crop));
    }
  }

  Future<CropSpacing> _lookupSpacing(VegetableDefinition crop) =>
      cropSpacingLookups.putIfAbsent(crop.id, () async {
        final profile = await OpenFarmService.instance.getCropByName(crop.name);
        final resolved = cropSpacingFor(crop, profile);
        if (!mounted) return resolved;
        setState(() {
          cropSpacings[crop.id] = resolved;
        });
        return resolved;
      });

  Future<void> _loadSpacing(VegetableDefinition crop) async {
    setState(() {
      spacing = _knownSpacing(crop);
      spacingLoading = true;
    });
    final resolved = await _lookupSpacing(crop);
    if (!mounted || selectedCrop.id != crop.id) return;
    setState(() {
      spacing = resolved;
      spacingLoading = false;
    });
  }

  void _place(Offset position) {
    if (erasing || spacingLoading) return;
    final openSpot = nearestOpenPlantSpot(
      widget.bed,
      position,
      grid,
      spacing,
      plants,
      (plant) => _knownSpacing(plant.crop),
    );
    if (openSpot == null) return;
    final plant = widget.onAdd(widget.bed.number, selectedCrop, openSpot);
    setState(() {
      plants = [...plants, plant];
    });
  }

  void _startRowPaint(Offset position) {
    if (erasing || spacingLoading) return;
    rowPaintStart = position;
    rowPaintCancelled = false;
    _updateRowPreview(position);
  }

  void _updateRowPreview(Offset position) {
    final start = rowPaintStart;
    if (start == null || erasing || spacingLoading || rowPaintCancelled) return;
    setState(() {
      rowPreview = rowPlantPreviewSpots(
        widget.bed,
        grid,
        start,
        position,
        spacing,
        plants,
        (plant) => _knownSpacing(plant.crop),
      );
    });
  }

  void _cancelRowPaint() {
    if (rowPaintStart == null && rowPreview.isEmpty && !rowPaintCancelled) {
      return;
    }
    setState(() {
      rowPaintStart = null;
      rowPreview = const [];
      rowPaintCancelled = true;
    });
  }

  void _commitRowPaint() {
    if (rowPaintCancelled || rowPreview.isEmpty) {
      _cancelRowPaint();
      return;
    }
    final positions = [...rowPreview];
    final added = widget.onAddMany(widget.bed.number, selectedCrop, positions);
    setState(() {
      plants = [...plants, ...added];
      rowPaintStart = null;
      rowPreview = const [];
      rowPaintCancelled = false;
    });
  }

  void _erase(GardenPlant plant) {
    if (!erasing) return;
    setState(() {
      plants = plants.where((item) => item.id != plant.id).toList();
    });
    widget.onRemove(widget.bed.number, plant.id);
  }

  void _selectCrop(VegetableDefinition crop, {bool returnToBed = false}) {
    setState(() {
      selectedCrop = crop;
      erasing = false;
      rowPaintStart = null;
      rowPreview = const [];
      rowPaintCancelled = false;
    });
    _loadSpacing(crop);
    if (!returnToBed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !plannerScroll.hasClients) return;
      plannerScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _fillGrid() {
    if (erasing || spacingLoading) return;
    final positions = openPlantGridSpots(
      widget.bed,
      grid,
      spacing,
      plants,
      (plant) => _knownSpacing(plant.crop),
    );
    if (positions.isEmpty) return;
    final added = widget.onAddMany(widget.bed.number, selectedCrop, positions);
    setState(() {
      plants = [...plants, ...added];
    });
  }

  void _clearBed() {
    if (plants.isEmpty) return;
    final removedPlants = [...plants];
    setState(() {
      plants = const [];
      lastAutoPlan = null;
      rowPaintStart = null;
      rowPreview = const [];
      rowPaintCancelled = false;
    });
    for (final plant in removedPlants) {
      widget.onRemove(widget.bed.number, plant.id);
    }
  }

  void _selectGeneratorStyle(AutoBedFoodStyle style) {
    setState(() {
      generatorStyle = style;
      lastAutoPlan = null;
    });
    for (final item in companionAwareAutoBedCropMix(style)) {
      final crop = vegetableLibrary.firstWhere(
        (crop) => crop.id == item.cropId,
        orElse: () => vegetableLibrary.first,
      );
      unawaited(_lookupSpacing(crop));
    }
  }

  void _generateAutoBed() {
    if (erasing || spacingLoading) return;
    final replacedPlants = [...plants];
    final plan = generateAutoBedPlan(
      bed: widget.bed,
      style: generatorStyle,
      existingPlants: const <GardenPlant>[],
      spacingForCrop: _knownSpacing,
      spacingForPlant: (plant) => _knownSpacing(plant.crop),
    );
    if (plan.totalPlants == 0) {
      setState(() => lastAutoPlan = plan);
      return;
    }

    for (final plant in replacedPlants) {
      widget.onRemove(widget.bed.number, plant.id);
    }
    final added = <GardenPlant>[];
    for (final entry in plan.placements.entries) {
      added.addAll(
        widget.onAddMany(widget.bed.number, entry.key, entry.value),
      );
    }
    setState(() {
      plants = added;
      selectedCrop = plan.crops.first;
      spacing = _knownSpacing(selectedCrop);
      lastAutoPlan = plan;
      erasing = false;
      rowPaintStart = null;
      rowPreview = const [];
      rowPaintCancelled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = crops;
    final season = gardenSeasonForDate(DateTime.now());
    return Sheet(
      child: ListView(
        controller: plannerScroll,
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(title: 'Plant bed', subtitle: widget.bed.label),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                CupertinoSlidingSegmentedControl<bool>(
                  groupValue: erasing,
                  children: const {
                    false: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Plant'),
                    ),
                    true: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Erase'),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) setState(() => erasing = value);
                  },
                ),
                const SizedBox(height: 12),
                _CropSpacingBanner(
                  crop: selectedCrop,
                  spacing: spacing,
                  count: _plantCount(selectedCrop),
                  loading: spacingLoading,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PlannerActionPill(
                      label: 'Fill',
                      icon: CupertinoIcons.square_grid_2x2,
                      onPressed: erasing || spacingLoading ? null : _fillGrid,
                    ),
                    const SizedBox(width: 8),
                    _PlannerActionPill(
                      label: 'Clear',
                      icon: CupertinoIcons.clear,
                      onPressed: plants.isEmpty ? null : _clearBed,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _BedPlantingCanvas(
                  bed: widget.bed,
                  crops: widget.assigned,
                  plants: plants,
                  gridPositions: grid,
                  previewPositions: rowPreview,
                  previewCrop: selectedCrop,
                  previewSpacing: spacing,
                  height: 236,
                  erasing: erasing,
                  spacingForPlant: (plant) => _knownSpacing(plant.crop),
                  onPlace: spacingLoading ? null : _place,
                  onPlantTap: erasing ? _erase : null,
                  onPaintStart:
                      erasing || spacingLoading ? null : _startRowPaint,
                  onPaintUpdate:
                      erasing || spacingLoading ? null : _updateRowPreview,
                  onPaintEnd:
                      erasing || spacingLoading ? null : _commitRowPaint,
                  onPaintCancel: _cancelRowPaint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  'Auto design',
                  trailing: ProductTag(
                    label: '${season.label} Blenheim',
                    color: C.forest,
                    background: C.forestSoft,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final style in AutoBedFoodStyle.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _AutoBedStyleButton(
                            style: style,
                            selected: generatorStyle == style,
                            onTap: () => _selectGeneratorStyle(style),
                          ),
                        ),
                    ],
                  ),
                ),
                if (lastAutoPlan != null) ...[
                  const SizedBox(height: 10),
                  _AutoBedResultSummary(plan: lastAutoPlan!),
                ],
                const SizedBox(height: 10),
                PrimaryButton(
                  label:
                      plants.isEmpty ? 'Generate bed layout' : 'Regenerate bed',
                  onPressed:
                      erasing || spacingLoading ? null : _generateAutoBed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CupertinoSearchTextField(
            controller: search,
            placeholder: 'Search vegetables',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CropFamilyButton(
                  label: 'All',
                  selected: familyId == 'all',
                  onTap: () => setState(() => familyId = 'all'),
                ),
                ...vegetableFamilies.map(
                  (family) => Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: _CropFamilyButton(
                      label: family.name,
                      iconPath: family.iconPath,
                      selected: familyId == family.id,
                      onTap: () => setState(() => familyId = family.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.08,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final crop = filtered[index];
              return _CropPaletteCard(
                crop: crop,
                selected: selectedCrop.id == crop.id && !erasing,
                count: _plantCount(crop),
                onTap: () => _selectCrop(crop, returnToBed: true),
              );
            },
          ),
          if (filtered.isEmpty)
            const EmptyInline('No vegetables match this filter.'),
        ],
      ),
    );
  }
}

class _CropSpacingBanner extends StatelessWidget {
  const _CropSpacingBanner({
    required this.crop,
    required this.spacing,
    required this.count,
    required this.loading,
  });

  final VegetableDefinition crop;
  final CropSpacing spacing;
  final int count;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('selected-crop-${crop.id}'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
        child: Row(
          children: [
            CropIcon(crop.iconPath, size: 34),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: C.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${spacing.label} | ${spacing.source}',
                    style: const TextStyle(
                      color: C.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const CupertinoActivityIndicator(radius: 8)
            else
              ProductTag(
                label: '$count planted',
                color: C.forest,
                background: C.forestSoft,
              ),
          ],
        ),
      );
}

class _PlannerActionPill extends StatelessWidget {
  const _PlannerActionPill({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: onPressed == null ? C.soft : C.forestSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: C.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: onPressed == null ? C.muted : C.forest,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: onPressed == null ? C.muted : C.forest,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}

class _AutoBedStyleButton extends StatelessWidget {
  const _AutoBedStyleButton({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final AutoBedFoodStyle style;
  final bool selected;
  final VoidCallback onTap;

  IconData get icon => switch (style) {
        AutoBedFoodStyle.quick => CupertinoIcons.timer,
        AutoBedFoodStyle.balanced => CupertinoIcons.square_grid_2x2,
        AutoBedFoodStyle.longHold => CupertinoIcons.archivebox,
        AutoBedFoodStyle.salad => CupertinoIcons.leaf_arrow_circlepath,
      };

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? C.forest : C.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? C.forest : C.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? CupertinoColors.white : C.muted,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                style.shortLabel,
                style: TextStyle(
                  color: selected ? CupertinoColors.white : C.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}

class _AutoBedResultSummary extends StatelessWidget {
  const _AutoBedResultSummary({required this.plan});

  final AutoBedPlanResult plan;

  @override
  Widget build(BuildContext context) {
    if (plan.totalPlants == 0) {
      return const EmptyInline('No open planting spots in this bed.');
    }
    final crops = plan.placements.entries.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: C.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${plan.totalPlants} plants | ${plan.placements.length} crops',
              style: const TextStyle(
                color: C.forest,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final entry in crops)
                  ProductTag(
                    label: entry.key.name,
                    color: C.forest,
                    background: C.card,
                  ),
                if (plan.placements.length > crops.length)
                  ProductTag(
                    label: '+${plan.placements.length - crops.length}',
                    color: C.muted,
                    background: C.card,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropFamilyButton extends StatelessWidget {
  const _CropFamilyButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconPath,
  });

  final String label;
  final String? iconPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: selected ? C.forest : C.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? C.forest : C.line),
          ),
          child: Row(
            children: [
              if (iconPath != null) ...[
                CropIcon(iconPath!, size: 24),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? CupertinoColors.white : C.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}

class _CropPaletteCard extends StatelessWidget {
  const _CropPaletteCard({
    required this.crop,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final VegetableDefinition crop;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? C.forestSoft : C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? C.forest : C.line,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  selected
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.add_circled,
                  color: selected ? C.forest : C.muted,
                  size: 20,
                ),
              ),
              if (count > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  child: ProductTag(
                    label: '$count',
                    color: C.forest,
                    background: C.card,
                  ),
                ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CropIcon(crop.iconPath, size: 54),
                    const SizedBox(height: 8),
                    Text(
                      crop.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class CropLookupField extends StatefulWidget {
  const CropLookupField({required this.onCropChosen, super.key});

  final void Function(String cropName, OpenFarmCrop? crop) onCropChosen;

  @override
  State<CropLookupField> createState() => _CropLookupFieldState();
}

class _CropLookupFieldState extends State<CropLookupField> {
  final controller = TextEditingController();
  Timer? debounce;
  List<OpenFarmCrop> suggestions = const [];
  bool loading = false;
  bool searched = false;

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    debounce?.cancel();

    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        suggestions = const [];
        loading = false;
        searched = false;
      });
      return;
    }

    setState(() {
      loading = true;
      searched = false;
    });

    debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await OpenFarmService.instance.searchCrops(query);
      if (!mounted) return;
      setState(() {
        suggestions = results.take(8).toList();
        loading = false;
        searched = true;
      });
    });
  }

  void _choose(OpenFarmCrop crop) {
    controller.text = crop.name;
    widget.onCropChosen(crop.name, crop);
    setState(() {
      suggestions = const [];
      searched = false;
      loading = false;
    });
  }

  void _addManual() {
    final clean = controller.text.trim();
    if (clean.isEmpty) return;
    widget.onCropChosen(clean, null);
    setState(() {
      controller.clear();
      suggestions = const [];
      searched = false;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canAddManual = controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: 'Search crop, e.g. tomato, lettuce, carrot...',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.search, color: C.muted, size: 19),
          ),
          suffix: canAddManual
              ? CupertinoButton(
                  padding: const EdgeInsets.only(right: 10),
                  minimumSize: Size.zero,
                  onPressed: _addManual,
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: C.forest,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : null,
          padding: const EdgeInsets.all(13),
          onChanged: _search,
          onSubmitted: (_) => _addManual(),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line),
          ),
        ),
        if (loading)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.line),
            ),
            child: const Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 10),
                Text(
                  'Searching OpenFarm...',
                  style: TextStyle(color: C.muted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        if (!loading && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: cardDecoration(radius: 16),
            child: Column(
              children: suggestions
                  .map(
                    (crop) => CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _choose(crop),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: C.line)),
                        ),
                        child: Row(
                          children: [
                            OpenFarmImageBox(imageUrl: crop.imageUrl, size: 42),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crop.name,
                                    style: const TextStyle(
                                      color: C.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    crop.sunRequirements.isEmpty
                                        ? 'OpenFarm crop profile'
                                        : crop.sunRequirements,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: C.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        if (!loading && searched && suggestions.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.line),
            ),
            child: const Text(
              'No matches - type to enter manually',
              style: TextStyle(color: C.muted, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class OpenFarmCropInfoSection extends StatefulWidget {
  const OpenFarmCropInfoSection({required this.cropName, super.key});

  final String cropName;

  @override
  State<OpenFarmCropInfoSection> createState() =>
      _OpenFarmCropInfoSectionState();
}

class _OpenFarmCropInfoSectionState extends State<OpenFarmCropInfoSection> {
  Future<OpenFarmCrop?>? future;

  @override
  void initState() {
    super.initState();
    future = OpenFarmService.instance.getCropByName(widget.cropName);
  }

  @override
  void didUpdateWidget(covariant OpenFarmCropInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropName != widget.cropName) {
      future = OpenFarmService.instance.getCropByName(widget.cropName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpenFarmCrop?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.soft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.line),
            ),
            child: const Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 10),
                Text(
                  'Loading crop info...',
                  style: TextStyle(color: C.muted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }

        final crop = snapshot.data;
        if (crop == null) return const SizedBox.shrink();

        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => showOpenFarmCropDetail(context, crop),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.forestSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OpenFarmImageBox(imageUrl: crop.imageUrl, size: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crop info',
                        style: TextStyle(
                          color: C.forest,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        crop.name,
                        style: const TextStyle(
                          color: C.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (crop.sunRequirements.isNotEmpty)
                        Text(
                          crop.sunRequirements,
                          style: const TextStyle(
                            color: C.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (crop.description.isNotEmpty)
                        Text(
                          crop.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: C.ink,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      const SizedBox(height: 4),
                      const Text(
                        'via OpenFarm',
                        style: TextStyle(
                          color: C.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: C.muted,
                  size: 17,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OpenFarmImageBox extends StatelessWidget {
  const OpenFarmImageBox({
    required this.imageUrl,
    required this.size,
    super.key,
  });

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: const Icon(CupertinoIcons.leaf_arrow_circlepath, color: C.forest),
    );

    if (imageUrl.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

void showOpenFarmCropDetail(BuildContext context, OpenFarmCrop crop) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: crop.imageUrl.isEmpty
                ? Container(
                    height: 190,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: C.forestSoft,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      CupertinoIcons.leaf_arrow_circlepath,
                      color: C.forest,
                      size: 46,
                    ),
                  )
                : Image.network(
                    crop.imageUrl,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Container(
                                height: 210,
                                alignment: Alignment.center,
                                color: C.forestSoft,
                                child: const CupertinoActivityIndicator(),
                              ),
                    errorBuilder: (_, __, ___) => Container(
                      height: 210,
                      alignment: Alignment.center,
                      color: C.forestSoft,
                      child: const Icon(
                        CupertinoIcons.leaf_arrow_circlepath,
                        color: C.forest,
                        size: 46,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SheetHeader(title: crop.name, subtitle: 'OpenFarm crop profile'),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop.description.isEmpty
                      ? 'No OpenFarm description listed.'
                      : crop.description,
                  style: const TextStyle(
                    color: C.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.35,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                OpenFarmFact(label: 'Sun', value: crop.sunRequirements),
                OpenFarmFact(label: 'Sowing', value: crop.sowingMethod),
                OpenFarmFact(label: 'Spread', value: formatCm(crop.spread)),
                OpenFarmFact(
                  label: 'Row spacing',
                  value: formatCm(crop.rowSpacing),
                ),
                OpenFarmFact(label: 'Height', value: formatCm(crop.height)),
              ],
            ),
          ),
          if (crop.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: crop.tags
                  .map(
                    (tag) => ProductTag(
                      label: tag,
                      color: C.muted,
                      background: C.greySoft,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          CupertinoButton(
            color: C.forest,
            borderRadius: BorderRadius.circular(16),
            onPressed: () async {
              try {
                await launchUrl(
                  Uri.parse(crop.openFarmUrl),
                  mode: LaunchMode.externalApplication,
                );
              } catch (_) {}
            },
            child: const Text(
              'View on OpenFarm',
              style: TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class OpenFarmFact extends StatelessWidget {
  const OpenFarmFact({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: C.forest,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.isEmpty ? '-' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: C.ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}

String formatCm(double? value) {
  if (value == null) return '-';
  final rounded = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$rounded cm';
}

class BottomNav extends StatelessWidget {
  const BottomNav({required this.tab, required this.onTap, super.key});
  final int tab;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = const [
      NavSpec('Home', CupertinoIcons.home),
      NavSpec('Garden', CupertinoIcons.square_grid_2x2),
      NavSpec('Spray', CupertinoIcons.drop),
      NavSpec('Records', CupertinoIcons.list_bullet),
      NavSpec('Products', CupertinoIcons.cube_box),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(color: C.line),
        boxShadow: softShadow,
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == tab;
          return Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => onTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 38,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? C.forest : CupertinoColors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      items[index].icon,
                      size: 18,
                      color: selected ? CupertinoColors.white : C.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    child: Text(
                      items[index].label,
                      style: TextStyle(
                        color: selected ? C.forest : C.muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class NavSpec {
  const NavSpec(this.label, this.icon);
  final String label;
  final IconData icon;
}

class RecordCard extends StatelessWidget {
  const RecordCard({required this.record, this.onDelete, super.key});
  final SprayRecord record;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final target = targetById(record.targetId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: target.softColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(target.icon, color: target.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bed ${record.beds.join(', ')} | ${target.short}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: C.ink,
                  ),
                ),
                Text(
                  record.crops.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${record.product} | sprayed ${shortDate(record.date)} | safe ${shortDate(record.safeDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: C.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          StatusPill(record.onHold ? 'HOLD' : 'SAFE', hold: record.onHold),
          if (onDelete != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: onDelete,
              child: const Icon(CupertinoIcons.delete, color: C.red, size: 20),
            ),
        ],
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.subtitle,
    required this.children,
    this.message = '',
    super.key,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String message;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
              color: C.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: C.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          if (message.isNotEmpty) ...[
            MessageBanner(message),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      );
}

class MessageBanner extends StatelessWidget {
  const MessageBanner(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.forestSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Text(
          message,
          style: const TextStyle(color: C.forest, fontWeight: FontWeight.w900),
        ),
      );
}

class Panel extends StatelessWidget {
  const Panel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) =>
      Container(padding: padding, decoration: cardDecoration(), child: child);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: C.forest,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Panel(
        child: Text(
          text,
          style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700),
        ),
      );
}

class EmptyInline extends StatelessWidget {
  const EmptyInline(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Text(
          text,
          style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700),
        ),
      );
}

class Sheet extends StatelessWidget {
  const Sheet({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => CupertinoPopupSurface(
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .86,
            child: Container(color: C.canvas, child: child),
          ),
        ),
      );
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: C.ink,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Icon(CupertinoIcons.clear, color: C.muted, size: 24),
          ),
        ],
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
        color: C.forest,
        disabledColor: C.line,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
        color: C.forestSoft,
        disabledColor: C.soft,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: onPressed == null ? C.muted : C.forest,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class NumberChip extends StatelessWidget {
  const NumberChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? C.forest : C.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? C.forest : C.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? CupertinoColors.white : C.ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {required this.hold, super.key});
  final String label;
  final bool hold;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hold ? C.amberSoft : C.forestSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: hold ? C.amber : C.forest,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      );
}

class ProductTag extends StatelessWidget {
  const ProductTag({
    required this.label,
    required this.color,
    required this.background,
    super.key,
  });
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 10.5,
          ),
        ),
      );
}

class CategoryPill extends StatelessWidget {
  const CategoryPill({required this.category, super.key});
  final String category;
  @override
  Widget build(BuildContext context) {
    final lower = category.toLowerCase();
    final color = lower == 'organic'
        ? C.forest
        : lower == 'chemical'
            ? C.amber
            : C.muted;
    final background = lower == 'organic'
        ? C.forestSoft
        : lower == 'chemical'
            ? C.amberSoft
            : C.greySoft;
    return ProductTag(
      label: category.isEmpty ? 'unknown' : category,
      color: color,
      background: background,
    );
  }
}

class Field extends StatelessWidget {
  const Field({
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
    super.key,
  });
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;
  @override
  Widget build(BuildContext context) => CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        maxLines: maxLines,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
      );
}

class Stepper extends StatelessWidget {
  const Stepper({
    required this.label,
    required this.value,
    required this.minus,
    required this.plus,
    super.key,
  });
  final String label;
  final int value;
  final VoidCallback? minus;
  final VoidCallback? plus;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            SmallButton('-', minus),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '$value',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            SmallButton('+', plus),
          ],
        ),
      );
}

class SmallButton extends StatelessWidget {
  const SmallButton(this.label, this.onPressed, {super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(34, 34),
        color: C.card,
        borderRadius: BorderRadius.circular(999),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: C.forest,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class TextChip extends StatelessWidget {
  const TextChip({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: C.ink,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      );
}

class CropChip extends StatelessWidget {
  const CropChip({required this.crop, required this.onRemove, super.key});
  final VegetableDefinition crop;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CropIcon(crop.iconPath, size: 22),
            const SizedBox(width: 7),
            Text(
              crop.name,
              style: const TextStyle(
                color: C.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onRemove,
              child: const Icon(CupertinoIcons.clear, color: C.muted, size: 16),
            ),
          ],
        ),
      );
}

class CountDot extends StatelessWidget {
  const CountDot(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 20),
        height: 20,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: C.forest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.card, width: 2),
        ),
        child: Text(
          '+$count',
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class DetailLine extends StatelessWidget {
  const DetailLine(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: C.forest,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: C.ink,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      );
}

class TargetGrid extends StatelessWidget {
  const TargetGrid({required this.selected, required this.onSelect, super.key});
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: .98,
        children: sprayTargets
            .map(
              (target) => TargetButton(
                target: target,
                selected: selected == target.id,
                onTap: () => onSelect(target.id),
              ),
            )
            .toList(),
      );
}

class TargetButton extends StatelessWidget {
  const TargetButton({
    required this.target,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final SprayTarget target;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? target.softColor : C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? target.color : C.line,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(target.icon, color: target.color, size: 22),
              const SizedBox(height: 5),
              FittedBox(
                child: Text(
                  target.short,
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class CropIcon extends StatelessWidget {
  const CropIcon(this.path, {this.size = 28, super.key});
  final String path;
  final double size;
  @override
  Widget build(BuildContext context) => path.toLowerCase().endsWith('.svg')
      ? SvgPicture.asset(path, width: size, height: size, fit: BoxFit.contain)
      : Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
}

class GridPainter extends CustomPainter {
  const GridPainter(this.plot);

  final GardenPlot plot;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE9E4D8)
      ..strokeWidth = .55;
    for (var meter = 0; meter <= plot.widthMeters.floor(); meter++) {
      final x = meter * size.width / plot.widthMeters;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var meter = 0; meter <= plot.lengthMeters.floor(); meter++) {
      final y = meter * size.height / plot.lengthMeters;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      plot.widthMeters != oldDelegate.plot.widthMeters ||
      plot.lengthMeters != oldDelegate.plot.lengthMeters;
}
