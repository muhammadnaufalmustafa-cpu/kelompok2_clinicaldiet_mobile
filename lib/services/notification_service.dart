import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // Setting WIB timezone

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle action when clicked
      },
    );

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleMealNotifications() async {
    // Membatalkan semua notifikasi lama terlebih dahulu
    await cancelAllNotifications();

    // 1. Notifikasi Sarapan (08:00)
    await _scheduleDailyNotification(
        id: 1,
        title: 'Waktunya Sarapan!',
        body: 'Jangan lupa perbarui catatan diet pagi Anda.',
        hour: 8,
        minute: 0);

    // 2. Notifikasi Makan Siang (12:00)
    await _scheduleDailyNotification(
        id: 2,
        title: 'Waktunya Makan Siang!',
        body: 'Jangan lupa perbarui catatan diet siang Anda.',
        hour: 12,
        minute: 0);

    // 3. Notifikasi Makan Malam (18:00)
    await _scheduleDailyNotification(
        id: 3,
        title: 'Waktunya Makan Malam!',
        body: 'Jangan lupa perbarui catatan diet malam Anda.',
        hour: 18,
        minute: 0);
  }

  Future<void> _scheduleDailyNotification(
      {required int id,
      required String title,
      required String body,
      required int hour,
      required int minute}) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminder_channel',
          'Meal Reminders',
          channelDescription: 'Notifikasi pengingat waktu makan',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
