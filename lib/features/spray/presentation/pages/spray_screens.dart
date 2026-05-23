part of '../../../../main.dart';

class SprayLogScreen extends StatefulWidget {
  const SprayLogScreen({
    required this.initialBeds,
    required this.plot,
    required this.gardenBeds,
    required this.bedCrops,
    required this.records,
    required this.products,
    required this.productsLoading,
    required this.sprayConditions,
    required this.onSave,
    super.key,
  });
  final Set<int> initialBeds;
  final GardenPlot plot;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final bool productsLoading;
  final Future<SprayConditionSummary> sprayConditions;
  final void Function({
    required Set<int> beds,
    required Set<String> crops,
    required Map<String, OpenFarmCrop> cropProfiles,
    required String targetId,
    required SprayProduct product,
    required String reason,
    required String notes,
    required int days,
  }) onSave;

  @override
  State<SprayLogScreen> createState() => _SprayLogScreenState();
}

class _SprayLogScreenState extends State<SprayLogScreen> {
  late Set<int> beds = {...widget.initialBeds};
  final Set<String> manualCrops = {};
  final Map<String, OpenFarmCrop> cropProfiles = {};
  String targetId = 'pest';
  SprayProduct? selectedProduct;
  int days = 0;
  final reason = TextEditingController();
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.products.isNotEmpty) {
      _selectProduct(_bestProductForTarget('pest'));
    }
  }

  @override
  void dispose() {
    reason.dispose();
    notes.dispose();
    super.dispose();
  }

  SprayProduct _bestProductForTarget(String target) {
    return widget.products.firstWhere(
      (product) => product.targets.contains(target),
      orElse: () => widget.products.first,
    );
  }

  void _selectProduct(SprayProduct product) {
    selectedProduct = product;
    days = product.withholdingDays;
  }

  @override
  Widget build(BuildContext context) {
    final product = selectedProduct;
    final crops = {
      ...cropNamesForBeds(widget.bedCrops, beds),
      ...manualCrops,
    }.toList()
      ..sort();
    final sortedBeds = beds.toList()..sort();
    return AppPage(
      title: 'Spray Log',
      subtitle:
          'Choose product, then withholding and re-entry notes fill automatically.',
      children: [
        SprayConditionBanner(sprayConditions: widget.sprayConditions),
        const SizedBox(height: 18),
        const SectionTitle('Beds sprayed'),
        const SizedBox(height: 8),
        Container(
          height: 360,
          decoration: BoxDecoration(
            color: C.soft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: C.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: GardenMap(
            selectedBed: beds.isEmpty ? -1 : beds.first,
            selectedBeds: beds,
            plot: widget.plot,
            gardenBeds: widget.gardenBeds,
            bedCrops: widget.bedCrops,
            records: widget.records,
            isHold: (bed) => widget.records.any(
              (record) => record.beds.contains(bed) && record.onHold,
            ),
            designing: false,
            onTap: (bed) => setState(
              () {
                if (beds.contains(bed)) {
                  beds.remove(bed);
                } else {
                  beds.add(bed);
                }
              },
            ),
            onMove: (_, __) {},
          ),
        ),
        const SizedBox(height: 8),
        if (beds.isEmpty)
          const EmptyCard('Tap beds on the garden outline to select them.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ProductTag(
                label:
                    '${beds.length} bed${beds.length == 1 ? '' : 's'} selected',
                color: C.forest,
                background: C.forestSoft,
              ),
              ...sortedBeds.map(
                (bed) => ProductTag(
                  label: 'Bed $bed',
                  color: C.forest,
                  background: C.card,
                ),
              ),
            ],
          ),
        const SizedBox(height: 18),
        const SectionTitle('Crops affected'),
        const SizedBox(height: 8),
        if (crops.isEmpty)
          const EmptyCard('No crops assigned to selected bed yet.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: crops.map((crop) => TextChip(label: crop)).toList(),
          ),
        const SizedBox(height: 8),
        CropLookupField(
          onCropChosen: (name, crop) => setState(() {
            manualCrops.add(name);
            if (crop != null) {
              cropProfiles[name] = crop;
            }
          }),
        ),
        if (crops.isNotEmpty) ...[
          const SizedBox(height: 8),
          OpenFarmCropInfoSection(cropName: crops.first),
        ],
        const SizedBox(height: 18),
        const SectionTitle('Spraying against'),
        const SizedBox(height: 8),
        TargetGrid(
          selected: targetId,
          onSelect: (id) => setState(() {
            targetId = id;
            if (widget.products.isNotEmpty) {
              _selectProduct(_bestProductForTarget(id));
            }
          }),
        ),
        const SizedBox(height: 18),
        const SectionTitle('NZ product library'),
        const SizedBox(height: 8),
        if (widget.productsLoading)
          const Center(child: CupertinoActivityIndicator())
        else if (widget.products.isEmpty)
          const EmptyCard('No products loaded.')
        else
          ...widget.products.map(
            (item) => ProductChoice(
              product: item,
              selected: product?.id == item.id,
              suggested: item.targets.contains(targetId),
              onTap: () => setState(() => _selectProduct(item)),
            ),
          ),
        const SizedBox(height: 18),
        Field(
          controller: reason,
          placeholder: 'Issue or reason, e.g. aphids on tomato tips',
        ),
        const SizedBox(height: 8),
        Field(controller: notes, placeholder: 'Notes optional', maxLines: 3),
        const SizedBox(height: 12),
        Stepper(
          label: 'Withholding days',
          value: days,
          minus: days > 0 ? () => setState(() => days--) : null,
          plus: () => setState(() => days++),
        ),
        if (product != null) ...[
          const SizedBox(height: 8),
          SprayProductHelperNotes(product: product),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Save spray record',
          onPressed: product == null || beds.isEmpty
              ? null
              : () => widget.onSave(
                    beds: beds,
                    crops: crops.toSet(),
                    cropProfiles: cropProfiles,
                    targetId: targetId,
                    product: product,
                    reason: reason.text,
                    notes: notes.text,
                    days: days,
                  ),
        ),
      ],
    );
  }
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({
    required this.products,
    required this.loading,
    required this.message,
    super.key,
  });
  final List<SprayProduct> products;
  final bool loading;
  final String message;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim();
    final filtered = widget.products
        .where((product) => product.matchesQuery(query))
        .toList();
    return AppPage(
      title: 'Products',
      subtitle:
          'Bundled NZ spray products. Verify labels and ACVM details before use.',
      message: widget.message,
      children: [
        CupertinoTextField(
          controller: search,
          placeholder: 'Search product, pest, crop, active ingredient...',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.search, color: C.muted, size: 19),
          ),
          padding: const EdgeInsets.all(13),
          onChanged: (_) => setState(() {}),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line),
          ),
        ),
        const SizedBox(height: 12),
        SectionTitle(
          'NZ spray product library',
          trailing: Text(
            '${filtered.length}',
            style: const TextStyle(color: C.muted, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CupertinoActivityIndicator(),
            ),
          )
        else if (filtered.isEmpty)
          const EmptyCard('No products match that search.')
        else
          ...filtered.map((product) => ProductTile(product: product)),
      ],
    );
  }
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({
    required this.records,
    required this.message,
    required this.onDelete,
    super.key,
  });
  final List<SprayRecord> records;
  final String message;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Records',
        subtitle: 'Saved sprays, target, product, and safe harvest date.',
        message: message,
        children: [
          if (records.isEmpty)
            const EmptyCard('No spray records yet.')
          else
            ...records.map(
              (record) => RecordCard(
                  record: record, onDelete: () => onDelete(record.id)),
            ),
        ],
      );
}

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, super.key});
  final SprayProduct product;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => showSprayProductDetail(context, product),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  CategoryPill(category: product.category),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${product.brand} | ${product.type}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: C.muted, fontWeight: FontWeight.w700),
              ),
              Text(
                product.activeIngredient,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: C.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ProductTag(
                    label: '${product.withholdingDays} day WHP',
                    color: C.forest,
                    background: C.forestSoft,
                  ),
                  ProductTag(
                    label: 'Re-entry: ${product.reEntryHours} hr',
                    color: C.blue,
                    background: C.blueSoft,
                  ),
                  if (product.reSprayIntervalDays > 0)
                    ProductTag(
                      label: 'Re-spray: ${product.reSprayIntervalDays} days',
                      color: C.amber,
                      background: C.amberSoft,
                    ),
                ],
              ),
              if (product.commonUses.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Uses: ${product.commonUses.take(5).join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class ProductChoice extends StatelessWidget {
  const ProductChoice({
    required this.product,
    required this.selected,
    required this.suggested,
    required this.onTap,
    super.key,
  });
  final SprayProduct product;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? C.forestSoft : C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? C.forest : C.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${product.type} | ${product.withholdingDays} day WHP | Re-entry ${product.reEntryHours} hr',
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
              if (suggested) ...[
                const SizedBox(width: 8),
                const StatusPill('MATCH', hold: false),
              ],
              const SizedBox(width: 8),
              Icon(
                selected
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                color: selected ? C.forest : C.muted,
                size: 22,
              ),
            ],
          ),
        ),
      );
}

