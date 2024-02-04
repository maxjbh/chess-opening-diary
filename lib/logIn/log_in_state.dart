part of 'log_in_cubit.dart';

class LogInState {
  User? user;
  User? newUser;
  LogInState({this.user, this.newUser});

}
class LogInExpiredState extends LogInState{}
class NotLoggedInState extends LogInState{}

class HaveAUserState extends LogInState{
  HaveAUserState({@required user}):super(user: user);
}
class NoUserState extends LogInState{
  NoUserState():super();
}
class SuccessfulLogInState extends LogInState{
  SuccessfulLogInState({@required user}):super(user: user);
}
class TransitionState extends LogInState{
  TransitionState({@required newUser, @required user}):super(newUser: newUser, user: user);
}
class InvalidCredentialsState extends LogInState{
  InvalidCredentialsState({@required newUser, @required user}):super(newUser: newUser, user: user);
}
class NoInternetState extends LogInState{
  NoInternetState({@required newUser, @required user}):super(newUser: newUser, user: user);
}

