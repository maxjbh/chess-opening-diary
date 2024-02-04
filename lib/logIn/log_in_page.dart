import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;

import '../model/user.dart';
import '../utils/global_tools.dart';
import 'log_in_cubit.dart';

class LogInPage extends StatelessWidget {
  final String title = GlobalTools.appTitle;
  final String backToAppRoute;

  LogInPage({required this.backToAppRoute});

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<LogInCubit>(context).startLogInTransaction();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: BlocListener<LogInCubit, LogInState>(
          listener: (context, state) {
            if (state is SuccessfulLogInState) {
              BlocProvider.of<LogInCubit>(context).obscurePassword = true;
              Navigator.pushNamedAndRemoveUntil(
                  context,
                  backToAppRoute,
                  (Route<dynamic> route) => false);
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LogInFields(),
              //LogIn button---------------------------
              BlocBuilder<LogInCubit, LogInState>(
                builder: (context, state) {
                  if (!(state is SuccessfulLogInState)) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(width: 0, height: 0),
                            ElevatedButton.icon(
                                onPressed: () async {
                                  BlocProvider.of<LogInCubit>(context)
                                      .logInAttempt();
                                },
                                icon: Icon(Icons.login),
                                label: Text('Log in')),
                          ]),
                    );
                  } else {
                    return Container(width: 0, height: 0);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LogInFields extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //User-----------------------------
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Identifiant :'),
        ),

        BlocBuilder<LogInCubit, LogInState>(
          builder: (context, state) {
            if (!(state is SuccessfulLogInState)) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: TextField(
                  key: const Key('emailTextField'),
                  obscureText: false,
                  controller: TextEditingController(text: (state.newUser!=null ? (state.newUser as User).email : '')),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.person),
                    labelText: 'E-mail',
                  ),
                  onChanged: (String value) {
                    BlocProvider.of<LogInCubit>(context).newUser?.email = value;
                  },
                ),
              );
            } else {
              return Container(width: 0, height: 0);
            }
          },
        ),

        //Password---------------------------
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Password :'),
        ),
        BlocBuilder<LogInCubit, LogInState>(
          builder: (context, state) {
            if (!(state is SuccessfulLogInState)) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: TextField(
                  key: const Key('passwordTextField'),
                  obscureText: BlocProvider.of<LogInCubit>(context).obscurePassword,
                  controller:
                      TextEditingController(text: (state.newUser!=null ? (state.newUser as User).password : '')),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.remove_red_eye),
                      onPressed: (){BlocProvider.of<LogInCubit>(context).togglePasswordVisible();},
                    ),
                    icon: Icon(Icons.lock),
                    labelText: 'Mot de passe',
                  ),
                  onSubmitted:(val){BlocProvider.of<LogInCubit>(context)
                      .logInAttempt();},
                  onChanged: (String value) {
                    BlocProvider.of<LogInCubit>(context).newUser?.password =
                        value;

                  },
                ),
              );
            } else {
              return Container(width: 0, height: 0);
            }
          },
        ),
        BlocBuilder<LogInCubit, LogInState>(
          builder: (context, state) {
            if (!(state is SuccessfulLogInState)) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Remember password : '),
                  Checkbox(
                    value: (state.newUser!=null ? (state.newUser as User).rememberPassword : false),
                    onChanged: (value) {
                      BlocProvider.of<LogInCubit>(context)
                          .toggleRememberPassword();
                    },
                  ),
                ],
              );
            } else {
              return Container(width: 0, height: 0);
            }
          },
        ),
        //Error messages--------------------------
        BlocBuilder<LogInCubit, LogInState>(
          builder: (context, state) {
            if (state is NoInternetState || state is InvalidCredentialsState) {
              developer.log('made it to error creation',name: "log_in_page.BlocBuilder");
              String errorMessage = "";
              if (state is NoInternetState) {
                errorMessage = 'You have no internet!';
              }
              if (state is InvalidCredentialsState) {
                errorMessage = 'email or passwor invalid!';
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    errorMessage,
                    textScaleFactor: 1.0,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            } else {
              return Container(width: 0, height: 0);
            }
          },
        ),
      ],
    );
  }
}
