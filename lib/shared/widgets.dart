import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../services/offline_service.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AppCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    final actionWidget = action;
    final children = <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitleText != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitleText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    ];
    if (actionWidget != null) {
      children.add(actionWidget);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: children),
    );
  }
}

class AppAvatar extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const AppAvatar({super.key, required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final seed = color ?? Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      backgroundColor: seed.withValues(alpha: 0.12),
      child: icon != null
          ? Icon(icon, color: seed)
          : Text(
              label.isEmpty ? '?' : label.substring(0, 1).toUpperCase(),
              style: TextStyle(color: seed, fontWeight: FontWeight.w700),
            ),
    );
  }
}

class AppSettingsActions extends StatefulWidget {
  const AppSettingsActions({super.key});

  @override
  State<AppSettingsActions> createState() => _AppSettingsActionsState();
}

class _AppSettingsActionsState extends State<AppSettingsActions> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<Locale>(
          tooltip: AppLocalizationService.instance.tr('settings_language'),
          onSelected: (locale) =>
              AppLocalizationService.instance.setLocale(locale),
          itemBuilder: (context) => AppLocalizationService
              .instance
              .supportedLocales
              .map(
                (locale) => PopupMenuItem(
                  value: locale,
                  child: Text(locale.languageCode.toUpperCase()),
                ),
              )
              .toList(),
        ),
        IconButton(
          tooltip: AppLocalizationService.instance.tr('settings_dark_mode'),
          icon: const Icon(Icons.dark_mode),
          onPressed: () {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            auth.toggleDarkMode();
          },
        ),
      ],
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OfflineService.instance.offlineNotifier,
      builder: (context, offline, _) {
        if (!offline) return const SizedBox.shrink();
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppLocalizationService.instance.tr('offline_banner'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final List<int>? sparkline;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.sparkline,
  });

  @override
  Widget build(BuildContext context) {
    final seed = color ?? Theme.of(context).colorScheme.primary;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: seed.withValues(alpha: 0.12),
            child: Icon(icon, color: seed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (sparkline != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _DashboardSparklinePainter(
                        values: sparkline!,
                        color: seed,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSparklinePainter extends CustomPainter {
  final List<int> values;
  final Color color;

  _DashboardSparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = (max - min) == 0 ? 1 : max - min;
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (size.height * (values[i] - min) / range);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
