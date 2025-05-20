import 'dart:async';

import 'package:deriv_chart/src/add_ons/drawing_tools_ui/drawing_tool_config.dart';
import 'package:deriv_chart/src/add_ons/repository.dart';
import 'package:deriv_chart/src/deriv_chart/chart/x_axis/x_axis_model.dart';
import 'package:deriv_chart/src/deriv_chart/interactive_layer/crosshair/crosshair_controller.dart';
import 'package:deriv_chart/src/deriv_chart/interactive_layer/crosshair/crosshair_variant.dart';
import 'package:deriv_chart/src/deriv_chart/interactive_layer/crosshair/crosshair_widget.dart';
import 'package:deriv_chart/src/deriv_chart/interactive_layer/drawing_tool_gesture_recognizer.dart';
import 'package:deriv_chart/src/deriv_chart/chart/gestures/gesture_manager.dart';
import 'package:deriv_chart/src/deriv_chart/chart/multiple_animated_builder.dart';
import 'package:deriv_chart/src/deriv_chart/chart/x_axis/x_axis_model.dart';
import 'package:deriv_chart/src/deriv_chart/interactive_layer/interactable_drawings/drawing_v2.dart';
import 'package:deriv_chart/src/models/axis_range.dart';
import 'package:deriv_chart/src/models/chart_config.dart';
import 'package:deriv_chart/src/theme/chart_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../chart/data_visualization/chart_data.dart';
import '../chart/data_visualization/chart_series/data_series.dart';
import '../chart/data_visualization/drawing_tools/ray/ray_line_drawing.dart';
import '../chart/data_visualization/models/animation_info.dart';
import '../drawing_tool_chart/drawing_tools.dart';
import 'interactable_drawings/interactable_drawing.dart';
import 'interactable_drawing_custom_painter.dart';
import 'interaction_notifier.dart';
import 'interactive_layer_base.dart';
import 'enums/state_change_direction.dart';
import 'interactive_layer_behaviours/interactive_layer_behaviour.dart';

// Define the enum for interaction modes
enum InteractionMode {
  none,
  drawingTool,
  crosshair,
}

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
    required this.crosshairZoomOutAnimation,
    required this.crosshairController,
    required this.crosshairVariant,
    this.showCrosshair = true,
    this.pipSize = 4,
    this.onCrosshairAppeared,
    this.onCrosshairDisappeared,
    required this.quoteRange,
    required this.interactiveLayerBehaviour,
    super.key,
  });

  /// Interactive layer behaviour which defines how interactive layer should
  /// behave in scenarios like adding/dragging, etc.
  final InteractiveLayerBehaviour interactiveLayerBehaviour;

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

  /// Whether to show the crosshair or not.
  final bool showCrosshair;

  /// Number of decimal digits when showing prices in the crosshair.
  final int pipSize;

  /// Called when the crosshair appears.
  final VoidCallback? onCrosshairAppeared;

  /// Called when the crosshair disappears.
  final VoidCallback? onCrosshairDisappeared;

  /// Animation for zooming out the crosshair
  final Animation<double> crosshairZoomOutAnimation;

  /// Crosshair controller
  final CrosshairController crosshairController;

  /// The variant of the crosshair to be used.
  /// This is used to determine the type of crosshair to display.
  /// The default is [CrosshairVariant.smallScreen].
  /// [CrosshairVariant.largeScreen] is mostly for web.
  final CrosshairVariant crosshairVariant;

  /// Chart's y-axis range.
  final QuoteRange quoteRange;

  @override
  State<InteractiveLayer> createState() => _InteractiveLayerState();
}

class _InteractiveLayerState extends State<InteractiveLayer> {
  final List<InteractableDrawing> _interactableDrawings = [];

  /// Timers for debouncing repository updates
  ///
  /// We use a map to have one timer per each drawing tool config. This is
  /// because the request to update the config of different tools can come at
  /// the same time. If we use only one timer a new request from a different
  /// tool will cancel the previous one.
  final Map<String, Timer> _debounceTimers = <String, Timer>{};

