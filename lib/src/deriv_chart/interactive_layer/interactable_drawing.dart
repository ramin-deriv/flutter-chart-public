import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:deriv_chart/src/add_ons/drawing_tools_ui/line/line_drawing_tool_config.dart';
import 'package:deriv_chart/src/theme/painting_styles/line_style.dart';
import 'package:flutter/widgets.dart';

import '../chart/data_visualization/chart_data.dart';
import '../chart/data_visualization/drawing_tools/data_model/drawing_paint_style.dart';
import '../chart/data_visualization/drawing_tools/data_model/edge_point.dart';
import '../chart/data_visualization/models/animation_info.dart';
import 'interactable_drawing_custom_painter.dart';

/// Represents the current state of a drawing tool on the chart.
///
/// The state determines how the drawing tool is rendered and how it responds
/// to user interactions. Different states trigger different visual appearances
/// and interaction behaviors.
enum DrawingToolState {
  /// Default state when the drawing tool is displayed on the chart
  /// but not being interacted with.
  normal,

  /// The drawing tool is currently selected by the user. Selected tools
  /// typically show additional visual cues like handles or a glowy effect
  /// to indicate they can be manipulated.
  selected,

  /// The user's pointer is hovering over the drawing tool but hasn't
  /// selected it yet. This state can be used to provide visual feedback
  /// before selection.
  hovered,

  /// The drawing tool is in the process of being created/added to the chart.
  /// In this state, the tool captures user inputs (like taps) to define
  /// its shape and position.
  adding,

  /// The drawing tool is being actively moved or resized by the user.
  /// This state is active during drag operations when the user is
  /// modifying the tool's position.
  dragging,
}

/// The class that will be generated by the drawing tool config instance when
/// they are created or the saved ones that are loaded from storage.
/// The information from this class (its subclasses) will be used to draw the
/// tool on the chart.
/// It will keep the latest state of the drawing tool as the user interacts
/// with the tools in the runtime.
/// During the time that user interacts with a tool. by some debounce mechanism
/// This class will update the config which is supposed to be saved in the storage.
abstract class InteractableDrawing<T extends DrawingToolConfig> {
  /// Initializes [InteractableDrawing].
  InteractableDrawing({required this.config});

  static const double _hitTestMargin = 16;

  /// The margin for hit testing.
  double get hitTestMargin => _hitTestMargin;

  /// The drawing tool config.
  final T config;

  @protected
  DrawingToolState state = DrawingToolState.normal;

  /// Returns the updated config.
  T getUpdatedConfig();

  /// Returns `true` if the drawing tool is hit by the given offset.
  bool hitTest(Offset offset, EpochToX epochToX, QuoteToY quoteToY);

  /// The tap event that is called when the [InteractableDrawing] is in adding
  /// state.
  ///
  /// the drawing can use the tap to capture and create the coordinates required
  /// for its shape.
  ///
  /// [onDone] is a callback that should be called when the drawing is done.
  void onCreateTap(
    TapUpDetails details,
    EpochFromX epochFromX,
    QuoteFromY quoteFromY,
    EpochToX epochToX,
    QuoteToY quoteToY,
    VoidCallback onDone,
  ) {
    print('onDragStart $runtimeType}');
  }

  /// Called when the drawing tool dragging is started.
  void onDragStart(
    DragStartDetails details,
    EpochFromX epochFromX,
    QuoteFromY quoteFromY,
    EpochToX epochToX,
    QuoteToY quoteToY,
  ) {
    print('onDragStart $runtimeType}');
  }

  /// Called when the drawing tool is dragged and updates the drawing position
  /// properties based on the dragging [details].
  ///
  /// Each drawing will know how to handle and update itself accordingly based
  /// on where the dragging position is like if it's dragging a point or a line
  /// of the tool.
  void onDragUpdate(
    DragUpdateDetails details,
    EpochFromX epochFromX,
    QuoteFromY quoteFromY,
    EpochToX epochToX,
    QuoteToY quoteToY,
  );

  /// Called when the drawing tool dragging is ended.
  void onDragEnd(
    DragEndDetails details,
    EpochFromX epochFromX,
    QuoteFromY quoteFromY,
    EpochToX epochToX,
    QuoteToY quoteToY,
  ) {
    print('onDragEnd $runtimeType');
  }

