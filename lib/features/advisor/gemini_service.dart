import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

class AdvisorProduct {
  const AdvisorProduct({
    required this.name,
    required this.type,
    required this.withholdingDays,
  });

  final String name;
  final String type;
  final int withholdingDays;
}

class GeminiAdvisorService {
  GeminiAdvisorService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<String> getAdvice({
    required String observation,
    required List<AdvisorProduct> products,
  }) async {
    final key = ApiConfig.geminiApiKey.trim();

    if (key.isEmpty || key == 'YOUR_KEY_HERE') {
      return OfflineAdvisorService.getAdvice(
        observation: observation,
        products: products,
        reason: 'No Gemini API key is set.',
      );
    }

    try {
      final uri = Uri.parse('$_endpoint?key=$key');
      final prompt = _buildPrompt(observation: observation, products: products);

      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.35,
                'topP': 0.9,
                'maxOutputTokens': 220,
              },
            }),
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return OfflineAdvisorService.getAdvice(
          observation: observation,
          products: products,
          reason: 'Gemini returned ${response.statusCode}.',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        return OfflineAdvisorService.getAdvice(
          observation: observation,
          products: products,
          reason: 'Gemini returned no response candidate.',
        );
      }

      final content = candidates.first['content'];
      final parts = content is Map<String, dynamic> ? content['parts'] : null;
      if (parts is! List || parts.isEmpty) {
        return OfflineAdvisorService.getAdvice(
          observation: observation,
          products: products,
          reason: 'Gemini returned no text parts.',
        );
      }

      final text = parts
          .whereType<Map<String, dynamic>>()
          .map((part) => part['text'])
          .whereType<String>()
          .join('\n')
          .trim();

      if (text.isEmpty) {
        return OfflineAdvisorService.getAdvice(
          observation: observation,
          products: products,
          reason: 'Gemini returned an empty response.',
        );
      }

      return text;
    } catch (_) {
      return OfflineAdvisorService.getAdvice(
        observation: observation,
        products: products,
        reason: 'Gemini could not be reached.',
      );
    }
  }

  String _buildPrompt({
    required String observation,
    required List<AdvisorProduct> products,
  }) {
    final productList = products.isEmpty
        ? 'No spray products are currently configured.'
        : products
            .map((product) =>
                '- ${product.name} — ${product.type} — ${product.withholdingDays} days')
            .join('\n');

    return '''You are a spray advisor for a home vegetable gardener in Marlborough, New Zealand. The gardener has the following spray products available:
$productList

When the gardener describes a problem, respond with:
1. The most likely cause (1-2 sentences)
2. Which product from their library to use, or if none is suitable, a free/organic alternative available in NZ
3. The withholding period reminder for the specific crop if relevant
4. One short tip on application timing or conditions

Keep the response concise — under 150 words. Plain text only, no markdown.

Gardener observation:
$observation''';
  }
}

