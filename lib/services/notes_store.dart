import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/note.dart';

/// Guarda todas las notas en un archivo JSON dentro del teléfono.
/// No hay cuenta, no hay nube, no hay red.
class NotesStore extends ChangeNotifier {
  NotesStore._();

  static final NotesStore instance = NotesStore._();

  final List<Note> _notes = <Note>[];
  File? _file;
  bool _initialized = false;

  bool get isReady => _initialized;

  List<Note> get all => List<Note>.unmodifiable(_notes);

  List<Note> get pending {
    final list = _notes.where((n) => !n.completed).toList();
    list.sort(_byRelevance);
    return list;
  }

  List<Note> get completed {
    final list = _notes.where((n) => n.completed).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Note> recent(int count) => pending.take(count).toList();

  int get pendingCount => _notes.where((n) => !n.completed).length;

  int _byRelevance(Note a, Note b) {
    final aDue = a.dueAt;
    final bDue = b.dueAt;
    if (aDue != null && bDue != null) {
      return aDue.compareTo(bDue);
    }
    if (aDue != null) return -1;
    if (bDue != null) return 1;
    return b.createdAt.compareTo(a.createdAt);
  }

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}${Platform.pathSeparator}dicta_notes.json');
    if (await _file!.exists()) {
      try {
        final raw = await _file!.readAsString();
        if (raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw) as List<dynamic>;
          _notes
            ..clear()
            ..addAll(decoded
                .whereType<Map<String, dynamic>>()
                .map(Note.fromJson));
        }
      } catch (_) {
        // Si el archivo se corrompe, empezamos de cero sin romper la app.
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> add(Note note) async {
    _notes.insert(0, note);
    await _persist();
  }

  Future<void> update(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return;
    _notes[index] = note;
    await _persist();
  }

  Future<void> remove(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _persist();
  }

  Future<void> toggleCompleted(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final current = _notes[index];
    _notes[index] = current.copyWith(completed: !current.completed);
    await _persist();
  }

  Note? byId(String id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  Future<void> _persist() async {
    final file = _file;
    if (file == null) return;
    final data = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await file.writeAsString(data, flush: true);
    notifyListeners();
  }
}
