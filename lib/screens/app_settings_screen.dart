import 'package:flutter/material.dart';
import '../utils/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  // AppSettings settings = AppSettings();

  late final SharedPreferences _prefs;
  late final _prefsFuture = SharedPreferences.getInstance().then((v) {
    _prefs = v;
    _chatLevelItem = ChatLevel.values[_prefs.getInt("chatLevel")];
  });

  ChatLevel? _chatLevelItem;
  //bool loading = true;

  @override
  void initState() {
    // settings.initPrefs().then((loaded) {
    //   setState(() {
    //     loading = loaded;
    //     _chatLevelItem = settings.getChatLevelSetting();
    //   });
    // });
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
                        groupValue: _chatLevelItem,
                        onChanged: (ChatLevel? value) {
                          _prefs.setInt("chatLevel", value!.index);
                          setState(() {
                            _chatLevelItem = value;
                          });
                        },
                        title: const Text('Basic'),
                        subtitle: const Text(
                            'Only show messages from and to users, do not display messages which are due to commands (like periodic battery check or settings)'),
                      ),
                      RadioListTile<ChatLevel>(
                        value: ChatLevel.advanced,
                        groupValue: _chatLevelItem,
                        onChanged: (ChatLevel? value) {
                          _prefs.setInt("chatLevel", value!.index);
                          setState(() {
                            _chatLevelItem = value;
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
          return const CircularProgressIndicator();
        },
      ),
    ));
  }
}
