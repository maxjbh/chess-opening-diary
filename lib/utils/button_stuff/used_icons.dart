import 'package:flutter/material.dart';

import '../../views/homepage.dart';


///To always access in same place, button icons placed here
class UsedIcons{
  static Icon loadFormIcon = const Icon(Icons.folder_open);
  static Icon horizontalTreeIcon = const Icon(Icons.account_tree);
  static Icon deleteIcon = const Icon(Icons.delete_forever);

  static Widget buildSettingsIconButton(BuildContext context){
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        debugPrint("No settings page yet");
      },
    );
  }

  ///Icon button to go back to homepage, onPressed runs any extra commands
  static Widget homeButton(context, {Function? onPressed}) {
    bool pressed = false;
    return IconButton(
      onPressed: () async {
        if (!pressed) {
          pressed = true;
          if (onPressed != null) {
            await onPressed();
          }
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
                  (Route<dynamic> route) => false);
          pressed = false;
        }
      },
      icon: const Icon(Icons.home),
      iconSize: 30.0,
    );
  }

}