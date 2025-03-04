import 'dart:async';

import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:deriv_chart/src/add_ons/repository.dart';
import 'package:deriv_chart/src/deriv_chart/chart/gestures/gesture_manager.dart';
import 'package:deriv_chart/src/deriv_chart/chart/x_axis/x_axis_model.dart';
import 'package:deriv_chart/src/models/chart_config.dart';
import 'package:deriv_chart/src/theme/chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../chart/data_visualization/chart_data.dart';
import '../chart/data_visualization/chart_series/data_series.dart';
import '../chart/data_visualization/drawing_tools/ray/ray_line_drawing.dart';
import '../drawing_tool_chart/drawing_tools.dart';
import 'interactable_drawing.dart';
import 'interactable_drawing_custom_painter.dart';
// ignore_for_file: public_member_api_docs

/// Interactive layer of the chart package where elements can be drawn and can
/// be interacted with.
class InteractiveLayer extends StatefulWidget {
  /// Initializes the interactive layer.
  const InteractiveLayer({
    required this.drawingTools,
    required this.series,
    required this.chartConfig,
    required this.quoteToCanvasY,
    required this.quoteFromCanvasY,
    required this.epochToCanvasX,
    required this.epochFromCanvasX,
    required this.drawingToolsRepo,
    super.key,
  });

  /// Drawing tools.
  final DrawingTools drawingTools;

  /// Drawing tools repo.
  final Repository<DrawingToolConfig> drawingToolsRepo;

  /// Main Chart series
  final DataSeries<Tick> series;

  /// Chart configuration
  final ChartConfig chartConfig;

  /// Converts quote to canvas Y coordinate.
  final QuoteToY quoteToCanvasY;

  /// Converts canvas Y coordinate to quote.
  final QuoteFromY quoteFromCanvasY;

  /// Converts canvas X coordinate to epoch.
  final EpochFromX epochFromCanvasX;

  /// Converts epoch to canvas X coordinate.
  final EpochToX epochToCanvasX;

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

  final List<InteractableDrawing> _interactableDrawings = [];

  /// Timer for debouncing repository updates
  Timer? _debounceTimer;

  /// Duration for debouncing repository updates (300ms is a good balance)
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();

    widget.drawingToolsRepo.addListener(_setDrawingsFromConfigs);
  }

  void _setDrawingsFromConfigs() {
    _interactableDrawings.clear();

    for (final config in widget.drawingToolsRepo.items) {
      _interactableDrawings.add(config.getInteractableDrawing());
    }

    setState(() {});
  }

  /// Updates the config in the repository with debouncing
  void _updateConfigInRepository(InteractableDrawing<dynamic> drawing) {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Create a new timer
    _debounceTimer = Timer(_debounceDuration, () {
      // Only proceed if the widget is still mounted
      if (!mounted) {
        return;
      }

      final Repository<DrawingToolConfig> repo =
          context.read<Repository<DrawingToolConfig>>();

      // Find the index of the config in the repository
      final int index = repo.items
          .indexWhere((config) => config.configId == drawing.config.configId);

      if (index == -1) {
        return; // Config not found
      }

      // Update the config in the repository
      repo.updateAt(index, drawing.getUpdatedConfig());
    });
  }

  void _addDrawingToRepo(InteractableDrawing<dynamic> drawing) =>
      widget.drawingToolsRepo.add(drawing.getUpdatedConfig());

  @override
  void dispose() {
    // Cancel the debounce timer when the widget is disposed
    _debounceTimer?.cancel();

    widget.drawingToolsRepo.removeListener(_setDrawingsFromConfigs);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InteractiveLayerGestureHandler(
      drawings: _interactableDrawings,
      epochFromX: widget.epochFromCanvasX,
      quoteFromY: widget.quoteFromCanvasY,
      epochToX: widget.epochToCanvasX,
      quoteToY: widget.quoteToCanvasY,
      series: widget.series,
      chartConfig: widget.chartConfig,
      addingDrawingTool: widget.drawingTools.selectedDrawingTool,
      onClearAddingDrawingTool: widget.drawingTools.clearDrawingToolSelection,
      onSaveDrawingChange: _updateConfigInRepository,
      onAddDrawing: _addDrawingToRepo,
    );
  }
}

class _InteractiveLayerGestureHandler extends StatefulWidget {
  const _InteractiveLayerGestureHandler({
    required this.drawings,
    required this.epochFromX,
    required this.quoteFromY,
    required this.epochToX,
    required this.quoteToY,
    required this.series,
    required this.chartConfig,
    required this.onClearAddingDrawingTool,
    this.addingDrawingTool,
    this.onSaveDrawingChange,
    this.onAddDrawing,
  });

  final List<InteractableDrawing> drawings;

  final Function(InteractableDrawing<dynamic>)? onSaveDrawingChange;
  final Function(InteractableDrawing<dynamic>)? onAddDrawing;

