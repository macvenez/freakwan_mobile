import 'dart:io';

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:geolocator/geolocator.dart';

import 'scan_screen.dart';

import '../utils/settings.dart';
import '../utils/snackbar.dart';

class BluetoothOffScreen extends StatefulWidget {
  const BluetoothOffScreen(
      {super.key, required this.prefs, required this.gpsStatus});

  final AppSettings prefs;

  final bool gpsStatus;

  @override
  State<BluetoothOffScreen> createState() => _BluetoothOffScreenState();
}

class _BluetoothOffScreenState extends State<BluetoothOffScreen> {
  BluetoothAdapterState _adapterState = FlutterBluePlus.adapterStateNow;

  late ServiceStatus _locationState =
      widget.gpsStatus ? ServiceStatus.enabled : ServiceStatus.disabled;

  late final _locationFuture = Geolocator.isLocationServiceEnabled().then((v) =>
      {_locationState = v ? ServiceStatus.enabled : ServiceStatus.disabled});

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  late StreamSubscription<ServiceStatus> _locationServiceStateSubscription;

  //bool locationEnabled = Geolocator.isLocationServiceEnabled();
  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      checkPermissionsLoadScreen();
      if (mounted) {
        setState(() {
          _adapterState = state;
        });
      }
    });

    _locationServiceStateSubscription =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      checkPermissionsLoadScreen();
      if (mounted) {
        setState(() {
          _locationState = status;
        });
      }
    });
  }

  void checkPermissionsLoadScreen() {
    if (widget.prefs.getGPSSetting() == false &&
        _adapterState == BluetoothAdapterState.on) {
      // we only need BT, we can move to scan screen
      MaterialPageRoute route = MaterialPageRoute(
          builder: (context) => ScanScreen(),
          settings: const RouteSettings(name: '/ScanScreen'));
      Navigator.of(context).push(route);
    }
    if (widget.prefs.getGPSSetting() == true &&
        _adapterState == BluetoothAdapterState.on &&
        _locationState == ServiceStatus.enabled) {
      // we need BT and GPS, we have both of them, move to scan screen
      MaterialPageRoute route = MaterialPageRoute(
          builder: (context) => ScanScreen(),
          settings: const RouteSettings(name: '/ScanScreen'));
      Navigator.of(context).push(route);
    }
  }

  Widget buildBluetoothIcon(BuildContext context) {
    if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on) {
      return const Icon(
        Icons.bluetooth,
        size: 200.0,
        color: Colors.white54,
      );
    }
    return const Icon(
      Icons.bluetooth_disabled,
      size: 200.0,
      color: Colors.white54,
    );
  }

  Widget buildLocationIcon(BuildContext context) {
    if (_locationState == ServiceStatus.enabled) {
      return const Icon(
        Icons.my_location,
        size: 200.0,
        color: Colors.white54,
      );
    }
    return const Icon(
      Icons.location_disabled,
      size: 200.0,
      color: Colors.white54,
    );
  }

  Widget buildBluetoothTitle(BuildContext context) {
    String? state = _adapterState.toString().split(".").last;
    return Text(
      'Bluetooth Adapter is ${state ?? 'not available'}',
      style: Theme.of(context)
          .primaryTextTheme
          .titleSmall
          ?.copyWith(color: Colors.white),
    );
  }

  Widget buildLocationTitle(BuildContext context) {
    String status;
    if (_locationState == ServiceStatus.disabled) {
      status = "disabled";
    } else {
      status = "enabled";
    }

    return Text(
      'Location is $status',
      style: Theme.of(context)
          .primaryTextTheme
          .titleSmall
          ?.copyWith(color: Colors.white),
    );
  }

  Widget buildTurnOnButton(BuildContext context) {
    if (_adapterState == BluetoothAdapterState.on) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: ElevatedButton(onPressed: null, child: Text('TURN ON')),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        child: const Text('TURN ON'),
        onPressed: () async {
          try {
            if (Platform.isAndroid) {
              await FlutterBluePlus.turnOn();
            }
          } catch (e) {
            Snackbar.show(ABC.a, prettyException("Error Turning On:", e),
                success: false);
          }
          checkPermissionsLoadScreen();
        },
      ),
    );
  }

  Widget buildLocationButtons(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElevatedButton(
            child: const Text('TURN ON GPS'),
            onPressed: () async {
              await Geolocator.openAppSettings();
              await Geolocator.openLocationSettings();
              checkPermissionsLoadScreen();
            },
          ),
          ElevatedButton(
            child: const Text('DON\'T USE GPS'),
            onPressed: () async {
              widget.prefs.setBoolPref("useGPS", false);
              checkPermissionsLoadScreen();
            },
          ),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyA,
      child: Scaffold(
        backgroundColor: Colors.lightBlue,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              buildBluetoothIcon(context),
              buildBluetoothTitle(context),
              if (Platform.isAndroid) buildTurnOnButton(context),
              buildLocationIcon(context),
              buildLocationTitle(context),
              buildLocationButtons(context)
            ],
          ),
        ),
      ),
    );
  }
}
