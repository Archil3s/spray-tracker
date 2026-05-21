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
      throw const GeminiAdvisorException('Missing Gemini API key.');
    }

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
      throw GeminiAdvisorException('Gemini request failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiAdvisorException('No Gemini response candidate.');
    }

    final content = candidates.first['content'];
    final parts = content is Map<String, dynamic> ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) {
      throw const GeminiAdvisorException('No Gemini response parts.');
    }

    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text'])
        .whereType<String>()
        .join('\n')
        .trim();

    if (text.isEmpty) {
      throw const GeminiAdvisorException('Empty Gemini response.');
    }

    return text;
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

class GeminiAdvisorException implements Exception {
  const GeminiAdvisorException(this.message);
  final String message;

  @override
  String toString() => message;
}
