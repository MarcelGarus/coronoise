import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'input.dart';

class IncidenceInput extends Input {
  bool isRunning = false;

  IncidenceInput() {
    Stream.periodic(const Duration(hours: 1)).listen((_) async {
      if (isRunning) {
        _getIncidence();
      }
    });
  }

  @override
  String get name => 'incidence';

  @override
  double value = 1000;

  @override
  double get max => 3000;

  @override
  void start() {
    _getIncidence();
    isRunning = true;
  }

  @override
  void stop() {
    isRunning = false;
  }

  // For now, the incidence is just hardcoded to Potsdam. In the future, we may
  // choose to get the right one based on our GPS coordinates, but that's out of
  // scope for now.
  Future<void> _getIncidence() async {
    try {
      final response = await http.get(Uri.parse(
        'https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_Landkreisdaten/FeatureServer/0/query?where=1%3D1&outFields=RS,GEN,EWZ,cases,deaths,county,last_update,cases7_lk,death7_lk,BL&returnGeometry=false&outSR=4326&f=json',
      ));
      final json = jsonDecode(response.body);
      final potsdamInfo = ((json['features'] as List<dynamic>)
                  .cast<Map<dynamic, dynamic>>()
                  .firstWhere((it) => it['attributes']['GEN'] == 'Potsdam')[
              'attributes'] as Map<dynamic, dynamic>)
          .cast<String, dynamic>();
      final numPeople = potsdamInfo['EWZ'] as int;
      final cases7days = potsdamInfo['cases7_lk'] as int;
      final incidence = cases7days * 100000 / numPeople;
      print('The incidence is $incidence');
      value = incidence.clamp(0.0, max);
    } catch (e) {
      print("Couldn't fetch incidence numbers: $e");
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
