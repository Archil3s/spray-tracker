class GardenSnapshot {
  const GardenSnapshot({
    required this.nextRecordId,
    required this.bedCropIds,
    required this.records,
    this.activeSeasonId = '',
    this.seasons = const [],
    this.beds = const [],
    this.plants = const [],
    this.seedlings = const [],
    this.pestSightings = const [],
    this.plotWidthMeters = 8,
    this.plotLengthMeters = 12,
  });

  final int nextRecordId;
  final String activeSeasonId;
  final List<GardenSeasonSnapshot> seasons;
  final Map<int, List<String>> bedCropIds;
  final List<StoredSprayRecord> records;
  final List<StoredGardenBed> beds;
  final List<StoredGardenPlant> plants;
  final List<StoredSeedlingBatch> seedlings;
  final List<StoredPestSighting> pestSightings;
  final double plotWidthMeters;
  final double plotLengthMeters;

  factory GardenSnapshot.fromJson(Map<String, dynamic> json) {
    final cropJson = json['bedCropIds'];
    final recordJson = json['records'];
    final bedJson = json['beds'];
    final plantJson = json['plants'];
    final seedlingJson = json['seedlings'];
    final pestSightingJson = json['pestSightings'];
    final seasonJson = json['seasons'];
    return GardenSnapshot(
      nextRecordId: _int(json['nextRecordId'], fallback: 1),
      activeSeasonId: _string(json['activeSeasonId']),
      seasons: seasonJson is List
          ? seasonJson
              .whereType<Map>()
              .map((item) => GardenSeasonSnapshot.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((season) => season.id.isNotEmpty)
              .toList(growable: false)
          : const [],
      plotWidthMeters: _double(json['plotWidthMeters'], fallback: 8),
      plotLengthMeters: _double(json['plotLengthMeters'], fallback: 12),
      bedCropIds: cropJson is Map
          ? {
              for (final entry in cropJson.entries)
                if (int.tryParse(entry.key.toString()) case final bed?)
                  bed: _stringList(entry.value),
            }
          : const {},
      records: recordJson is List
          ? recordJson
              .whereType<Map>()
              .map((item) => StoredSprayRecord.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
      beds: bedJson is List
          ? bedJson
              .whereType<Map>()
              .map((item) => StoredGardenBed.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((bed) => bed.number > 0)
              .toList(growable: false)
          : const [],
      plants: plantJson is List
          ? plantJson
              .whereType<Map>()
              .map((item) => StoredGardenPlant.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((plant) => plant.id > 0 && plant.bed > 0)
              .toList(growable: false)
          : const [],
      seedlings: seedlingJson is List
          ? seedlingJson
              .whereType<Map>()
              .map((item) => StoredSeedlingBatch.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((batch) => batch.id > 0)
              .toList(growable: false)
          : const [],
      pestSightings: pestSightingJson is List
          ? pestSightingJson
              .whereType<Map>()
              .map((item) => StoredPestSighting.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((sighting) => sighting.id > 0 && sighting.bed > 0)
              .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'nextRecordId': nextRecordId,
        'activeSeasonId': activeSeasonId,
        'seasons': seasons.map((season) => season.toJson()).toList(),
        'plotWidthMeters': plotWidthMeters,
        'plotLengthMeters': plotLengthMeters,
        'bedCropIds': {
          for (final entry in bedCropIds.entries) '${entry.key}': entry.value,
        },
        'records': records.map((record) => record.toJson()).toList(),
        'beds': beds.map((bed) => bed.toJson()).toList(),
        'plants': plants.map((plant) => plant.toJson()).toList(),
        'seedlings': seedlings.map((batch) => batch.toJson()).toList(),
        'pestSightings':
            pestSightings.map((sighting) => sighting.toJson()).toList(),
      };
}

class GardenSeasonSnapshot {
  const GardenSeasonSnapshot({
    required this.id,
    required this.label,
    required this.startedAt,
    required this.nextRecordId,
    required this.bedCropIds,
    required this.records,
    this.beds = const [],
    this.plants = const [],
    this.seedlings = const [],
    this.pestSightings = const [],
    this.plotWidthMeters = 8,
    this.plotLengthMeters = 12,
  });

  final String id;
  final String label;
  final DateTime startedAt;
  final int nextRecordId;
  final Map<int, List<String>> bedCropIds;
  final List<StoredSprayRecord> records;
  final List<StoredGardenBed> beds;
  final List<StoredGardenPlant> plants;
  final List<StoredSeedlingBatch> seedlings;
  final List<StoredPestSighting> pestSightings;
  final double plotWidthMeters;
  final double plotLengthMeters;

  factory GardenSeasonSnapshot.fromJson(Map<String, dynamic> json) {
    final cropJson = json['bedCropIds'];
    final recordJson = json['records'];
    final bedJson = json['beds'];
    final plantJson = json['plants'];
    final seedlingJson = json['seedlings'];
    final pestSightingJson = json['pestSightings'];
    final startedAt =
        DateTime.tryParse(_string(json['startedAt'])) ?? DateTime(1970);
    return GardenSeasonSnapshot(
      id: _string(json['id']),
      label: _string(json['label']),
      startedAt: startedAt,
      nextRecordId: _int(json['nextRecordId'], fallback: 1),
      plotWidthMeters: _double(json['plotWidthMeters'], fallback: 8),
      plotLengthMeters: _double(json['plotLengthMeters'], fallback: 12),
      bedCropIds: cropJson is Map ? _cropMap(cropJson) : const {},
      records: recordJson is List
          ? recordJson
              .whereType<Map>()
              .map((item) => StoredSprayRecord.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
      beds: bedJson is List
          ? bedJson
              .whereType<Map>()
              .map((item) => StoredGardenBed.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((bed) => bed.number > 0)
              .toList(growable: false)
          : const [],
      plants: plantJson is List
          ? plantJson
              .whereType<Map>()
              .map((item) => StoredGardenPlant.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((plant) => plant.id > 0 && plant.bed > 0)
              .toList(growable: false)
          : const [],
      seedlings: seedlingJson is List
          ? seedlingJson
              .whereType<Map>()
              .map((item) => StoredSeedlingBatch.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((batch) => batch.id > 0)
              .toList(growable: false)
          : const [],
      pestSightings: pestSightingJson is List
          ? pestSightingJson
              .whereType<Map>()
              .map((item) => StoredPestSighting.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((sighting) => sighting.id > 0 && sighting.bed > 0)
              .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'startedAt': startedAt.toIso8601String(),
        'nextRecordId': nextRecordId,
        'plotWidthMeters': plotWidthMeters,
        'plotLengthMeters': plotLengthMeters,
        'bedCropIds': {
          for (final entry in bedCropIds.entries) '${entry.key}': entry.value,
        },
        'records': records.map((record) => record.toJson()).toList(),
        'beds': beds.map((bed) => bed.toJson()).toList(),
        'plants': plants.map((plant) => plant.toJson()).toList(),
        'seedlings': seedlings.map((batch) => batch.toJson()).toList(),
        'pestSightings':
            pestSightings.map((sighting) => sighting.toJson()).toList(),
      };
}

class StoredGardenBed {
  const StoredGardenBed({
    required this.number,
    required this.name,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.widthMeters = 0,
    this.lengthMeters = 0,
  });

  final int number;
  final String name;
  final double left;
  final double top;
  final double width;
  final double height;
  final double widthMeters;
  final double lengthMeters;

  factory StoredGardenBed.fromJson(Map<String, dynamic> json) =>
      StoredGardenBed(
        number: _int(json['number']),
        name: _string(json['name']),
        left: _double(json['left']),
        top: _double(json['top']),
        width: _double(json['width']),
        height: _double(json['height']),
        widthMeters: _double(json['widthMeters']),
        lengthMeters: _double(json['lengthMeters']),
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'name': name,
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        'widthMeters': widthMeters,
        'lengthMeters': lengthMeters,
      };
}

class StoredGardenPlant {
  const StoredGardenPlant({
    required this.id,
    required this.bed,
    required this.cropId,
    required this.x,
    required this.y,
  });

  final int id;
  final int bed;
  final String cropId;
  final double x;
  final double y;

  factory StoredGardenPlant.fromJson(Map<String, dynamic> json) =>
      StoredGardenPlant(
        id: _int(json['id']),
        bed: _int(json['bed']),
        cropId: _string(json['cropId']),
        x: _double(json['x']),
        y: _double(json['y']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bed': bed,
        'cropId': cropId,
        'x': x,
        'y': y,
      };
}

class StoredSprayRecord {
  const StoredSprayRecord({
    required this.id,
    required this.beds,
    required this.crops,
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
  final String targetId;
  final String product;
  final String productId;
  final String reason;
  final String notes;
  final DateTime date;
  final int days;

  factory StoredSprayRecord.fromJson(Map<String, dynamic> json) =>
      StoredSprayRecord(
        id: _int(json['id']),
        beds: _intList(json['beds']),
        crops: _stringList(json['crops']),
        targetId: _string(json['targetId']),
        product: _string(json['product']),
        productId: _string(json['productId']),
        reason: _string(json['reason']),
        notes: _string(json['notes']),
        date: DateTime.tryParse(_string(json['date'])) ?? DateTime(1970),
        days: _int(json['days']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'beds': beds,
        'crops': crops,
        'targetId': targetId,
        'product': product,
        'productId': productId,
        'reason': reason,
        'notes': notes,
        'date': date.toIso8601String(),
        'days': days,
      };
}

class StoredPestSighting {
  const StoredPestSighting({
    required this.id,
    required this.bed,
    required this.cropName,
    required this.issueName,
    required this.severity,
    required this.actionTaken,
    required this.date,
    required this.recheckDate,
    required this.notes,
    this.status = 'active',
    this.followUpDate,
    this.followUpResult,
  });

  final int id;
  final int bed;
  final String cropName;
  final String issueName;
  final String severity;
  final String actionTaken;
  final DateTime date;
  final DateTime recheckDate;
  final String notes;
  final String status;
  final DateTime? followUpDate;
  final String? followUpResult;

  factory StoredPestSighting.fromJson(Map<String, dynamic> json) =>
      StoredPestSighting(
        id: _int(json['id']),
        bed: _int(json['bed']),
        cropName: _string(json['cropName']),
        issueName: _string(json['issueName']),
        severity: _string(json['severity']),
        actionTaken: _string(json['actionTaken']),
        date: DateTime.tryParse(_string(json['date'])) ?? DateTime(1970),
        recheckDate:
            DateTime.tryParse(_string(json['recheckDate'])) ?? DateTime(1970),
        notes: _string(json['notes']),
        status: _string(json['status']).isEmpty
            ? 'active'
            : _string(json['status']),
        followUpDate: DateTime.tryParse(_string(json['followUpDate'])),
        followUpResult: _string(json['followUpResult']).isEmpty
            ? null
            : _string(json['followUpResult']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bed': bed,
        'cropName': cropName,
        'issueName': issueName,
        'severity': severity,
        'actionTaken': actionTaken,
        'date': date.toIso8601String(),
        'recheckDate': recheckDate.toIso8601String(),
        'notes': notes,
        'status': status,
        'followUpDate': followUpDate?.toIso8601String(),
        'followUpResult': followUpResult,
      };
}

class StoredSeedlingBatch {
  const StoredSeedlingBatch({
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
  final String status;
  final int expectedGerminationDaysMin;
  final int expectedGerminationDaysMax;
  final DateTime targetPlantOutDate;
  final int? plantedOutBed;
  final DateTime? plantedOutDate;
  final String notes;

  factory StoredSeedlingBatch.fromJson(Map<String, dynamic> json) =>
      StoredSeedlingBatch(
        id: _int(json['id']),
        cropId: _string(json['cropId']),
        cropName: _string(json['cropName']),
        varietyName: _string(json['varietyName']),
        quantityStarted: _int(json['quantityStarted']),
        quantityAlive: _int(json['quantityAlive']),
        dateStarted:
            DateTime.tryParse(_string(json['dateStarted'])) ?? DateTime(1970),
        location: _string(json['location']),
        method: _string(json['method']),
        status: _string(json['status']).isEmpty
            ? 'started'
            : _string(json['status']),
        expectedGerminationDaysMin:
            _int(json['expectedGerminationDaysMin'], fallback: 7),
        expectedGerminationDaysMax:
            _int(json['expectedGerminationDaysMax'], fallback: 14),
        targetPlantOutDate:
            DateTime.tryParse(_string(json['targetPlantOutDate'])) ??
                DateTime(1970),
        plantedOutBed:
            json['plantedOutBed'] == null ? null : _int(json['plantedOutBed']),
        plantedOutDate: DateTime.tryParse(_string(json['plantedOutDate'])),
        notes: _string(json['notes']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cropId': cropId,
        'cropName': cropName,
        'varietyName': varietyName,
        'quantityStarted': quantityStarted,
        'quantityAlive': quantityAlive,
        'dateStarted': dateStarted.toIso8601String(),
        'location': location,
        'method': method,
        'status': status,
        'expectedGerminationDaysMin': expectedGerminationDaysMin,
        'expectedGerminationDaysMax': expectedGerminationDaysMax,
        'targetPlantOutDate': targetPlantOutDate.toIso8601String(),
        'plantedOutBed': plantedOutBed,
        'plantedOutDate': plantedOutDate?.toIso8601String(),
        'notes': notes,
      };
}

String _string(Object? value) => value is String ? value : '';

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

double _double(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

List<int> _intList(Object? value) =>
    value is List ? value.map(_int).toList(growable: false) : const [];

List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];

Map<int, List<String>> _cropMap(Map<dynamic, dynamic> value) => {
      for (final entry in value.entries)
        if (int.tryParse(entry.key.toString()) case final bed?)
          bed: _stringList(entry.value),
    };

String gardenSeasonIdFor(DateTime date) {
  final season = _southernSeasonName(date).toLowerCase();
  final year = _southernSeasonYear(date);
  return '$season-$year';
}

String gardenSeasonLabelFor(DateTime date) {
  final season = _southernSeasonName(date);
  final year = _southernSeasonYear(date);
  return '$season $year';
}

DateTime gardenSeasonStartFor(DateTime date) {
  if (date.month <= 2) return DateTime(date.year - 1, 12);
  if (date.month <= 5) return DateTime(date.year, 3);
  if (date.month <= 8) return DateTime(date.year, 6);
  if (date.month <= 11) return DateTime(date.year, 9);
  return DateTime(date.year, 12);
}

DateTime nextGardenSeasonStart(DateTime date) {
  final start = gardenSeasonStartFor(date);
  return DateTime(start.year, start.month + 3);
}

String _southernSeasonName(DateTime date) {
  if (date.month == 12 || date.month <= 2) return 'Summer';
  if (date.month <= 5) return 'Autumn';
  if (date.month <= 8) return 'Winter';
  return 'Spring';
}

int _southernSeasonYear(DateTime date) =>
    date.month <= 2 ? date.year - 1 : date.year;
