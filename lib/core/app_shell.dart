part of '../main.dart';

class SprayTrackerApp extends StatelessWidget {
  const SprayTrackerApp({super.key});

  @override
  Widget build(BuildContext context) => CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'Spray Tracker',
        builder: (context, child) => ScrollConfiguration(
          behavior: const SmoothScrollBehavior(),
          child: child ?? const SizedBox.shrink(),
        ),
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: C.forest,
          scaffoldBackgroundColor: C.canvas,
          textTheme: CupertinoTextThemeData(textStyle: TextStyle(color: C.ink)),
        ),
        home: const SprayTrackerHome(),
      );
}

class SmoothScrollBehavior extends CupertinoScrollBehavior {
  const SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class C {
  static const canvas = Color(0xFFF6F7F1);
  static const card = Color(0xFFFFFEFA);
  static const soft = Color(0xFFEEF2EA);
  static const ink = Color(0xFF152019);
  static const muted = Color(0xFF657266);
  static const line = Color(0xFFDDD8CB);
  static const forest = Color(0xFF143F2A);
  static const forestSoft = Color(0xFFE3F1E8);
  static const soil = Color(0xFF755436);
  static const amber = Color(0xFFB96912);
  static const amberSoft = Color(0xFFFFEACB);
  static const red = Color(0xFFB64842);
  static const redSoft = Color(0xFFF8E1DE);
  static const blue = Color(0xFF286A79);
  static const blueSoft = Color(0xFFDDEFF3);
  static const greySoft = Color(0xFFEAECE4);
}

final softShadow = [
  BoxShadow(
    color: const Color(0xFF1A2A20).withValues(alpha: .07),
    blurRadius: 20,
    offset: const Offset(0, 8),
  ),
];

BoxDecoration cardDecoration({Color color = C.card, double radius = 18}) =>
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
