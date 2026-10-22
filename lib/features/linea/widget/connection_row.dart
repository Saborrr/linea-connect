import 'package:flutter/material.dart';

class ConnectionRow extends StatelessWidget {
  const ConnectionRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.trailing,
    this.margin = EdgeInsets.zero,
  });
  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget trailing;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: margin,
      elevation: 0,
      color: selected ? theme.colorScheme.secondaryContainer : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        dense: true,
        minVerticalPadding: 8,
        contentPadding: const EdgeInsets.only(left: 14, right: 4),
        leading: Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 22,
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        title: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
        subtitle: Text(subtitle, style: theme.textTheme.labelSmall),
        trailing: SizedBox(width: 44, height: 44, child: trailing),
        onTap: onTap,
      ),
    );
  }
}
