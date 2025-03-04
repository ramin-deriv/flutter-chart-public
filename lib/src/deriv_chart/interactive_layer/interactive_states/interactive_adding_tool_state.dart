import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:flutter/widgets.dart';

import '../interactable_drawing.dart';
import 'interactive_normal_state.dart';
import 'interactive_state.dart';

/// The state of the interactive layer when a tool is being added.
class InteractiveAddingToolState extends InteractiveState {
  /// Initializes the state with the interactive layer and the [addingTool].
  InteractiveAddingToolState(
    this.addingTool, {
    required super.interactiveLayer,
  });

  /// The tool being added.
  final DrawingToolConfig addingTool;

  InteractableDrawing<DrawingToolConfig>? _addingDrawing;

  @override
  List<InteractableDrawing<DrawingToolConfig>> get additionalDrawings =>
      [if (_addingDrawing != null) _addingDrawing!];

  @override
  DrawingToolState getToolState(
    InteractableDrawing<DrawingToolConfig> drawing,
  ) =>
      drawing.config.configId == addingTool.configId
          ? DrawingToolState.adding
          : DrawingToolState.normal;

  @override
  void onPanEnd(DragEndDetails details) {}

  @override
  void onPanStart(DragStartDetails details) {}

  @override
  void onPanUpdate(DragUpdateDetails details) {}

  @override
  void onTap(TapUpDetails details) {
    _addingDrawing ??= addingTool.getInteractableDrawing();

    _addingDrawing!
        .onCreateTap(details, epochFromX, quoteFromY, epochToX, quoteToY, () {
      interactiveLayer
        ..clearAddingDrawing()
        ..onAddDrawing(_addingDrawing!)
        ..updateStateTo(
          InteractiveNormalState(interactiveLayer: interactiveLayer),
        );
    });
  }
}
