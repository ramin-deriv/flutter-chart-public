import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_data.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/line_series/line_painter.dart';
import 'package:deriv_chart/src/models/tick.dart';
import 'package:deriv_chart/src/theme/painting_styles/line_style.dart';
import 'package:flutter/material.dart';

import 'package:deriv_technical_analysis/deriv_technical_analysis.dart';
import '../data_series.dart';
import '../line_series/line_series.dart';
import '../series_painter.dart';
import '../visible_entries.dart';

/// A series which shows ZigZag data calculated from [entries].
class ZigZagSeries extends LineSeries {
  /// Initializes a series which shows shows ZigZag data calculated
  /// from [entries].
  ///
  /// [distance] The minimum distance in percent between two zigzag points.
  ZigZagSeries(
    IndicatorDataInput entries, {
    String? id,
    LineStyle? style,
    double distance = 10,
  }) : super(
          ZigZagIndicator<Tick>(entries, distance).calculateValues(),
          id: id ?? 'Zigzag Indicator',
          style: style ?? const LineStyle(thickness: 0.9, color: Colors.blue),
        );

  @override
  SeriesPainter<DataSeries<Tick>> createPainter() => LinePainter(this);

  @override
  bool shouldRepaint(ChartData? oldDelegate) {
    if (oldDelegate == null) {
      return true;
    }

    return style != (oldDelegate as ZigZagSeries).style;
  }

  @override
  VisibleEntries<Tick> getVisibleEntries(int startIndex, int endIndex) {
    int firstIndex = startIndex;
    int lastIndex = endIndex;
    if (entries == null || startIndex < 0 || endIndex - 1 > entries!.length) {
      return VisibleEntries<Tick>.empty();
    }
    if (entries![startIndex].quote.isNaN) {
      for (int i = startIndex - 1; i >= 0; i--) {
        final Tick entry = entries![i];
        if (!entry.quote.isNaN) {
          firstIndex = i;
          break;
        }
      }
    }
    if (entries![endIndex - 1].quote.isNaN) {
      for (int i = endIndex + 1; i < entries!.length; i++) {
        final Tick entry = entries![i];
        if (!entry.quote.isNaN) {
          lastIndex = i + 1;
          break;
        }
      }
    }
    return VisibleEntries<Tick>(
      entries!.sublist(firstIndex, lastIndex),
      firstIndex,
      lastIndex,
    );
  }
}
