import 'package:flutter/cupertino.dart';

import '../models/note.dart';
import '../services/nlp_service.dart';
import '../services/note_actions.dart';
import '../theme/app_theme.dart';
import '../utils/date_text.dart';
import '../widgets/common.dart';

/// Pantalla para revisar y ajustar un dictado antes de guardarlo.
class ComposeScreen extends StatefulWidget {
  final String transcript;
  final Note? existing;

  const ComposeScreen({super.key, required this.transcript, this.existing});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _transcriptCtrl;
  late NoteType _type;
  DateTime? _dueAt;
  bool _remind = true;
  bool _addToCalendar = false;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleCtrl = TextEditingController(text: existing.title);
      _transcriptCtrl = TextEditingController(text: existing.transcript);
      _type = existing.type;
      _dueAt = existing.dueAt;
      _remind = existing.dueAt != null;
      _addToCalendar = existing.calendarEventId != null;
    } else {
      final insight = NlpService.analyze(widget.transcript);
      _titleCtrl = TextEditingController(text: insight.title);
      _transcriptCtrl = TextEditingController(text: widget.transcript);
      _type = insight.type;
      _dueAt = insight.dueAt;
      _remind = insight.dueAt != null;
      _addToCalendar = insight.type == NoteType.evento;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _transcriptCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = AppPalette.of(context);
    final initial = _dueAt ?? DateTime.now().add(const Duration(hours: 1));
    var temp = initial;
    var confirmed = false;
    var cleared = false;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (modalContext) {
        return Container(
          height: 336,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        cleared = true;
                        Navigator.of(modalContext).pop();
                      },
                      child: Text('Quitar', style: TextStyle(color: AppColors.red)),
                    ),
                    Text(
                      'Fecha y hora',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: p.label,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        confirmed = true;
                        Navigator.of(modalContext).pop();
                      },
                      child: const Text('Listo'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: initial,
                  minuteInterval: 5,
                  minimumDate: DateTime.now().subtract(const Duration(days: 1)),
                  onDateTimeChanged: (value) => temp = value,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (cleared) {
      setState(() {
        _dueAt = null;
        _remind = false;
      });
    } else if (confirmed) {
      setState(() {
        _dueAt = temp;
        _remind = true;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final title = _titleCtrl.text.trim();
    final transcript = _transcriptCtrl.text.trim();
    final note = Note(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.isEmpty ? (transcript.isEmpty ? 'Nota' : transcript) : title,
      transcript: transcript,
      type: _type,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      dueAt: _dueAt,
      completed: widget.existing?.completed ?? false,
      calendarEventId: widget.existing?.calendarEventId,
      calendarId: widget.existing?.calendarId,
    );

    final outcome = await NoteActions.upsert(
      note,
      wantReminder: _remind && _dueAt != null,
      wantCalendar: _addToCalendar && _type == NoteType.evento,
    );

    if (!mounted) return;
    Navigator.of(context).pop<SaveOutcome>(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final showCalendarRow = _type == NoteType.evento;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditing ? 'Editar nota' : 'Nueva nota'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator(radius: 9)
              : Text(
                  'Guardar',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: p.blue,
                  ),
                ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            const SectionHeader('Contenido'),
            SettingsCard(
              children: [
                CupertinoTextField(
                  controller: _titleCtrl,
                  placeholder: 'Título',
                  decoration: const BoxDecoration(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: p.label,
                  ),
                  placeholderStyle: TextStyle(color: p.secondaryLabel),
                ),
                CupertinoTextField(
                  controller: _transcriptCtrl,
                  placeholder: 'Lo que dictaste',
                  decoration: const BoxDecoration(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(fontSize: 16, color: p.label),
                  placeholderStyle: TextStyle(color: p.secondaryLabel),
                ),
              ],
            ),
            const SectionHeader('Tipo'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSlidingSegmentedControl<NoteType>(
                groupValue: _type,
                backgroundColor: p.cardAlt,
                children: <NoteType, Widget>{
                  NoteType.nota: _segment('Nota'),
                  NoteType.recordatorio: _segment('Recordatorio'),
                  NoteType.evento: _segment('Evento'),
                },
                onValueChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _type = value;
                    if (value == NoteType.evento) _addToCalendar = true;
                  });
                },
              ),
            ),
            const SectionHeader('Cuándo'),
            SettingsCard(
              children: [
                SettingsRow(
                  icon: CupertinoIcons.calendar,
                  title: 'Fecha y hora',
                  value: _dueAt == null
                      ? 'Añadir'
                      : DateText.dayAndTime(_dueAt!),
                  iconColor: AppColors.orange,
                  onTap: _pickDate,
                ),
                if (_dueAt != null)
                  SettingsRow(
                    icon: CupertinoIcons.bell,
                    title: 'Avisarme 10 minutos antes',
                    iconColor: AppColors.red,
                    trailing: CupertinoSwitch(
                      value: _remind,
                      onChanged: (v) => setState(() => _remind = v),
                    ),
                  ),
                if (showCalendarRow)
                  SettingsRow(
                    icon: CupertinoIcons.calendar_badge_plus,
                    title: 'Añadir al Calendario',
                    iconColor: AppColors.purple,
                    trailing: CupertinoSwitch(
                      value: _addToCalendar,
                      onChanged: (v) => setState(() => _addToCalendar = v),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              child: Text(
                'Todo se queda en tu iPhone. Dicta no usa internet ni cuentas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.secondaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      );
}
