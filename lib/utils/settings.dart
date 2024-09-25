import 'package:shared_preferences/shared_preferences.dart';

enum ChatLevel { basic, advanced }

class AppSettings {
  SharedPreferences? prefs;

  AppSettings() {
    initPrefs();
  }

  Future<bool> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs!.getInt('chatLevel') == -1) {
      await prefs!.setInt('chatLevel', 0); //ChatLevel.basic default setting
    }
    return false;
  }

  void setPrefs(String key, int value) async {
    if (prefs == null) {
      throw 'You must initialize AppSettings first';
    }
    prefs!.setInt(key, value);
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
