class User {

  ///id, only ever modify this value from user_dao
  int? id;

  String email;
  String password;
  bool rememberPassword;
  bool isCurrentUser;
  String? uid;

  ///Most of the time we will just check if successful login state, but this is needed in the case of failed login transactions.
  bool hasLoggedIn = false;

  User({
    this.id,
    required this.email,
    required this.password,
    required this.rememberPassword,
    required this.isCurrentUser,
    this.uid,
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> answer = {
      'email': email,
      'password': password,
      'rememberPassword': rememberPassword,
      'isCurrentUser': isCurrentUser,
      'uid': uid,
    };
    return answer;
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'],
      password : map['password'],
      rememberPassword: map['rememberPassword'],
      isCurrentUser: map['isCurrentUser'],
      uid: map['uid'],
    );
  }

  bool isAdmin(){
    return email == 'maxjbh@hotmail.com';
  }

}