  final DrawingToolConfig? addingDrawingTool;

  /// To be called whenever adding the [addingDrawingTool] is done to clear it.
  final VoidCallback onClearAddingDrawingTool;

  /// Main Chart series
  final DataSeries<Tick> series;

  /// Chart configuration
  final ChartConfig chartConfig;

  final EpochFromX epochFromX;
  final QuoteFromY quoteFromY;
  final EpochToX epochToX;
  final QuoteToY quoteToY;

  @override
  State<_InteractiveLayerGestureHandler> createState() =>
      _InteractiveLayerGestureHandlerState();
}

class _InteractiveLayerGestureHandlerState
    extends State<_InteractiveLayerGestureHandler>
    implements InteractiveLayerBase {
  // InteractableDrawing? _selectedDrawing;

  late InteractiveState _interactiveState;

  @override
  void initState() {
    super.initState();

    _interactiveState = InteractiveNormalState(interactiveLayer: this);

    // register the callback
    context.read<GestureManagerState>().registerCallback(onTap);
  }

  @override
  void didUpdateWidget(covariant _InteractiveLayerGestureHandler oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.addingDrawingTool != null) {
      updateStateTo(
        InteractiveAddingToolState(
          widget.addingDrawingTool!,
          interactiveLayer: this,
        ),
      );
    }
  }

  @override
  void updateStateTo(InteractiveState state) =>
      setState(() => _interactiveState = state);

  @override
  Widget build(BuildContext context) {
    final XAxisModel xAxis = context.watch<XAxisModel>();
    return Semantics(
      child: GestureDetector(
        onTapUp: (details) => _interactiveState.onTap(details),
        onPanStart: (details) => _interactiveState.onPanStart(details),
        onPanUpdate: (details) => _interactiveState.onPanUpdate(details),
        onPanEnd: (details) => _interactiveState.onPanEnd(details),
        // TODO(NA): Move this part into separate widget. InteractiveLayer only cares about the interactions and selected tool movement
        // It can delegate it to an inner component as well. which we can have different interaction behaviours like per platform as well.
        child: Stack(
          fit: StackFit.expand,
          children: [
            ...widget.drawings
                .map((e) => CustomPaint(
                      foregroundPainter: InteractableDrawingCustomPainter(
                        drawing: e,
                        series: widget.series,
                        theme: context.watch<ChartTheme>(),
                        chartConfig: widget.chartConfig,
                        epochFromX: xAxis.epochFromX,
                        epochToX: xAxis.xFromEpoch,
                        quoteToY: widget.quoteToY,
                        quoteFromY: widget.quoteFromY,
                        getDrawingState: _interactiveState.getToolState,
                        // onDrawingToolClicked: () => _selectedDrawing = e,
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  void onTap(TapUpDetails details) {
    _interactiveState.onTap(details);
  }

  @override
  List<InteractableDrawing<DrawingToolConfig>> get drawings => widget.drawings;

  @override
  EpochFromX get epochFromX => widget.epochFromX;

  @override
  EpochToX get epochToX => widget.epochToX;

  @override
  QuoteFromY get quoteFromY => widget.quoteFromY;

  @override
  QuoteToY get quoteToY => widget.quoteToY;
}

abstract class InteractiveState {
  InteractiveState({required this.interactiveLayer});

  DrawingToolState getToolState(InteractableDrawing<DrawingToolConfig> drawing);

  final InteractiveLayerBase interactiveLayer;

  EpochFromX get epochFromX => interactiveLayer.epochFromX;

  QuoteFromY get quoteFromY => interactiveLayer.quoteFromY;

  EpochToX get epochToX => interactiveLayer.epochToX;

  QuoteToY get quoteToY => interactiveLayer.quoteToY;

  void onTap(TapUpDetails details);

  void onPanUpdate(DragUpdateDetails details);

  void onPanEnd(DragEndDetails details);

  void onPanStart(DragStartDetails details);
}

class InteractiveNormalState extends InteractiveState {
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

class InteractiveSelectedToolState extends InteractiveState {
  InteractiveSelectedToolState({
    required this.selected,
    required super.interactiveLayer,
  });

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

    interactiveLayer.updateStateTo(
        InteractiveNormalState(interactiveLayer: interactiveLayer));
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

class InteractiveAddingToolState extends InteractiveState {
  InteractiveAddingToolState(
    this.addingTool, {
    required super.interactiveLayer,
  });

  final DrawingToolConfig addingTool;

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
  void onTap(TapUpDetails details) {}
}

abstract class InteractiveLayerBase {
  void updateStateTo(InteractiveState state);

  List<InteractableDrawing<DrawingToolConfig>> get drawings;

  EpochFromX get epochFromX;

  QuoteFromY get quoteFromY;

  EpochToX get epochToX;

  QuoteToY get quoteToY;
}
