// Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'dart:developer';

import '../utils/settings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'screens/bluetooth_off_screen.dart';
import 'screens/scan_screen.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.warning, color: true);
  runApp(const FlutterBlueApp());
}

//
// This widget shows BluetoothOffScreen or
// ScanScreen depending on the adapter state
//
class FlutterBlueApp extends StatefulWidget {
  const FlutterBlueApp({super.key});

  @override
  State<FlutterBlueApp> createState() => _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  late final Future neededFutures;

  final AppSettings _prefs = AppSettings();
  late Future _prefsFuture = _prefs.initPrefs();

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  bool _locationState = false;

  late final _locationFuture =
      Geolocator.isLocationServiceEnabled().then((v) => {_locationState = v});
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    neededFutures = Future.wait([_prefsFuture, _locationFuture]);
    super.initState();

    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Widget screen = _adapterState == BluetoothAdapterState.on
    //     ? const ScanScreen()
    //     : const BluetoothOffScreen();

    return MaterialApp(
      color: const Color.fromARGB(255, 3, 244, 43),
      home: FutureBuilder(
          future: neededFutures,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (_prefs.getGPSSetting() == false &&
                  _adapterState == BluetoothAdapterState.on) {
                //if we don't need gps just check for bluetooth
                return const ScanScreen();
              }
              if (_prefs.getGPSSetting() == true && _locationState == false) {
                // if we need gps and it is disabled
                return BluetoothOffScreen(
                    prefs: _prefs, gpsStatus: _locationState);
              }
              return BluetoothOffScreen(
                  prefs: _prefs, gpsStatus: _locationState);
            }
            return const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }),
      navigatorObservers: [BluetoothAdapterStateObserver()],
    );
  }
}

//
// This observer listens for Bluetooth Off and dismisses the DeviceScreen
//
class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/DeviceScreen') {
      // Start listening to Bluetooth state changes when a new route is pushed
      _adapterStateSubscription ??=
          FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on) {
          // Pop the current route if Bluetooth is off
          navigator?.pop();
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    // Cancel the subscription when the route is popped
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}
