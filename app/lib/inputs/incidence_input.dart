import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'input.dart';

class IncidenceInput extends Input {
  bool isRunning = false;

  IncidenceInput() {
    Stream.periodic(const Duration(seconds: 10)).listen((_) async {
      if (isRunning) {
        _getIncidence();
      }
    });
  }

  @override
  String get name => 'incidence';

  @override
  double value = 0;

  @override
  double get max => 10;

  @override
  void start() {
    _enableGps();
    _getIncidence();
    isRunning = true;
  }

  @override
  void stop() {
    isRunning = false;
  }

  Future<void> _getIncidence() async {
    try {
      final response = await http.get(Uri.parse(
        'https://api.corona-zahlen.org/germany/history/hospitalization/1',
      ));
      final json = jsonDecode(response.body);
      final incidence = json['data'].single['incidence7Days'];
      value = incidence.clamp(0.0, max);
    } catch (e) {
      print("Couldn't fetch incidence numbers.");
    }
  }

  Future<bool> _enableGps() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied.');
        return false;
      }
    }

    return true;
  }

  Future<void> _getPosition() async {
    if (!await _enableGps()) return;
    final position = await Geolocator.getCurrentPosition();
    print('We are at position $position');
  }
}
