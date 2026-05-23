class GardenSnapshot {
  const GardenSnapshot({
    required this.nextRecordId,
    required this.bedCropIds,
    required this.records,
    this.beds = const [],
    this.plants = const [],
    this.plotWidthMeters = 8,
    this.plotLengthMeters = 12,
  });

  final int nextRecordId;
  final Map<int, List<String>> bedCropIds;
  final List<StoredSprayRecord> records;
  final List<StoredGardenBed> beds;
  final List<StoredGardenPlant> plants;
  final double plotWidthMeters;
  final double plotLengthMeters;

  factory GardenSnapshot.fromJson(Map<String, dynamic> json) {
    final cropJson = json['bedCropIds'];
    final recordJson = json['records'];
    final bedJson = json['beds'];
    final plantJson = json['plants'];
    return GardenSnapshot(
      nextRecordId: _int(json['nextRecordId'], fallback: 1),
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
    );
  }

  Map<String, dynamic> toJson() => {
        'nextRecordId': nextRecordId,
        'plotWidthMeters': plotWidthMeters,
        'plotLengthMeters': plotLengthMeters,
        'bedCropIds': {
          for (final entry in bedCropIds.entries) '${entry.key}': entry.value,
        },
        'records': records.map((record) => record.toJson()).toList(),
        'beds': beds.map((bed) => bed.toJson()).toList(),
        'plants': plants.map((plant) => plant.toJson()).toList(),
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