class OfflineAdvisorService {
  static String getAdvice({
    required String observation,
    required List<AdvisorProduct> products,
    required String reason,
  }) {
    final text = observation.toLowerCase();
    final crop = _detectCrop(text);

    if (_containsAny(text, [
      'aphid',
      'whitefly',
      'white fly',
      'thrip',
      'mite',
      'bug',
      'insect',
      'sticky',
      'curling leaves',
      'curling',
      'chewed',
      'holes',
    ])) {
      final product = _findProduct(products, ['neem', 'pyrethrin', 'insect', 'pest', 'oil']);
      return _format(
        cause: 'The most likely cause is pest pressure from insects such as aphids, whitefly, mites, thrips or caterpillars.',
        product: product == null
            ? 'Use a strong water spray first, remove badly affected leaves, or use an organic soap/oil spray available in NZ if it suits the crop.'
            : 'Use ${product.name} from your product library if its label supports use on $crop.',
        withholding: product == null
            ? 'Check any product label before harvesting $crop.'
            : 'Withholding reminder: ${product.name} is set to ${product.withholdingDays} days in your app.',
        tip: 'Apply in the cool of the day and avoid spraying when bees are active or plants are heat-stressed.',
        reason: reason,
      );
    }

    if (_containsAny(text, [
      'mildew',
      'powder',
      'white patches',
      'rust',
      'blight',
      'spots',
      'spot',
      'fungus',
      'mould',
      'mold',
      'black marks',
    ])) {
      final product = _findProduct(products, ['copper', 'fungicide', 'fungus']);
      return _format(
        cause: 'The most likely cause is fungal pressure, often encouraged by humidity, poor airflow or leaves staying damp overnight.',
        product: product == null
            ? 'Remove affected leaves, improve airflow, water at soil level, or use an organic copper/sulphur-style fungicide available in NZ if suitable for the crop.'
            : 'Use ${product.name} from your product library if its label supports use on $crop.',
        withholding: product == null
            ? 'Check the label withholding period before harvesting $crop.'
            : 'Withholding reminder: ${product.name} is set to ${product.withholdingDays} days in your app.',
        tip: 'Spray only when leaves can dry before evening, and avoid spraying before rain.',
        reason: reason,
      );
    }

    if (_containsAny(text, [
      'yellow',
      'pale',
      'slow growth',
      'weak',
      'stressed',
      'transplant',
      'wind damage',
      'cold damage',
      'wilting',
      'wilt',
    ])) {
      final product = _findProduct(products, ['seaweed', 'tonic', 'health', 'plant']);
      return _format(
        cause: 'The most likely cause is plant stress, nutrient shortage, cold or wind exposure, or transplant shock rather than a pest outbreak.',
        product: product == null
            ? 'Use compost, worm tea, diluted seaweed tonic, or a gentle vegetable feed available in NZ.'
            : 'Use ${product.name} from your product library as a plant support product.',
        withholding: product == null
            ? 'Most plant tonics have no harvest hold, but always check the label.'
            : 'Withholding reminder: ${product.name} is set to ${product.withholdingDays} days in your app.',
        tip: 'Apply in mild conditions and water the soil first if it is dry.',
        reason: reason,
      );
    }

    final product = _findProduct(products, ['seaweed', 'tonic', 'health']) ?? products.firstOrNull;
    return _format(
      cause: 'The cause is not clear from the description. Inspect leaf undersides for insects and check for powder, rust, spots, rot or chewing damage.',
      product: product == null
          ? 'Start with non-spray steps: remove damaged leaves, improve airflow, water at soil level and monitor for 24-48 hours.'
          : 'If the plant looks stressed rather than diseased, ${product.name} may be the safest starting point if the label supports the crop.',
      withholding: product == null
          ? 'No withholding period can be confirmed without choosing a product.'
          : 'Withholding reminder: ${product.name} is set to ${product.withholdingDays} days in your app.',
      tip: 'Do not spray unless you can identify the target problem or the product label clearly matches the crop and issue.',
      reason: reason,
    );
  }

  static String _format({
    required String cause,
    required String product,
    required String withholding,
    required String tip,
    required String reason,
  }) {
    return '$cause\n\n$product\n\n$withholding\n\nTip: $tip\n\nOffline advisor used: $reason';
  }

  static bool _containsAny(String text, List<String> words) => words.any(text.contains);

  static AdvisorProduct? _findProduct(List<AdvisorProduct> products, List<String> terms) {
    for (final product in products) {
      final combined = '${product.name} ${product.type}'.toLowerCase();
      if (terms.any(combined.contains)) return product;
    }
    return null;
  }

  static String _detectCrop(String text) {
    const crops = [
      'tomato',
      'chilli',
      'capsicum',
      'potato',
      'cucumber',
      'zucchini',
      'lettuce',
      'kale',
      'broccoli',
      'cabbage',
      'onion',
      'garlic',
      'beans',
      'peas',
      'strawberry',
    ];
    for (final crop in crops) {
      if (text.contains(crop)) return crop;
    }
    return 'the affected crop';
  }
}

class GeminiAdvisorException implements Exception {
  const GeminiAdvisorException(this.message);
  final String message;

  @override
  String toString() => message;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
