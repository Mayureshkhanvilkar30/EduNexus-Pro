import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart'; // Add this for time parsing

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Notification click logic
      },
    );

    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // --- HELPER: Parse String Time to DateTime ---
  static DateTime parseTimeString(String timeString) {
    try {
      // Input: "07:00 PM" -> Output: Today's DateTime at 19:00
      DateTime now = DateTime.now();
      DateFormat format = DateFormat.jm(); // AM/PM format handle karel
      DateTime parsedTime = format.parse(timeString);
      
      return DateTime(
        now.year,
        now.month,
        now.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (e) {
      print("Time Parsing Error: $e");
      return DateTime.now().add(const Duration(minutes: 1)); // Error aala tar 1 min nantar schedule kar
    }
  }

  // Instant Notification
  static Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'study_alerts',
      'Study Alerts',
      channelDescription: 'Notifications for study reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, title, body, notificationDetails);
  }

  // Schedule Notification
  static Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
    // Jar time nighun gela asel tar udya sathi schedule kara
    if (scheduledTime.isBefore(DateTime.now())) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_alerts_scheduled',
            'Timetable Alerts',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("Notification scheduled successfully for: $scheduledTime");
    } catch (e) {
      print("Notification Error: $e");
    }
  }
}