import 'dart:collection';
import 'dart:ui' as ui;

import 'package:deriv_chart/deriv_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const ChartShowcaseApp());
}

class ChartShowcaseApp extends StatelessWidget {
  const ChartShowcaseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          ChartLocalization.delegate,
        ],
        supportedLocales: const [Locale('en')],
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const ShowcaseHomePage(),
      );
}

class ShowcaseHomePage extends StatelessWidget {
  const ShowcaseHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Chart Features Showcase'),
        ),
        body: ListView(
          children: [
            _buildFeatureTile(
              context,
              'Simple Line Chart',
              'Basic implementation of a line chart',
              const SimpleLineChartPage(),
            ),
            _buildFeatureTile(
              context,
              'Simple Candle Chart',
              'Basic implementation of a candlestick chart',
              const SimpleCandleChartPage(),
            ),
            _buildFeatureTile(
              context,
              'Line Chart with RSI',
              'Line chart with Relative Strength Index indicator',
              const LineWithIndicatorPage(),
            ),
            _buildFeatureTile(
              context,
              'Bollinger Bands',
              'Candlestick chart with Bollinger Bands overlay',
              const BollingerBandsPage(),
            ),
            _buildFeatureTile(
              context,
              'Chart with Markers',
              'Chart demonstrating up/down markers',
              const ChartWithMarkersPage(),
            ),
            _buildFeatureTile(
              context,
              'Chart with Barriers',
              'Chart showing horizontal and vertical barriers',
              const ChartWithBarriersPage(),
            ),
          ],
        ),
      );

  Widget _buildFeatureTile(
    BuildContext context,
    String title,
    String subtitle,
    Widget page,
  ) =>
      Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (BuildContext context) => page),
          ),
        ),
      );
}

/// Simple Line Chart Example
class SimpleLineChartPage extends StatelessWidget {
  const SimpleLineChartPage({Key? key}) : super(key: key);

  List<Tick> _generateMockData() => List<Tick>.generate(
        100,
        (int index) => Tick(
          epoch: DateTime.now()
              .subtract(Duration(minutes: 100 - index))
              .millisecondsSinceEpoch,
          quote: 100 +
              (50 * (1 + (0.5 * (index % 10) / 10)) * (index % 2 == 0 ? 1 : -1)),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Simple Line Chart'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Chart(
            mainSeries: LineSeries(
              _generateMockData(),
              style: const LineStyle(
                color: Colors.blue,
                thickness: 2,
                hasArea: true,
              ),
            ),
            pipSize: 2,
            granularity: 60000, // 1 minute in milliseconds
          ),
        ),
      );
}

/// Simple Candle Chart Example
class SimpleCandleChartPage extends StatelessWidget {
  const SimpleCandleChartPage({Key? key}) : super(key: key);

  List<Candle> _generateMockData() => List<Candle>.generate(
        50,
        (int index) {
          final double basePrice = 100 + (index % 10) * 5;
          final bool isUp = index % 3 != 0;

          return Candle(
            epoch: DateTime.now()
                .subtract(Duration(hours: 50 - index))
                .millisecondsSinceEpoch,
            high: basePrice + 10,
            low: basePrice - 10,
            open: isUp ? basePrice - 5 : basePrice + 5,
            close: isUp ? basePrice + 5 : basePrice - 5,
          );
        },
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Simple Candle Chart'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Chart(
            mainSeries: CandleSeries(
              _generateMockData(),
              style: const CandleStyle(
                positiveColor: Colors.green,
                negativeColor: Colors.red,
              ),
            ),
            pipSize: 2,
            granularity: 3600000, // 1 hour in milliseconds
          ),
        ),
      );
}

/// Line Chart with RSI Example
class LineWithIndicatorPage extends StatelessWidget {
  const LineWithIndicatorPage({Key? key}) : super(key: key);

  List<Tick> _generateMockData() => List<Tick>.generate(
        100,
        (int index) => Tick(
          epoch: DateTime.now()
              .subtract(Duration(minutes: 100 - index))
              .millisecondsSinceEpoch,
          quote: 100 +
              (30 * (1 + (0.5 * (index % 20) / 10)) * (index % 2 == 0 ? 1 : -1)),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Line Chart with RSI'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Chart(
            mainSeries: LineSeries(
              _generateMockData(),
              style: const LineStyle(
                color: Colors.blue,
                thickness: 2,
                hasArea: true,
              ),
            ),
            granularity: 60000, // 1 minute in milliseconds
            bottomConfigs: [
              RSIIndicatorConfig(
                period: 14,
                lineStyle: const LineStyle(
                  color: Colors.green,
                  thickness: 1,
                ),
                oscillatorLinesConfig: const OscillatorLinesConfig(
                  overboughtValue: 70,
                  oversoldValue: 30,
                  overboughtStyle: LineStyle(color: Colors.red),
                  oversoldStyle: LineStyle(color: Colors.green),
                ),
                showZones: true,
              ),
            ],
            pipSize: 2,
          ),
        ),
      );
}

