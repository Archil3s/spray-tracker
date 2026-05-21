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

  List<OpenFarmCrop> get featuredCrops => _fallbackCrops;

  Future<List<OpenFarmCrop>> searchCrops(String query) async {
    final clean = query.trim();
    if (clean.length < 2) {
      return const [];
    }

    final key = _key(clean);
    final cached = _searchCache[key];
    if (cached != null) {
      return cached;
    }

    final apiResults = <OpenFarmCrop>[];

    try {
      final uri = Uri.https('openfarm.cc', '/api/v1/crops', {'filter': clean});
      final response = await _client.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;

        if (data is List) {
          apiResults.addAll(
            data
                .whereType<Map<String, dynamic>>()
                .map(OpenFarmCrop.fromApiJson)
                .where((crop) => crop.name.trim().isNotEmpty)
                .map((crop) => OpenFarmCrop(
                      name: crop.name,
                      description: crop.description,
                      sunRequirements: crop.sunRequirements,
                      sowingMethod: crop.sowingMethod,
                      spread: crop.spread,
                      rowSpacing: crop.rowSpacing,
                      height: crop.height,
                      imageUrl: '',
                      tags: crop.tags,
                      slug: crop.slug,
                    )),
          );
        }
      }
    } on TimeoutException {
      // Optional enrichment only.
    } catch (_) {
      // Optional enrichment only.
    }

    final combined = _rank(clean, [..._fallbackSearch(clean), ...apiResults]);
    _searchCache[key] = combined;

    for (final crop in combined) {
      _cropCache[_key(crop.name)] = crop;
    }

    return combined;
  }

  Future<OpenFarmCrop?> getCropByName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      return null;
    }

    final key = _key(clean);
    final cached = _cropCache[key];
    if (cached != null) {
      return cached;
    }

    final local = _fallbackCrops.where((crop) => _key(crop.name) == key).firstOrNull;
    if (local != null) {
      _cropCache[key] = local;
      return local;
    }

    final results = await searchCrops(clean);
    if (results.isEmpty) {
      return null;
    }

    _cropCache[key] = results.first;
    return results.first;
  }

  List<OpenFarmCrop> _fallbackSearch(String query) {
    final q = _key(query);
    final synonym = _synonyms[q];
    final terms = <String>{q, if (synonym != null) synonym};

    return _fallbackCrops.where((crop) {
      final text = [
        crop.name,
        crop.description,
        crop.sunRequirements,
        crop.sowingMethod,
        ...crop.tags,
      ].join(' ').toLowerCase();

      return terms.any(text.contains);
    }).toList();
  }

  List<OpenFarmCrop> _rank(String query, List<OpenFarmCrop> crops) {
    final seen = <String>{};
    final unique = <OpenFarmCrop>[];

    for (final crop in crops) {
      final key = _key(crop.name);
      if (seen.add(key)) {
        unique.add(crop);
      }
    }

    unique.sort((a, b) => _score(query, b).compareTo(_score(query, a)));
    return unique;
  }

  int _score(String query, OpenFarmCrop crop) {
    final q = _key(query);
    final name = _key(crop.name);
    final tags = crop.tags.join(' ').toLowerCase();

    if (name == q) {
      return 100;
    }
    if (name.startsWith(q)) {
      return 80;
    }
    if (name.contains(q)) {
      return 60;
    }
    if (tags.contains(q)) {
      return 40;
    }
    return 0;
  }

  String _key(String value) => value.toLowerCase().trim();
}

const Map<String, String> _synonyms = {
  'courgette': 'zucchini',
  'capsicum': 'sweet pepper',
  'pepper': 'capsicum',
  'chilli': 'chili',
  'kumara': 'sweet potato',
  'silverbeet': 'swiss chard',
  'rocket': 'arugula',
  'coriander': 'cilantro',
  'aubergine': 'eggplant',
};

