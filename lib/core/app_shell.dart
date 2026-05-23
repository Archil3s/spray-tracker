part of '../main.dart';

class SprayTrackerApp extends StatelessWidget {
  const SprayTrackerApp({super.key});

  @override
  Widget build(BuildContext context) => const CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'Spray Tracker',
        theme: CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: C.forest,
          scaffoldBackgroundColor: C.canvas,
          textTheme: CupertinoTextThemeData(textStyle: TextStyle(color: C.ink)),
        ),
        home: SprayTrackerHome(),
      );
}

class C {
  static const canvas = Color(0xFFF8F6F0);
  static const card = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF3EFE6);
  static const ink = Color(0xFF172018);
  static const muted = Color(0xFF667064);
  static const line = Color(0xFFE1DBCF);
  static const forest = Color(0xFF173F2A);
  static const forestSoft = Color(0xFFE8F0EA);
  static const soil = Color(0xFF735235);
  static const amber = Color(0xFFC77618);
  static const amberSoft = Color(0xFFFFEFD7);
  static const red = Color(0xFFB94A42);
  static const redSoft = Color(0xFFF8E4E1);
  static const blue = Color(0xFF2B6777);
  static const blueSoft = Color(0xFFE1F0F3);
  static const greySoft = Color(0xFFEDECE7);
}

final softShadow = [
  BoxShadow(
    color: const Color(0xFF000000).withValues(alpha: .07),
    blurRadius: 18,
    offset: const Offset(0, 7),
  ),
];

BoxDecoration cardDecoration({Color color = C.card, double radius = 22}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: C.line),
      boxShadow: softShadow,
    );

String monthName(int month) => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][month - 1];
String shortDate(DateTime d) => '${d.day} ${monthName(d.month)}';

const gardenMapWidthMeters = 8.0;
const gardenMapLengthMeters = 12.0;

String meterLabel(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
