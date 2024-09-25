import 'package:shared_preferences/shared_preferences.dart';

enum ChatLevel { basic, advanced }

class AppSettings {
  SharedPreferences? prefs;

  AppSettings() {
    initPrefs();
  }

  void initPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int chatLevel = prefs.getInt('chatLevel') ??
        -1; //if chatLevel setting is not found use -1

    if (chatLevel == -1) {
      await prefs.setInt('chatLevel', 0); //ChatLevel.basic default setting
      chatLevel = 0;
    }
  }

  void setPrefs(String key, int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, value);
  }

  ChatLevel getChatLevelSetting() {
    if (prefs == null) {
      throw 'You must initialize AppSettings first';
    }
    if (prefs!.getInt('chatLevel') == null) {
      throw 'chatLevel setting has not been initialized';
    }
    return ChatLevel.values[prefs!.getInt("chatLevel")!];
  }
}
