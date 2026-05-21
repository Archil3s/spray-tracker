import '../../data/openfarm_service.dart';

class GeminiService {
  GeminiService({OpenFarmService? openFarmService})
      : _openFarmService = openFarmService ?? OpenFarmService.instance;

  final OpenFarmService _openFarmService;

  Future<String> withOpenFarmCropContext({
    required String systemPrompt,
    required String cropName,
  }) async {
    final cleanCrop = cropName.trim();
    if (cleanCrop.isEmpty) return systemPrompt;

    final crop = await _openFarmService.getCropByName(cleanCrop);
    if (crop == null) return systemPrompt;

    final context = [
      'The gardener is asking about ${crop.name}.',
      if (crop.description.isNotEmpty)
        'OpenFarm growing notes: ${crop.description}.',
      if (crop.sunRequirements.isNotEmpty) 'Sun: ${crop.sunRequirements}.',
      if (crop.tags.isNotEmpty) 'Tags: ${crop.tags.join(', ')}.',
    ].join(' ');

    return '$systemPrompt\n\n$context';
  }
}
