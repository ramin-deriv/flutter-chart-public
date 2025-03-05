import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:flutter/widgets.dart';

import '../interactable_drawing.dart';
import 'interactive_normal_state.dart';
import 'interactive_state.dart';

/// The state of the interactive layer when a tool is selected.
///
/// This class represents the state of the [InteractiveLayer] when a drawing tool
/// is selected by the user. In this state, the selected tool can be manipulated
/// through drag gestures, and tapping on empty space will return to the normal state.
///
/// It handles user interactions specifically for when a drawing tool is selected,
/// providing appropriate responses to gestures and maintaining the selected state.
class InteractiveSelectedToolState extends InteractiveState {
  /// Initializes the state with the interactive layer and the [selected] tool.
  ///
  /// The [selected] parameter is the drawing tool that has been selected by the user
  /// and will respond to manipulation gestures.
  ///
  /// The [interactiveLayer] parameter is passed to the superclass and provides
  /// access to the layer's methods and properties.
  InteractiveSelectedToolState({
    required this.selected,
    required super.interactiveLayer,
  });

  /// The selected tool.
  ///
  /// This is the drawing tool that is currently selected and will respond to
  /// manipulation gestures. It will be rendered with a selected appearance.
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
