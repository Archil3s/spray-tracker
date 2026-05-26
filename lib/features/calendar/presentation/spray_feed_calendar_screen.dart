part of '../../../main.dart';

typedef CalendarActionSave = void Function({
  required PreventativeCalendarItem item,
  required SprayProduct product,
  required List<PreventativeCalendarItem> coveredItems,
});

class SprayFeedCalendarScreen extends StatefulWidget {
  const SprayFeedCalendarScreen({
    required this.seasonLabel,
    required this.gardenBeds,
    required this.bedCrops,
    required this.records,
    required this.products,
    required this.message,
    required this.gardenRisks,
    required this.onLogAction,
    super.key,
  });

  final String seasonLabel;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final String message;
  final Future<GardenRiskSummary> gardenRisks;
  final CalendarActionSave onLogAction;

  @override
  State<SprayFeedCalendarScreen> createState() =>
      _SprayFeedCalendarScreenState();
}

class _SprayFeedCalendarScreenState extends State<SprayFeedCalendarScreen> {
  late DateTime selectedDay = _dayOnly(DateTime.now());
  late DateTime visibleMonth = DateTime(selectedDay.year, selectedDay.month);

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Calendar',
        subtitle:
            'Visual spray and feeding schedule for ${widget.seasonLabel}.',
        message: widget.message,
        children: [
          FutureBuilder<GardenRiskSummary>(
            future: widget.gardenRisks,
            builder: (context, snapshot) {
              final items = generatePreventativeCalendar(
                beds: widget.gardenBeds,
                bedCrops: widget.bedCrops,
                records: widget.records,
                products: widget.products,
                risks: snapshot.data,
              );
              final events = _calendarEvents(
                items: items,
                records: widget.records,
              );
              final selectedEvents =
                  events[_dayOnly(selectedDay)] ?? const <_CalendarEvent>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CalendarHero(
                    events: events.values.expand((day) => day).toList(),
                  ),
                  const SizedBox(height: 14),
                  _CalendarMonthPanel(
                    visibleMonth: visibleMonth,
                    selectedDay: selectedDay,
                    events: events,
                    onPreviousMonth: () => setState(() {
                      visibleMonth = DateTime(
                        visibleMonth.year,
                        visibleMonth.month - 1,
                      );
                    }),
                    onNextMonth: () => setState(() {
                      visibleMonth = DateTime(
                        visibleMonth.year,
                        visibleMonth.month + 1,
                      );
                    }),
                    onSelectDay: (day) => setState(() {
                      selectedDay = day;
                      visibleMonth = DateTime(day.year, day.month);
                    }),
                  ),
                  const SizedBox(height: 14),
                  SectionTitle(
                    shortDate(selectedDay),
                    trailing: ProductTag(
                      label: '${selectedEvents.length} event',
                      color: selectedEvents.isEmpty ? C.muted : C.forest,
                      background:
                          selectedEvents.isEmpty ? C.greySoft : C.forestSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedEvents.isEmpty)
                    const EmptyCard('No spray or feeding actions on this day.')
                  else
                    ...selectedEvents.map(
                      (event) => _CalendarAgendaCard(
                        event: event,
                        items: items,
                        products: widget.products,
                        records: widget.records,
                        onLogAction: widget.onLogAction,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      );
}

class _CalendarHero extends StatelessWidget {
  const _CalendarHero({required this.events});

  final List<_CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final today = _dayOnly(DateTime.now());
    final dueNow = events.where((event) => !event.day.isAfter(today)).length;
    final feed =
        events.where((event) => event.kind == _CalendarKind.feed).length;
    final spray =
        events.where((event) => event.kind == _CalendarKind.spray).length;
    return Panel(
      child: Row(
        children: [
          Expanded(
            child: HeroMetric(
              label: 'DUE NOW',
              value: '$dueNow',
              color: dueNow > 0 ? C.amber : C.forest,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: HeroMetric(
              label: 'SPRAY',
              value: '$spray',
              color: C.red,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: HeroMetric(
              label: 'FEED',
              value: '$feed',
              color: C.amber,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarMonthPanel extends StatelessWidget {
  const _CalendarMonthPanel({
    required this.visibleMonth,
    required this.selectedDay,
    required this.events,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDay,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final Map<DateTime, List<_CalendarEvent>> events;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final leading = firstDay.weekday - DateTime.monday;
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final days = [
      for (var index = 0; index < totalCells; index++)
        _dayOnly(firstDay.add(Duration(days: index - leading))),
    ];

    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(38, 38),
                onPressed: onPreviousMonth,
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: C.forest,
                ),
              ),
              Expanded(
                child: Text(
                  '${monthName(visibleMonth.month)} ${visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(38, 38),
                onPressed: onNextMonth,
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  color: C.forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
              _WeekdayLabel('S'),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: .66,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              return _CalendarDayCell(
                day: day,
                visibleMonth: visibleMonth,
                selected: _sameDay(day, selectedDay),
                events: events[day] ?? const <_CalendarEvent>[],
                onTap: () => onSelectDay(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: C.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.visibleMonth,
    required this.selected,
    required this.events,
    required this.onTap,
  });

  final DateTime day;
  final DateTime visibleMonth;
  final bool selected;
  final List<_CalendarEvent> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inMonth = day.month == visibleMonth.month;
    final today = _sameDay(day, DateTime.now());
    return SmoothTap(
      onTap: onTap,
      scale: .98,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 3),
        decoration: BoxDecoration(
          color: selected
              ? C.forestSoft
              : inMonth
                  ? C.card
                  : C.soft,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? C.forest
                : today
                    ? C.amber
                    : C.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: inMonth ? C.ink : C.muted,
                fontSize: 11,
                fontWeight: today ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            ...events.take(3).map(
                  (event) => Container(
                    width: double.infinity,
                    height: 9,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: event.background,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: event.color.withValues(alpha: .12),
                      ),
                    ),
                  ),
                ),
            if (events.length > 3)
              Text(
                '+${events.length - 3}',
                style: const TextStyle(
                  color: C.muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarAgendaCard extends StatelessWidget {
  const _CalendarAgendaCard({
    required this.event,
    required this.items,
    required this.products,
    required this.records,
    required this.onLogAction,
  });

  final _CalendarEvent event;
  final List<PreventativeCalendarItem> items;
  final List<SprayProduct> products;
  final List<SprayRecord> records;
  final CalendarActionSave onLogAction;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: event.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(event.icon, color: event.color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.muted,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (event.plannable)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(34, 34),
              onPressed: () => _showCalendarActionSheet(context),
              child: const Icon(
                CupertinoIcons.plus_circle_fill,
                color: C.forest,
              ),
            ),
        ],
      ),
    );
    if (!event.plannable) return card;
    return SmoothTap(
      onTap: () => _showCalendarActionSheet(context),
      child: card,
    );
  }

  void _showCalendarActionSheet(BuildContext context) {
    final item = event.item;
    if (item == null) return;
    final recommendations = _recommendedProducts(item, products);
    if (recommendations.isEmpty) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('No product loaded'),
          message: const Text('Load products before logging from calendar.'),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ),
      );
      return;
    }

    var selected = recommendations.first;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final covered = calendarItemsCoveredByProduct(
            source: item,
            items: items,
            product: selected,
          );
          final nextCheck =
              DateTime.now().add(Duration(days: item.intervalDays));
          return Sheet(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SheetHeader(
                    title: 'Log ${protectionTargetLabel(item.target)}',
                    subtitle: '${item.bed.label} | ${item.crop.name}',
                  ),
                  const SizedBox(height: 12),
                  const ProductTag(
                    label: 'Recommended from crop, target, and product fit',
                    color: C.forest,
                    background: C.forestSoft,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        ...recommendations.take(6).map(
                              (product) => ProductChoice(
                                product: product,
                                selected: product.id == selected.id,
                                suggested: true,
                                onTap: () =>
                                    setSheetState(() => selected = product),
                              ),
                            ),
                        const SizedBox(height: 10),
                        SectionTitle(
                          'Will mark as covered',
                          trailing: ProductTag(
                            label: '${covered.length}',
                            color: C.forest,
                            background: C.forestSoft,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: covered
                              .map(
                                (entry) => ProductTag(
                                  label:
                                      '${entry.crop.name} ${protectionTargetLabel(entry.target)}',
                                  color: entry.target == ProtectionTarget.feed
                                      ? C.amber
                                      : targetById(_targetId(entry.target))
                                          .color,
                                  background:
                                      entry.target == ProtectionTarget.feed
                                          ? C.amberSoft
                                          : targetById(_targetId(entry.target))
                                              .softColor,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        _CalendarCountdownPanel(
                          item: item,
                          product: selected,
                          nextCheck: nextCheck,
                          records: records,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Log and update countdowns',
                    onPressed: () {
                      Navigator.pop(context);
                      onLogAction(
                        item: item,
                        product: selected,
                        coveredItems: covered,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarCountdownPanel extends StatelessWidget {
  const _CalendarCountdownPanel({
    required this.item,
    required this.product,
    required this.nextCheck,
    required this.records,
  });

  final PreventativeCalendarItem item;
  final SprayProduct product;
  final DateTime nextCheck;
  final List<SprayRecord> records;

  @override
  Widget build(BuildContext context) {
    final rotation = sprayRotationAdvice(
      product: product,
      records: records,
      products: [product],
      beds: [item.bed.number],
    );
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalendarInfoLine(
            icon: CupertinoIcons.time,
            color: C.blue,
            title: 'Next calendar check',
            body:
                '${shortDate(nextCheck)} | ${item.intervalDays} day interval for this crop/task.',
          ),
          _CalendarInfoLine(
            icon: CupertinoIcons.hand_raised,
            color: C.amber,
            title: 'Harvest hold',
            body:
                '${product.withholdingDays} day WHP | re-entry ${product.reEntryHours} hr.',
          ),
          if (rotation != null)
            _CalendarInfoLine(
              icon: rotation.caution
                  ? CupertinoIcons.exclamationmark_triangle_fill
                  : CupertinoIcons.arrow_2_circlepath,
              color: rotation.caution ? C.red : C.amber,
              title: rotation.title,
              body: rotation.body,
            ),
        ],
      ),
    );
  }
}

class _CalendarInfoLine extends StatelessWidget {
  const _CalendarInfoLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: C.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    body,
                    style: const TextStyle(
                      color: C.muted,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

enum _CalendarKind { spray, feed, log }

class _CalendarEvent {
  const _CalendarEvent({
    required this.day,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.color,
    required this.background,
    required this.icon,
    this.item,
    this.plannable = false,
  });

  final DateTime day;
  final String title;
  final String subtitle;
  final _CalendarKind kind;
  final Color color;
  final Color background;
  final IconData icon;
  final PreventativeCalendarItem? item;
  final bool plannable;
}

Map<DateTime, List<_CalendarEvent>> _calendarEvents({
  required List<PreventativeCalendarItem> items,
  required List<SprayRecord> records,
}) {
  final map = <DateTime, List<_CalendarEvent>>{};
  void add(_CalendarEvent event) =>
      map.putIfAbsent(event.day, () => <_CalendarEvent>[]).add(event);

  for (final item in items) {
    final target = targetById(_targetId(item.target));
    final isFeed = item.target == ProtectionTarget.feed;
    add(
      _CalendarEvent(
        day: _dayOnly(item.dueDate),
        title: '${item.bed.label} ${protectionTargetLabel(item.target)}',
        subtitle:
            '${item.crop.name} | ${_dueCountdown(item.dueDate)} | every ${item.intervalDays} days',
        kind: isFeed ? _CalendarKind.feed : _CalendarKind.spray,
        color: isFeed ? C.amber : target.color,
        background: isFeed ? C.amberSoft : target.softColor,
        icon: target.icon,
        item: item,
        plannable: item.status == ProtectionStatus.due ||
            item.status == ProtectionStatus.soon,
      ),
    );
  }

  for (final record in records) {
    final target = targetById(record.targetId);
    add(
      _CalendarEvent(
        day: _dayOnly(record.date),
        title: 'Sprayed Bed ${record.beds.join(', ')}',
        subtitle:
            '${target.short} | ${record.product} | safe ${shortDate(record.safeDate)}',
        kind: _CalendarKind.log,
        color: target.color,
        background: target.softColor,
        icon: target.icon,
      ),
    );
  }

  for (final events in map.values) {
    events.sort((a, b) {
      final kind = a.kind.index.compareTo(b.kind.index);
      if (kind != 0) return kind;
      return a.title.compareTo(b.title);
    });
  }
  return map;
}

List<SprayProduct> _recommendedProducts(
  PreventativeCalendarItem item,
  List<SprayProduct> products,
) {
  final issue = item.issues.isEmpty ? item.title : item.issues.first;
  final ranked = rankedSprayProductsForSpray(
    targetId: _targetId(item.target),
    issue: issue,
    crops: [item.crop],
    products: products,
  );
  final byId = <String, SprayProduct>{};
  if (item.product != null) byId[item.product!.id] = item.product!;
  for (final product in ranked) {
    byId[product.id] = product;
  }
  for (final product in products) {
    if (_productMatchesSprayTarget(product, _targetId(item.target))) {
      byId.putIfAbsent(product.id, () => product);
    }
  }
  return byId.values.toList(growable: false);
}

String _dueCountdown(DateTime dueDate) {
  final today = _dayOnly(DateTime.now());
  final due = _dayOnly(dueDate);
  final days = due.difference(today).inDays;
  if (days == 0) return 'due today';
  if (days < 0) return '${days.abs()}d overdue';
  return 'in ${days}d';
}

DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
