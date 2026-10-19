import 'package:flutter/cupertino.dart';

import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/date_text.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  const NoteTile({
    super.key,
    required this.note,
    this.onTap,
    this.onToggle,
  });

  static IconData iconFor(NoteType type) {
    switch (type) {
      case NoteType.nota:
        return CupertinoIcons.text_alignleft;
      case NoteType.recordatorio:
        return CupertinoIcons.bell_fill;
      case NoteType.evento:
        return CupertinoIcons.calendar;
    }
  }

  static Color colorFor(NoteType type) {
    switch (type) {
      case NoteType.nota:
        return AppColors.blue;
      case NoteType.recordatorio:
        return AppColors.orange;
      case NoteType.evento:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = colorFor(note.type);
    final subtitleParts = <String>[
      note.type.label,
      if (note.dueAt != null) DateText.dayAndTime(note.dueAt!),
    ];

    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconFor(note.type), size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title.isEmpty ? 'Sin título' : note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: note.completed ? p.secondaryLabel : p.label,
                    decoration: note.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: p.secondaryLabel),
                ),
              ],
            ),
          ),
          if (onToggle != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onToggle,
              child: Icon(
                note.completed
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 26,
                color: note.completed ? AppColors.green : p.tertiaryLabel,
              ),
            )
          else if (onTap != null)
            Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: p.tertiaryLabel,
            ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size.fromHeight(0),
      pressedOpacity: 0.6,
      onPressed: onTap,
      child: tile,
    );
  }
}
