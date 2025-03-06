import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_deriv_api/api/manually/tick.dart';
import 'package:flutter_deriv_api/api/manually/tick_base.dart';

/// A mock data generator that simulates real-time market data
class MockDataGenerator {
  /// Creates a new instance of [MockDataGenerator]
  MockDataGenerator({
    this.initialPrice = 1000.0,
    this.volatility = 0.02,
    this.trend = 0.0,
  }) {
    _currentPrice = initialPrice;
    _random = math.Random();
  }

  /// The initial price to start generating from
  final double initialPrice;

  /// The volatility factor (0.02 = 2% standard deviation)
  final double volatility;

  /// The trend factor (-0.01 = downward trend, 0.01 = upward trend)
  final double trend;

  late double _currentPrice;
  late math.Random _random;
  Timer? _timer;
  StreamController<TickBase>? _controller;

  /// Starts generating mock data
  Stream<TickBase> start() {
    _controller = StreamController<TickBase>.broadcast(
      onCancel: () {
        _timer?.cancel();
        _controller?.close();
      },
    );

    // Generate a new tick every second
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _generateTick(),
    );

    return _controller!.stream;
  }

  void _generateTick() {
    // Generate a random price movement using a normal distribution
    final double randomFactor = _random.nextDouble() * 2 - 1; // Between -1 and 1
    final double movement = randomFactor * volatility * _currentPrice;

    // Apply the trend
    final double trendMovement = trend * _currentPrice;

    // Calculate new price
    _currentPrice += movement + trendMovement;

    // Ensure price doesn't go negative
    _currentPrice = math.max(_currentPrice, 0.01);

    // Round to 2 decimal places
    _currentPrice = double.parse(_currentPrice.toStringAsFixed(2));

    final Tick tick = Tick(
      ask: _currentPrice,
      bid: _currentPrice - 0.01,
      epoch: DateTime.now(),
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      pipSize: 2,
      quote: _currentPrice,
      symbol: 'R_50',
    );

    _controller?.add(tick);
  }

  /// Stops generating mock data
  void stop() {
    _timer?.cancel();
    _controller?.close();
  }
}