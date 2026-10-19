import 'package:dicta/models/note.dart';
import 'package:dicta/services/nlp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 17, 9, 0);

  group('NlpService', () {
    test('clasifica una tarea con fecha como recordatorio', () {
      final insight = NlpService.analyze(
        'mañana a las 10:00 necesito hacer un trabajo del colegio',
        nowOverride: now,
      );

      expect(insight.type, NoteType.recordatorio);
      expect(insight.dueAt, DateTime(2026, 10, 18, 10, 0));
      expect(insight.hasTime, isTrue);
      expect(
        insight.title.toLowerCase(),
        contains('trabajo del colegio'),
      );
    });

    test('clasifica una cita como evento y calcula el próximo lunes', () {
      final insight = NlpService.analyze(
        'el lunes a la 1 tengo cita con el doctor',
        nowOverride: now,
      );

      expect(insight.type, NoteType.evento);
      expect(insight.dueAt, isNotNull);
      expect(insight.dueAt!.weekday, DateTime.monday);
      expect(insight.dueAt!.hour, 13);
    });

    test('interpreta tiempos relativos', () {
      final insight = NlpService.analyze(
        'en 30 minutos pagar la luz',
        nowOverride: now,
      );

      expect(insight.type, NoteType.recordatorio);
      expect(insight.dueAt, now.add(const Duration(minutes: 30)));
    });

    test('sin fecha ni palabras clave es solo una nota', () {
      final insight = NlpService.analyze(
        'me gusta el color azul',
        nowOverride: now,
      );

      expect(insight.type, NoteType.nota);
      expect(insight.dueAt, isNull);
    });

    test('interpreta "a las 3 de la tarde"', () {
      final insight = NlpService.analyze(
        'hoy a las 3 de la tarde reunion de trabajo',
        nowOverride: now,
      );

      expect(insight.type, NoteType.evento);
      expect(insight.dueAt, DateTime(2026, 10, 17, 15, 0));
    });
  });
}
