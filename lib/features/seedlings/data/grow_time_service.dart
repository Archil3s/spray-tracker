import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../crop_library.dart';

class GrowTimeEstimate {
  const GrowTimeEstimate({
    required this.germinationDaysMin,
    required this.germinationDaysMax,
    required this.transplantWeeks,
    required this.harvestDaysMin,
    required this.harvestDaysMax,
    required this.source,
    required this.note,
    this.apiGrowthRate,
    this.apiHarvestSeason,
  });

  final int germinationDaysMin;
  final int germinationDaysMax;
  final int transplantWeeks;
  final int harvestDaysMin;
  final int harvestDaysMax;
  final String source;
  final String note;
  final String? apiGrowthRate;
  final String? apiHarvestSeason;
}

class GrowTimeService {
  GrowTimeService({http.Client? client}) : _client = client ?? http.Client();

  static final GrowTimeService instance = GrowTimeService();

  static const perenualApiKey = String.fromEnvironment('PERENUAL_API_KEY');

  final http.Client _client;
  final Map<String, GrowTimeEstimate> _cache = {};

  Future<GrowTimeEstimate> estimateFor(VegetableDefinition crop) async {
    final cached = _cache[crop.id];
    if (cached != null) return cached;

    final fallback = GrowTimeDefaults.estimateFor(crop);
    if (perenualApiKey.trim().isEmpty) {
      _cache[crop.id] = fallback;
      return fallback;
    }

    try {
      final listUri = Uri.https('perenual.com', '/api/v2/species-list', {
        'key': perenualApiKey,
        'q': crop.name,
        'edible': '1',
      });
      final listResponse =
          await _client.get(listUri).timeout(const Duration(seconds: 6));
      if (listResponse.statusCode < 200 || listResponse.statusCode >= 300) {
        _cache[crop.id] = fallback;
        return fallback;
      }

      final listJson = jsonDecode(listResponse.body);
      final data = listJson is Map<String, dynamic> ? listJson['data'] : null;
      if (data is! List || data.isEmpty) {
        _cache[crop.id] = fallback;
        return fallback;
      }

      final first = data.whereType<Map<String, dynamic>>().firstOrNull;
      final id = first == null ? null : first['id'];
      if (id == null) {
        _cache[crop.id] = fallback;
        return fallback;
      }

      final detailUri =
          Uri.https('perenual.com', '/api/v2/species/details/$id', {
        'key': perenualApiKey,
      });
      final detailResponse =
          await _client.get(detailUri).timeout(const Duration(seconds: 6));
      if (detailResponse.statusCode < 200 || detailResponse.statusCode >= 300) {
        _cache[crop.id] = fallback;
        return fallback;
      }

      final detailJson = jsonDecode(detailResponse.body);
      if (detailJson is! Map<String, dynamic>) {
        _cache[crop.id] = fallback;
        return fallback;
      }

      final growthRate = _string(detailJson['growth_rate']);
      final harvestSeason = _string(detailJson['harvest_season']);
      final adjusted = _adjustFromApi(
        fallback,
        growthRate: growthRate,
        harvestSeason: harvestSeason,
      );
      _cache[crop.id] = adjusted;
      return adjusted;
    } on TimeoutException {
      _cache[crop.id] = fallback;
      return fallback;
    } catch (_) {
      _cache[crop.id] = fallback;
      return fallback;
    }
  }