  /// Duration for debouncing repository updates (1-sec is a good balance)
  static const Duration _debounceDuration = Duration(seconds: 1);

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
  void _updateConfigInRepository(
    InteractableDrawing<DrawingToolConfig> drawing,
  ) {
    final String? configId = drawing.config.configId;

    if (configId == null) {
      return;
    }

    // Cancel any existing timer
    _debounceTimers[configId]?.cancel();

    // Create a new timer
    _debounceTimers[configId] = Timer(_debounceDuration, () {
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

  DrawingToolConfig _addDrawingToRepo(
      InteractableDrawing<DrawingToolConfig> drawing) {
    final config = drawing
        .getUpdatedConfig()
        .copyWith(configId: DateTime.now().millisecondsSinceEpoch.toString());

    widget.drawingToolsRepo.add(config);

    return config;
  }

  @override
  void dispose() {
    // Cancel the debounce timers when the widget is disposed
    for (final Timer timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

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
      quoteRange: widget.quoteRange,
      interactiveLayerBehaviour: widget.interactiveLayerBehaviour,
      onClearAddingDrawingTool: widget.drawingTools.clearDrawingToolSelection,
      onSaveDrawingChange: _updateConfigInRepository,
      onAddDrawing: _addDrawingToRepo,
      showCrosshair: widget.showCrosshair,
      pipSize: widget.pipSize,
      crosshairZoomOutAnimation: widget.crosshairZoomOutAnimation,
      onCrosshairAppeared: widget.onCrosshairAppeared,
      onCrosshairDisappeared: widget.onCrosshairDisappeared,
      crosshairController: widget.crosshairController,
      crosshairVariant: widget.crosshairVariant,
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
    required this.onAddDrawing,
    required this.crosshairZoomOutAnimation,
    required this.crosshairController,
    required this.crosshairVariant,
    required this.quoteRange,
    required this.interactiveLayerBehaviour,
    this.addingDrawingTool,
    this.onSaveDrawingChange,
    this.showCrosshair = true,
    this.pipSize = 4,
    this.onCrosshairAppeared,
    this.onCrosshairDisappeared,
  });

  final List<InteractableDrawing> drawings;

  final InteractiveLayerBehaviour interactiveLayerBehaviour;

  final Function(InteractableDrawing<DrawingToolConfig>)? onSaveDrawingChange;
  final DrawingToolConfig Function(InteractableDrawing<DrawingToolConfig>)
      onAddDrawing;

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
  final QuoteRange quoteRange;

  /// Whether to show the crosshair or not.
  final bool showCrosshair;

  /// Number of decimal digits when showing prices in the crosshair.
  final int pipSize;

  /// Called when the crosshair appears.
  final VoidCallback? onCrosshairAppeared;

  /// Called when the crosshair disappears.
  final VoidCallback? onCrosshairDisappeared;

  /// Animation for zooming out the crosshair
  final Animation<double> crosshairZoomOutAnimation;

  /// Crosshair controller
  final CrosshairController crosshairController;

  /// The variant of the crosshair to be used.
  /// This is used to determine the type of crosshair to display.
  /// The default is [CrosshairVariant.smallScreen].
  /// [CrosshairVariant.largeScreen] is mostly for web.
  final CrosshairVariant crosshairVariant;

  @override
  State<_InteractiveLayerGestureHandler> createState() =>
      _InteractiveLayerGestureHandlerState();
}

class _InteractiveLayerGestureHandlerState
    extends State<_InteractiveLayerGestureHandler>
    with SingleTickerProviderStateMixin
    implements InteractiveLayerBase {
  late AnimationController _stateChangeController;

  // Use an enum instead of a boolean flag
  InteractionMode _currentInteractionMode = InteractionMode.none;

  // Custom gesture recognizer for drawing tools
  late DrawingToolGestureRecognizer _drawingToolGestureRecognizer;

  static const Curve _stateChangeCurve = Curves.easeInOut;
  final InteractionNotifier _interactionNotifier = InteractionNotifier();

  @override
  AnimationController? get stateChangeAnimationController =>
      _stateChangeController;

  final GlobalKey _layerKey = GlobalKey();

  Size? _size;

  @override
  void initState() {
    super.initState();

    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      setState(() {
        _size =
            (_layerKey.currentContext?.findRenderObject() as RenderBox?)?.size;
      });
    });

    widget.interactiveLayerBehaviour.init(
      interactiveLayer: this,
      onUpdate: () => setState(() {}),
    );

    _stateChangeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize the drawing tool gesture recognizer once
    _drawingToolGestureRecognizer = DrawingToolGestureRecognizer(
      onDrawingToolPanStart: _handleDrawingToolPanStart,
      onDrawingToolPanUpdate: _handleDrawingToolPanUpdate,
      onDrawingToolPanEnd: _handleDrawingToolPanEnd,
      onDrawingToolPanCancel: _handleDrawingToolPanCancel,
      hitTest: _hitTestDrawings,
      onCrosshairCancel: _cancelCrosshair,
      debugOwner: this,
    );
  }

  @override
  void dispose() {
    _drawingToolGestureRecognizer.dispose();
    _stateChangeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _InteractiveLayerGestureHandler oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.addingDrawingTool != null &&
        widget.addingDrawingTool != oldWidget.addingDrawingTool) {
      widget.interactiveLayerBehaviour
          .onAddDrawingTool(widget.addingDrawingTool!);
    }
  }

