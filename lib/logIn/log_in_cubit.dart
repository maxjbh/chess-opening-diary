import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../dal/api/api_tools.dart';
import '../dal/local/user_dao.dart';
import '../model/user.dart';
import '../utils/global_tools.dart';


part 'log_in_state.dart';

class LogInCubit extends Cubit<LogInState> {
  User? user;
  //an object to save old connected user between start of login page and successfull login
  User? newUser;
  bool obscurePassword = true;

  LogInCubit() : super(LogInState()){
    debugPrint('get last connected user');
    _updateCurrentUser();
  }

  void emitInvalidCredentialState(){
    emit(InvalidCredentialsState(newUser: newUser, user: user));
  }

  ///Function to run when token has expired, emits LogInExpired state. A listener will show a message
  void setToExpired(){
    if(user != null){
      user?.hasLoggedIn = false;
      emit(LogInExpiredState());
    }
  }
  ///Function to emit a state when an api call fails because we're not logged in
  void onNotLoggedInRealisation(){
    emit(NotLoggedInState());
  }
  ///Function to emit a state when an api call fails because we have no internet
  void onNoInternetInRealisation(){
    emit(NoInternetState(newUser: newUser, user: user));
  }

  void togglePasswordVisible(){
    obscurePassword = !obscurePassword;
    emit(TransitionState(newUser: newUser, user: user));
  }

  ///To be called at the start of login transaction
  void startLogInTransaction(){
    //initialise empty user so we don't call operations on null
    if(user==null){
      debugPrint('setting user as it was null');
      newUser = User(email: '', password: '', rememberPassword: false, isCurrentUser: false);
    }
    else{
      User nonNullUser = user as User;
      newUser = User(email: nonNullUser.email, password: nonNullUser.password, rememberPassword: nonNullUser.rememberPassword, isCurrentUser: false);
    }
    emit(TransitionState(newUser: newUser, user: user));
  }

  void toggleRememberPassword() {
    if(newUser != null){
      User nonNullNewUser = newUser as User;
      nonNullNewUser.rememberPassword = nonNullNewUser.rememberPassword;
      newUser = nonNullNewUser;
      emit(TransitionState(newUser: newUser, user: user));
    }
  }
  ///Emit no user state if user is null, have a user state otherwise
  void _emitUser(){
    if(user != null) {
      if((user as User).hasLoggedIn){
        emit(SuccessfulLogInState(user: user));
      }
      else{
        emit(HaveAUserState(user: user));
      }
    }
    else{
      emit(NoUserState());
    }
  }

  ///check current user isn't null due to a shut down and reset it if so
  void _updateCurrentUser() async{
    if(user == null){
      user = await UserDao.userDao.getLastConnectedUser();
    }
    _emitUser();
  }
  ///public version of set current user to allow changing of user
  void setCurrentUser(User newUser) async{
    this.newUser = newUser;
    await _resetCurrentUser();
    emit(HaveAUserState(user: user));
  }
  ///unsets old current user, updates database, sets new current user then updates database again. Optional: a user to set to
  Future<void> _resetCurrentUser() async{
    if(user!=null) {
      User nonNullUser = user as User;
      if(nonNullUser.hasLoggedIn){
        await logOut();
      }
      user?.isCurrentUser = false;
      user?.hasLoggedIn = false;
      if(user != null){
        await UserDao.userDao.update(user as User);
      }
    }
    newUser?.isCurrentUser = true;
    user = newUser;
    if(newUser != null){
      await UserDao.userDao.update(newUser as User);
    }
  }
  Future<void> logOut() async{
    await ApiTools.logOutOfFirebase();
    emit(NotLoggedInState());
  }
  void logInAttempt() async {
    debugPrint('attempting to log in');
    if (await GlobalTools.doHaveConnexion()) {
      debugPrint('found connexion');
      if(user !=null){
        ApiTools.logOnToFirebase(email: (user as User).email , password: (user as User).password);
      }else{
        debugPrint("In log in cubit, user object is null");
      }
    } else {
      debugPrint('no internet');
      emit(NoInternetState(newUser: newUser, user: user));
    }
  }
  ///Things to load after a connexion has been made
  void successfulConnexionLoad() async{
    newUser?.hasLoggedIn = true;
    //ApiTools.setLogInCubit(this);
    //Add user to remembered users , set password to '' if we don't want to remember it!
    if (!newUser!.rememberPassword) {
      newUser?.password = '';
    }
    //Before inserting new user we have to check if this user is already in the database manually
    List<User> temp = await UserDao.userDao.getAll(uid: newUser?.uid, email: newUser?.email);
    if(temp!=null&&temp.isNotEmpty){
      User tempUser = temp.first;
      //Things that don't change during a log in:
      newUser?.id = tempUser.id;
      newUser?.uid = tempUser.uid;
    }
    if(newUser != null){
      newUser = await UserDao.userDao.insert(newUser as User);

      await _resetCurrentUser();
      emit(SuccessfulLogInState(user: user));
    }

  }
}
