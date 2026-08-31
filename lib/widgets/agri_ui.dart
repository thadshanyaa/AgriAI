import 'package:flutter/material.dart';
import '../localization/app_language.dart';
import '../theme/app_theme.dart';

class AgriPage extends StatelessWidget {
  const AgriPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    this.showBack = true,
    this.scrollable = true,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool showBack;
  final bool scrollable;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF09140D), Color(0xFF16321D)]
                : const [Color(0xFFF8FFF6), AppColors.backgroundDeep],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (showBack && Navigator.canPop(context)) ...[
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: theme.colorScheme.onSurface,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Expanded(
                      child: Text(
                        tr(title),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    ...actions,
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: showBack && Navigator.canPop(context) ? 48 : 0,
                  ),
                  child: Text(
                    tr(subtitle),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: scrollable
                      ? SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: child,
                        )
                      : child,
                ),
                if (bottom != null) ...[const SizedBox(height: 10), bottom!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AgriHeroCard extends StatelessWidget {
  const AgriHeroCard({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(18),
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(
                    tr(eyebrow!),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                Text(
                  tr(title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    tr(subtitle!),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class AgriSection extends StatelessWidget {
  const AgriSection({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(top: 12),
  });

  final Widget child;
  final String? title;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: dark
            ? theme.colorScheme.surface.withValues(alpha: 0.98)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? theme.colorScheme.outlineVariant : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              tr(title!),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class AgriPrimaryButton extends StatelessWidget {
  const AgriPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(
          tr(label),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AgriActionTile extends StatelessWidget {
  const AgriActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundDeep,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(title),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tr(subtitle),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class AgriInfoRow extends StatelessWidget {
  const AgriInfoRow(this.label, this.value, {super.key, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              tr(label),
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              tr(value),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AgriChip extends StatelessWidget {
  const AgriChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(tr(label)),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
      selectedColor: dark ? const Color(0xFF284C31) : AppColors.backgroundDeep,
      backgroundColor: dark
          ? theme.colorScheme.surfaceContainerHighest
          : AppColors.surfaceSoft,
      side: BorderSide(
        color: selected ? AppColors.primary : const Color(0xFFD9E8DA),
      ),
      labelStyle: TextStyle(
        color: selected
            ? (dark ? AppColors.primaryLight : AppColors.primaryDark)
            : theme.colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

void showDemoMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(tr(message)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
      ),
    );
}
