import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/openfarm_crop.dart';

class OpenFarmService {
  OpenFarmService({http.Client? client}) : _client = client ?? http.Client();

  static final OpenFarmService instance = OpenFarmService();

  final http.Client _client;
  final Map<String, OpenFarmCrop> _cropCache = {};
  final Map<String, List<OpenFarmCrop>> _searchCache = {};

  Future<List<OpenFarmCrop>> searchCrops(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return const [];

    final key = _key(clean);
    final cached = _searchCache[key];
    if (cached != null) return cached;

    try {
      final uri = Uri.https('openfarm.cc', '/api/v1/crops', {'filter': clean});
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode < 200 || response.statusCode >= 300)
        return const [];

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! List) return const [];

      final crops = data
          .whereType<Map<String, dynamic>>()
          .map(OpenFarmCrop.fromApiJson)
          .where((crop) => crop.name.trim().isNotEmpty)
          .toList();

      for (final crop in crops) {
        _cropCache[_key(crop.name)] = crop;
        if (crop.slug.isNotEmpty) _cropCache[_key(crop.slug)] = crop;
      }

      _searchCache[key] = crops;
      return crops;
    } on TimeoutException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<OpenFarmCrop?> getCropByName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return null;

    final key = _key(clean);
    final cached = _cropCache[key];
    if (cached != null) return cached;

    final results = await searchCrops(clean);
    if (results.isEmpty) return null;

    final exact = results.where((crop) => _key(crop.name) == key).firstOrNull;
    final crop = exact ?? results.first;
    _cropCache[key] = crop;
    return crop;
  }

  String _key(String value) => value.toLowerCase().trim();
}
