import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:flutter/widgets.dart';

import '../interactable_drawing.dart';
import 'interactive_normal_state.dart';
import 'interactive_state.dart';

/// The state of the interactive layer when a tool is selected.
class InteractiveSelectedToolState extends InteractiveState {
  /// Initializes the state with the interactive layer and the [selected] tool.
  InteractiveSelectedToolState({
    required this.selected,
    required super.interactiveLayer,
  });

  /// The selected tool.
  final InteractableDrawing selected;

  @override
  DrawingToolState getToolState(
      InteractableDrawing<DrawingToolConfig> drawing) {
    return drawing.config.configId == selected.config.configId
        ? DrawingToolState.selected
        : DrawingToolState.normal;
  }

  @override
  void onPanEnd(DragEndDetails details) {
    selected.onDragEnd(details, epochFromX, quoteFromY, epochToX, quoteToY);
    interactiveLayer.onSaveDrawing(selected);
  }

  @override
  void onPanStart(DragStartDetails details) {
    selected.onDragStart(details, epochFromX, quoteFromY, epochToX, quoteToY);
  }

  @override
  void onPanUpdate(DragUpdateDetails details) {
    selected.onDragUpdate(details, epochFromX, quoteFromY, epochToX, quoteToY);
  }

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

    interactiveLayer.updateStateTo(
      InteractiveNormalState(interactiveLayer: interactiveLayer),
    );
  }
}
