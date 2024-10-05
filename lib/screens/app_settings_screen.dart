import 'package:flutter/material.dart';
import '../utils/settings.dart';
//import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  //ChatLevel? _chatLevelItem;

  // late final SharedPreferencesWithCache _prefs;
  // late final _prefsFuture = SharedPreferencesWithCache.create(
  //   cacheOptions: const SharedPreferencesWithCacheOptions(),
  // ).then((v) => {
  //       _prefs = v,
  //       //_chatLevelItem = ChatLevel.values[_prefs.getInt("chatLevel")!]
  //     });

  final AppSettings _prefs = AppSettings();
  late final _prefsFuture = _prefs.initPrefs();

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
        future: _prefsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(children: <Widget>[
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
                            _prefs.setPref("chatLevel", value!.index);
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
                            _prefs.setPref("chatLevel", value!.index);
                          });
                        },
                        title: const Text('Advanced'),
                        subtitle: const Text(
                            'Show all messages which are effectively sent and received from and to the device (will also display settings commands and periodic battery check for example)'),
                      ),
                    ],
                  )),
              const Divider(),
            ]); // `_prefs` is ready for use.
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
