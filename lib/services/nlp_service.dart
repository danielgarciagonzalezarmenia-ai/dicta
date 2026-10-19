import '../models/note.dart';

/// Resultado del análisis de un dictado.
class SpokenInsight {
  final NoteType type;
  final String title;
  final DateTime? dueAt;
  final bool hasTime;

  const SpokenInsight({
    required this.type,
    required this.title,
    this.dueAt,
    this.hasTime = false,
  });
}

class _Span {
  final int start;
  final int end;
  const _Span(this.start, this.end);
}

class _TimeResult {
  final int? hour;
  final int? minute;
  final bool found;
  final List<_Span> spans;
  const _TimeResult({
    this.hour,
    this.minute,
    this.found = false,
    this.spans = const <_Span>[],
  });
}

class _DateResult {
  final DateTime? date;
  final DateTime? exact;
  final List<_Span> spans;
  const _DateResult({this.date, this.exact, this.spans = const <_Span>[]});
}

/// Analiza texto hablado en español: extrae fecha/hora, clasifica el tipo
/// y genera un título limpio. Todo ocurre en el dispositivo.
class NlpService {
  const NlpService._();

  static const Map<String, String> _accents = <String, String>{
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c',
  };

  static const Map<String, int> _months = <String, int>{
    'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5, 'junio': 6,
    'julio': 7, 'agosto': 8, 'septiembre': 9, 'setiembre': 9, 'octubre': 10,
    'noviembre': 11, 'diciembre': 12,
  };

  static const Map<String, int> _weekdays = <String, int>{
    'lunes': 1, 'martes': 2, 'miercoles': 3, 'jueves': 4, 'viernes': 5,
    'sabado': 6, 'domingo': 7,
  };

  static const Map<String, int> _numberWords = <String, int>{
    'un': 1, 'una': 1, 'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4,
    'cinco': 5, 'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10,
    'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15,
    'dieciseis': 16, 'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19,
    'veinte': 20, 'veinticinco': 25, 'treinta': 30, 'cuarenta': 40,
    'cincuenta': 50, 'sesenta': 60, 'noventa': 90,
  };

  static const List<String> _eventWords = <String>[
    'cita', 'reunion', 'junta', 'clase', 'examen', 'entrevista', 'doctor',
    'medico', 'dentista', 'almuerzo', 'cena', 'desayuno', 'cumpleanos',
    'evento', 'presentacion', 'entrega', 'exposicion', 'partido', 'gimnasio',
    'vuelo', 'viaje', 'concierto', 'fiesta', 'terapia', 'consulta', 'turno',
    'practica', 'ensayo', 'clases', 'reuniones',
  ];

  static const List<String> _reminderWords = <String>[
    'recordar', 'recuerdame', 'recordarme', 'recordatorio', 'recordatorio',
    'olvidar', 'pendiente', 'tarea', 'tengo que', 'debo', 'necesito',
    'acordarme', 'avisame', 'recuerda', 'hacer', 'entregar', 'pagar',
    'comprar', 'llamar', 'enviar', 'estudiar', 'terminar',
  ];

