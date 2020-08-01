import 'package:flutter/material.dart';

import 'preferences.dart';

class Styles extends ChangeNotifier {
  // Indigio ios Color(0xFF5e5ce6)

  static const Color brightIndigo = Color(0xff6966ff);
  static Color appBarColor;
  static Color backgroundColor;
  static Color cardColor;
  static Color accentColor;
  static Color backButtonColor;
  static Color textColor;
  static Color subtitleColor;

  static updateTheme(var currentTheme) {
    switch (currentTheme) {
      case VmAppTheme.MilkyWay:
        appBarColor = Colors.white;
        backgroundColor = Colors.grey[100];
        cardColor = Color(0xFF2f3152);
        accentColor = Color(0xFFeb4034);
        backButtonColor = Color(0xff6966ff);
        textColor = Colors.grey[800];
        subtitleColor = Colors.grey[500];
        return;

      case VmAppTheme.Night:
        // primaryColor = Color(0xFF42446E);
        appBarColor = Colors.black;
        backgroundColor = Colors.black;
        cardColor = Color(0xFF1c1c1d);
        accentColor = Color(0xFFeb4034);
        backButtonColor = Color(0xff6966ff);
        textColor = Colors.grey[200];
        subtitleColor = Colors.white60;
        return;

      case VmAppTheme.Planet:
      default:
        appBarColor = Color(0xFF42446E);
        backgroundColor = Color(0xFF262645);
        cardColor = Color(0xFF2f3152);
        accentColor = Color(0xFFeb4034);
        backButtonColor = Colors.white;
        textColor = Colors.grey[100];
        subtitleColor = Colors.white60;
        return;
    }
  }
}
//Planet Theme

// static const Color actionButtonColor = Color(0xFF2f3152);

// class ThemeModel extends ChangeNotifier {
//   String currentTheme = "Night";

//   changeTheme(ThemeType themeType) {
//     switch (themeType) {
//       case ThemeType.Night:
//         currentTheme = "Night";
//         return notifyListeners();

//       case ThemeType.Planet:
//         currentTheme = "Planet";
//         return notifyListeners();
//     }
//   }
// }

//Themes

/*
Widgets to use
ExpansionTile()
.map() operator on list to get multiple widgets

*/
