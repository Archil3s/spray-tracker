import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/open_meteo_service.dart';
import '../../models/spray_condition.dart';

class HarvestReminder {
  const HarvestReminder({
    required this.id,
    required this.safeAt,
    required this.beds,
    required this.crops,
  });

  final int id;
  final DateTime safeAt;
  final List<int> beds;
  final List<String> crops;
}

class HarvestReminderService {
  HarvestReminderService._();

  static final HarvestReminderService instance = HarvestReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> schedule(HarvestReminder reminder) async {
    if (!reminder.safeAt.isAfter(DateTime.now())) return;

    await _initialize();
    await _notifications.zonedSchedule(
      id: reminder.id,
      title: 'Safe to harvest',
      body: '${_bedsText(reminder.beds)} - ${reminder.crops.join(', ')}',
      scheduledDate: tz.TZDateTime.from(reminder.safeAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'safe-harvest',
          'Safe harvest reminders',
          channelDescription:
              'Quiet reminders when a spray withholding period ends.',
          playSound: false,
          enableVibration: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int recordId) async {
    await _initialize();
    await _notifications.cancel(id: recordId);
  }

  Future<void> scheduleSprayWindow(SprayWindowReminderPlan? reminder) async {
    await _initialize();
    await _notifications.cancel(id: _sprayWindowReminderId);
    if (reminder == null || !reminder.notifyAt.isAfter(DateTime.now())) {
      return;
    }

    await _notifications.zonedSchedule(
      id: _sprayWindowReminderId,
      title: _sprayWindowTitle(reminder.window),
      body: 'Blenheim ${_windowHours(reminder.window)} - wind and rain look '
          'favourable.',
      scheduledDate: tz.TZDateTime.from(reminder.notifyAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'spray-window',
          'Spray window reminders',
          channelDescription:
              'Quiet heads-ups when a good spray window is forecast.',
          playSound: false,
          enableVibration: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(OpenMeteoService.blenheimTimezone));
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_spray_notification'),
      ),
    );

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    _initialized = true;
  }

  String _bedsText(List<int> beds) =>
      beds.length == 1 ? 'Bed ${beds.single}' : 'Beds ${beds.join(', ')}';

  String _sprayWindowTitle(SprayWindow window) => _isTomorrow(window.start)
      ? 'Good spray window tomorrow'
      : 'Good spray window soon';

  bool _isTomorrow(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  String _windowHours(SprayWindow window) =>
      '${_hourLabel(window.start)}-${_hourLabel(window.end)}';

  String _hourLabel(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final suffix = date.hour < 12 ? 'am' : 'pm';
    return '$hour$suffix';
  }
}

const _sprayWindowReminderId = 900000001;
