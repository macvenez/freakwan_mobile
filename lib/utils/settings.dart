import 'package:shared_preferences/shared_preferences.dart';

enum ChatLevel { basic, advanced }

class AppSettings {
  late SharedPreferencesWithCache _prefs;

  AppSettings();

  Future initPrefs() async {
    // return await SharedPreferencesWithCache.create(
    //   cacheOptions: const SharedPreferencesWithCacheOptions(),
    // ).then((v) => {
    //       _prefs = v,
    //       if (_prefs.getInt('chatLevel') == null)
    //         {
    //           _prefs.setInt('chatLevel', 0), //ChatLevel.basic default setting
    //           _prefs.setDouble('devicePoll',
    //               20.0) //default of 20 seconds for device poll (battery, rssi)
    //         }
    //       // if (_prefs.getDouble('devicePoll') == null) {
    //       //   _prefs.setDouble('devicePoll',
    //       //       20.0); //default of 20 seconds for device poll (battery, rssi)
    //       // }
    //       // return;
    //     });
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    if (_prefs.getInt('chatLevel') == null) {
      _prefs.setInt('chatLevel', 0); //ChatLevel.basic default setting
    }
    if (_prefs.getInt('devicePoll') == null) {
      _prefs.setInt('devicePoll',
          20); //default of 20 seconds for device poll (battery, rssi)
    }
    if (_prefs.getBool('useGPS') == null) {
      _prefs.setBool('useGPS', true); //use GPS by default
    }
    return;
  }

  void setIntPref(String key, int value) async {
    _prefs.setInt(key, value);
  }

  void setDoublePref(String key, double value) async {
    _prefs.setDouble(key, value);
  }

  void setBoolPref(String key, bool value) async {
    _prefs.setBool(key, value);
  }

  Future reloadPrefs() async {
    return _prefs.reloadCache();
  }

  Future applyDefaultSettings() async {
    await _prefs.clear();
    return await initPrefs();
  }

  ChatLevel getChatLevelSetting() {
    if (_prefs.getInt('chatLevel') == null) {
      throw 'chatLevel setting has not been initialized';
    }
    return ChatLevel.values[_prefs.getInt("chatLevel")!];
  }

  int getDevicePollIntervalSetting() {
    if (_prefs.getInt('devicePoll') == null) {
      throw 'devicePoll setting has not been initialized';
    }
    return _prefs.getInt("devicePoll")!;
  }

  bool getGPSSetting() {
    if (_prefs.getBool('useGPS') == null) {
      throw 'useGPS setting has not been initialized';
    }
    return _prefs.getBool("useGPS")!;
  }
}
