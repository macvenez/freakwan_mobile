// import 'package:shared_preferences/shared_preferences.dart';


// class AppSettings {
//   ChatLevel? _chatLevelItem;
//   SharedPreferences? prefs;

//   AppSettings() {
//     initPrefs();
//   }

//   void initPrefs() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     int chatLevel = prefs.getInt('chatLevel') ?? -1; //if chatLevel setting is not found use -1

//     if (chatLevel == -1) {
//       await prefs.setInt('chatLevel', 0); //chat level basic
//       chatLevel = 0;
//     }
//   }

//   void setPrefs(String key, int value) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.setInt(key, value);
//   }

//   ChatLevel getChatLevelSetting(){
//     _chatLevelItem = 
//   }

// }