  @override
  Future<void> animateStateChange(
      StateChangeAnimationDirection direction) async {
    await _runAnimation(direction);
  }

  Future<void> _runAnimation(StateChangeAnimationDirection direction) async {
    if (direction == StateChangeAnimationDirection.forward) {
      _stateChangeController.reset();
      await _stateChangeController.forward();
    } else {
      await _stateChangeController.reverse(from: 1);
    }
  }

  // Update the interaction mode and notify listeners if needed
  void _updateInteractionMode(InteractionMode mode) {
    if (_currentInteractionMode != mode) {
      setState(() {
        _currentInteractionMode = mode;
      });
    }
  }

  // Method to cancel any active crosshair
  void _cancelCrosshair() {
    if (_currentInteractionMode == InteractionMode.crosshair) {
      widget.crosshairController.onExit(const PointerExitEvent());
      _updateInteractionMode(InteractionMode.none);
    }
  }

  // Check if a point hits any drawing
  bool _hitTestDrawings(Offset localPosition) {
    for (final drawing in <DrawingV2>[
      ...widget.drawings,
      ...widget.interactiveLayerBehaviour.previewDrawings
    ]) {
      if (drawing.hitTest(localPosition, epochToX, quoteToY)) {
        return true;
      }
    }
    return false;
  }

  // Handle drawing tool pan start
  void _handleDrawingToolPanStart(DragStartDetails details) {
    // The custom gesture recognizer has already determined that a drawing was hit,
    // so we don't need to check again with _interactiveState.onPanStart
    // Just delegate to the interactive state and update our mode
    widget.interactiveLayerBehaviour.onPanStart(details);
    _updateInteractionMode(InteractionMode.drawingTool);
  }

  // Handle drawing tool pan update
  void _handleDrawingToolPanUpdate(DragUpdateDetails details) {
    final bool affectingDrawing =
        widget.interactiveLayerBehaviour.onPanUpdate(details);

    if (affectingDrawing) {
      _updateInteractionMode(InteractionMode.drawingTool);
    }
  }

  // Handle drawing tool pan end
  void _handleDrawingToolPanEnd(DragEndDetails details) {
    widget.interactiveLayerBehaviour.onPanEnd(details);
    _updateInteractionMode(InteractionMode.none);
  }

