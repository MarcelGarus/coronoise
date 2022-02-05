abstract class Input {
  String get name;
  double get value;
  double get max;
  set value(double value);

  double get normalizedValue => value / max;

  void start();
  void stop();
}
