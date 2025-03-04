import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_data.dart';
import 'package:flutter/widgets.dart';

import '../interactable_drawing.dart';
import '../interactive_layer_base.dart';

/// The state of the interactive layer.
abstract class InteractiveState {
  /// Initializes the state with the interactive layer.
  InteractiveState({required this.interactiveLayer});

  /// Returns the state of the drawing tool.
  DrawingToolState getToolState(InteractableDrawing<DrawingToolConfig> drawing);

  /// Additional drawings of the state to be drawn on top of the main drawings.
  List<InteractableDrawing<DrawingToolConfig>> get additionalDrawings => [];

  /// The interactive layer.
  final InteractiveLayerBase interactiveLayer;

  /// Converts x to epoch.
  EpochFromX get epochFromX => interactiveLayer.epochFromX;

  /// Converts y to quote.
  QuoteFromY get quoteFromY => interactiveLayer.quoteFromY;

  /// Converts epoch to x.
  EpochToX get epochToX => interactiveLayer.epochToX;

  /// Converts quote to y.
  QuoteToY get quoteToY => interactiveLayer.quoteToY;

  /// Handles tap event.
  void onTap(TapUpDetails details);

  /// Handles pan update event.
  void onPanUpdate(DragUpdateDetails details);

  /// Handles pan end event.
  void onPanEnd(DragEndDetails details);

  /// Handles pan start event.
  void onPanStart(DragStartDetails details);
}
