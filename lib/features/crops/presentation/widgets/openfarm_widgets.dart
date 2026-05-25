part of '../../../../main.dart';

class CropLookupField extends StatefulWidget {
  const CropLookupField({required this.onCropChosen, super.key});

  final void Function(String cropName, OpenFarmCrop? crop) onCropChosen;

  @override
  State<CropLookupField> createState() => _CropLookupFieldState();
}

class _CropLookupFieldState extends State<CropLookupField> {
  final controller = TextEditingController();
  Timer? debounce;
  List<OpenFarmCrop> suggestions = const [];
  bool loading = false;
  bool searched = false;

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    debounce?.cancel();

    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        suggestions = const [];
        loading = false;
        searched = false;
      });
      return;
    }

    setState(() {
      loading = true;
      searched = false;
    });

    debounce = Timer(const Duration(milliseconds: 260), () async {
      final results = await OpenFarmService.instance.searchCrops(query);
      if (!mounted) return;
      setState(() {
        suggestions = results.take(8).toList();
        loading = false;
        searched = true;
      });
    });
  }

  void _choose(OpenFarmCrop crop) {
    controller.text = crop.name;
    widget.onCropChosen(crop.name, crop);
    setState(() {
      suggestions = const [];
      searched = false;
      loading = false;
    });
  }

  void _addManual() {
    final clean = controller.text.trim();
    if (clean.isEmpty) return;
    widget.onCropChosen(clean, null);
    setState(() {
      controller.clear();
      suggestions = const [];
      searched = false;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canAddManual = controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: 'Search crop, e.g. tomato, lettuce, carrot...',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.search, color: C.muted, size: 19),
          ),
          suffix: canAddManual
              ? CupertinoButton(
                  padding: const EdgeInsets.only(right: 10),
                  minimumSize: Size.zero,
                  onPressed: _addManual,
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: C.forest,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : null,
          padding: const EdgeInsets.all(13),
          onChanged: _search,
          onSubmitted: (_) => _addManual(),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line),
          ),
        ),
        if (loading)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.line),
            ),
            child: const Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 10),
                Text(
                  'Searching OpenFarm...',
                  style: TextStyle(color: C.muted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        if (!loading && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: cardDecoration(radius: 16),
            child: Column(
              children: suggestions
                  .map(
                    (crop) => CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _choose(crop),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: C.line)),
                        ),
                        child: Row(
                          children: [
                            OpenFarmImageBox(imageUrl: crop.imageUrl, size: 42),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crop.name,
                                    style: const TextStyle(
                                      color: C.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    crop.sunRequirements.isEmpty
                                        ? 'OpenFarm crop profile'
                                        : crop.sunRequirements,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: C.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        if (!loading && searched && suggestions.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.line),
            ),
            child: const Text(
              'No matches - type to enter manually',
              style: TextStyle(color: C.muted, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class OpenFarmCropInfoSection extends StatefulWidget {
  const OpenFarmCropInfoSection({required this.cropName, super.key});

  final String cropName;

  @override
  State<OpenFarmCropInfoSection> createState() =>
      _OpenFarmCropInfoSectionState();
}

class _OpenFarmCropInfoSectionState extends State<OpenFarmCropInfoSection> {
  Future<OpenFarmCrop?>? future;

  @override
  void initState() {
    super.initState();
    future = OpenFarmService.instance.getCropByName(widget.cropName);
  }

  @override
  void didUpdateWidget(covariant OpenFarmCropInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropName != widget.cropName) {
      future = OpenFarmService.instance.getCropByName(widget.cropName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpenFarmCrop?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.soft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.line),
            ),
            child: const Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 10),
                Text(
                  'Loading crop info...',
                  style: TextStyle(color: C.muted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }

        final crop = snapshot.data;
        if (crop == null) return const SizedBox.shrink();

        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => showOpenFarmCropDetail(context, crop),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.forestSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OpenFarmImageBox(imageUrl: crop.imageUrl, size: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crop info',
                        style: TextStyle(
                          color: C.forest,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        crop.name,
                        style: const TextStyle(
                          color: C.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (crop.sunRequirements.isNotEmpty)
                        Text(
                          crop.sunRequirements,
                          style: const TextStyle(
                            color: C.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (crop.description.isNotEmpty)
                        Text(
                          crop.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: C.ink,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      const SizedBox(height: 4),
                      const Text(
                        'via OpenFarm',
                        style: TextStyle(
                          color: C.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: C.muted,
                  size: 17,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OpenFarmImageBox extends StatelessWidget {
  const OpenFarmImageBox({
    required this.imageUrl,
    required this.size,
    super.key,
  });

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: const Icon(CupertinoIcons.leaf_arrow_circlepath, color: C.forest),
    );

    if (imageUrl.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

void showOpenFarmCropDetail(BuildContext context, OpenFarmCrop crop) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: crop.imageUrl.isEmpty
                ? Container(
                    height: 190,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: C.forestSoft,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      CupertinoIcons.leaf_arrow_circlepath,
                      color: C.forest,
                      size: 46,
                    ),
                  )
                : Image.network(
                    crop.imageUrl,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Container(
                                height: 210,
                                alignment: Alignment.center,
                                color: C.forestSoft,
                                child: const CupertinoActivityIndicator(),
                              ),
                    errorBuilder: (_, __, ___) => Container(
                      height: 210,
                      alignment: Alignment.center,
                      color: C.forestSoft,
                      child: const Icon(
                        CupertinoIcons.leaf_arrow_circlepath,
                        color: C.forest,
                        size: 46,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SheetHeader(title: crop.name, subtitle: 'OpenFarm crop profile'),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop.description.isEmpty
                      ? 'No OpenFarm description listed.'
                      : crop.description,
                  style: const TextStyle(
                    color: C.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.35,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                OpenFarmFact(label: 'Sun', value: crop.sunRequirements),
                OpenFarmFact(label: 'Sowing', value: crop.sowingMethod),
                OpenFarmFact(label: 'Spread', value: formatCm(crop.spread)),
                OpenFarmFact(
                  label: 'Row spacing',
                  value: formatCm(crop.rowSpacing),
                ),
                OpenFarmFact(label: 'Height', value: formatCm(crop.height)),
              ],
            ),
          ),
          if (crop.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: crop.tags
                  .map(
                    (tag) => ProductTag(
                      label: tag,
                      color: C.muted,
                      background: C.greySoft,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          CupertinoButton(
            color: C.forest,
            borderRadius: BorderRadius.circular(16),
            onPressed: () async {
              try {
                await launchUrl(
                  Uri.parse(crop.openFarmUrl),
                  mode: LaunchMode.externalApplication,
                );
              } catch (_) {}
            },
            child: const Text(
              'View on OpenFarm',
              style: TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class OpenFarmFact extends StatelessWidget {
  const OpenFarmFact({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: C.forest,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.isEmpty ? '-' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: C.ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}

String formatCm(double? value) {
  if (value == null) return '-';
  final rounded = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$rounded cm';
}