/// Bollinger Bands Example
class BollingerBandsPage extends StatelessWidget {
  const BollingerBandsPage({Key? key}) : super(key: key);

  List<Candle> _generateMockData() => List<Candle>.generate(
        50,
        (int index) {
          final double basePrice = 100 + 20 * (index % 10) / 10;
          final bool isUp = index % 3 != 0;

          return Candle(
            epoch: DateTime.now()
                .subtract(Duration(hours: 50 - index))
                .millisecondsSinceEpoch,
            high: basePrice + 5,
            low: basePrice - 5,
            open: isUp ? basePrice - 2 : basePrice + 2,
            close: isUp ? basePrice + 2 : basePrice - 2,
          );
        },
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Bollinger Bands'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Chart(
            mainSeries: CandleSeries(
              _generateMockData(),
              style: const CandleStyle(
                positiveColor: Colors.green,
                negativeColor: Colors.red,
              ),
            ),
            overlayConfigs: [
              BollingerBandsIndicatorConfig(
                period: 20,
                standardDeviation: 2,
                movingAverageType: MovingAverageType.exponential,
                upperLineStyle: const LineStyle(color: Colors.purple),
                middleLineStyle: const LineStyle(color: Colors.white),
                lowerLineStyle: const LineStyle(color: Colors.blue),
              ),
            ],
            pipSize: 2,
            granularity: 3600000, // 1 hour in milliseconds
          ),
        ),
      );
}

/// Chart with Markers Example
class ChartWithMarkersPage extends StatelessWidget {
  const ChartWithMarkersPage({Key? key}) : super(key: key);

  List<Tick> _generateMockData() => List<Tick>.generate(
        100,
        (int index) => Tick(
          epoch: DateTime.now()
              .subtract(Duration(minutes: 100 - index))
              .millisecondsSinceEpoch,
          quote: 100 + (30 * (1 + (0.5 * (index % 10) / 10))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final List<Tick> data = _generateMockData();
    final markers = SplayTreeSet<Marker>()
      ..add(
        Marker(
          direction: MarkerDirection.up,
          epoch: data[30].epoch,
          quote: data[30].quote,
        ),
      )
      ..add(
        Marker(
          direction: MarkerDirection.down,
          epoch: data[60].epoch,
          quote: data[60].quote,
        ),
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart with Markers'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Chart(
          mainSeries: LineSeries(
            data,
            style: const LineStyle(
              color: Colors.blue,
              thickness: 2,
              hasArea: true,
            ),
          ),
          markerSeries: MarkerSeries(
            markers,
            markerIconPainter: SimpleMarkerIconPainter(),
          ),
          granularity: 60000, // 1 minute in milliseconds
          pipSize: 2,
        ),
      ),
    );
  }
}

/// A simple implementation of MarkerIconPainter that draws triangles
class SimpleMarkerIconPainter extends MarkerIconPainter {
  @override
  void paintMarker(
    ui.Canvas canvas,
    ui.Offset start,
    ui.Offset end,
    MarkerDirection direction,
    MarkerStyle style,
  ) {
    final paint = ui.Paint()
      ..color = direction == MarkerDirection.up ? Colors.green : Colors.red
      ..style = ui.PaintingStyle.fill;

    final path = ui.Path();
    final midX = (start.dx + end.dx) / 2;
    
    if (direction == MarkerDirection.up) {
      path.moveTo(midX, start.dy);
      path.lineTo(end.dx, end.dy);
      path.lineTo(start.dx, end.dy);
    } else {
      path.moveTo(midX, end.dy);
      path.lineTo(end.dx, start.dy);
      path.lineTo(start.dx, start.dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }
}

/// Chart with Barriers Example
class ChartWithBarriersPage extends StatelessWidget {
  const ChartWithBarriersPage({Key? key}) : super(key: key);

  List<Tick> _generateMockData() => List<Tick>.generate(
        100,
        (int index) => Tick(
          epoch: DateTime.now()
              .subtract(Duration(minutes: 100 - index))
              .millisecondsSinceEpoch,
          quote: 100 + (30 * (1 + (0.5 * (index % 10) / 10))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final List<Tick> data = _generateMockData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart with Barriers'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
          child: Chart(
            mainSeries: LineSeries(
              data,
              style: const LineStyle(
                color: Colors.blue,
                thickness: 2,
                hasArea: true,
              ),
            ),
            granularity: 60000, // 1 minute in milliseconds
            annotations: [
            HorizontalBarrier(
              data[50].quote,
              title: 'Resistance',
              style: const HorizontalBarrierStyle(
                color: Colors.red,
                isDashed: true,
              ),
            ),
            HorizontalBarrier(
              data[20].quote,
              title: 'Support',
              style: const HorizontalBarrierStyle(
                color: Colors.green,
                isDashed: true,
              ),
            ),
            VerticalBarrier(
              data[70].epoch,
              title: 'Event',
              style: const VerticalBarrierStyle(
                color: Colors.yellow,
              ),
            ),
          ],
          pipSize: 2,
        ),
      ),
    );
  }
}
