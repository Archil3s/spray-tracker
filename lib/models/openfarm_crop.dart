class OpenFarmCrop {
  const OpenFarmCrop({
    required this.name,
    required this.description,
    required this.sunRequirements,
    required this.sowingMethod,
    required this.spread,
    required this.rowSpacing,
    required this.height,
    required this.imageUrl,
    required this.tags,
    required this.slug,
  });

  final String name;
  final String description;
  final String sunRequirements;
  final String sowingMethod;
  final double? spread;
  final double? rowSpacing;
  final double? height;
  final String imageUrl;
  final List<String> tags;
  final String slug;

  String get openFarmUrl {
    final safeSlug = slug.isNotEmpty ? slug : _slugify(name);
    return 'https://openfarm.cc/en/crops/$safeSlug';
  }

  factory OpenFarmCrop.fromApiJson(Map<String, dynamic> item) {
    final attributes = item['attributes'];
    final attrs = attributes is Map<String, dynamic> ? attributes : item;

    final name = _string(attrs, ['name']);
    final slug = _string(attrs, ['slug']);
    final imageUrl = _normaliseUrl(
      _string(attrs, [
        'main_image_url',
        'mainImageUrl',
        'main_image_path',
        'mainImagePath',
        'image_url',
        'imageUrl',
      ]),
    );

    return OpenFarmCrop(
      name: name,
      description: _string(attrs, ['description']),
      sunRequirements: _string(attrs, ['sun_requirements', 'sunRequirements']),
      sowingMethod: _string(attrs, ['sowing_method', 'sowingMethod']),
      spread: _cm(attrs, ['spread']),
      rowSpacing: _cm(attrs, ['row_spacing', 'rowSpacing']),
      height: _cm(attrs, ['height']),
      imageUrl: imageUrl,
      tags: _tags(attrs['tags'] ?? attrs['tags_array'] ?? attrs['tagsArray']),
      slug: slug.isNotEmpty ? slug : _slugify(name),
    );
  }

  static String _string(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is String) return value.trim();
      if (value is num) return value.toString();
      if (value is Map && value['value'] != null) {
        return value['value'].toString().trim();
      }
    }
    return '';
  }

  static double? _cm(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final parsed = _number(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static double? _number(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    if (value is String) {
      final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(value);
      if (match == null) return null;
      return double.tryParse(match.group(0)!);
    }

    if (value is Map) {
      for (final key in ['cm', 'value', 'min', 'max']) {
        if (value[key] != null) {
          final parsed = _number(value[key]);
          if (parsed != null) return parsed;
        }
      }
    }

    return null;
  }

  static List<String> _tags(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static String _normaliseUrl(String value) {
    if (value.isEmpty) return '';
    if (value.startsWith('//')) return 'https:$value';
    if (value.startsWith('/')) return 'https://openfarm.cc$value';
    return value;
  }

  static String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
