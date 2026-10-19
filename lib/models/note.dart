import 'package:flutter/foundation.dart';

/// Clasificación que la app le da a cada dictado.
enum NoteType { nota, recordatorio, evento }

extension NoteTypeInfo on NoteType {
  String get label {
    switch (this) {
      case NoteType.nota:
        return 'Nota';
      case NoteType.recordatorio:
        return 'Recordatorio';
      case NoteType.evento:
        return 'Evento';
    }
  }

  String get storageKey {
    switch (this) {
      case NoteType.nota:
        return 'nota';
      case NoteType.recordatorio:
        return 'recordatorio';
      case NoteType.evento:
        return 'evento';
    }
  }

  static NoteType fromStorage(String? value) {
    switch (value) {
      case 'recordatorio':
        return NoteType.recordatorio;
      case 'evento':
        return NoteType.evento;
      default:
        return NoteType.nota;
    }
  }
}

/// Una nota guardada localmente. No hay servidor: todo vive en el teléfono.
@immutable
class Note {
  final String id;
  final String title;
  final String transcript;
  final NoteType type;
  final DateTime createdAt;
  final DateTime? dueAt;
  final bool completed;
  final String? calendarEventId;
  final String? calendarId;

  const Note({
    required this.id,
    required this.title,
    required this.transcript,
    required this.type,
    required this.createdAt,
    this.dueAt,
    this.completed = false,
    this.calendarEventId,
    this.calendarId,
  });

  bool get hasDueDate => dueAt != null;

  Note copyWith({
    String? title,
    String? transcript,
    NoteType? type,
    DateTime? dueAt,
    bool clearDueAt = false,
    bool? completed,
    String? calendarEventId,
    String? calendarId,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      transcript: transcript ?? this.transcript,
      type: type ?? this.type,
      createdAt: createdAt,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      completed: completed ?? this.completed,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      calendarId: calendarId ?? this.calendarId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'transcript': transcript,
        'type': type.storageKey,
        'createdAt': createdAt.toIso8601String(),
        'dueAt': dueAt?.toIso8601String(),
        'completed': completed,
        'calendarEventId': calendarEventId,
        'calendarId': calendarId,
      };

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      transcript: (json['transcript'] as String?) ?? '',
      type: NoteTypeInfo.fromStorage(json['type'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      dueAt: json['dueAt'] != null
          ? DateTime.tryParse(json['dueAt'] as String)
          : null,
      completed: (json['completed'] as bool?) ?? false,
      calendarEventId: json['calendarEventId'] as String?,
      calendarId: json['calendarId'] as String?,
    );
  }
}
