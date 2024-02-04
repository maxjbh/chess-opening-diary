import 'package:chess_opening_diary/dal/api/api_tools.dart';
import 'package:chess_opening_diary/logIn/log_in_page.dart';
import 'package:chess_opening_diary/views/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'logIn/log_in_cubit.dart';
import 'utils/global_tools.dart';
import 'package:responsive_framework/responsive_framework.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  LogInCubit loginStateController = LogInCubit();
  ApiTools.setLogInCubit(loginStateController);
  ApiTools.launchConnexionEventListner();
  runApp(MyApp(loginStateController));
}

class MyApp extends StatelessWidget {
  LogInCubit loginStateController;

  MyApp(this.loginStateController, {super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    //Wrapping the app with a tap detector to unfocus if tapped on nothing
    return BlocProvider(
      create: (context) => loginStateController,
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus ) {
            currentFocus.focusedChild?.unfocus();
          }
        },
        child: MaterialApp(

          builder: (context, widget) =>
              ResponsiveWrapper.builder(
                ClampingScrollWrapper.builder(context, widget!),
                breakpointsLandscape: const [
                  ResponsiveBreakpoint.resize(800, name: MOBILE),
                  ResponsiveBreakpoint.autoScale(1280, name: TABLET),
                  ResponsiveBreakpoint.resize(1440, name: DESKTOP),
                  ResponsiveBreakpoint.autoScale(2000, name: 'XL'),

                ],
                breakpoints: const [
                  ResponsiveBreakpoint.resize(400, name: MOBILE),
                  ResponsiveBreakpoint.autoScale(800, name: TABLET),
                  ResponsiveBreakpoint.resize(1000, name: DESKTOP),
                  ResponsiveBreakpoint.autoScale(1700, name: 'XL'),

                ],
              ),
          title: GlobalTools.appTitle,
          theme: GlobalTools.globalTheme,
          home: const Homepage(),
          routes: <String, WidgetBuilder>{
            '/home': (BuildContext context) => const Homepage(),
          },
          debugShowCheckedModeBanner: false,
        ),

      ),
    );
  }
}


