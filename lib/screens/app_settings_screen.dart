import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer';

import '../utils/settings.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final AppSettings _prefs = AppSettings();
  late Future _prefsFuture = _prefs.initPrefs();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
        child: Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => {Navigator.maybePop(context, "pleaseReload")},
        ),
        title: const Text("App settings"),
      ),
      body: FutureBuilder(
        //we have to use FutureBuilder because the preferences must be awaited
        future: _prefsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.waiting) {
            // only show the settings if we're not waiting for the future to complete
            return SingleChildScrollView(
                child: Column(children: <Widget>[
              Container(
                  padding:
                      const EdgeInsets.only(top: 16.0, left: 16.0, right: 22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Chat messages type",
                      ),
                      RadioListTile<ChatLevel>(
                        value: ChatLevel.basic,
                        groupValue: _prefs.getChatLevelSetting(),
                        onChanged: (ChatLevel? value) {
                          setState(() {
                            _prefs.setIntPref("chatLevel", value!.index);
                          });
                        },
                        title: const Text('Basic'),
                        subtitle: const Text(
                            'Only show messages from and to users, do not display messages which are due to commands (like periodic battery check or settings)'),
                      ),
                      RadioListTile<ChatLevel>(
                        value: ChatLevel.advanced,
                        groupValue: _prefs.getChatLevelSetting(),
                        onChanged: (ChatLevel? value) {
                          setState(() {
                            _prefs.setIntPref("chatLevel", value!.index);
                          });
                        },
                        title: const Text('Advanced'),
                        subtitle: const Text(
                            'Show all messages which are effectively sent and received from and to the device (will also display settings commands and periodic battery check for example)'),
                      ),
                    ],
                  )),
              //const Divider(),
              Container(
                padding:
                    const EdgeInsets.only(top: 16.0, left: 16.0, right: 22.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Device info poll interval",
                      ),
                      TextFormField(
                        initialValue:
                            _prefs.getDevicePollIntervalSetting().toString(),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ], // Only numbers can be entered
                        onFieldSubmitted: (String value) {
                          _prefs.setIntPref("devicePoll", int.parse(value));
                        },
                      ),
                    ]),
              ),
              Container(
                  child: Switch(
                // This bool value toggles the switch.
                value: _prefs.getGPSSetting(),
                activeColor: Colors.red,
                onChanged: (bool value) {
                  // This is called when the user toggles the switch.
                  setState(() {
                    _prefs.setBoolPref("useGPS", value);
                  });
                },
              )),
              const Divider(),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      //we should wait again for the future to complete, we can show again CircularProgressIndicator while we await for the settings to be reset
                      _prefsFuture = _prefs.applyDefaultSettings();
                    });
                  },
                  child: const Text("Reload default settings"))
            ]) // `_prefs` is ready for use.
                );
          }

          // `_prefs` is not ready yet, show loading bar till then.
          return const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        },
      ),
    ));
  }
}
