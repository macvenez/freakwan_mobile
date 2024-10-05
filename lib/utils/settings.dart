import 'package:shared_preferences/shared_preferences.dart';

enum ChatLevel { basic, advanced }

class AppSettings {
  late final SharedPreferencesWithCache _prefs;

  AppSettings();

  Future initPrefs() async {
    return await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    ).then((v) => {
          _prefs = v,
          if (_prefs.getInt('chatLevel') == null)
            {
              _prefs.setInt('chatLevel', 0) //ChatLevel.basic default setting
            }
        });
  }

  void setPref(String key, int value) async {
    _prefs.setInt(key, value);
  }

  ChatLevel getChatLevelSetting() {
    if (_prefs.getInt('chatLevel') == null) {
      throw 'chatLevel setting has not been initialized';
    }
    return ChatLevel.values[_prefs.getInt("chatLevel")!];
  }
}
