import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/note.dart';

/// Referencia a un evento creado en el calendario del teléfono.
class CalendarEventRef {
  final String eventId;
  final String calendarId;
  const CalendarEventRef(this.eventId, this.calendarId);
}

/// Crea eventos en el Calendario del teléfono usando la API nativa.
class CalendarService {
  CalendarService._();

  static final CalendarService instance = CalendarService._();

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  String? _cachedCalendarId;

  Future<bool> requestPermission() async {
    try {
      final result = await _plugin.requestPermissions();
      return result.isSuccess && (result.data ?? false);
    } catch (_) {
      return false;
    }
  }

  Future<String?> _defaultCalendarId() async {
    if (_cachedCalendarId != null) return _cachedCalendarId;
    try {
      final result = await _plugin.retrieveCalendars();
      final calendars = result.data;
      if (calendars == null || calendars.isEmpty) return null;
      final writable =
          calendars.where((c) => c.isReadOnly != true).toList(growable: false);
      final pool = writable.isNotEmpty ? writable : calendars;
      Calendar chosen = pool.first;
      for (final calendar in pool) {
        if (calendar.isDefault == true) {
          chosen = calendar;
          break;
        }
      }
      _cachedCalendarId = chosen.id;
      return _cachedCalendarId;
    } catch (_) {
      return null;
    }
  }

  /// Crea el evento y devuelve su referencia, o null si no se pudo.
  Future<CalendarEventRef?> addEvent(Note note) async {
    final due = note.dueAt;
    if (due == null) return null;

    final calendarId = await _defaultCalendarId();
    if (calendarId == null) return null;

    final start = tz.TZDateTime.from(due, tz.local);
    final end = start.add(const Duration(hours: 1));

    final event = Event(
      calendarId,
      title: note.title.isEmpty ? 'Dicta' : note.title,
      description: note.transcript,
      start: start,
      end: end,
      startTimeZone: tz.local.name,
      endTimeZone: tz.local.name,
    );

    try {
      final result = await _plugin.createOrUpdateEvent(event);
      if (result == null || !result.isSuccess || result.data == null) {
        return null;
      }
      return CalendarEventRef(result.data!, calendarId);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteEvent(String calendarId, String eventId) async {
    try {
      await _plugin.deleteEvent(calendarId, eventId);
    } catch (_) {}
  }
}
