import 'package:deriv_chart/deriv_chart.dart';
import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:deriv_chart/src/add_ons/repository.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/data_series.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/data_model/draggable_edge_point.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/data_model/edge_point.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/data_model/point.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/drawing_tools/drawing.dart';
import 'package:deriv_chart/src/deriv_chart/chart/gestures/gesture_manager.dart';
import 'package:deriv_chart/src/deriv_chart/chart/x_axis/x_axis_model.dart';
import 'package:deriv_chart/src/models/chart_config.dart';
import 'package:deriv_chart/src/theme/chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../chart/data_visualization/drawing_tools/drawing_data.dart';
import '../chart/data_visualization/drawing_tools/ray/ray_line_drawing.dart';
import '../chart/y_axis/y_axis_config.dart';
import 'drawing_tools.dart';

/// Interactive layer of the chart package where elements can be drawn and can
/// be interacted with.
class InteractiveLayer extends StatefulWidget {
  const InteractiveLayer({
    super.key,
    required this.drawingTools,
    required this.series,
    required this.chartConfig,
    required this.quoteToCanvasY,
    required this.quoteFromCanvasY,
    required this.epochToCanvasX,
    this.selectedDrawingTool,
  });

  final DrawingTools drawingTools;
  final DataSeries<Tick> series;
  final ChartConfig chartConfig;
  final QuoteToY quoteToCanvasY;
  final QuoteFromY quoteFromCanvasY;
  final EpochToX epochToCanvasX;

  /// Selected drawing tool.
  final DrawingToolConfig? selectedDrawingTool;

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
  ///

  DraggableEdgePoint _draggableStartPoint = DraggableEdgePoint();
  DraggableEdgePoint _draggableMiddlePoint = DraggableEdgePoint();
  DraggableEdgePoint _draggableEndPoint = DraggableEdgePoint();
  bool isTouchHeld = false;

  InteractableDrawing? _selectedDrawing;

  List<InteractableDrawing> _interactableDrawings = [];

  @override
  void initState() {
    super.initState();

    _setDrawingsFromConfigs();

    // register the callback
    context.read<GestureManagerState>()
      ..registerCallback(onPanUpdate)
      ..registerCallback(onLongPressStart)
      ..registerCallback(onLongPressMoveUpdate);
  }

  @override
  void didUpdateWidget(covariant InteractiveLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    _setDrawingsFromConfigs();
  }

  void _setDrawingsFromConfigs() {
    _interactableDrawings.clear();

    final Repository<DrawingToolConfig> repo =
        context.watch<Repository<DrawingToolConfig>>();
    for (final config in repo.items) {
      _interactableDrawings.add(config.getInteractableDrawing());
    }
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
    final XAxisModel xAxis = context.watch<XAxisModel>();
    return Stack(
      fit: StackFit.expand,
      children: [
        ..._interactableDrawings
            .map((e) => CustomPaint(
                  foregroundPainter: _DrawingPainter(
                    drawing: e,
                    series: widget.series,
                    config: e.config,
                    theme: context.watch<ChartTheme>(),
                    chartConfig: widget.chartConfig,
                    epochFromX: xAxis.epochFromX,
                    epochToX: xAxis.xFromEpoch,
                    quoteToY: widget.quoteToCanvasY,
                    quoteFromY: widget.quoteFromCanvasY,
                    draggableStartPoint: _draggableStartPoint,
                    draggableMiddlePoint: _draggableMiddlePoint,
                    isTouchHeld: isTouchHeld,
                    isDrawingToolSelected: widget.selectedDrawingTool != null,
                    draggableEndPoint: _draggableEndPoint,
                    leftEpoch: xAxis.leftBoundEpoch,
                    rightEpoch: xAxis.rightBoundEpoch,
                    onDrawingToolClicked: (DrawingData drawingData) {
                      print('#### onDrawingToolClicked ${drawingData.id}');
                      // if (widget.selectedDrawingTool != null &&
                      //     widget.selectedDrawingTool!.configId != e.id) {
                      //   widget.drawingTools.clearDrawingToolSelection();
                      // }
                      // widget.drawingTools.onMouseEnter(e.id);
                    },
                    updatePositionCallback: (
                      EdgePoint edgePoint,
                      DraggableEdgePoint draggableEdgePoint,
                    ) {
                      return draggableEdgePoint.updatePosition(
                        edgePoint.epoch,
                        edgePoint.quote,
                        xAxis.xFromEpoch,
                        widget.quoteToCanvasY,
                      );
                    },
                    setIsOverStartPoint: ({
                      required bool isOverPoint,
                    }) {
                      // isOverStartPoint = isOverPoint;
                    },
                    setIsOverMiddlePoint: ({
                      required bool isOverPoint,
                    }) {
                      // isOverMiddlePoint = isOverPoint;
                    },
                    setIsOverEndPoint: ({
                      required bool isOverPoint,
                    }) {
                      // isOverEndPoint = isOverPoint;
                    },
                  ),
                ))
            .toList(),
      ],
    );
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter({
    required this.drawing,
    required this.series,
    required this.config,
    required this.theme,
    required this.chartConfig,
    required this.epochFromX,
    required this.epochToX,
    required this.quoteToY,
    required this.quoteFromY,
    required this.draggableStartPoint,
    required this.setIsOverStartPoint,
    required this.updatePositionCallback,
    required this.leftEpoch,
    required this.rightEpoch,
    required this.onDrawingToolClicked,
    this.isDrawingToolSelected = false,
    this.isTouchHeld = false,
    this.draggableMiddlePoint,
    this.draggableEndPoint,
    this.setIsOverMiddlePoint,
    this.setIsOverEndPoint,
  });

  final InteractableDrawing drawing;
  final DataSeries<Tick> series;
  final DrawingToolConfig config;
  final ChartTheme theme;
  final ChartConfig chartConfig;
  final bool isDrawingToolSelected;
  final bool isTouchHeld;
  final int Function(double x) epochFromX;
  final double Function(int x) epochToX;
  final double Function(double y) quoteToY;
  final DraggableEdgePoint draggableStartPoint;
  final DraggableEdgePoint? draggableMiddlePoint;
  final DraggableEdgePoint? draggableEndPoint;
  final void Function({required bool isOverPoint}) setIsOverStartPoint;
  final void Function({required bool isOverPoint})? setIsOverMiddlePoint;
  final void Function({required bool isOverPoint})? setIsOverEndPoint;
  final Point Function(
    EdgePoint edgePoint,
    DraggableEdgePoint draggableEdgePoint,
  ) updatePositionCallback;

  /// Current left epoch of the chart.
  final int leftEpoch;

  /// Current right epoch of the chart.
  final int rightEpoch;

  double Function(double) quoteFromY;

  final Function(DrawingData) onDrawingToolClicked;

  @override
  void paint(Canvas canvas, Size size) {
    YAxisConfig.instance.yAxisClipping(canvas, size, () {
      // TODO(NA): Paint the [drawing]
    });
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) =>
      // TODO(NA): Return true/false based on the [drawing] state
      true;

  @override
  bool shouldRebuildSemantics(_DrawingPainter oldDelegate) => false;

  @override
  bool hitTest(Offset position) => drawing.hitTest(position);
}
