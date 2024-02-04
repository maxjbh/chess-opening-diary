import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/user.dart';
import '../../logIn/log_in_cubit.dart';
import '../../logIn/log_in_page.dart';

///Log in button wrapped by builder to revert transaction if it failed
class LogInButton extends StatelessWidget {
  final String backToAppRoute;

  LogInButton({required this.backToAppRoute});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LogInCubit, LogInState>(builder: (context, state) {
      String buttonName;
      User? user = BlocProvider.of<LogInCubit>(context).user;
      if (user != null) {
        if (user.hasLoggedIn) {
          buttonName = 'Change user';
        } else {
          buttonName = 'Login';
        }
      } else {
        buttonName = 'Login';
      }

      return ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => WillPopScope(
                    onWillPop: () async{
                      BlocProvider.of<LogInCubit>(context).obscurePassword = true;
                      return true;
                    },
                    child: LogInPage(
                          backToAppRoute: backToAppRoute,
                        ),
                  )),
            );
          },
          icon: Icon(Icons.login),
          label: Text(buttonName));
      /* } else {
          return CircularProgressIndicator();
        }*/
    });
  }
}
