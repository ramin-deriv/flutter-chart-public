import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
