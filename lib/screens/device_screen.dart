import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:freakwan_mobile/screens/app_settings_screen.dart';

//import '../widgets/service_tile.dart';
//import '../widgets/characteristic_tile.dart';
//import '../widgets/descriptor_tile.dart';
import '../utils/snackbar.dart';
import '../utils/extra.dart';
import '../utils/messageitem.dart';
import '../utils/settings.dart';

RegExp batteryRegex = RegExp(r'(?=.*\bbattery\b)(?=.*volts)(?=.*%)',
    caseSensitive:
        false); //regex to match if a battery status command has been received

RegExp presetRegex = RegExp(r'(?=.*Setting)(?=.*bw:)(?=.*cr:)(?=.*sp:)',
    caseSensitive:
        false); //regex to match if a valid preset has been set successfully

const List<String> radioPresetsList = <String>[
  //radio presets which directly match freakwan radio presets names
  'superfar',
  'veryfar',
  'far',
  'mid',
  'fast',
  'veryfast',
  'superfast'
];

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

enum MenuItem { showNearby, nodeSettings }

class _DeviceScreenState extends State<DeviceScreen> {
  int? _rssi;
  int? _batteryPercent;
  double? _batteryVoltage;
  //int? _mtuSize;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  //late StreamSubscription<int> _mtuSubscription;

  late BluetoothCharacteristic rxChannel,
      txChannel; //rxChannel and txChannel are those which we need to write to to send and receive commands and messages

  List<int> _value = [];

  List<MessageItem> messages = []; //this list will hold all received messages

  Timer?
      updateDeviceInfoTask; //a periodic task to ask the device for info (rssi and battery voltage for now)

  late StreamSubscription<List<int>> _lastValueSubscription;

  final sendCommandFieldController = TextEditingController();

  final chatBoxScrollController =
      ScrollController(); //used to implement autoscroll

  bool autoScroll = true;

  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');

  String?
      nearbyNodesString; // this string will be populated when we receive info about nearby nodes (!ls command)
  bool nearbyNodesDataready = false;

  final AppSettings _prefs = AppSettings();
  late final _prefsFuture = _prefs.initPrefs().then((v) => {});

  String nodeSettingsRadioPreset = radioPresetsList.first;

  @override
  void initState() {
    super.initState();
    chatBoxScrollController.addListener(() {
      //if the user has scrolled to the bottom of the messages list then we'll enable autoscroll for new messages
      if (chatBoxScrollController.position.pixels ==
          chatBoxScrollController.position.maxScrollExtent) {
        //Snackbar.show(ABC.c, "END OF SCROLL", success: true);
        autoScroll = true;
      }
    });

    _connectionStateSubscription =
        widget.device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        increaseMTU(widget.device);
        _services = []; // must rediscover services
        await discoverServices();
        for (final e in _services) {
          if (e.serviceUuid ==
              Guid.fromString("6e400001-b5a3-f393-e0a9-e50e24dcca9e")) {
            rxChannel = e.characteristics.firstWhere((c) =>
                c.characteristicUuid.toString() ==
                "6e400003-b5a3-f393-e0a9-e50e24dcca9e");
            txChannel = e.characteristics.firstWhere((c) =>
                c.characteristicUuid.toString() ==
                "6e400002-b5a3-f393-e0a9-e50e24dcca9e");
            await subscribe(
                rxChannel); //we'll subscribe to the rxChannel and wait for new messages coming from the node
            requestDeviceInfo(
                txChannel); //ask the device its informations for the first time

            _lastValueSubscription = rxChannel.lastValueStream.listen((value) {
              //we'll process all messages received from the device
              _value = value;
              processBuffer(String.fromCharCodes(_value));
            });

            Future.wait([_prefsFuture]).then(
              (value) {
                if (updateDeviceInfoTask?.isActive != true) {
                  //check if the periodic task already exists to avoid creating multiple ones
                  updateDeviceInfoTask = Timer.periodic(
                    Duration(
                      seconds: _prefs.getDevicePollIntervalSetting(),
                    ),
                    (t) => requestDeviceInfo(
                        txChannel), //each 20 seconds we'll ask the device for info, processBuffer will process all relative informations
                  );
                }
              },
            );
          }
        }
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.device.readRssi();
      }
      if (mounted) {
        setState(() {});
      }
    });
