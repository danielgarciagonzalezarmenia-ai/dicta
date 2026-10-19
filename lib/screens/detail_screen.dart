import 'package:flutter/cupertino.dart';

import '../models/note.dart';
import '../services/calendar_service.dart';
import '../services/notes_store.dart';
import '../services/note_actions.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_text.dart';
import '../widgets/common.dart';
import '../widgets/note_tile.dart';
import 'compose_screen.dart';

class DetailScreen extends StatefulWidget {
  final String noteId;

  const DetailScreen({super.key, required this.noteId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
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

  Note? get _note => _store.byId(widget.noteId);

  Future<void> _edit(Note note) async {
    await Navigator.of(context).push(
      CupertinoPageRoute<SaveOutcome>(
        builder: (_) =>
            ComposeScreen(transcript: note.transcript, existing: note),
      ),
    );
  }

  Future<void> _toggle(Note note) async {
    if (!note.completed) {
      await NotificationService.instance.cancel(note.id);
    }
    await _store.toggleCompleted(note.id);
  }

  Future<void> _addToCalendar(Note note) async {
    final granted = await CalendarService.instance.requestPermission();
    if (!granted) return;
    final ref = await CalendarService.instance.addEvent(note);
    if (ref == null) return;
    await _store.update(
      note.copyWith(calendarEventId: ref.eventId, calendarId: ref.calendarId),
    );
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Eliminar'),
        content: const Text('¿Seguro que quieres eliminar esta nota?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await NoteActions.delete(note);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final note = _note;

    if (note == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Detalle')),
        child: const Center(child: Text('Esta nota ya no existe.')),
      );
    }

    final typeColor = NoteTile.colorFor(note.type);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Detalle'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () => _edit(note),
          child: Icon(CupertinoIcons.pencil, color: p.blue, size: 22),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            const SectionHeader('Dictado'),
            SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    note.title.isEmpty ? 'Sin título' : note.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: p.label,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Text(
                    note.transcript.isEmpty
                        ? 'Sin texto.'
                        : note.transcript,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.35,
                      color: p.label,
                    ),
                  ),
                ),
              ],
            ),
            const SectionHeader('Detalle'),
            SettingsCard(
              children: [
                SettingsRow(
                  icon: NoteTile.iconFor(note.type),
                  iconColor: typeColor,
                  title: 'Tipo',
                  value: note.type.label,
                ),
                SettingsRow(
                  icon: CupertinoIcons.calendar,
                  iconColor: AppColors.orange,
                  title: 'Cuándo',
                  value: note.dueAt == null
                      ? 'Sin fecha'
                      : DateText.dayAndTime(note.dueAt!),
                ),
                SettingsRow(
                  icon: CupertinoIcons.bell,
                  iconColor: AppColors.red,
                  title: 'Recordatorio',
                  value: note.dueAt == null ? '—' : '10 min antes',
                ),
                if (note.type == NoteType.evento)
                  SettingsRow(
                    icon: CupertinoIcons.calendar_badge_plus,
                    iconColor: AppColors.purple,
                    title: 'Calendario',
                    value: note.calendarEventId != null
                        ? 'Añadido'
                        : 'Añadir',
                    onTap: note.calendarEventId == null
                        ? () => _addToCalendar(note)
                        : null,
                  ),
              ],
            ),
            const SectionHeader('Acciones'),
            SettingsCard(
              children: [
                SettingsRow(
                  icon: note.completed
                      ? CupertinoIcons.arrow_counterclockwise
                      : CupertinoIcons.checkmark_circle,
                  iconColor: AppColors.green,
                  title: note.completed
                      ? 'Marcar como pendiente'
                      : 'Marcar como hecho',
                  onTap: () => _toggle(note),
                ),
                SettingsRow(
                  icon: CupertinoIcons.pencil,
                  iconColor: AppColors.blue,
                  title: 'Editar',
                  onTap: () => _edit(note),
                ),
                SettingsRow(
                  icon: CupertinoIcons.trash,
                  iconColor: AppColors.red,
                  title: 'Eliminar',
                  onTap: () => _confirmDelete(note),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
