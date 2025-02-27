import 'package:deriv_chart/deriv_chart.dart';
import 'package:deriv_chart/src/deriv_chart/chart/x_axis/widgets/x_axis_mobile.dart';
import 'package:deriv_chart/src/deriv_chart/chart/x_axis/widgets/x_axis_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const Duration _defaultDuration = Duration(milliseconds: 300);

/// X-axis wrapper widget.
///
/// Renders x-axis web widget or mobile widget based on the [kIsWeb] flag.
class XAxisWrapper extends StatelessWidget {
  /// Initialize
  const XAxisWrapper({
    required this.entries,
    required this.child,
    required this.isLive,
    required this.startWithDataFitMode,
    required this.pipSize,
    required this.chartAxisConfig,
    this.onVisibleAreaChanged,
    this.minEpoch,
    this.maxEpoch,
    this.msPerPx,
    this.minIntervalWidth,
    this.maxIntervalWidth,
    this.dataFitPadding,
    this.scrollAnimationDuration = _defaultDuration,
    Key? key,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// A reference to chart's main candles.
  final List<Tick> entries;

  /// Whether the chart is showing live data.
  final bool isLive;

  /// Starts in data fit mode.
  final bool startWithDataFitMode;

  /// Callback provided by library user.
  final VisibleAreaChangedCallback? onVisibleAreaChanged;

  /// Minimum epoch for this [XAxis].
  final int? minEpoch;

  /// Maximum epoch for this [XAxis].
  final int? maxEpoch;

  /// Number of digits after decimal point in price
  final int pipSize;

  /// Specifies the zoom level of the chart.
  final double? msPerPx;

  /// Specifies the minimum interval width
  /// that is used for calculating the maximum msPerPx.
  final double? minIntervalWidth;

  /// Specifies the maximum interval width
  /// that is used for calculating the maximum msPerPx.
  final double? maxIntervalWidth;

  /// Padding around data used in data-fit mode.
  final EdgeInsets? dataFitPadding;

  /// Duration of the scroll animation.
  final Duration scrollAnimationDuration;

  /// Chart axis configuration.
  final ChartAxisConfig chartAxisConfig;

  @override
  Widget build(BuildContext context) {
    if (!chartAxisConfig.smoothScrolling) {
      return XAxisWeb(
        child: child,
        entries: entries,
        isLive: isLive,
        startWithDataFitMode: startWithDataFitMode,
        pipSize: pipSize,
        onVisibleAreaChanged: onVisibleAreaChanged,
        minEpoch: minEpoch,
        maxEpoch: maxEpoch,
        msPerPx: msPerPx,
        minIntervalWidth: minIntervalWidth,
        maxIntervalWidth: maxIntervalWidth,
        dataFitPadding: dataFitPadding,
        scrollAnimationDuration: scrollAnimationDuration,
      );
    } else {
      return XAxisMobile(
        child: child,
        entries: entries,
        isLive: isLive,
        startWithDataFitMode: startWithDataFitMode,
        pipSize: pipSize,
        onVisibleAreaChanged: onVisibleAreaChanged,
        minEpoch: minEpoch,
        maxEpoch: maxEpoch,
        msPerPx: msPerPx,
        minIntervalWidth: minIntervalWidth,
        maxIntervalWidth: maxIntervalWidth,
        dataFitPadding: dataFitPadding,
        scrollAnimationDuration: scrollAnimationDuration,
      );
    }
  }
}