  /// Paints the drawing tool on the chart.
  void paint(
    Canvas canvas,
    Size size,
    EpochToX epochToX,
    QuoteToY quoteToY,
    AnimationInfo animationInfo,
    GetDrawingState getDrawingState,
  );
}

/// Interactable drawing for line drawing tool.
class LineInteractableDrawing
    extends InteractableDrawing<LineDrawingToolConfig> {
  /// Initializes [LineInteractableDrawing].
  LineInteractableDrawing({
    required LineDrawingToolConfig config,
    required this.startPoint,
    required this.endPoint,
  }) : super(config: config);

  /// Start point of the line.
  EdgePoint? startPoint;

  /// End point of the line.
  EdgePoint? endPoint;

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

    // Calculate line length
    final double lineLength = (endOffset - startOffset).distance;

    // If line length is too small, treat it as a point
    if (lineLength < 1) {
      return (offset - startOffset).distance <= hitTestMargin;
    }

    // Calculate perpendicular distance from point to line
    // Formula: |((y2-y1)x - (x2-x1)y + x2y1 - y2x1)| / sqrt((y2-y1)² + (x2-x1)²)
    final double distance = ((endOffset.dy - startOffset.dy) * offset.dx -
                (endOffset.dx - startOffset.dx) * offset.dy +
                endOffset.dx * startOffset.dy -
                endOffset.dy * startOffset.dx)
            .abs() /
        lineLength;

    // Check if point is within the line segment (not just the infinite line)
    final double dotProduct =
        (offset.dx - startOffset.dx) * (endOffset.dx - startOffset.dx) +
            (offset.dy - startOffset.dy) * (endOffset.dy - startOffset.dy);

    final bool isWithinRange =
        dotProduct >= 0 && dotProduct <= lineLength * lineLength;

    final result = isWithinRange && distance <= hitTestMargin;
    // Return true if within range and close enough to line (8 pixel margin)
    return result;
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
    final DrawingPaintStyle paintStyle = DrawingPaintStyle();

    if (startPoint != null && endPoint != null) {
      final Offset startOffset =
          Offset(epochToX(startPoint!.epoch), quoteToY(startPoint!.quote));
      final Offset endOffset =
          Offset(epochToX(endPoint!.epoch), quoteToY(endPoint!.quote));

      // Check if this drawing is selected
      final DrawingToolState state = getDrawingState(this);

      // Use glowy paint style if selected, otherwise use normal paint style
      final Paint paint = state == DrawingToolState.selected
          ? paintStyle.glowyLinePaintStyle(lineStyle.color, lineStyle.thickness)
          : paintStyle.linePaintStyle(lineStyle.color, lineStyle.thickness);

      canvas.drawLine(startOffset, endOffset, paint);

      // Draw endpoints with glowy effect if selected
      if (state == DrawingToolState.selected ||
          state == DrawingToolState.hovered) {
        const double markerRadius = 5;
        canvas
          ..drawCircle(
            startOffset,
            markerRadius,
            paintStyle.glowyCirclePaintStyle(lineStyle.color),
          )
          ..drawCircle(
            endOffset,
            markerRadius,
            paintStyle.glowyCirclePaintStyle(lineStyle.color),
          );
      }
    } else {
      if (startPoint != null) {
        _drawPoint(
            startPoint!, epochToX, quoteToY, canvas, paintStyle, lineStyle);
      }

      if (endPoint != null) {
        _drawPoint(
            endPoint!, epochToX, quoteToY, canvas, paintStyle, lineStyle);
      }
    }
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
      Offset(epochToX(startPoint!.epoch), quoteToY(startPoint!.quote)),
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

    // Get the drag delta in screen coordinates
    final Offset delta = details.delta;

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

    // Note: The actual config update should be handled by the InteractiveLayer
    // which has access to the Repository. This method only updates the local
    // startPoint and endPoint properties, which will be reflected in the drawing.
    //
    // The InteractiveLayer should periodically check if the selected drawing's
    // points have changed and update the config in the repository accordingly.
  }

  @override
  LineDrawingToolConfig getUpdatedConfig() =>
      config.copyWith(edgePoints: <EdgePoint>[
        if (startPoint != null) startPoint!,
        if (endPoint != null) endPoint!
      ]);
}