/*
    _mtuSubscription = widget.device.mtu.listen((value) {
      _mtuSize = value;
      if (mounted) {
        setState(() {});
      }
      
    });*/

    _isConnectingSubscription = widget.device.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isDisconnectingSubscription =
        widget.device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    updateDeviceInfoTask?.cancel();
    _connectionStateSubscription.cancel();
    //_mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    _lastValueSubscription.cancel();
    super.dispose();
  }

  void processBuffer(String data) {
    //that's the main function to process all messages received from the node and decide which are relative to commands and which are simple messages from other nodes
    if (data.length <= 1) {
      //filter out all empty messages
      return;
    }
    if (data.startsWith('!') ||
        batteryRegex.hasMatch(data) ||
        presetRegex.hasMatch(data) ||
        data.contains("Nobody around...") ||
        RegExp(r'^\d+.*RSSI.*nodes').hasMatch(data)) {
      //various regexps for commands implemented by now
      if (presetRegex.hasMatch(data)) {
        Snackbar.show(ABC.c, "Correctly set radio preset", success: true);
      }
      if (data.contains("Nobody around...") ||
          RegExp(r'^\d+.*RSSI.*nodes').hasMatch(data)) {
        setState(() {
          nearbyNodesString = data;
          nearbyNodesDataready = true;
        });
      }
      if (batteryRegex.hasMatch(data)) {
        //if we have a match for battery data we'll try to extract battery voltage and charge percent
        int startIndex = data.indexOf("battery");
        int endIndex = data.indexOf("%", startIndex + 7);
        try {
          _batteryPercent = int.parse(data.substring(startIndex + 8, endIndex));
          startIndex = data.indexOf("%, ");
          endIndex = data.indexOf("volts", startIndex + 3);
          _batteryVoltage =
              double.parse(data.substring(startIndex + 3, endIndex - 1));
        } catch (e) {
          // Snackbar.show(ABC.c, prettyException("Not battery data", e),
          //     success: false);
        }
      }
      setState(() {
        //we'll add the message to the list with type cmdReceived, this will trigger a rebuild of the interface containing messages
        messages
            .add(MessageItem(data, MessageType.cmdReceived, DateTime.now()));
      });
    } else {
      //if all previous regexps are not matched it must be a message originated from another node
      setState(() {
        messages
            .add(MessageItem(data, MessageType.msgReceived, DateTime.now()));
      });
    }

    if (chatBoxScrollController.position.pixels ==
        chatBoxScrollController.position.maxScrollExtent) {
      //Snackbar.show(ABC.c, "END OF SCROLL", success: true);
      autoScroll = true;
    } else {
      autoScroll = false;
      //Snackbar.show(ABC.c, "REMOVED AUTOSCROLL", success: true);
    }
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future subscribe(BluetoothCharacteristic c) async {
    try {
      String op = c.isNotifying == false ? "Subscribe" : "Unubscribe";
      await c.setNotifyValue(true); //toggle subscription (0->1,  1->0)
      Snackbar.show(ABC.c, "$op Successfully subscribed", success: true);
      if (c.properties.read) {
        await c.read();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Subscribe Error:", e),
          success: false);
    }
  }

  Future requestDeviceInfo(BluetoothCharacteristic c) async =>
      sendMessageOrCommand(c, "!bat");

  Future requestNearbyNodesList(BluetoothCharacteristic c) async {
    nearbyNodesDataready = false;
    sendMessageOrCommand(c, "!ls");
    while (!nearbyNodesDataready) {
      await Future.delayed(const Duration(
          milliseconds: 100)); // Wait 100ms before checking again
    }
  }

  Future sendMessageOrCommand(BluetoothCharacteristic c, String data) async {
    //generic function to send data to the node
    if (data.startsWith('!')) {
      //check if we're sending a command
      setState(() {
        messages.add(MessageItem(data, MessageType.cmdSent, DateTime.now()));
      });
    } else {
      setState(() {
        messages.add(MessageItem(data, MessageType.msgSent, DateTime.now()));
      });
    }
    if (chatBoxScrollController.position.pixels ==
        chatBoxScrollController.position.maxScrollExtent) {
      //Snackbar.show(ABC.c, "END OF SCROLL", success: true);
      autoScroll = true;
    } else {
      autoScroll = false;
      //Snackbar.show(ABC.c, "REMOVED AUTOSCROLL", success: true);
    }

    List<int> hexList = data.runes.map((int rune) {
      //convert char contained in the message string to a corrisponding list of hex values
      return int.parse(rune.toRadixString(16),
          radix: 16); // Parse to int from hex
    }).toList();

    try {
      //try to send data
      await c.write(hexList,
          withoutResponse: c.properties.writeWithoutResponse);
      //Snackbar.show(ABC.c, "Write: Success", success: true);
      if (c.properties.read) {
        await c.read();
      }
    } catch (e) {
      Snackbar.show(
          ABC.c, prettyException("Unable to request data from device:", e),
          success: false);
    }
  }

  //sendCommandFieldController.text

  Future onConnectPressed() async {
    try {
      await widget.device.connectAndUpdateStream();
      Snackbar.show(ABC.c, "Connect: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ABC.c, prettyException("Connect Error:", e),
            success: false);
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ABC.c, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
    }
  }

  Future onDisconnectPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream();
      updateDeviceInfoTask?.cancel();
      _lastValueSubscription.cancel();
      Snackbar.show(ABC.c, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Disconnect Error:", e),
          success: false);
    }
  }

  Future discoverServices() async {
    try {
      _services = await widget.device.discoverServices();
      Snackbar.show(ABC.c, "Discover Services: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e),
          success: false);
    }
  }

  Future increaseMTU(BluetoothDevice d) async {
    try {
      await d.requestMtu(223, predelay: 0);
      Snackbar.show(ABC.c, "Request Mtu: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Change Mtu Error:", e),
          success: false);
    }
  }

