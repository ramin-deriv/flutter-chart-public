import 'package:deriv_chart/src/deriv_chart/chart/gestures/gesture_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'drawing_tools.dart';

/// Interactive layer of the chart package where elements can be drawn and can
/// be interacted with.
class InteractiveLayer extends StatefulWidget {
  const InteractiveLayer({super.key, required this.drawingTools});

  final DrawingTools drawingTools;

  @override
  State<InteractiveLayer> createState() => _InteractiveLayerState();
}

class _InteractiveLayerState extends State<InteractiveLayer> {
  /// 1. Keep the state of the selected tool here, the tool that the focus is on
  /// it right now
  /// 2. provide callback to outside to let them what is the current selected tool
  /// 3. This widget will handle adding a tool, can delegate adding to inner components
  ///    but anyway it will happen here. either directly or indirectly through inner components
  /// 4. This widget knows the current selected tool, will update its position when its interacted
  /// 5. the decision to make which tool is selected based on the user click and it's coordinate will happen here
  /// 6.

  @override
  void initState() {
    super.initState();

    // register the callback
    context.read<GestureManagerState>()
      ..registerCallback(onPanUpdate)
      ..registerCallback(onLongPressStart)
      ..registerCallback(onLongPressMoveUpdate);
  }

  void onPanUpdate(DragUpdateDetails details) {
    // handle pan update
  }

  void onLongPressStart(LongPressStartDetails details) {
    // handle long press start
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    // handle long press move update
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
