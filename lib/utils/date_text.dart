import 'package:intl/intl.dart';

/// Formatea fechas en español con un tono cercano ("Hoy", "Mañana").
class DateText {
  const DateText._();

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  static String relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    switch (diff) {
      case 0:
        return 'Hoy';
      case 1:
        return 'Mañana';
      case 2:
        return 'Pasado mañana';
    }
    if (diff == -1) return 'Ayer';
    return _capitalize(
      DateFormat("EEEE d 'de' MMMM", 'es').format(date),
    );
  }

  static String time(DateTime date) => DateFormat('H:mm', 'es').format(date);

  /// Ej: "Mañana · 10:00"
  static String dayAndTime(DateTime date) =>
      '${relativeDay(date)} · ${time(date)}';

  static String full(DateTime date) =>
      '${relativeDay(date)} · ${DateFormat("d 'de' MMMM 'de' y", 'es').format(date)} · ${time(date)}';

  /// Para agrupar en el historial: "Hoy", "Ayer", "12 de mayo", ...
  static String groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == -1) return 'Ayer';
    if (diff > -7 && diff < 0) return _capitalize(DateFormat('EEEE', 'es').format(date));
    return _capitalize(DateFormat("d 'de' MMMM", 'es').format(date));
  }
}