const List<OpenFarmCrop> _fallbackCrops = [
  OpenFarmCrop(name: 'Tomato', description: 'Warm season fruiting crop. Needs full sun, airflow, staking, and steady watering.', sunRequirements: 'Full Sun', sowingMethod: 'Start indoors or transplant after frost risk.', spread: 60, rowSpacing: 90, height: 150, imageUrl: '', tags: ['Fruiting', 'Nightshade', 'Vegetable'], slug: 'tomato'),
  OpenFarmCrop(name: 'Cherry Tomato', description: 'Small-fruited tomato. Productive, high pest monitoring crop.', sunRequirements: 'Full Sun', sowingMethod: 'Start indoors or transplant after frost risk.', spread: 60, rowSpacing: 90, height: 180, imageUrl: '', tags: ['Fruiting', 'Nightshade', 'Vegetable'], slug: 'cherry-tomato'),
  OpenFarmCrop(name: 'Capsicum', description: 'Warm season sweet pepper crop. Needs heat and even watering.', sunRequirements: 'Full Sun', sowingMethod: 'Start indoors or transplant after frost risk.', spread: 45, rowSpacing: 60, height: 75, imageUrl: '', tags: ['Fruiting', 'Nightshade', 'Vegetable'], slug: 'sweet-pepper'),
  OpenFarmCrop(name: 'Chilli', description: 'Warm season pepper crop. Needs heat, sun, and protection from cold nights.', sunRequirements: 'Full Sun', sowingMethod: 'Start indoors or transplant in warm weather.', spread: 45, rowSpacing: 60, height: 80, imageUrl: '', tags: ['Fruiting', 'Nightshade', 'Vegetable'], slug: 'chili-pepper'),
  OpenFarmCrop(name: 'Eggplant', description: 'Warm season nightshade. Needs heat, full sun, and steady moisture.', sunRequirements: 'Full Sun', sowingMethod: 'Start indoors or transplant after frost risk.', spread: 60, rowSpacing: 75, height: 90, imageUrl: '', tags: ['Fruiting', 'Nightshade', 'Vegetable'], slug: 'eggplant'),
  OpenFarmCrop(name: 'Potato', description: 'Root crop. Hill soil as plants grow and monitor for blight and psyllid.', sunRequirements: 'Full Sun', sowingMethod: 'Plant seed potatoes.', spread: 45, rowSpacing: 75, height: 70, imageUrl: '', tags: ['Root', 'Nightshade', 'Vegetable'], slug: 'potato'),
  OpenFarmCrop(name: 'Lettuce', description: 'Cool season leafy crop. Needs regular moisture and some shade in hot weather.', sunRequirements: 'Full Sun to Partial Shade', sowingMethod: 'Direct sow or transplant.', spread: 25, rowSpacing: 30, height: 25, imageUrl: '', tags: ['Leafy', 'Vegetable'], slug: 'lettuce'),
  OpenFarmCrop(name: 'Spinach', description: 'Cool season leafy crop. Bolts in heat and prefers steady moisture.', sunRequirements: 'Full Sun to Partial Shade', sowingMethod: 'Direct sow or transplant.', spread: 20, rowSpacing: 30, height: 25, imageUrl: '', tags: ['Leafy', 'Vegetable'], slug: 'spinach'),
  OpenFarmCrop(name: 'Silverbeet', description: 'Hardy leafy crop also known as Swiss chard.', sunRequirements: 'Full Sun to Partial Shade', sowingMethod: 'Direct sow or transplant.', spread: 35, rowSpacing: 45, height: 55, imageUrl: '', tags: ['Leafy', 'Vegetable'], slug: 'swiss-chard'),
  OpenFarmCrop(name: 'Kale', description: 'Hardy brassica leafy green. Good cool season crop.', sunRequirements: 'Full Sun to Partial Shade', sowingMethod: 'Direct sow or transplant.', spread: 45, rowSpacing: 60, height: 75, imageUrl: '', tags: ['Leafy', 'Brassica', 'Vegetable'], slug: 'kale'),
  OpenFarmCrop(name: 'Rocket', description: 'Fast leafy brassica also known as arugula.', sunRequirements: 'Full Sun to Partial Shade', sowingMethod: 'Direct sow.', spread: 15, rowSpacing: 25, height: 25, imageUrl: '', tags: ['Leafy', 'Brassica', 'Vegetable'], slug: 'arugula'),
  OpenFarmCrop(name: 'Cabbage', description: 'Cool season brassica. Needs even moisture and caterpillar protection.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow or transplant.', spread: 60, rowSpacing: 75, height: 45, imageUrl: '', tags: ['Leafy', 'Brassica', 'Vegetable'], slug: 'cabbage'),
  OpenFarmCrop(name: 'Broccoli', description: 'Cool season brassica grown for flower heads.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow or transplant.', spread: 60, rowSpacing: 75, height: 75, imageUrl: '', tags: ['Brassica', 'Vegetable'], slug: 'broccoli'),
  OpenFarmCrop(name: 'Cauliflower', description: 'Cool season brassica grown for heads.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow or transplant.', spread: 60, rowSpacing: 75, height: 60, imageUrl: '', tags: ['Brassica', 'Vegetable'], slug: 'cauliflower'),
  OpenFarmCrop(name: 'Bok Choy', description: 'Fast cool season brassica. Can bolt in heat.', sunRequirements: 'Full Sun to Partial Shade', sowingMethod: 'Direct sow or transplant.', spread: 20, rowSpacing: 30, height: 30, imageUrl: '', tags: ['Leafy', 'Brassica', 'Vegetable'], slug: 'bok-choy'),
  OpenFarmCrop(name: 'Carrot', description: 'Root crop that prefers loose soil, steady moisture, and direct sowing.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow only.', spread: 5, rowSpacing: 25, height: 30, imageUrl: '', tags: ['Root', 'Vegetable'], slug: 'carrot'),
  OpenFarmCrop(name: 'Beetroot', description: 'Root crop that prefers even moisture and loose soil.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow.', spread: 10, rowSpacing: 30, height: 30, imageUrl: '', tags: ['Root', 'Vegetable'], slug: 'beet'),
  OpenFarmCrop(name: 'Radish', description: 'Fast root crop. Best grown quickly in cool conditions.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow.', spread: 5, rowSpacing: 20, height: 20, imageUrl: '', tags: ['Root', 'Vegetable'], slug: 'radish'),
  OpenFarmCrop(name: 'Parsnip', description: 'Long season root crop. Needs deep loose soil and steady moisture.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow fresh seed.', spread: 10, rowSpacing: 35, height: 45, imageUrl: '', tags: ['Root', 'Vegetable'], slug: 'parsnip'),
  OpenFarmCrop(name: 'Kumara', description: 'Warm season sweet potato crop. Needs warm soil and long frost-free season.', sunRequirements: 'Full Sun', sowingMethod: 'Plant slips or rooted shoots.', spread: 90, rowSpacing: 100, height: 30, imageUrl: '', tags: ['Root', 'Vegetable'], slug: 'sweet-potato'),
  OpenFarmCrop(name: 'Onion', description: 'Cool season allium crop. Needs weed-free soil and even moisture.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow, transplant, or plant sets.', spread: 10, rowSpacing: 30, height: 45, imageUrl: '', tags: ['Allium', 'Vegetable'], slug: 'onion'),
  OpenFarmCrop(name: 'Garlic', description: 'Allium crop grown from cloves. Needs free draining soil.', sunRequirements: 'Full Sun', sowingMethod: 'Plant individual cloves.', spread: 10, rowSpacing: 25, height: 60, imageUrl: '', tags: ['Allium', 'Vegetable'], slug: 'garlic'),
  OpenFarmCrop(name: 'Leek', description: 'Cool season allium. Hill soil around stems for longer white shanks.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow or transplant.', spread: 15, rowSpacing: 30, height: 60, imageUrl: '', tags: ['Allium', 'Vegetable'], slug: 'leek'),
  OpenFarmCrop(name: 'Spring Onion', description: 'Fast allium crop. Useful for small gardens and repeat sowing.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow or transplant.', spread: 5, rowSpacing: 15, height: 35, imageUrl: '', tags: ['Allium', 'Vegetable'], slug: 'scallion'),
  OpenFarmCrop(name: 'Peas', description: 'Cool season legume. Needs support for climbing types.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow.', spread: 10, rowSpacing: 45, height: 120, imageUrl: '', tags: ['Legume', 'Vegetable'], slug: 'pea'),
  OpenFarmCrop(name: 'Beans', description: 'Warm season legume. Bush beans stay compact, climbing beans need support.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow after soil warms.', spread: 20, rowSpacing: 45, height: 180, imageUrl: '', tags: ['Legume', 'Vegetable'], slug: 'bean'),
  OpenFarmCrop(name: 'Broad Beans', description: 'Cool season legume. Pinch tips if black aphids build up.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow.', spread: 25, rowSpacing: 45, height: 120, imageUrl: '', tags: ['Legume', 'Vegetable'], slug: 'fava-bean'),
  OpenFarmCrop(name: 'Cucumber', description: 'Warm season vine crop. Benefits from trellising, airflow, and regular watering.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow or transplant after frost risk.', spread: 90, rowSpacing: 120, height: 180, imageUrl: '', tags: ['Cucurbit', 'Vine', 'Vegetable'], slug: 'cucumber'),
  OpenFarmCrop(name: 'Zucchini', description: 'Fast growing warm season cucurbit. Needs space, sun, and regular harvest.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow or transplant after frost risk.', spread: 90, rowSpacing: 120, height: 60, imageUrl: '', tags: ['Cucurbit', 'Vegetable'], slug: 'zucchini'),
  OpenFarmCrop(name: 'Pumpkin', description: 'Large warm season vine crop. Needs space, sun, and steady watering.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow or transplant after frost risk.', spread: 180, rowSpacing: 180, height: 60, imageUrl: '', tags: ['Cucurbit', 'Vine', 'Vegetable'], slug: 'pumpkin'),
  OpenFarmCrop(name: 'Watermelon', description: 'Warm season vine crop. Needs heat, full sun, space, and regular moisture.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow or transplant after frost risk.', spread: 180, rowSpacing: 180, height: 40, imageUrl: '', tags: ['Cucurbit', 'Fruit', 'Vine'], slug: 'watermelon'),
  OpenFarmCrop(name: 'Sweetcorn', description: 'Warm season crop. Plant in blocks for pollination.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow after soil warms.', spread: 30, rowSpacing: 75, height: 200, imageUrl: '', tags: ['Fruiting', 'Vegetable'], slug: 'corn'),
  OpenFarmCrop(name: 'Strawberry', description: 'Perennial fruiting crop. Keep fruit off wet soil and improve airflow.', sunRequirements: 'Full Sun', sowingMethod: 'Plant runners or young plants.', spread: 30, rowSpacing: 45, height: 20, imageUrl: '', tags: ['Berry', 'Fruit', 'Perennial'], slug: 'strawberry'),
  OpenFarmCrop(name: 'Blueberry', description: 'Perennial berry crop. Needs acidic soil, mulch, and steady moisture.', sunRequirements: 'Full Sun', sowingMethod: 'Plant young shrubs.', spread: 100, rowSpacing: 150, height: 150, imageUrl: '', tags: ['Berry', 'Fruit', 'Perennial'], slug: 'blueberry'),
  OpenFarmCrop(name: 'Raspberry', description: 'Perennial cane berry. Needs pruning and support.', sunRequirements: 'Full Sun', sowingMethod: 'Plant canes.', spread: 60, rowSpacing: 180, height: 180, imageUrl: '', tags: ['Berry', 'Fruit', 'Perennial'], slug: 'raspberry'),
  OpenFarmCrop(name: 'Basil', description: 'Warm season herb. Likes sun, warmth, and regular picking.', sunRequirements: 'Full Sun', sowingMethod: 'Direct sow or transplant in warm weather.', spread: 30, rowSpacing: 35, height: 45, imageUrl: '', tags: ['Herb', 'Annual'], slug: 'basil'),
  OpenFarmCrop(name: 'Parsley', description: 'Cool season herb. Tolerates partial shade.', sunRequirements: 'Full Sun to Partial Shade', sowingMethod: 'Direct sow or transplant.', spread: 25, rowSpacing: 30, height: 35, imageUrl: '', tags: ['Herb', 'Biennial'], slug: 'parsley'),
  OpenFarmCrop(name: 'Coriander', description: 'Cool season herb also known as cilantro. Bolts quickly in heat.', sunRequirements: 'Full Sun to Partial Shade', sowingMethod: 'Direct sow.', spread: 20, rowSpacing: 25, height: 40, imageUrl: '', tags: ['Herb', 'Annual'], slug: 'cilantro'),
  OpenFarmCrop(name: 'Mint', description: 'Hardy herb. Best grown in a container because it spreads strongly.', sunRequirements: 'Partial Shade to Full Sun', sowingMethod: 'Plant divisions or seedlings.', spread: 45, rowSpacing: 45, height: 45, imageUrl: '', tags: ['Herb', 'Perennial'], slug: 'mint'),
];
