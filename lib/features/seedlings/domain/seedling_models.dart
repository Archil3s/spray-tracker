part of '../../../main.dart';

enum SeedlingStatus {
  started,
  germinated,
  prickedOut,
  pottedUp,
  hardeningOff,
  readyToPlantOut,
  plantedOut,
  failed,
}

String seedlingStatusLabel(SeedlingStatus status) => switch (status) {
      SeedlingStatus.started => 'Started',
      SeedlingStatus.germinated => 'Germinated',
      SeedlingStatus.prickedOut => 'Pricked out',
      SeedlingStatus.pottedUp => 'Potted up',
      SeedlingStatus.hardeningOff => 'Hardening off',
      SeedlingStatus.readyToPlantOut => 'Ready to plant out',
      SeedlingStatus.plantedOut => 'Planted out',
      SeedlingStatus.failed => 'Failed',
    };

class SeedlingBatch {
  const SeedlingBatch({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.varietyName,
    required this.quantityStarted,
    required this.quantityAlive,
    required this.dateStarted,
    required this.location,
    required this.method,
    required this.status,
    required this.expectedGerminationDaysMin,
    required this.expectedGerminationDaysMax,
    required this.targetPlantOutDate,
    required this.notes,
    this.plantedOutBed,
    this.plantedOutDate,
  });

  final int id;
  final String cropId;
  final String cropName;
  final String varietyName;
  final int quantityStarted;
  final int quantityAlive;
  final DateTime dateStarted;
  final String location;
  final String method;
  final SeedlingStatus status;
  final int expectedGerminationDaysMin;
  final int expectedGerminationDaysMax;
  final DateTime targetPlantOutDate;
  final int? plantedOutBed;
  final DateTime? plantedOutDate;
  final String notes;

  DateTime get germinationStart =>
      dateStarted.add(Duration(days: expectedGerminationDaysMin));

  DateTime get germinationEnd =>
      dateStarted.add(Duration(days: expectedGerminationDaysMax));

  bool get active =>
      status != SeedlingStatus.plantedOut && status != SeedlingStatus.failed;

  SeedlingBatch copyWith({
    int? quantityAlive,
    SeedlingStatus? status,
    int? plantedOutBed,
    DateTime? plantedOutDate,
  }) =>
      SeedlingBatch(
        id: id,
        cropId: cropId,
        cropName: cropName,
        varietyName: varietyName,
        quantityStarted: quantityStarted,
        quantityAlive: quantityAlive ?? this.quantityAlive,
        dateStarted: dateStarted,
        location: location,
        method: method,
        status: status ?? this.status,
        expectedGerminationDaysMin: expectedGerminationDaysMin,
        expectedGerminationDaysMax: expectedGerminationDaysMax,
        targetPlantOutDate: targetPlantOutDate,
        plantedOutBed: plantedOutBed ?? this.plantedOutBed,
        plantedOutDate: plantedOutDate ?? this.plantedOutDate,
        notes: notes,
      );
}

({int min, int max}) seedlingGerminationWindowFor(VegetableDefinition crop) {
  final id = crop.id.toLowerCase();
  final family = crop.familyId.toLowerCase();
  if (const ['tomato', 'chilli', 'capsicum', 'eggplant'].contains(id)) {
    return (min: 7, max: 14);
  }
  if (const ['lettuce', 'spinach', 'rocket'].contains(id)) {
    return (min: 3, max: 7);
  }
  if (family == 'brassicas') return (min: 4, max: 10);
  if (family == 'cucurbits') return (min: 5, max: 10);
  if (family == 'herbs') return (min: 7, max: 21);
  return (min: 7, max: 14);
}

DateTime seedlingTargetPlantOutDate(
    DateTime started, VegetableDefinition crop) {
  final family = crop.familyId.toLowerCase();
  final id = crop.id.toLowerCase();
  final weeks = switch (family) {
    'leafy_greens' => 4,
    'brassicas' => 5,
    'cucurbits' => 3,
    'herbs' => 6,
    _ =>
      const ['tomato', 'chilli', 'capsicum', 'eggplant'].contains(id) ? 8 : 6,
  };
  return started.add(Duration(days: weeks * 7));
}
