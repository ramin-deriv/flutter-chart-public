import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:flutter/gestures.dart';

import '../interactable_drawing.dart';
import 'interactive_state.dart';

/// The state of the interactive layer when a tool is hovered.
///
/// Defined as mixin so that it can be combined with other states meaning that
/// other states can also have hover functionality.
mixin InteractiveHoverState on InteractiveState {
  InteractableDrawing<DrawingToolConfig>? _hoveredTool;

  @override
  DrawingToolState getToolState(
      InteractableDrawing<DrawingToolConfig> drawing) {
    return drawing == _hoveredTool
        ? DrawingToolState.hovered
        : DrawingToolState.normal;
  }

  @override
  void onHover(PointerHoverEvent event) {
    super.onHover(event);

    final hoveredTool = anyDrawingHit(event.localPosition);

    if (hoveredTool == _hoveredTool) {
      return;
    }

    if (hoveredTool != _hoveredTool) {
      _hoveredTool = hoveredTool;
    } else {
      _hoveredTool = null;
    }
  }
}
