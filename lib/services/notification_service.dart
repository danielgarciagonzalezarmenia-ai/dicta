import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/note.dart';

/// Programa las notificaciones locales (10 minutos antes de cada cosa).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static const String _channelId = 'dicta_recordatorios';
  static const String _channelName = 'Recordatorios';
  static const String _channelDescription =
      'Te aviso 10 minutos antes de lo que dictaste.';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Si no se puede resolver la zona, seguimos con la predeterminada.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );

    _ready = true;
  }

  Future<bool> requestPermissions() async {
    await init();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      try {
        await android.requestExactAlarmsPermission();
      } catch (_) {}
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  int _idFor(String noteId) => noteId.hashCode & 0x7fffffff;

  /// Programa el aviso. Devuelve true si quedó programado.
  Future<bool> scheduleReminder(
    Note note, {
    Duration lead = const Duration(minutes: 10),
  }) async {
    final due = note.dueAt;
    if (due == null) return false;
    await init();

    final when = due.subtract(lead);
    if (!when.isAfter(DateTime.now())) return false;

    await _plugin.zonedSchedule(
      id: _idFor(note.id),
      title: _titleFor(note, lead),
      body: note.title,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: note.id,
    );
    return true;
  }

  String _titleFor(Note note, Duration lead) {
    final minutes = lead.inMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return hours == 1 ? 'En 1 hora' : 'En $hours horas';
    }
    return 'En $minutes minutos';
  }

  Future<void> cancel(String noteId) async {
    await init();
    await _plugin.cancel(id: _idFor(noteId));
  }

  Future<void> showNow(String noteId, String title, String body) async {
    await init();
    await _plugin.show(
      id: _idFor(noteId),
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }
}
