import '../models/note.dart';
import 'calendar_service.dart';
import 'notes_store.dart';
import 'notification_service.dart';

class SaveOutcome {
  final Note note;
  final bool reminderScheduled;
  final bool calendarCreated;

  const SaveOutcome({
    required this.note,
    this.reminderScheduled = false,
    this.calendarCreated = false,
  });
}

/// Centraliza lo que pasa al guardar: almacenamiento local, notificación
/// y (si aplica) evento en el Calendario.
class NoteActions {
  const NoteActions._();

  static Future<SaveOutcome> upsert(
    Note note, {
    bool wantReminder = true,
    bool wantCalendar = false,
  }) async {
    var current = note;
    var reminderScheduled = false;
    var calendarCreated = false;

    await NotesStore.instance.init();
    await NotificationService.instance.init();

    // Reemplazamos cualquier aviso previo de esta nota.
    await NotificationService.instance.cancel(current.id);

    if (current.dueAt != null && wantReminder) {
      await NotificationService.instance.requestPermissions();
      reminderScheduled =
          await NotificationService.instance.scheduleReminder(current);
    }

    final wantsEvent = current.type == NoteType.evento;
    if (wantsEvent &&
        current.dueAt != null &&
        wantCalendar &&
        current.calendarEventId == null) {
      final granted = await CalendarService.instance.requestPermission();
      if (granted) {
        final ref = await CalendarService.instance.addEvent(current);
        if (ref != null) {
          current = current.copyWith(
            calendarEventId: ref.eventId,
            calendarId: ref.calendarId,
          );
          calendarCreated = true;
        }
      }
    }

    if (NotesStore.instance.byId(current.id) == null) {
      await NotesStore.instance.add(current);
    } else {
      await NotesStore.instance.update(current);
    }

    return SaveOutcome(
      note: current,
      reminderScheduled: reminderScheduled,
      calendarCreated: calendarCreated,
    );
  }

  static Future<void> delete(Note note) async {
    await NotificationService.instance.cancel(note.id);
    final calendarId = note.calendarId;
    final eventId = note.calendarEventId;
    if (calendarId != null && eventId != null) {
      await CalendarService.instance.deleteEvent(calendarId, eventId);
    }
    await NotesStore.instance.remove(note.id);
  }
}