class SprayProductHelperNotes extends StatelessWidget {
  const SprayProductHelperNotes({required this.product, super.key});
  final SprayProduct product;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.withholdingNote.isNotEmpty)
              Text(
                product.withholdingNote,
                style: const TextStyle(
                  color: C.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            Text(
              'Re-entry: ${product.reEntryHours} hr',
              style: const TextStyle(
                color: C.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (product.reSprayIntervalDays > 0)
              Text(
                'Re-spray interval: ${product.reSprayIntervalDays} days',
                style: const TextStyle(
                  color: C.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
}

void showSprayProductDetail(BuildContext context, SprayProduct product) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(
            title: product.name,
            subtitle: '${product.brand} | ${product.type}',
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailLine('Category', product.category),
                DetailLine('Active ingredient', product.activeIngredient),
                DetailLine('Withholding days', '${product.withholdingDays}'),
                DetailLine('Withholding note', product.withholdingNote),
                DetailLine('Re-entry hours', '${product.reEntryHours}'),
                DetailLine(
                  'Re-spray interval',
                  product.reSprayIntervalDays > 0
                      ? '${product.reSprayIntervalDays} days'
                      : 'Not set',
                ),
                DetailLine('Common uses', product.commonUses.join(', ')),
                DetailLine('Suitable crops', product.suitableCrops.join(', ')),
                DetailLine(
                  'ACVM number',
                  product.acvmRegistrationNumber.isEmpty
                      ? 'Not filled yet'
                      : product.acvmRegistrationNumber,
                ),
                DetailLine('Source', product.source),
                DetailLine(
                  'Notes',
                  product.notes.isEmpty ? 'None' : product.notes,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
