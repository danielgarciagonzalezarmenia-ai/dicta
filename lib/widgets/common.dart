import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          letterSpacing: -0.1,
          fontWeight: FontWeight.w500,
          color: p.secondaryLabel,
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(left: 16),
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

class SettingsRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: (iconColor ?? p.blue).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor ?? p.blue),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 17, color: p.label, letterSpacing: -0.4),
            ),
          ),
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                value!,
                style: TextStyle(fontSize: 17, color: p.secondaryLabel),
              ),
            ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
          if (onTap != null && trailing == null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: p.tertiaryLabel,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return content;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      pressedOpacity: 0.6,
      minimumSize: const Size.fromHeight(0),
      onPressed: onTap,
      child: content,
    );
  }
}
