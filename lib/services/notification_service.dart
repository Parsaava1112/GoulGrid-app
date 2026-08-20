import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../database/database_helper.dart';
import '../models/task.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTapNotification,
      onDidReceiveBackgroundNotificationResponse: _onTapBackgroundNotification,
    );

    // ساخت کانال‌ها
    const androidChannel = AndroidNotificationChannel(
      'daily_reminder',
      'یادآوری روزانه',
      description: 'یادآوری تسک‌ها و عادت‌ها',
      importance: Importance.max,
    );
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  // اکشن‌ها
  static const String _actionMarkDone = 'MARK_DONE';

  Future<void> scheduleTaskNotification(Task task) async {
    if (task.id == null) return;
    await cancelTaskNotification(task.id!);

    final timeParts = task.reminderTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // اعلان تطبیقی: اگر ۳ روز پیاپی انجام نشده باشد، متن جدی‌تر
    final db = DatabaseHelper.instance;
    final missedDays = await _countMissedDays(task.id!);
    String title = 'یادآوری تسک';
    String body = task.title;
    if (missedDays >= 3) {
      title = '⚠️ یادآوری جدی';
      body = '${task.title} – ۳ روز است انجام نشده!';
    } else if (missedDays >= 1) {
      body = '${task.title} – دیروز انجام نشد';
    }

    // دکمه‌های اکشن
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'یادآوری روزانه',
      channelDescription: 'یادآوری تسک‌ها و عادت‌ها',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          _actionMarkDone,
          'انجام شد ✅',
          showsUserInterface: true,
        ),
      ],
    );

    await _plugin.zonedSchedule(
      task.id!,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'task_${task.id}',
    );
  }

  Future<int> _countMissedDays(int taskId) async {
    final db = DatabaseHelper.instance;
    int missed = 0;
    var date = DateTime.now().subtract(const Duration(days: 1));
    while (missed < 30) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final completed = await db.isTaskCompletedOnDate(taskId, dateStr);
      if (completed) break;
      missed++;
      date = date.subtract(const Duration(days: 1));
    }
    return missed;
  }

  Future<void> _onTapNotification(NotificationResponse response) async {
    _handleAction(response.payload, response.actionId);
  }

  @pragma('vm:entry-point')
  static Future<void> _onTapBackgroundNotification(NotificationResponse response) async {
    _handleAction(response.payload, response.actionId);
  }

  static Future<void> _handleAction(String? payload, String? actionId) async {
    if (actionId == _actionMarkDone && payload != null && payload.startsWith('task_')) {
      final taskId = int.parse(payload.substring(5));
      // اینجا می‌توانید مستقیماً تسک را کامل کنید یا برنامه را باز کنید
      // برای سادگی، فقط برنامه باز می‌شود و کاربر تأیید را انجام می‌دهد
      // اما می‌توانید منطق کامل شدن را در اینجا پیاده کنید
    }
  }

  Future<void> cancelTaskNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}