  // Handle drawing tool pan cancel
  void _handleDrawingToolPanCancel() {
    _updateInteractionMode(InteractionMode.none);
  }

  void _handleHover(PointerHoverEvent event) {
    if (widget.crosshairVariant == CrosshairVariant.smallScreen) {
      return;
    }
    // This returns true if a drawing tool was hit according to the state
    final bool hitDrawing = widget.interactiveLayerBehaviour.onHover(event);

    // Determine the appropriate interaction mode based on current state
    // If we're hovering over a drawing, we should be in drawing tool mode
    // Otherwise, we should be in normal mode.
    _updateInteractionMode(
        hitDrawing ? InteractionMode.drawingTool : InteractionMode.none);

    // Handle crosshair visibility based on the interaction mode
    if (_currentInteractionMode == InteractionMode.drawingTool) {
      // If we're in drawing tool mode, hide the crosshair
      widget.crosshairController.onExit(const PointerExitEvent());
      return;
    }

    // Otherwise, let the crosshair controller handle the hover
    widget.crosshairController.onHover(event);
  }

  void _handleExit(PointerExitEvent event) {
    // Only handle exit events if we're not in drawing tool mode
    if (_currentInteractionMode != InteractionMode.drawingTool) {
      widget.crosshairController.onExit(event);
    }
  }

  // Tap handler
  void _handleTapUp(TapUpDetails details) {
    final bool hitDrawing = widget.interactiveLayerBehaviour.onTap(details);
    _updateInteractionMode(
        hitDrawing ? InteractionMode.drawingTool : InteractionMode.none);
  }

