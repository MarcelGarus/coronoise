import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/rxdart.dart';
import 'package:time/time.dart';

import 'input.dart';

class NumberOfPeopleInput extends Input {
  late final ExposureNotificationScanner _scanner;
  late final ExposureNotificationRiskAssessor _riskAssessor;
  bool isRunning = false;

  NumberOfPeopleInput() {
    _scanner = ExposureNotificationScanner();
    _riskAssessor = ExposureNotificationRiskAssessor(_scanner);
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (isRunning) {
        value = _riskAssessor.assessRisk();
      }
    });
  }

  @override
  String get name => 'nearby people';

  @override
  double value = 0;

  @override
  double get max => 20;

  @override
  void start() {
    _scanner.start();
    isRunning = true;
  }

  @override
  void stop() {
    _scanner.stop();
    isRunning = false;
  }
}

class ExposureNotificationRiskAssessor {
  final ExposureNotificationScanner scanner;
  final _risksSink = BehaviorSubject<Map<String, double>>();
  late final Stream<Map<String, double>> risks;
  final _notificationsById = <String, ExposureNotification>{};

  ExposureNotificationRiskAssessor(this.scanner) {
    risks = _risksSink.stream;
    scanner.notifications.listen((notification) {
      _notificationsById[notification.device.id.id] = notification;
    });
  }

  void _cleanUpGarbarge() {
    final now = DateTime.now();
    _notificationsById.removeWhere((_, notification) {
      return now.difference(notification.timestamp) > 10.seconds;
    });
  }

  double assessRisk() {
    _cleanUpGarbarge();
    return _notificationsById.values.length.toDouble();
  }
}

@immutable
class ExposureNotification {
  const ExposureNotification({
    required this.timestamp,
    required this.device,
    required this.txPowerLevel,
    required this.rssi,
  });

  static ExposureNotification? from(ScanResult scanResult) {
    final serviceData = scanResult.advertisementData.serviceData[_serviceId];
    if (serviceData == null || serviceData.length != 20) return null;

    return ExposureNotification(
      timestamp: DateTime.now().toUtc(),
      device: scanResult.device,
      txPowerLevel: scanResult.advertisementData.txPowerLevel,
      rssi: scanResult.rssi,
    );
  }

  static final _serviceId = _shortToLongServiceId('FD6F').toLowerCase();
  static String _shortToLongServiceId(String shortServiceId) =>
      '0000$shortServiceId-0000-1000-8000-00805F9B34FB';

  final DateTime timestamp;
  final BluetoothDevice device;
  final int? txPowerLevel;
  final int rssi;
}

class ExposureNotificationScanner {
  static final flutterBlue = FlutterBlue.instance;

  var _running = false;
  final _notificationsSink = BehaviorSubject<ExposureNotification>();
  late final Stream<ExposureNotification> notifications;

  ExposureNotificationScanner() {
    notifications = _notificationsSink.stream;
    _scan();
  }

  void start() => _running = true;
  void stop() => _running = false;

  void _scan() async {
    if (await flutterBlue.isScanning.first) {
      flutterBlue.stopScan();
    }
    while (true) {
      if (_running) {
        try {
          print('Starting scan.');
          final result = await flutterBlue.startScan(
            scanMode: ScanMode.lowLatency,
            timeout: const Duration(seconds: 1),
          );
          print('Stopping scan.');
          await flutterBlue.stopScan();
          final list = (result as List<dynamic>).cast<ScanResult>();
          print('Notifications: $list');
          list
              .map(ExposureNotification.from)
              .whereNotNull()
              .forEach(_notificationsSink.add);
        } catch (e) {
          print('Error while running scan: $e');
        }
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
