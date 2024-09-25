import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatLevel { basic, advanced }

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  ChatLevel? _chatLevelItem;
  bool loading = true;

  void initPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int chatLevel = prefs.getInt('chatLevel') ?? -1;

    if (chatLevel == -1) {
      await prefs.setInt('chatLevel', 0); //chat level basic
      chatLevel = 0;
    }
    _chatLevelItem = ChatLevel.values[chatLevel];
    setState(() {
      loading = false;
    });
  }

  void setPrefs(String key, int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, value);
  }

  @override
  void initState() {
    initPrefs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(body: CircularProgressIndicator());
    }
    return ScaffoldMessenger(
        child: Scaffold(
            appBar: AppBar(
              title: const Text("App settings"),
            ),
            body: Column(
              children: <Widget>[
                Container(
                    padding: const EdgeInsets.only(
                        top: 16.0, left: 16.0, right: 22.0),
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
                            setPrefs("chatLevel", value!.index);
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
                            setPrefs("chatLevel", value!.index);
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
                /*Container(
                    padding: const EdgeInsets.only(
                        top: 16.0, left: 16.0, right: 22.0),
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
                            setPrefs("chatLevel", value!.index);
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
                            setPrefs("chatLevel", value!.index);
                            setState(() {
                              _chatLevelItem = value;
                            });
                          },
                          title: const Text('Advanced'),
                          subtitle: const Text(
                              'Show all messages which are effectively sent and received from and to the device (will also display settings commands and periodic battery check for example)'),
                        ),
                      ],
                    ))*/
              ],
            )));
  }
}
