import 'package:deriv_chart/src/add_ons/drawing_tools_ui/channel/channel_drawing_tool_config.dart';
import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/data_series.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/data_model/draggable_edge_point.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/data_model/drawing_paint_style.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/data_model/drawing_parts.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/data_model/drawing_pattern.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/data_model/edge_point.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/extensions/extensions.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/data_model/vector.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/data_model/point.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/drawing.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/drawing_data.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/line_vector_drawing_mixin.dart';
import 'package:deriv_chart/src/models/tick.dart';
import 'package:deriv_chart/src/theme/chart_theme.dart';
import 'package:deriv_chart/src/theme/painting_styles/line_style.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'channel_drawing.g.dart';

/// Channel drawing tool. A channel is 2 parallel lines that
/// created with 3 points.
@JsonSerializable()
class ChannelDrawing extends Drawing with LineVectorDrawingMixin {
  /// Initializes
  ChannelDrawing({
    required this.drawingPart,
    this.startEdgePoint = const EdgePoint(),
    this.middleEdgePoint = const EdgePoint(),
    this.endEdgePoint = const EdgePoint(),
    this.isDrawingFinished = false,
  });

  /// Initializes from JSON.
  factory ChannelDrawing.fromJson(Map<String, dynamic> json) =>
      _$ChannelDrawingFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ChannelDrawingToJson(this)
    ..putIfAbsent(Drawing.classNameKey, () => nameKey);

  /// Key of drawing tool name property in JSON.
  static const String nameKey = 'ChannelDrawing';

  /// Part of a drawing: 'marker' or 'line'
  final DrawingParts drawingPart;

  /// Starting point of drawing which is used as the start point of initial
  /// vector
  final EdgePoint startEdgePoint;

  /// Second point of drawing which is used to draw the end point of initial
  /// vector
  final EdgePoint middleEdgePoint;

  /// Ending point of drawing which is used to draw the second(final) vector
  final EdgePoint endEdgePoint;

  /// Marker radius.
  final double markerRadius = 10;

  /// Flag to show if drawing is finished.
  final bool isDrawingFinished;

  Vector _initialVector = const Vector.zero();
  Vector _finalVector = const Vector.zero();

  /// Keeps the latest position of the start and end point of drawing
  Point? _startPoint, _middlePoint, _endPoint;

  /// Returns the Parallelogram path
  Path getParallelogramPath(
    Vector startVector,
    Vector endVector,
  ) =>
      Path()
        ..moveTo(startVector.x0, startVector.y0)
        ..lineTo(startVector.x1, startVector.y1)
        ..lineTo(endVector.x1, endVector.y1)
        ..lineTo(endVector.x0, endVector.y0)
        ..close();

  /// Draw the shaded area between two vectors
  void drawParallelogram(
    Canvas canvas,
    ChannelDrawingToolConfig config,
    DrawingPaintStyle paint,
    Vector startVector,
    Vector endVector,
  ) {
    final LineStyle fillStyle = config.fillStyle;

    /// The path for the shaded area between two lines
    final Path path = getParallelogramPath(startVector, endVector);

    canvas.drawPath(
        path, paint.fillPaintStyle(fillStyle.color, fillStyle.thickness));
  }