  // Long press handlers
  void _handleLongPressStart(LongPressStartDetails details) {
    // Only handle long press if we're not already interacting with a drawing
    if (_currentInteractionMode == InteractionMode.none) {
      widget.crosshairController.onLongPressStart(details);
      _updateInteractionMode(InteractionMode.crosshair);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    // Only handle updates if we're in crosshair mode
    if (_currentInteractionMode == InteractionMode.crosshair) {
      widget.crosshairController.onLongPressUpdate(details);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    // Only handle end if we're in crosshair mode
    if (_currentInteractionMode == InteractionMode.crosshair) {
      widget.crosshairController.onLongPressEnd(details);
      _updateInteractionMode(InteractionMode.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final XAxisModel xAxis = context.watch<XAxisModel>();

    // Reconfigure the drawing tool gesture recognizer instead of creating a new one
    _drawingToolGestureRecognizer.reset(
      onDrawingToolPanStart: _handleDrawingToolPanStart,
      onDrawingToolPanUpdate: _handleDrawingToolPanUpdate,
      onDrawingToolPanEnd: _handleDrawingToolPanEnd,
      onDrawingToolPanCancel: _handleDrawingToolPanCancel,
      hitTest: _hitTestDrawings,
      onCrosshairCancel: _cancelCrosshair,
    );

    return Semantics(
      child: MouseRegion(
        onHover: _handleHover,
        onExit: _handleExit,
        child: RawGestureDetector(
          gestures: <Type, GestureRecognizerFactory>{
            // Configure tap recognizer
            TapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (TapGestureRecognizer instance) {
                instance.onTapUp = _handleTapUp;
              },
            ),

            // Configure our custom drawing tool gesture recognizer
            DrawingToolGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                DrawingToolGestureRecognizer>(
              () => _drawingToolGestureRecognizer,
              (DrawingToolGestureRecognizer instance) {
                // Configuration is done in the reset method
              },
            ),

            // Configure long press recognizer
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(),
              (LongPressGestureRecognizer instance) {
                instance
                  ..onLongPressStart = _handleLongPressStart
                  ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
                  ..onLongPressEnd = _handleLongPressEnd;
              },
            ),
          },
          behavior: HitTestBehavior.opaque,
          // Ensure gestures are detected even if the widget is transparent
          // TODO(NA): Move this part into separate widget. InteractiveLayer only cares about the interactions and selected tool movement
          // It can delegate it to an inner component as well. which we can have different interaction behaviours like per platform as well.
          child: AnimatedBuilder(
              animation: _stateChangeController,
              builder: (_, __) {
                final double animationValue =
                    _stateChangeCurve.transform(_stateChangeController.value);

                return Stack(
                  key: _layerKey,
                  fit: StackFit.expand,
                  children: [
                    CrosshairWidget(
                      mainSeries: widget.series,
                      quoteToCanvasY: widget.quoteToY,
                      pipSize: widget.pipSize,
                      crosshairController: widget.crosshairController,
                      crosshairZoomOutAnimation:
                          widget.crosshairZoomOutAnimation,
                      crosshairVariant: widget.crosshairVariant,
                      showCrosshair: widget.showCrosshair,
                    ),
                    ...widget.drawings
                        .map((e) => CustomPaint(
                              foregroundPainter:
                                  InteractableDrawingCustomPainter(
                                      drawing: e,
                                      series: widget.series,
                                      theme: context.watch<ChartTheme>(),
                                      chartConfig: widget.chartConfig,
                                      epochFromX: xAxis.epochFromX,
                                      epochToX: xAxis.xFromEpoch,
                                      quoteToY: widget.quoteToY,
                                      quoteFromY: widget.quoteFromY,
                                      drawingState: widget
                                          .interactiveLayerBehaviour
                                          .getToolState,
                                      currentDrawingState: widget
                                          .interactiveLayerBehaviour
                                          .getToolState(e),
                                      epochRange: EpochRange(
                                        rightEpoch: xAxis.rightBoundEpoch,
                                        leftEpoch: xAxis.leftBoundEpoch,
                                      ),
                                      quoteRange: widget.quoteRange,
                                      animationInfo: AnimationInfo(
                                        stateChangePercent: animationValue,
                                      )
                                      // onDrawingToolClicked: () => _selectedDrawing = e,
                                      ),
                            ))
                        .toList(),
                    ...widget.interactiveLayerBehaviour.previewDrawings
                        .map((e) => CustomPaint(
                              foregroundPainter:
                                  InteractableDrawingCustomPainter(
                                      drawing: e,
                                      series: widget.series,
                                      theme: context.watch<ChartTheme>(),
                                      chartConfig: widget.chartConfig,
                                      epochFromX: xAxis.epochFromX,
                                      epochToX: xAxis.xFromEpoch,
                                      quoteToY: widget.quoteToY,
                                      quoteFromY: widget.quoteFromY,
                                      epochRange: EpochRange(
                                        rightEpoch: xAxis.rightBoundEpoch,
                                        leftEpoch: xAxis.leftBoundEpoch,
                                      ),
                                      quoteRange: widget.quoteRange,
                                      drawingState: widget
                                          .interactiveLayerBehaviour
                                          .getToolState,
                                      currentDrawingState: widget
                                          .interactiveLayerBehaviour
                                          .getToolState(e),
                                      animationInfo: AnimationInfo(
                                          stateChangePercent: animationValue)
                                      // onDrawingToolClicked: () => _selectedDrawing = e,
                                      ),
                            ))
                        .toList(),
                  ],
                );
              }),
        ),
      ),
    );
  }

  void onTap(TapUpDetails details) {
    widget.interactiveLayerBehaviour.onTap(details);
    _interactionNotifier.notify();
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

  @override
  void clearAddingDrawing() => widget.onClearAddingDrawingTool.call();

  @override
  DrawingToolConfig onAddDrawing(
          InteractableDrawing<DrawingToolConfig> drawing) =>
      widget.onAddDrawing.call(drawing);

  @override
  void onSaveDrawing(InteractableDrawing<DrawingToolConfig> drawing) =>
      widget.onSaveDrawingChange?.call(drawing);

  @override
  Size? get layerSize => _size;
}
