import 'dart:ui' as ui;
import 'package:deriv_chart/src/add_ons/drawing_tools_ui/fibfan/fibfan_drawing_tool_config.dart';
import 'package:deriv_chart/src/theme/painting_styles/line_style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../chart/data_visualization/chart_data.dart';
import '../../chart/data_visualization/drawing_tools/data_model/drawing_paint_style.dart';
import '../../chart/data_visualization/drawing_tools/data_model/edge_point.dart';
import '../../chart/data_visualization/models/animation_info.dart';
import '../interactable_drawing_custom_painter.dart';
import 'interactable_drawing.dart';

/// Interactable drawing for Fibonacci Fan drawing tool.
class FibFanInteractableDrawing
    extends InteractableDrawing<FibfanDrawingToolConfig> {
  /// Initializes [FibFanInteractableDrawing].
  FibFanInteractableDrawing({
    required FibfanDrawingToolConfig config,
    required this.startPoint,
    required this.endPoint,
  }) : super(config: config);

  /// Start point of the fan.
  EdgePoint? startPoint;

  /// End point of the fan.
  EdgePoint? endPoint;

  // Fibonacci ratios for fan lines
  static const List<double> _fibRatios = [0, 0.236, 0.382, 0.5, 0.618, 1];

  // Tracks which point is being dragged, if any
  // null: dragging the whole fan
  // true: dragging the start point
  // false: dragging the end point
  bool? _isDraggingStartPoint;

  Offset? _hoverPosition;

  @override
  void onHover(PointerHoverEvent event, EpochFromX epochFromX,
      QuoteFromY quoteFromY, EpochToX epochToX, QuoteToY quoteToY) {
    _hoverPosition = event.localPosition;
  }

  @override
  void onDragStart(
    DragStartDetails details,
    EpochFromX epochFromX,
    QuoteFromY quoteFromY,
    EpochToX epochToX,
    QuoteToY quoteToY,
  ) {
    if (startPoint == null || endPoint == null) {
      return;
    }

    // Reset the dragging flag
    _isDraggingStartPoint = null;

    // Convert start and end points from epoch/quote to screen coordinates
    final Offset startOffset = Offset(
      epochToX(startPoint!.epoch),
      quoteToY(startPoint!.quote),
    );
    final Offset endOffset = Offset(
      epochToX(endPoint!.epoch),
      quoteToY(endPoint!.quote),
    );

    // Check if the drag is starting on one of the endpoints
    final double startDistance = (details.localPosition - startOffset).distance;
    final double endDistance = (details.localPosition - endOffset).distance;

    // If the drag is starting on the start point
    if (startDistance <= hitTestMargin) {
      _isDraggingStartPoint = true;
      return;
    }

    // If the drag is starting on the end point
    if (endDistance <= hitTestMargin) {
      _isDraggingStartPoint = false;
      return;
    }

    // If we reach here, the drag is on the fan itself, not on a specific point
    // _isDraggingStartPoint remains null, indicating we're dragging the whole fan
  }

  @override
  bool hitTest(Offset offset, EpochToX epochToX, QuoteToY quoteToY) {
    if (startPoint == null || endPoint == null) {
      return false;
    }

    // Convert start and end points from epoch/quote to screen coordinates
    final Offset startOffset = Offset(
      epochToX(startPoint!.epoch),
      quoteToY(startPoint!.quote),
    );
    final Offset endOffset = Offset(
      epochToX(endPoint!.epoch),
      quoteToY(endPoint!.quote),
    );

    // Check if the pointer is near either endpoint
    final double startDistance = (offset - startOffset).distance;
    final double endDistance = (offset - endOffset).distance;

    if (startDistance <= hitTestMargin || endDistance <= hitTestMargin) {
      return true;
    }

    // Check if the point is near any of the fan lines
    for (final ratio in _fibRatios) {
      if (_isPointNearFanLine(offset, startOffset, endOffset, ratio)) {
        return true;
      }
    }

    return false;
  }

  bool _isPointNearFanLine(
      Offset point, Offset start, Offset end, double ratio) {
    // Calculate the end point of the fan line at this ratio
    final Offset fanEnd = Offset(
      end.dx,
      start.dy + (end.dy - start.dy) * ratio,
    );

    // Calculate line length
    final double lineLength = (fanEnd - start).distance;

    // If line length is too small, treat it as a point
    if (lineLength < 1) {
      return (point - start).distance <= hitTestMargin;
    }

    // Calculate perpendicular distance from point to line
    final double distance = ((fanEnd.dy - start.dy) * point.dx -
                (fanEnd.dx - start.dx) * point.dy +
                fanEnd.dx * start.dy -
                fanEnd.dy * start.dx)
            .abs() /
        lineLength;

    // Check if point is within the line segment
    final double dotProduct = (point.dx - start.dx) * (fanEnd.dx - start.dx) +
        (point.dy - start.dy) * (fanEnd.dy - start.dy);

    final bool isWithinRange =
        dotProduct >= 0 && dotProduct <= lineLength * lineLength;

    return isWithinRange && distance <= hitTestMargin;
  }

  @override
  void paint(
    Canvas canvas,
    Size size,
    EpochToX epochToX,
    QuoteToY quoteToY,
    AnimationInfo animationInfo,
    GetDrawingState getDrawingState,
  ) {
    final LineStyle lineStyle = config.lineStyle;
    final LineStyle fillStyle = config.fillStyle;
    final DrawingPaintStyle paintStyle = DrawingPaintStyle();
    final Set<DrawingToolState> state = getDrawingState(this);

    if (startPoint != null && endPoint != null) {
      final Offset startOffset =
          Offset(epochToX(startPoint!.epoch), quoteToY(startPoint!.quote));
      final Offset endOffset =
          Offset(epochToX(endPoint!.epoch), quoteToY(endPoint!.quote));

      // Draw filled areas with different opacity based on selection state
      for (int i = 0; i < _fibRatios.length - 1; i++) {
        final double ratio = _fibRatios[i];
        final double nextRatio = _fibRatios[i + 1];

        final Offset fanEnd = Offset(
          endOffset.dx,
          startOffset.dy + (endOffset.dy - startOffset.dy) * ratio,
        );
        final Offset nextFanEnd = Offset(
          endOffset.dx,
          startOffset.dy + (endOffset.dy - startOffset.dy) * nextRatio,
        );

        final Path fillPath = Path()
          ..moveTo(startOffset.dx, startOffset.dy)
          ..lineTo(fanEnd.dx, fanEnd.dy)
          ..lineTo(nextFanEnd.dx, nextFanEnd.dy)
          ..lineTo(startOffset.dx, startOffset.dy);

        // Use different colors and opacities based on selection state
        final Color fillColor = state.contains(DrawingToolState.selected) ||
                state.contains(DrawingToolState.dragging)
            ? fillStyle.color.withOpacity(0.4) // More prominent when selected
            : fillStyle.color.withOpacity(0.25); // More visible in normal state

        final Paint fillPaint = Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true
          ..blendMode = BlendMode.srcOver;
        canvas.drawPath(fillPath, fillPaint);
      }

      // Draw fan lines
      for (final ratio in _fibRatios) {
        final Offset fanEnd = Offset(
          endOffset.dx,
          startOffset.dy + (endOffset.dy - startOffset.dy) * ratio,
        );

        // Use different styles for selected/dragging state
        final Paint linePaint = state.contains(DrawingToolState.selected) ||
                state.contains(DrawingToolState.dragging)
            ? paintStyle.linePaintStyle(
                lineStyle.color, 1 + 1 * animationInfo.stateChangePercent)
            : paintStyle.linePaintStyle(lineStyle.color, lineStyle.thickness);

        // Draw the fan line
        canvas.drawLine(startOffset, fanEnd, linePaint);
      }

      // Draw endpoints with glowy effect if selected
      if (state.contains(DrawingToolState.selected) ||
          state.contains(DrawingToolState.dragging)) {
        _drawPointsFocusedCircle(
          paintStyle,
          lineStyle,
          canvas,
          startOffset,
          10 * animationInfo.stateChangePercent,
          3 * animationInfo.stateChangePercent,
          endOffset,
        );
      } else if (state.contains(DrawingToolState.hovered)) {
        _drawPointsFocusedCircle(
            paintStyle, lineStyle, canvas, startOffset, 10, 3, endOffset);
      }

      // Draw alignment guides when dragging
      if (state.contains(DrawingToolState.dragging)) {
        _drawAlignmentGuides(canvas, size, startOffset, endOffset, paintStyle);
      }
    } else if (state.contains(DrawingToolState.adding)) {
      if (startPoint != null) {
        _drawPoint(
            startPoint!, epochToX, quoteToY, canvas, paintStyle, lineStyle);
        _drawPointAlignmentGuides(canvas, size,
            Offset(epochToX(startPoint!.epoch), quoteToY(startPoint!.quote)));

        if (_hoverPosition != null) {
          // Draw preview fan lines while creating
          final Offset startOffset = Offset(
            epochToX(startPoint!.epoch),
            quoteToY(startPoint!.quote),
          );

          for (final ratio in _fibRatios) {
            final Offset previewEnd = Offset(
              _hoverPosition!.dx,
              startOffset.dy + (_hoverPosition!.dy - startOffset.dy) * ratio,
            );
            canvas.drawLine(
                startOffset,
                previewEnd,
                paintStyle.linePaintStyle(
                    lineStyle.color, lineStyle.thickness));
          }

          _drawPointAlignmentGuides(canvas, size, _hoverPosition!);
        }
      }

      if (endPoint != null) {
        _drawPoint(
            endPoint!, epochToX, quoteToY, canvas, paintStyle, lineStyle);
      }
    }
  }

  void _drawPointsFocusedCircle(
      DrawingPaintStyle paintStyle,
      LineStyle lineStyle,
      ui.Canvas canvas,
      ui.Offset startOffset,
      double outerCircleRadius,
      double innerCircleRadius,
      ui.Offset endOffset) {
    final normalPaintStyle = paintStyle.glowyCirclePaintStyle(lineStyle.color);
    final glowyPaintStyle =
        paintStyle.glowyCirclePaintStyle(lineStyle.color.withOpacity(0.3));
    canvas
      ..drawCircle(
        startOffset,
        outerCircleRadius,
        glowyPaintStyle,
      )
      ..drawCircle(
        startOffset,
        innerCircleRadius,
        normalPaintStyle,
      )
      ..drawCircle(
        endOffset,
        outerCircleRadius,
        glowyPaintStyle,
      )
      ..drawCircle(
        endOffset,
        innerCircleRadius,
        normalPaintStyle,
      );
  }

  void _drawAlignmentGuides(Canvas canvas, Size size, Offset startOffset,
      Offset endOffset, DrawingPaintStyle paintStyle) {
    _drawPointAlignmentGuides(canvas, size, startOffset);
    _drawPointAlignmentGuides(canvas, size, endOffset);
  }

  void _drawPointAlignmentGuides(Canvas canvas, Size size, Offset pointOffset) {
    final Paint guidesPaint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Path horizontalPath = Path();
    final Path verticalPath = Path();

    horizontalPath
      ..moveTo(0, pointOffset.dy)
      ..lineTo(size.width, pointOffset.dy);

    verticalPath
      ..moveTo(pointOffset.dx, 0)
      ..lineTo(pointOffset.dx, size.height);

    canvas
      ..drawPath(
        _dashPath(horizontalPath,
            dashArray: _CircularIntervalList<double>(<double>[5, 5])),
        guidesPaint,
      )
      ..drawPath(
        _dashPath(verticalPath,
            dashArray: _CircularIntervalList<double>(<double>[5, 5])),
        guidesPaint,
      );
  }

  Path _dashPath(
    Path source, {
    required _CircularIntervalList<double> dashArray,
  }) {
    final Path dest = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray.next;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  void _drawPoint(
    EdgePoint point,
    EpochToX epochToX,
    QuoteToY quoteToY,
    Canvas canvas,
    DrawingPaintStyle paintStyle,
    LineStyle lineStyle,
  ) {
    canvas.drawCircle(
      Offset(epochToX(point.epoch), quoteToY(point.quote)),
      5,
      paintStyle.glowyCirclePaintStyle(lineStyle.color),
    );
  }

  @override
  void onCreateTap(
    TapUpDetails details,
    EpochFromX epochFromX,
    QuoteFromY quoteFromY,
    EpochToX epochToX,
    QuoteToY quoteToY,
    VoidCallback onDone,
  ) {
    if (startPoint == null) {
      startPoint = EdgePoint(
        epoch: epochFromX(details.localPosition.dx),
        quote: quoteFromY(details.localPosition.dy),
      );
    } else {
      endPoint ??= EdgePoint(
        epoch: epochFromX(details.localPosition.dx),
        quote: quoteFromY(details.localPosition.dy),
      );
      onDone();
    }
  }

  @override
  void onDragUpdate(
    DragUpdateDetails details,
    EpochFromX epochFromX,
    QuoteFromY quoteFromY,
    EpochToX epochToX,
    QuoteToY quoteToY,
  ) {
    if (startPoint == null || endPoint == null) {
      return;
    }

    final Offset delta = details.delta;

    if (_isDraggingStartPoint != null) {
      // Get the current point being dragged
      final EdgePoint pointBeingDragged =
          _isDraggingStartPoint! ? startPoint! : endPoint!;

      // Get the current screen position of the point
      final Offset currentOffset = Offset(
        epochToX(pointBeingDragged.epoch),
        quoteToY(pointBeingDragged.quote),
      );

      // Apply the delta to get the new screen position
      final Offset newOffset = currentOffset + delta;

      // Convert back to epoch and quote coordinates
      final int newEpoch = epochFromX(newOffset.dx);
      final double newQuote = quoteFromY(newOffset.dy);

      // Create updated point
      final EdgePoint updatedPoint = EdgePoint(
        epoch: newEpoch,
        quote: newQuote,
      );

      // Update the appropriate point
      if (_isDraggingStartPoint!) {
        startPoint = updatedPoint;
      } else {
        endPoint = updatedPoint;
      }
    } else {
      // We're dragging the whole fan
      // Convert start and end points to screen coordinates
      final Offset startOffset = Offset(
        epochToX(startPoint!.epoch),
        quoteToY(startPoint!.quote),
      );
      final Offset endOffset = Offset(
        epochToX(endPoint!.epoch),
        quoteToY(endPoint!.quote),
      );

      // Apply the delta to get new screen coordinates
      final Offset newStartOffset = startOffset + delta;
      final Offset newEndOffset = endOffset + delta;

      // Convert back to epoch and quote coordinates
      final int newStartEpoch = epochFromX(newStartOffset.dx);
      final double newStartQuote = quoteFromY(newStartOffset.dy);
      final int newEndEpoch = epochFromX(newEndOffset.dx);
      final double newEndQuote = quoteFromY(newEndOffset.dy);

      // Update the start and end points
      startPoint = EdgePoint(
        epoch: newStartEpoch,
        quote: newStartQuote,
      );
      endPoint = EdgePoint(
        epoch: newEndEpoch,
        quote: newEndQuote,
      );
    }
  }

  @override
  void onDragEnd(
    DragEndDetails details,
    EpochFromX epochFromX,
    QuoteFromY quoteFromY,
    EpochToX epochToX,
    QuoteToY quoteToY,
  ) {
    // Reset the dragging flag when drag is complete
    _isDraggingStartPoint = null;
  }

  @override
  FibfanDrawingToolConfig getUpdatedConfig() =>
      config.copyWith(edgePoints: <EdgePoint>[
        if (startPoint != null) startPoint!,
        if (endPoint != null) endPoint!
      ]);
}

/// A circular array for dash patterns
class _CircularIntervalList<T> {
  _CircularIntervalList(this._values);

  final List<T> _values;
  int _index = 0;

  T get next {
    if (_index >= _values.length) {
      _index = 0;
    }
    return _values[_index++];
  }
}