  GrowTimeEstimate _adjustFromApi(
    GrowTimeEstimate fallback, {
    required String growthRate,
    required String harvestSeason,
  }) {
    final lower = growthRate.toLowerCase();
    var min = fallback.harvestDaysMin;
    var max = fallback.harvestDaysMax;
    if (lower.contains('high') || lower.contains('fast')) {
      min = (min * .92).round();
      max = (max * .92).round();
    } else if (lower.contains('low') || lower.contains('slow')) {
      min = (min * 1.12).round();
      max = (max * 1.12).round();
    }

    final apiBits = [
      if (growthRate.isNotEmpty) 'growth: $growthRate',
      if (harvestSeason.isNotEmpty) 'harvest season: $harvestSeason',
    ];

    return GrowTimeEstimate(
      germinationDaysMin: fallback.germinationDaysMin,
      germinationDaysMax: fallback.germinationDaysMax,
      transplantWeeks: fallback.transplantWeeks,
      harvestDaysMin: min,
      harvestDaysMax: max,
      source: apiBits.isEmpty ? fallback.source : 'Perenual + local estimate',
      note: apiBits.isEmpty
          ? fallback.note
          : 'API matched plant details (${apiBits.join(', ')}). Exact vegetable maturity days still use local fallback ranges.',
      apiGrowthRate: growthRate.isEmpty ? null : growthRate,
      apiHarvestSeason: harvestSeason.isEmpty ? null : harvestSeason,
    );
  }

  String _string(Object? value) => value is String ? value.trim() : '';
}

class GrowTimeDefaults {
  const GrowTimeDefaults._();

  static GrowTimeEstimate estimateFor(VegetableDefinition crop) {
    final id = crop.id.toLowerCase();
    final family = crop.familyId.toLowerCase();
    final germ = germinationWindowFor(crop);
    final transplantWeeks = transplantWeeksFor(crop);
    final harvest = harvestWindowFor(crop);
    return GrowTimeEstimate(
      germinationDaysMin: germ.min,
      germinationDaysMax: germ.max,
      transplantWeeks: transplantWeeks,
      harvestDaysMin: harvest.min,
      harvestDaysMax: harvest.max,
      source: 'Local grow-time estimate',
      note: id.isEmpty || family.isEmpty
          ? 'Generic seedling grow-time range.'
          : 'Vegetable grow-time estimate based on crop family and common home-garden timing.',
    );
  }

  static ({int min, int max}) germinationWindowFor(VegetableDefinition crop) {
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

  static int transplantWeeksFor(VegetableDefinition crop) {
    final id = crop.id.toLowerCase();
    final family = crop.familyId.toLowerCase();
    return switch (family) {
      'leafy_greens' => 4,
      'brassicas' => 5,
      'cucurbits' => 3,
      'herbs' => 6,
      _ =>
        const ['tomato', 'chilli', 'capsicum', 'eggplant'].contains(id) ? 8 : 6,
    };
  }

  static ({int min, int max}) harvestWindowFor(VegetableDefinition crop) {
    final id = crop.id.toLowerCase();
    final family = crop.familyId.toLowerCase();
    if (id.contains('radish')) return (min: 25, max: 35);
    if (id.contains('lettuce') || id.contains('rocket')) {
      return (min: 35, max: 60);
    }
    if (id.contains('spinach') || id.contains('silverbeet')) {
      return (min: 45, max: 70);
    }
    if (id.contains('tomato')) return (min: 70, max: 100);
    if (id.contains('chilli') || id.contains('capsicum')) {
      return (min: 80, max: 120);
    }
    if (id.contains('eggplant')) return (min: 80, max: 110);
    if (id.contains('zucchini') || id.contains('cucumber')) {
      return (min: 50, max: 70);
    }
    if (id.contains('pumpkin') || id.contains('squash')) {
      return (min: 90, max: 130);
    }
    if (id.contains('bean')) return (min: 50, max: 75);
    if (id.contains('pea')) return (min: 60, max: 85);
    if (id.contains('carrot')) return (min: 70, max: 100);
    if (id.contains('beetroot')) return (min: 55, max: 80);
    if (id.contains('onion') || id.contains('garlic')) {
      return (min: 120, max: 210);
    }
    if (family == 'brassicas') return (min: 60, max: 110);
    if (family == 'herbs') return (min: 45, max: 90);
    return (min: 60, max: 100);
  }
}