  /// Paint the line
  @override
  void onPaint(
    Canvas canvas,
    Size size,
    ChartTheme theme,
    int Function(double x) epochFromX,
    double Function(double) quoteFromY,
    double Function(int x) epochToX,
    double Function(double y) quoteToY,
    DrawingToolConfig config,
    DrawingData drawingData,
    DataSeries<Tick> series,
    Point Function(
      EdgePoint edgePoint,
      DraggableEdgePoint draggableEdgePoint,
    ) updatePositionCallback,
    DraggableEdgePoint draggableStartPoint, {
    DraggableEdgePoint? draggableMiddlePoint,
    DraggableEdgePoint? draggableEndPoint,
  }) {
    final DrawingPaintStyle paint = DrawingPaintStyle();

    /// Get the latest config of any drawing tool which is used to draw the line
    config as ChannelDrawingToolConfig;

    final LineStyle lineStyle = config.lineStyle;
    final DrawingPatterns pattern = config.pattern;
    final List<EdgePoint> edgePoints = config.edgePoints;

    /// Since we want to draw a marker on the screen base on the user click,
    /// we need to call the onPaint function each time any record added to
    /// edgePoints list, so we need to check the edgePoints list lenght to
    /// know which marker should be drawn
    _startPoint = updatePositionCallback(edgePoints.first, draggableStartPoint);
    if (edgePoints.length > 1) {
      _middlePoint =
          updatePositionCallback(edgePoints[1], draggableMiddlePoint!);
    } else {
      _middlePoint =
          updatePositionCallback(middleEdgePoint, draggableMiddlePoint!);
    }
    if (edgePoints.length > 2) {
      _endPoint = updatePositionCallback(edgePoints.last, draggableEndPoint!);
    } else {
      _endPoint = updatePositionCallback(endEdgePoint, draggableEndPoint!);
    }

    final double startXCoord = _startPoint!.x;
    final double startQuoteToY = _startPoint!.y;

    final double middleXCoord = _middlePoint!.x;
    final double middleQuoteToY = _middlePoint!.y;

    final double height = middleQuoteToY - _endPoint!.y;

    final double endXCoord = middleXCoord;
    final double endQuoteToY = middleQuoteToY - height;

    _initialVector = getLineVector(
      startXCoord,
      startQuoteToY,
      middleXCoord,
      middleQuoteToY,
    );

    _finalVector = getLineVector(
      endXCoord,
      endQuoteToY,
      startXCoord,
      startQuoteToY - height,
    );

    if (drawingPart == DrawingParts.marker) {
      if (endEdgePoint.epoch != 0 && endQuoteToY != 0) {
        /// Draw final point
        canvas.drawCircle(
            Offset(middleXCoord, middleQuoteToY - height),
            markerRadius,
            drawingData.shouldHighlight
                ? paint.glowyCirclePaintStyle(lineStyle.color)
                : paint.transparentCirclePaintStyle());
      } else if (startEdgePoint.epoch != 0 && startQuoteToY != 0) {
        /// Draw first point
        canvas.drawCircle(
            Offset(startXCoord, startQuoteToY),
            markerRadius,
            drawingData.shouldHighlight
                ? paint.glowyCirclePaintStyle(lineStyle.color)
                : paint.transparentCirclePaintStyle());
      } else if (middleEdgePoint.epoch != 0 && middleQuoteToY != 0) {
        /// Draw second point
        canvas.drawCircle(
            Offset(middleXCoord, middleQuoteToY),
            markerRadius,
            drawingData.shouldHighlight
                ? paint.glowyCirclePaintStyle(lineStyle.color)
                : paint.transparentCirclePaintStyle());
      }
    } else if (drawingPart == DrawingParts.line) {
      if (endEdgePoint.epoch != 0 && endQuoteToY != 0) {
        /// Draw second line
        drawParallelogram(
          canvas,
          config,
          paint,
          _initialVector,
          _finalVector,
        );
        if (pattern == DrawingPatterns.solid) {
          /// Drawing the markers in the final step again to hide the overlap
          /// of fill color and the markers
          canvas
            ..drawCircle(
                Offset(startXCoord, startQuoteToY),
                markerRadius,
                drawingData.shouldHighlight
                    ? paint.glowyCirclePaintStyle(lineStyle.color)
                    : paint.transparentCirclePaintStyle())
            ..drawCircle(
                Offset(middleXCoord, middleQuoteToY),
                markerRadius,
                drawingData.shouldHighlight
                    ? paint.glowyCirclePaintStyle(lineStyle.color)
                    : paint.transparentCirclePaintStyle())
            ..drawCircle(
                Offset(middleXCoord, middleQuoteToY - height),
                markerRadius,
                drawingData.shouldHighlight
                    ? paint.glowyCirclePaintStyle(lineStyle.color)
                    : paint.transparentCirclePaintStyle())

            /// Draw first line again to hide the overlap of fill color and line
            ..drawLine(
              Offset(_initialVector.x0, _initialVector.y0),
              Offset(_initialVector.x1, _initialVector.y1),
              drawingData.shouldHighlight
                  ? paint.glowyLinePaintStyle(
                      lineStyle.color, lineStyle.thickness)
                  : paint.linePaintStyle(lineStyle.color, lineStyle.thickness),
            )
            ..drawLine(
              Offset(_finalVector.x0, _finalVector.y0),
              Offset(_finalVector.x1, _finalVector.y1),
              drawingData.shouldHighlight
                  ? paint.glowyLinePaintStyle(
                      lineStyle.color, lineStyle.thickness)
                  : paint.linePaintStyle(lineStyle.color, lineStyle.thickness),
            );
        }
      } else if (startEdgePoint.epoch != 0 && startQuoteToY != 0) {
        /// Draw first line
        if (pattern == DrawingPatterns.solid) {
          canvas.drawLine(
            Offset(_initialVector.x0, _initialVector.y0),
            Offset(_initialVector.x1, _initialVector.y1),
            drawingData.shouldHighlight
                ? paint.glowyLinePaintStyle(
                    lineStyle.color, lineStyle.thickness)
                : paint.linePaintStyle(lineStyle.color, lineStyle.thickness),
          );
        }
      }
    }
  }