/*
  List<Widget> _buildServiceTiles(BuildContext context, BluetoothDevice d) {
    for (final e in _services) {
      if (e.serviceUuid ==
          Guid.fromString("6e400001-b5a3-f393-e0a9-e50e24dcca9e")) {
        print("FOUND VALID BLE DEVICE");
        //c.setNotifyValue(c.isNotifying == false);
      }
    }
    return _services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map((c) => _buildCharacteristicTile(c))
                .toList(),
          ),
        )
        .toList();
  }

  CharacteristicTile _buildCharacteristicTile(BluetoothCharacteristic c) {
    return CharacteristicTile(
      characteristic: c,
      descriptorTiles:
          c.descriptors.map((d) => DescriptorTile(descriptor: d)).toList(),
    );
  }
*/

  Widget buildValue(BuildContext context) {
    return Text(String.fromCharCodes(_value),
        style: const TextStyle(fontSize: 13, color: Colors.grey));
  }

  Widget buildSpinner(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget buildRemoteId(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
          '${widget.device.remoteId} - Device is ${_connectionState.toString().split('.')[1]}.'),
    );
  }

  Widget buildRssiTile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isConnected
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        Text(((isConnected && _rssi != null) ? '${_rssi!} dBm' : ''),
            style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  Widget buildBatteryTile(BuildContext context) {
    Icon batteryStateIcon = const Icon(Icons.battery_alert_outlined);
    switch (_batteryPercent) {
      case null:
        batteryStateIcon = const Icon(Icons.battery_alert_outlined);
      case < 11.1:
        batteryStateIcon = const Icon(Icons.battery_0_bar_outlined);
      case >= 11.1 && < 22.2:
        batteryStateIcon = const Icon(Icons.battery_1_bar_outlined);
      case >= 22.2 && < 33.3:
        batteryStateIcon = const Icon(Icons.battery_2_bar_outlined);
      case >= 33.3 && < 44.4:
        batteryStateIcon = const Icon(Icons.battery_3_bar_outlined);
      case >= 44.4 && < 55.5:
        batteryStateIcon = const Icon(Icons.battery_4_bar_outlined);
      case >= 55.5 && < 66.6:
        batteryStateIcon = const Icon(Icons.battery_5_bar_outlined);
      case >= 66.6 && < 77.7:
        batteryStateIcon = const Icon(Icons.battery_6_bar_outlined);
      case >= 88.8:
        batteryStateIcon = const Icon(Icons.battery_full_outlined);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        batteryStateIcon,
        Text(("$_batteryPercent% ${_batteryVoltage}V"),
            style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

/*
  Widget buildGetServices(BuildContext context) {
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        TextButton(
          child: const Text("Get Services"),
          onPressed: discoverServices,
        ),
        const IconButton(
          icon: SizedBox(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.grey),
            ),
            width: 18.0,
            height: 18.0,
          ),
          onPressed: null,
        )
      ],
    );
  }
*/
/*
  Widget buildMtuTile(BuildContext context) {
    return ListTile(
        title: const Text('MTU Size'),
        subtitle: Text('$_mtuSize bytes'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onRequestMtuPressed,
        ));
  }
*/

  Widget buildConnectButton(BuildContext context) {
    return Row(children: [
      if (_isConnecting || _isDisconnecting) buildSpinner(context),
      TextButton(
          onPressed: _isConnecting
              ? onCancelPressed
              : (isConnected ? onDisconnectPressed : onConnectPressed),
          child: Text(
            _isConnecting ? "CANCEL" : (isConnected ? "DISCONNECT" : "CONNECT"),
            style: Theme.of(context)
                .primaryTextTheme
                .labelLarge
                ?.copyWith(color: const Color.fromARGB(255, 219, 81, 81)),
          ))
    ]);
  }

  Widget buildSendCommandBox(BuildContext context) {
    return SizedBox(
      //padding: EdgeInsets.all(10.0),
      height: 70,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center, //Center Row contents horizontally,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: TextField(
            controller: sendCommandFieldController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter command to send',
            ),
          )),
          Container(
              padding: const EdgeInsets.only(left: 5.0),
              child: ElevatedButton(
                  onPressed: () {
                    sendMessageOrCommand(
                        txChannel, sendCommandFieldController.text);
                    sendCommandFieldController.clear();
                  },
                  child: const Icon(Icons.send)))
        ],
      ),
    );
  }

  Widget buildChatBox(BuildContext context) {
    bool basic = _prefs.getChatLevelSetting().index == 0 ? false : true;
    return Expanded(
        child: Container(
            color: Colors.blueGrey[50],
            child: SingleChildScrollView(
                controller: chatBoxScrollController,
                child: Column(
                    children: (!basic
                            ? messages.where((item) =>
                                item.type == MessageType.msgReceived ||
                                item.type == MessageType.msgSent)
                            : messages)
                        .map((message) => buildMessage(context, message))
                        .toList()))));
  }

  Widget buildMessage(BuildContext context, MessageItem message) {
    Color borderColor;
    Alignment messageAlignment;
    switch (message.type) {
      case MessageType.cmdSent || MessageType.msgSent:
        borderColor = Colors.red;
        messageAlignment = Alignment.centerRight;
      case MessageType.cmdReceived || MessageType.msgReceived:
        borderColor = Colors.green;
        messageAlignment = Alignment.centerLeft;
    }
    return Align(
        alignment: messageAlignment,
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                  color: borderColor,
                ),
                borderRadius: BorderRadius.circular(8),
                color: borderColor),
            padding: const EdgeInsets.all(6.0),
            margin: const EdgeInsets.only(bottom: 2.0),
            child: IntrinsicWidth(
                child: Column(children: [
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    message.content,
                  )),
              Align(
                  alignment: Alignment.bottomRight,
                  child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        "${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}:${message.time.second.toString().padLeft(2, '0')}", //use padLeft to keep the leading 0 if number is in single digit (ex. 12:6 -> 12:06)
                        style: DefaultTextStyle.of(context)
                            .style
                            .apply(fontSizeFactor: 0.8),
                      )))
            ]))));
  }

  Widget buildDotMenu(BuildContext context) {
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: () async {
            await requestNearbyNodesList(txChannel);
            await nearbyNodesDialog(context);
          },
          leadingIcon: const Icon(Icons.device_hub),
          child: const Text('Show nearby nodes'),
        ),
        MenuItemButton(
          onPressed: () {
            nodeSettingsDialog(context);
          },
          leadingIcon: const Icon(Icons.settings),
          child: const Text('Settings'),
        ),
        /*
        MenuItemButton(
          onPressed: () {},
          child: const Text('Node info'),
        ),*/
      ],
      builder: (_, MenuController controller, Widget? child) {
        return IconButton(
          focusNode: _buttonFocusNode,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
        );
      },
    );
  }

  Future<String?> nodeSettingsDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Node settings'),
        content: Container(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Radio preset",
                ),
                Row(children: [
                  DropdownMenu<String>(
                    initialSelection: radioPresetsList.first,
                    onSelected: (String? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        nodeSettingsRadioPreset = value!;
                      });
                    },
                    dropdownMenuEntries: radioPresetsList
                        .map<DropdownMenuEntry<String>>((String value) {
                      return DropdownMenuEntry<String>(
                          value: value, label: value);
                    }).toList(),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        sendMessageOrCommand(
                            txChannel, "!preset $nodeSettingsRadioPreset");
                      },
                      child: const Icon(Icons.send))
                ]),
              ],
            )),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Close'),
          ),
          // TextButton(
          //   onPressed: () => Navigator.pop(context, 'OK'),
          //   child: const Text('OK'),
          // ),
        ],
      ),
    );
  }

  Future<String?> nearbyNodesDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Nearby nodes'),
        content: Text('$nearbyNodesString'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Close'),
          ),
          // TextButton(
          //   onPressed: () => Navigator.pop(context, 'OK'),
          //   child: const Text('OK'),
          // ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
        key: Snackbar.snackBarKeyC,
        child: Scaffold(
            appBar: AppBar(
              title: Text(widget.device.platformName),
              actions: [
                buildConnectButton(context),
                IconButton(
                    onPressed: () async {
                      MaterialPageRoute route = MaterialPageRoute(
                          builder: (context) => const AppSettingsScreen(),
                          settings:
                              const RouteSettings(name: '/AppSettingsScreen'));
                      final result = await Navigator.of(context).push(route);
                      if (result != null) {
                        //when we're coming from settings page we need to refresh this page and reload settings cache to account for possible new settings
                        int previousDevicePollInterval =
                            _prefs.getDevicePollIntervalSetting();
                        await _prefs.reloadPrefs();
                        if (_prefs.getDevicePollIntervalSetting() !=
                            previousDevicePollInterval) {
                          //pollInterval has been changed from settings
                          if (updateDeviceInfoTask?.isActive == true) {
                            //if the timer has been initialized and is running
                            updateDeviceInfoTask?.cancel(); //stop the timer
                          }
                          updateDeviceInfoTask = Timer.periodic(
                            Duration(
                              seconds: _prefs.getDevicePollIntervalSetting(),
                            ),
                            (t) => requestDeviceInfo(
                                txChannel), //each 20 seconds we'll ask the device for info, processBuffer will process all relative informations
                          );
                        }

                        setState(() {
                          _prefs.getChatLevelSetting();
                          //_chatLevelItem = settings.getChatLevelSetting();
                          //Snackbar.show(ABC.c, result, success: true);
                        });
                      }
                    },
                    icon: const Icon(Icons.settings))
              ],
            ),
            body: FutureBuilder(
                future: _prefsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (autoScroll) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        chatBoxScrollController.jumpTo(
                            chatBoxScrollController.position.maxScrollExtent);
                      });
                    }
                    return Container(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: <Widget>[
                          buildRemoteId(context),
                          ListTile(
                              contentPadding: const EdgeInsets.only(right: 0.0),
                              leading: buildRssiTile(context),
                              title: buildBatteryTile(context),
                              trailing: buildDotMenu(context)),
                          buildChatBox(context),
                          buildSendCommandBox(context),

                          //buildChatBox(context),
                          //buildMtuTile(context),
                          //..._buildServiceTiles(context, widget.device),
                        ],
                      ),
                    );
                  }
                  return const Scaffold(
                    body: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                })));
  }
}
