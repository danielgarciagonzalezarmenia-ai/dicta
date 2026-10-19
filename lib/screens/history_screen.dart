import 'package:flutter/cupertino.dart';

import '../models/note.dart';
import '../services/note_actions.dart';
import '../services/notes_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/note_tile.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final NotesStore _store = NotesStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _open(Note note) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => DetailScreen(noteId: note.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final pending = _store.pending;
    final completed = _store.completed;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Historial')),
      child: SafeArea(
        child: (pending.isEmpty && completed.isEmpty)
            ? _empty(p)
            : ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  if (pending.isNotEmpty) ...[
                    const SectionHeader('Pendientes'),
                    _group(pending),
                  ],
                  if (completed.isNotEmpty) ...[
                    const SectionHeader('Completadas'),
                    _group(completed),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _empty(AppPalette p) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.mic, size: 44, color: p.tertiaryLabel),
          const SizedBox(height: 14),
          Text(
            'Aún no hay nada guardado',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: p.label,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tus dictados aparecerán aquí.',
            style: TextStyle(fontSize: 15, color: p.secondaryLabel),
          ),
        ],
      ),
    );
  }

  Widget _group(List<Note> notes) {
    final p = AppPalette.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      rows.add(
        Dismissible(
          key: ValueKey<String>(note.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppColors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(CupertinoIcons.trash,
                color: CupertinoColors.white),
          ),
          onDismissed: (_) => NoteActions.delete(note),
          child: Container(
            color: p.card,
            child: NoteTile(
              note: note,
              onTap: () => _open(note),
              onToggle: () => _store.toggleCompleted(note.id),
            ),
          ),
        ),
      );
      if (i != notes.length - 1) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(left: 62),
            child: Container(height: 0.5, color: p.separator),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}
