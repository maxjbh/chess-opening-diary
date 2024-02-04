import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:developer' as developer;

import '../../logIn/log_in_cubit.dart';
import '../../model/user.dart' as local_user;
import '../../utils/global_tools.dart';


/*
 * Class containing all links to api, this way we wont have to worry about calling the reset token function in the main code.
 */
class ApiTools {

  static LogInCubit? logInCubit;

  static void setLogInCubit(LogInCubit logInCubit) {
    ApiTools.logInCubit = logInCubit;
  }

  static Future<List<String>> pointlessFuture() async {
    return ['TODO'];
  }

  static Future<void> logOutOfFirebase() async{
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> logOnToFirebase({required String email, required String password}) async{
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      logInCubit!.successfulConnexionLoad();
    } on FirebaseAuthException catch (e) {
      logInCubit?.emitInvalidCredentialState();
    }
  }

  static void launchConnexionEventListner() async {
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) {
      if (user != null) {
        local_user.User? localUser = logInCubit?.user;
        localUser?.hasLoggedIn = true;
        localUser?.uid = user.uid;
      } else {
        local_user.User? localUser = logInCubit?.user;
        localUser?.hasLoggedIn = false;
      }
    });
  }

  ///Checks internet status if we are on the mobile version.
  ///Then checks if user is logged on to firestore
  static Future<ConnexionStatus> getConnexionStatus() async {
    if (await GlobalTools.doHaveConnexion()) {
      local_user.User? user;
      if (logInCubit != null) {
        user = logInCubit!.user;
      }
      if (user != null && user.hasLoggedIn) {
        return ConnexionStatus.logged;
      } else {
        debugPrint('NOT LOGGED IN');
        //For now just
        logInCubit?.onNotLoggedInRealisation();
        return ConnexionStatus.notLogged;
      }
    } else {
      debugPrint('NO INTERNET');
      logInCubit?.onNoInternetInRealisation();
      return ConnexionStatus.noInternet;
    }
  }

}

enum ConnexionStatus { logged, noInternet, notLogged, expired }