  static SpokenInsight analyze(String rawText, {DateTime? nowOverride}) {
    final now = nowOverride ?? DateTime.now();
    final original = rawText.trim();
    if (original.isEmpty) {
      return const SpokenInsight(type: NoteType.nota, title: '');
    }

    final norm = _normalize(original);

    final timeResult = _extractTime(norm);
    final spans = <_Span>[...timeResult.spans];

    final withoutTime = _removeSpans(norm, timeResult.spans);
    final dateResult = _extractDate(withoutTime, now);
    spans.addAll(dateResult.spans);

    DateTime? dueAt;
    if (dateResult.exact != null) {
      dueAt = dateResult.exact;
    } else if (dateResult.date != null || timeResult.found) {
      final base = dateResult.date ?? DateTime(now.year, now.month, now.day);
      final hour = timeResult.hour ?? 9;
      final minute = timeResult.minute ?? 0;
      var candidate = DateTime(base.year, base.month, base.day, hour, minute);
      final onlyTime = dateResult.date == null;
      if (onlyTime && !candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      dueAt = candidate;
    }

    final type = _classify(norm, dueAt);
    final title = _buildTitle(original, spans);

    return SpokenInsight(
      type: type,
      title: title,
      dueAt: dueAt,
      hasTime: timeResult.found,
    );
  }

  static String _normalize(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_accents[ch] ?? ch);
    }
    return buffer.toString();
  }

  static String _removeSpans(String text, List<_Span> spans) {
    if (spans.isEmpty) return text;
    final sorted = List<_Span>.from(spans)
      ..sort((a, b) => b.start.compareTo(a.start));
    var result = text;
    for (final span in sorted) {
      if (span.start < 0 || span.end > result.length || span.start >= span.end) {
        continue;
      }
      result =
          '${result.substring(0, span.start)} ${result.substring(span.end)}';
    }
    return result;
  }

  static _TimeResult _extractTime(String norm) {
    final patterns = <_TimePattern>[
      // 10:00 / 10.30 / 10:00 pm
      _TimePattern(
        RegExp(r'\b(\d{1,2})[:.](\d{2})\s*(am\b|pm\b|a\s?m\b|p\s?m\b)?'),
        (m) => _TimeParts(
          hour: int.parse(m.group(1)!),
          minute: int.parse(m.group(2)!),
          period: m.group(3),
        ),
      ),
      // a las 10 / a la 1 de la tarde / a las 3 pm
      _TimePattern(
        RegExp(
          r'\ba\s+la?s?\s+(\d{1,2})(?:\s*(am|pm|a\s?m|p\s?m))?'
          r'(?:\s+(?:de\s+la\s+|por\s+la\s+)?(manana|tarde|noche|madrugada|mediodia))?',
        ),
        (m) => _TimeParts(
          hour: int.parse(m.group(1)!),
          period: m.group(2) ?? m.group(3),
        ),
      ),
      // 3 de la tarde / 8 de la noche
      _TimePattern(
        RegExp(r'\b(\d{1,2})\s+(?:de\s+la\s+|por\s+la\s+)(manana|tarde|noche|madrugada)'),
        (m) => _TimeParts(
          hour: int.parse(m.group(1)!),
          period: m.group(2),
        ),
      ),
      // 8 am / 7 pm
      _TimePattern(
        RegExp(r'\b(\d{1,2})\s*(am\b|pm\b|a\s?m\b|p\s?m\b)'),
        (m) => _TimeParts(hour: int.parse(m.group(1)!), period: m.group(2)),
      ),
      // mediodia / medianoche
      _TimePattern(
        RegExp(r'\b(mediodia|medianoche)\b'),
        (m) => _TimeParts(
          hour: m.group(1) == 'mediodia' ? 12 : 0,
          minute: 0,
        ),
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.regex.firstMatch(norm);
      if (match == null) continue;
      final parts = pattern.build(match);
      var hour = parts.hour;
      final minute = parts.minute ?? 0;
      hour = _applyPeriod(hour, parts.period);
      return _TimeResult(
        hour: hour % 24,
        minute: minute,
        found: true,
        spans: <_Span>[_Span(match.start, match.end)],
      );
    }

    return const _TimeResult();
  }

  static int _applyPeriod(int hour, String? period) {
    if (period == null) {
      // Sin indicador: 1-7 se asumen de la tarde (13-19).
      if (hour >= 1 && hour <= 7) return hour + 12;
      return hour;
    }
    final p = period.replaceAll('.', '').replaceAll(' ', '');
    switch (p) {
      case 'pm':
        return hour < 12 ? hour + 12 : hour;
      case 'am':
        return hour == 12 ? 0 : hour;
      case 'tarde':
        return hour < 12 ? hour + 12 : hour;
      case 'noche':
        if (hour == 12) return 0;
        return hour < 12 ? hour + 12 : hour;
      case 'madrugada':
        return hour == 12 ? 0 : hour;
      case 'manana':
        return hour;
      case 'mediodia':
        return 12;
      default:
        return hour;
    }
  }

  static _DateResult _extractDate(String source, DateTime now) {
    // Evitamos que "de la mañana" / "por la mañana" cuenten como "mañana".
    var text = source
        .replaceAll('de la manana', '___diurno___')
        .replaceAll('por la manana', '___diurno___')
        .replaceAll('esta manana', '___diurno___')
        .replaceAll('de la tarde', '___tarde___')
        .replaceAll('por la tarde', '___tarde___')
        .replaceAll('de la noche', '___noche___')
        .replaceAll('por la noche', '___noche___');

    final spans = <_Span>[];

    // en 30 minutos / en 2 horas / en media hora / en 3 dias
    final relative = RegExp(
      r'\ben\s+([a-z0-9]+)\s+(minutos?|min\b|horas?|hora\b|hrs?\b|dias?|dia\b)',
    ).firstMatch(text);
    if (relative != null) {
      final value = _numberFromWord(relative.group(1)!);
      final unit = relative.group(2)!;
      if (value != null) {
        Duration delta;
        if (unit.startsWith('min')) {
          delta = Duration(minutes: value.round());
        } else if (unit.startsWith('hor') || unit.startsWith('hr')) {
          delta = Duration(minutes: (value * 60).round());
        } else {
          delta = Duration(days: value.round());
        }
        text = text.replaceRange(relative.start, relative.end, ' ');
        return _DateResult(
          exact: now.add(delta),
          spans: <_Span>[_Span(relative.start, relative.end)],
        );
      }
    }

    // pasado mañana
    final dayAfter = RegExp(r'\bpasado\s+manana\b').firstMatch(text);
    if (dayAfter != null) {
      spans.add(_Span(dayAfter.start, dayAfter.end));
      return _DateResult(
        date: DateTime(now.year, now.month, now.day).add(const Duration(days: 2)),
        spans: spans,
      );
    }

    // mañana (sin haberse consumido como "de la mañana")
    final tomorrow = RegExp(r'\bmanana\b').firstMatch(text);
    if (tomorrow != null) {
      spans.add(_Span(tomorrow.start, tomorrow.end));
      return _DateResult(
        date: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
        spans: spans,
      );
    }

    // hoy
    final today = RegExp(r'\bhoy\b').firstMatch(text);
    if (today != null) {
      spans.add(_Span(today.start, today.end));
      return _DateResult(
        date: DateTime(now.year, now.month, now.day),
        spans: spans,
      );
    }

    // el 25 de julio
    final explicit = RegExp(
      r'\b(?:el\s+)?(\d{1,2})\s+de\s+'
      '(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre)',
    ).firstMatch(text);
    if (explicit != null) {
      final day = int.parse(explicit.group(1)!);
      final month = _months[explicit.group(2)!]!;
      var year = now.year;
      var candidate = DateTime(year, month, day);
      if (candidate.isBefore(DateTime(now.year, now.month, now.day))) {
        year += 1;
        candidate = DateTime(year, month, day);
      }
      spans.add(_Span(explicit.start, explicit.end));
      return _DateResult(date: candidate, spans: spans);
    }

    // próximo lunes / el lunes
    for (final entry in _weekdays.entries) {
      final match = RegExp('\\b${entry.key}\\b').firstMatch(text);
      if (match == null) continue;
      var delta = (entry.value - now.weekday) % 7;
      if (delta <= 0) delta += 7;
      final before = text.substring(0, match.start);
      if (before.trimRight().endsWith('proximo') ||
          before.trimRight().endsWith('proxima') ||
          before.trimRight().endsWith('siguiente')) {
        delta += 7;
      }
      spans.add(_Span(match.start, match.end));
      return _DateResult(
        date: DateTime(now.year, now.month, now.day).add(Duration(days: delta)),
        spans: spans,
      );
    }

    return const _DateResult();
  }

  static double? _numberFromWord(String word) {
    final asInt = int.tryParse(word);
    if (asInt != null) return asInt.toDouble();
    final asDouble = double.tryParse(word);
    if (asDouble != null) return asDouble;
    if (word == 'media' || word == 'medio') return 0.5;
    final mapped = _numberWords[word];
    if (mapped != null) return mapped.toDouble();
    return null;
  }

  static NoteType _classify(String norm, DateTime? dueAt) {
    for (final word in _eventWords) {
      if (norm.contains(word)) return NoteType.evento;
    }
    for (final word in _reminderWords) {
      if (norm.contains(word)) return NoteType.recordatorio;
    }
    if (dueAt != null) return NoteType.recordatorio;
    return NoteType.nota;
  }

  static const List<String> _leadingFillers = <String>[
    'recuerdame que', 'recuerdame', 'recordarme que', 'recordarme',
    'recuerda que', 'recuerda', 'avisame que', 'avisame', 'no olvidar que',
    'no olvidar', 'anota que', 'anota', 'apunta que', 'apunta', 'agrega que',
    'agrega', 'anade que', 'anade', 'quiero que', 'tengo que', 'necesito que',
    'necesito', 'debo', 'hay que', 'que', 'de', 'para', 'el', 'la', 'los',
    'las', 'un', 'una', 'a',
  ];

  static String _buildTitle(String original, List<_Span> spans) {
    var text = _removeSpans(original, spans);
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    var changed = true;
    while (changed) {
      changed = false;
      final lower = text.toLowerCase();
      for (final filler in _leadingFillers) {
        if (lower.startsWith('$filler ')) {
          text = text.substring(filler.length + 1).trim();
          changed = true;
          break;
        }
      }
    }

    if (text.isEmpty) text = original.trim();

    if (text.length > 90) {
      final cut = text.substring(0, 90);
      final lastSpace = cut.lastIndexOf(' ');
      text = '${lastSpace > 40 ? cut.substring(0, lastSpace) : cut}…';
    }

    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _TimeParts {
  final int hour;
  final int? minute;
  final String? period;
  const _TimeParts({required this.hour, this.minute, this.period});
}

class _TimePattern {
  final RegExp regex;
  final _TimeParts Function(RegExpMatch) build;
  const _TimePattern(this.regex, this.build);
}
