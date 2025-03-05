import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:flutter/widgets.dart';

import '../interactable_drawing.dart';
import 'interactive_selected_tool_state.dart';
import 'interactive_state.dart';

/// The normal state of the interactive layer.
///
/// This class represents the default state of the [InteractiveLayer] when no tools
/// are selected or being added. In this state, tapping on a drawing will select it
/// and transition to the [InteractiveSelectedToolState].
///
/// This is the initial state of the interactive layer and the state it returns to
/// when a tool is deselected or after a tool has been added.
class InteractiveNormalState extends InteractiveState {
  /// Initializes the state with the interactive layer.
  ///
  /// The [interactiveLayer] parameter is passed to the superclass and provides
  /// access to the layer's methods and properties.
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
