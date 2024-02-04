import 'dart:async';
import 'dart:io';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

import '../app_theme.dart';
import 'button_stuff/used_icons.dart';
import 'exapndable_checkboxes/expandable_checkboxs_cubit.dart';


//a most likely temporary file until i tidy things up
class GlobalTools {




  //NavigationStuff--------------------------------------------------------
  ///Pop up dialog in case we are on last page
  static Future<bool> onFinalBackPressed(BuildContext context) async{
    await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Do you really want to exit the app?'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text('Yes'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: Text('No'),
              ),
            ],
          );
        });
    return false;
  }

  ///Builds a bottom navigation bar if on tiny tablet or smaller
  static Widget? mobileBottomNavigationBarGeneral(
      BuildContext context, ThemeData theme) {
    return (ResponsiveWrapper.of(context).isLargerThan(MOBILE)
        ? null
        : BottomAppBar(
            //shape: const CircularNotchedRectangle(),
            color:
                (theme == null ? globalTheme.primaryColor : theme.primaryColor),
            child: IconTheme(
              data:
                  IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _bottomNavBarCommon(context),
              ),
            ),
          ));
  }

  static List<Widget> _bottomNavBarCommon(BuildContext context,
      {Function? onHomeButtonPressed}) {
    return [
      UsedIcons.homeButton(context, onPressed: onHomeButtonPressed),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
        child: Tooltip(
          message: 'Paramètres',
          child: UsedIcons.buildSettingsIconButton(context),
        ),
      ),
    ];
  }

  //Settings----------------------------------------------------------------
  static String language = 'en';

  //Strings --------------------------------------------------------------
  static final String appTitle = 'My Chess Diary';

  static String notLoggedInMessage = "You're not logged in idiot!";

  static String cancelMessage() {
    switch (language) {
      case 'fr':
        return "Annuler";
        break;
      case 'en':
        return 'Cancel';
        break;
    }
    return ('Language error');
  }

  static String validateMessage() {
    switch (language) {
      case 'fr':
        return "Valider";
        break;
      case 'en':
        return 'Validate';
        break;
    }
    return ('Language error');
  }

  static String nextMessage() {
    switch (language) {
      case 'fr':
        return "Suivant";
        break;
      case 'en':
        return 'Next';
        break;
    }
    return ('Language error');
  }

  //Sizes---------------------------------(these base sizes rescale automatically thanks to the responsive package)
  static final double textSizeLarge = 30.0;
  static final double textSizeNormalLarge = 25.0;
  static final double textSizeNormal = 20.0;
  static final double textSizeSmall = 15.0;

  //Theme data
  static final TextTheme textTheme = AppTheme.textTheme;
  static final TargetPlatform targetPlatform = TargetPlatform.android;

  static final ThemeData globalTheme = ThemeData(
    primarySwatch: Colors.blue,
    textTheme: textTheme,
    platform: targetPlatform,
  );

  static final ThemeData yellowTheme = ThemeData(
    primarySwatch: Colors.yellow,
    textTheme: AppTheme.textTheme,
    platform: targetPlatform,
  );
  static final ThemeData pinkTheme = ThemeData(
    primarySwatch: Colors.pink,
    textTheme: textTheme,
    platform: targetPlatform,
  );

  //String formatters ---------------------------------------------------------
  ///This was needed for the first time because data creation raw responce returns [] around the value of the uri for some reason.
  static String removeFirstAndLastCharacter(String s) {
    return s.substring(1, s.length - 1);
  }

  static String stringListToString(List<String> list) {
    String megaString = '';
    bool first = true;
    for (String s in list) {
      if (!first) {
        megaString += ', ';
      }
      megaString += s;
      first = false;
    }
    return megaString;
  }

  //Graphical popups ---------------------------------------------------------

  ///Popup that creates a list of checkbox tiles from a given list of possibilities, then runs onConfirm with this selection
  static Future<void> showCheckboxesInput({
    required BuildContext context,
    required String popupTitle,
    String? popupHintText,
    required List<String> options,
    required Function(List<String>) onSubmit,
    required bool cancelPosibility,
  }) async {
    bool applyButtonRunning = false;
    ExpandableCheckboxesCubit checkboxesController =
        ExpandableCheckboxesCubit([]);

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user doesn't have to tap button!
      builder: (BuildContext context) {
        return BlocProvider(
          create: (context) => checkboxesController,
          child: AlertDialog(
            scrollable: true,
            title: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(popupTitle),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                (popupHintText == null
                    ? Container()
                    : Row(children: [
                        Text(
                          popupHintText,
                          style: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ])),
              ],
            ),
            content: SingleChildScrollView(
                primary: true,
                child: Column(
                  children: options.map((e) {
                    return BlocBuilder<ExpandableCheckboxesCubit, ExpandableCheckboxesState>(
                      bloc: checkboxesController,
                      buildWhen: (prev, next){
                        return next is ExpandableCheckboxChanged && next.checkboxName==e;
                      },
                      builder: (context, state) {
                        return CheckboxListTile(
                            value: checkboxesController.currentSelection
                                .contains(e),
                            title: Text(
                              e,
                              style: TextStyle(
                                  fontSize: GlobalTools.textSizeNormal),
                            ),
                            onChanged: (val) async {
                              checkboxesController
                                  .addOrRemoveToSelectionAndEmit(e);
                            });
                      },
                    );
                  }).toList(),
                ),
              ),
            actions: (cancelPosibility
                ? [
                    TextButton(
                      child: Text(validateMessage()),
                      onPressed: () async {
                        if (!applyButtonRunning) {
                          applyButtonRunning = true;
                          //Have to pop before so that if we pop a potentially pushed page during onSubmit we don't land back on this popup
                          Navigator.of(context).pop();
                          await onSubmit(checkboxesController.currentSelection);
                          applyButtonRunning = false;
                        }
                      },
                    ),
                    TextButton(
                      child: Text(cancelMessage()),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ]
                : [
                    TextButton(
                      child: Text(nextMessage()),
                      onPressed: () async {
                        if (!applyButtonRunning) {
                          applyButtonRunning = true;
                          //Have to pop before so that if we pop a potentially pushed page during onSubmit we don't land back on this popup
                          Navigator.of(context).pop();
                          await onSubmit(checkboxesController.currentSelection);
                          applyButtonRunning = false;
                        }
                      },
                    ),
                  ]),
          ),
        );
      },
    );
  }

  ///Popup to enter text
  static Future<void> showTextInput({
    required BuildContext context,
    required String popupTitle,
    String? popupHintText,
    required String textFieldLabel,
    required bool capitalizeTextField,
    List<TextInputFormatter>? textInputFormatters,
    required Function(String?) onSubmit,
    required String hintTextOrMaskExample,
    required bool cancelPosibility,
  }) async {
    String? currentEnteredString;
    bool applyButtonRunning = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user doesn't have to tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(popupTitle),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              (popupHintText == null
                  ? Container()
                  : Row(children: [
                      Text(
                        popupHintText,
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ])),
            ],
          ),
          content: Column(
            children: [
              TextField(
                obscureText: false,
                inputFormatters:
                    (textInputFormatters == null ? null : textInputFormatters),
                textCapitalization: (capitalizeTextField
                    ? TextCapitalization.characters
                    : TextCapitalization.none),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: textFieldLabel,
                  hintText: hintTextOrMaskExample,
                ),
                onSubmitted: (String value) async {
                  if (!cancelPosibility) {
                    if (!applyButtonRunning) {
                      applyButtonRunning = true;
                      //Have to pop before so that if we pop a potentially pushed page during onSubmit we don't land back on this popup
                      Navigator.of(context).pop();
                      await onSubmit(value);
                      applyButtonRunning = false;
                    }
                  }
                },
                onChanged: (String value) {
                  currentEnteredString = value;
                },
              ),
            ],
          ),
          /*),
          ),*/
          actions: (cancelPosibility
              ? [
                  TextButton(
                    child: Text(validateMessage()),
                    onPressed: () async {
                      if (!applyButtonRunning) {
                        applyButtonRunning = true;
                        //Have to pop before so that if we pop a potentially pushed page during onSubmit we don't land back on this popup
                        Navigator.of(context).pop();
                        await onSubmit(currentEnteredString);
                        applyButtonRunning = false;
                      }
                    },
                  ),
                  TextButton(
                    child: Text(cancelMessage()),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ]
              : [
                  TextButton(
                    child: Text(nextMessage()),
                    onPressed: () async {
                      if (!applyButtonRunning) {
                        applyButtonRunning = true;
                        //Have to pop before so that if we pop a potentially pushed page during onSubmit we don't land back on this popup
                        Navigator.of(context).pop();
                        await onSubmit(currentEnteredString);
                        applyButtonRunning = false;
                      }
                    },
                  ),
                ]),
        );
      },
    );
  }

  ///Popup contazining a stateful widget, the builder functions depend on a controller defined outside of this function
  ///controllerAccessorBuilder is some widget that will result in state changes when we perform actions on it, for now it's placed below
  ///textFieldBuilder text field widget will get rebuilt on state changes
  static Future<void> showControlledInput({
    required BuildContext context,
    required String popupTitle,
    String? popupHintText,
    required Function onSubmit,
    required bool cancelPosibility,
    required Function inputBuilder,
    required Function controllerAccessorBuilder,
    required Function getApplyButtonRunning,
    required Function setApplyButtonRunning,
  }) async {
    //String currentEnteredString;
    //bool applyButtonRunning = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user doesn't have to tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(popupTitle),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              (popupHintText == null
                  ? Container()
                  : Row(children: [
                Text(
                  popupHintText,
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ])),
            ],
          ),
          content: Column(
            children: [
              inputBuilder(),
              controllerAccessorBuilder(),
            ],
          ),
          /*),
          ),*/
          actions: (cancelPosibility
              ? [
            TextButton(
              child: Text(validateMessage()),
              onPressed: () async {
                if (!getApplyButtonRunning()) {
                  setApplyButtonRunning(true);
                  //Have to pop before so that if we pop a potentially pushed page during onSubmit we don't land back on this popup
                  Navigator.of(context).pop();
                  await onSubmit();
                  setApplyButtonRunning(false);
                }
              },
            ),
            TextButton(
              child: Text(cancelMessage()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ]
              : [
            TextButton(
              child: Text(nextMessage()),
              onPressed: () async {
                if (!getApplyButtonRunning()) {
                  setApplyButtonRunning(true);
                  //Have to pop before so that if we pop a potentially pushed page during onSubmit we don't land back on this popup
                  Navigator.of(context).pop();
                  await onSubmit();
                  setApplyButtonRunning(false);
                }
              },
            ),
          ]),
        );
      },
    );
  }

  static void errorPopup(String message, BuildContext context,
      {Function? onPop}) {
    showDialog<void>(
      context: context,
      barrierDismissible: true, // user doesn't have to tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                message,
                style: TextStyle(fontSize: GlobalTools.textSizeNormalLarge),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  if (onPop != null) {
                    onPop();
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  //Internet stuff ------------------------------------------------------
  /*
  Sais if we have internet connexion or nay
   */
  static Future<bool> doHaveConnexion() async {
    if (!kIsWeb) {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile) {
        debugPrint('Checking mobile internet');
        try {
          final result = await InternetAddress.lookup('example.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            debugPrint('connected');
            return true;
          }
        } on SocketException catch (_) {
          debugPrint('not connected');
          return false;
        }
      } else if (connectivityResult == ConnectivityResult.wifi) {
        debugPrint('Checking wifi');
        try {
          final result = await InternetAddress.lookup('example.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            debugPrint('connected');
            return true;
          }
        } on SocketException catch (_) {
          debugPrint('not connected');
          return false;
        }
      } else {
        // Neither mobile data or WIFI detected, not internet connection found.
        return false;
      }
      return false;
    } else {
      // web internet check TODO
      return true;
    }
  }

  //Widgets ------------------------------------------------------------------
  ///Little line to show end of lists and stuff
  static Widget listEnd = const Padding(
    padding: EdgeInsets.symmetric(vertical: 10.0),
    child: Divider(
      thickness: 2.0,
      indent: 300.0,
      endIndent: 300.0,
    ),
  );

}
