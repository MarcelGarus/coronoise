import 'dart:ui';

import 'package:charts_flutter/flutter.dart' as charts;

extension FancyFlutterColor on Color {
  charts.Color get asChartsColor =>
      charts.Color(r: red, g: green, b: blue, a: alpha);
}

extension FancyDouble on double {
  bool isBetween(double lower, double upper) => this >= lower && this < upper;
}
