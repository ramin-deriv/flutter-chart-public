import 'package:flutter/material.dart';
import 'package:deriv_chart/generated/l10n.dart';

/// A widget that provides localization to the chart widget tree.
class LocalizationProvider extends InheritedWidget {
  final ChartLocalization localization;

  const LocalizationProvider({
    required this.localization,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  static ChartLocalization of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<LocalizationProvider>();
    return provider?.localization ?? ChartLocalization();
  }

  @override
  bool updateShouldNotify(LocalizationProvider oldWidget) {
    return localization != oldWidget.localization;
  }
}