  /// Calculation for detemining whether a user's touch or click intersects
  /// with any of the painted areas on the screen, for any of the edge points
  /// it will call "setIsEdgeDragged" callback function to determine which
  /// point is clicked
  @override
  bool hitTest(
    Offset position,
    double Function(int x) epochToX,
    double Function(double y) quoteToY,
    DrawingToolConfig config,
    DraggableEdgePoint draggableStartPoint,
    void Function({required bool isOverPoint}) setIsOverStartPoint, {
    DraggableEdgePoint? draggableMiddlePoint,
    DraggableEdgePoint? draggableEndPoint,
    void Function({required bool isOverPoint})? setIsOverMiddlePoint,
    void Function({required bool isOverPoint})? setIsOverEndPoint,
  }) {
    final double middleXCoord = _middlePoint!.x;
    final double middleQuoteToY = _middlePoint!.y;

    final double height = middleQuoteToY - _endPoint!.y;

    final double endXCoord = middleXCoord;
    final double endQuoteToY = middleQuoteToY - height;

    /// Check if start point clicked
    if (_startPoint!.isClicked(position, markerRadius)) {
      setIsOverStartPoint(isOverPoint: true);
    } else {
      setIsOverStartPoint(isOverPoint: false);
    }

    /// Check if middle point clicked
    if (_middlePoint!.isClicked(position, markerRadius)) {
      setIsOverMiddlePoint!(isOverPoint: true);
    } else {
      setIsOverMiddlePoint!(isOverPoint: false);
    }

    /// Check if end point clicked, since the endPoint position is dependendat
    /// to middle point position, we need to check it differently
    final Point endPoint = Point(x: endXCoord, y: endQuoteToY);

    /// Check if end point clicked
    if (endPoint.isClicked(position, markerRadius)) {
      setIsOverEndPoint!(isOverPoint: true);
    } else {
      setIsOverEndPoint!(isOverPoint: false);
    }

    /// Detect the area between 2 parallel lines
    final Path path = getParallelogramPath(_initialVector, _finalVector);

    return (isDrawingFinished && path.contains(position)) ||
        (_startPoint!.isClicked(position, markerRadius) ||
            _middlePoint!.isClicked(position, markerRadius) ||
            endPoint.isClicked(position, markerRadius));
  }

  // TODO(NA): return true if the channel drawing is in epoch range.
  @override
  bool needsRepaint(
    int leftEpoch,
    int rightEpoch,
    DraggableEdgePoint draggableStartPoint, {
    DraggableEdgePoint? draggableMiddlePoint,
    DraggableEdgePoint? draggableEndPoint,
  }) =>
      draggableStartPoint.isInViewPortRange(leftEpoch, rightEpoch) ||
      (draggableEndPoint?.isInViewPortRange(leftEpoch, rightEpoch) ?? true);
}
