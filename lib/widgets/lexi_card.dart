import 'package:flutter/material.dart';

class LexiCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool useHeroDecoration;
  final Color? accentColor;
  final Gradient? gradient;

  const LexiCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.useHeroDecoration = false,
    this.accentColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // In M3 Redesign, we use standard Material Card
    return Card(
      elevation: useHeroDecoration ? 0 : 1,
      color: useHeroDecoration ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(useHeroDecoration ? 16 : 12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(useHeroDecoration ? 16 : 12),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
