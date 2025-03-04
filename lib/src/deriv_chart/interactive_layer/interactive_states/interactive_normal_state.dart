import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:flutter/widgets.dart';

import '../interactable_drawing.dart';
import 'interactive_selected_tool_state.dart';
import 'interactive_state.dart';

/// The normal state of the interactive layer.
class InteractiveNormalState extends InteractiveState {
  /// Initializes the state with the interactive layer.
  InteractiveNormalState({required super.interactiveLayer});

  @override
  DrawingToolState getToolState(
    InteractableDrawing<DrawingToolConfig> drawing,
  ) =>
      DrawingToolState.normal;

  @override
  void onPanEnd(DragEndDetails details) {}

  @override
  void onPanStart(DragStartDetails details) {}

  @override
  void onPanUpdate(DragUpdateDetails details) {}

  @override
  void onTap(TapUpDetails details) {
    for (final drawing in interactiveLayer.drawings) {
      if (drawing.hitTest(
        details.localPosition,
        epochToX,
        quoteToY,
      )) {
        interactiveLayer.updateStateTo(
          InteractiveSelectedToolState(
            selected: drawing,
            interactiveLayer: interactiveLayer,
          ),
        );
        return;
      }
    }
  }
}
