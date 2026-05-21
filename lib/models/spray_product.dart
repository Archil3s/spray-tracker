class SprayProduct {
  const SprayProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.type,
    required this.activeIngredient,
    required this.withholdingDays,
    required this.withholdingNote,
    required this.reEntryHours,
    required this.category,
    required this.commonUses,
    required this.suitableCrops,
    required this.reSprayIntervalDays,
    required this.acvmRegistrationNumber,
    required this.source,
    required this.notes,
  });

  final String id;
  final String name;
  final String brand;
  final String type;
  final String activeIngredient;
  final int withholdingDays;
  final String withholdingNote;
  final int reEntryHours;
  final String category;
  final List<String> commonUses;
  final List<String> suitableCrops;
  final int reSprayIntervalDays;
  final String acvmRegistrationNumber;
  final String source;
  final String notes;

  factory SprayProduct.fromJson(Map<String, dynamic> json) => SprayProduct(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        type: json['type'] as String? ?? '',
        activeIngredient: json['activeIngredient'] as String? ?? '',
        withholdingDays: (json['withholdingDays'] as num?)?.toInt() ?? 0,
        withholdingNote: json['withholdingNote'] as String? ?? '',
        reEntryHours: (json['reEntryHours'] as num?)?.toInt() ?? 0,
        category: json['category'] as String? ?? '',
        commonUses: _stringList(json['commonUses']),
        suitableCrops: _stringList(json['suitableCrops']),
        reSprayIntervalDays: (json['reSprayIntervalDays'] as num?)?.toInt() ?? 0,
        acvmRegistrationNumber: json['acvmRegistrationNumber'] as String? ?? '',
        source: json['source'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'type': type,
        'activeIngredient': activeIngredient,
        'withholdingDays': withholdingDays,
        'withholdingNote': withholdingNote,
        'reEntryHours': reEntryHours,
        'category': category,
        'commonUses': commonUses,
        'suitableCrops': suitableCrops,
        'reSprayIntervalDays': reSprayIntervalDays,
        'acvmRegistrationNumber': acvmRegistrationNumber,
        'source': source,
        'notes': notes,
      };

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      name,
      brand,
      type,
      activeIngredient,
      category,
      source,
      notes,
      ...commonUses,
      ...suitableCrops,
    ].any((value) => value.toLowerCase().contains(q));
  }

  bool matchesUse(String use) {
    final q = use.trim().toLowerCase();
    if (q.isEmpty) return true;
    return commonUses.any((item) => item.toLowerCase().contains(q));
  }

  bool matchesCrop(String crop) {
    final q = crop.trim().toLowerCase();
    if (q.isEmpty) return true;
    return suitableCrops.any((item) => item.toLowerCase().contains(q));
  }

  String get targetsText => commonUses.join(', ');
  int get days => withholdingDays;
  List<String> get targets {
    final lower = '$type ${commonUses.join(' ')}'.toLowerCase();
    final result = <String>{};
    if (lower.contains('fung') || lower.contains('mildew') || lower.contains('rust') || lower.contains('blight')) result.add('fungus');
    if (lower.contains('insect') || lower.contains('aphid') || lower.contains('mite') || lower.contains('whitefly') || lower.contains('thrip') || lower.contains('scale') || lower.contains('caterpillar')) result.add('pest');
    if (lower.contains('plant health') || lower.contains('tonic') || lower.contains('stress')) result.add('maintain');
    if (result.isEmpty) result.add('prevent');
    return result.toList();
  }
}

List<String> _stringList(Object? value) {
  if (value is List) return value.whereType<String>().toList();
  return const <String>[];
}
