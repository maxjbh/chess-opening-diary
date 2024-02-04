import 'package:flutter/material.dart';

import '../../model/user.dart';

import '../../utils/local_database.dart';
import 'package:sembast/sembast.dart';

class UserDao{
  static const String USER_STORE_NAME = 'users';
  static UserDao userDao = UserDao();
  // A Store with int keys and Map<String, dynamic> values.
  // This Store acts like a persistent map, values of which are Fruit objects converted to Map
  final _store = intMapStoreFactory.store(USER_STORE_NAME);

  // Private getter to shorten the amount of code needed to get the
  // singleton instance of an opened database.
  Future<Database> get _db async => await LocalDatabase.instance.database;

  ///Inserts user if it doesn't have an id, otherwise call update.
  Future<User> insert(User user) async {
    if(user.id!=null){
      await update(user);
      return user;
    }
    var key = await _store.add(await _db, user.toMap());
    //set id
    await _store.update(await _db, {'id': key});
    user.id = key;
    return user;

  }
  Future deleteAll() async{
    _store.delete(await _db);
  }
  Future update(User user) async {
    if(user.id != null){
      await _store.record(user.id as int).update(
        await _db,
        user.toMap(),
      );
    }

  }
  Future delete(User user) async {
    if(user!=null) {
      final finder = Finder(filter: Filter.byKey(user.id));
      await _store.delete(
        await _db,
        finder: finder,
      );
    }
  }

  ///Function to fetch the last known connected user on startup
  Future<User?> getLastConnectedUser() async {
    List<User> allUsers = await getAll(isLastLoggedUser: true);
    User? answer;
    if(allUsers.isNotEmpty){
      if(allUsers.length>1){
        throw Exception('Multiple users in local database have isCurrentUser = true.');
      }
      answer = allUsers.first;
    }
    return answer;
  }
  Future<List<User>> getAll({String? uid, String? email, bool? isLastLoggedUser}) async {
    List<Filter> filters = [];
    if(isLastLoggedUser!=null){
      filters.add(Filter.equals('isCurrentUser', isLastLoggedUser));
    }
    if(uid!=null && uid!=''){
      filters.add(Filter.equals('uid', uid));
    }
    if(email!=null && email!=''){
      filters.add(Filter.equals('email', email));
    }
    // Finder object can also sort data.
    final finder = Finder(sortOrders: [
      SortOrder('email'),
    ],
    filter: Filter.and(filters));

    final recordSnapshots = await _store.find(
      await _db,
      finder: finder,
    );

    // Making a List<Form> out of List<RecordSnapshot>
    return recordSnapshots.map((snapshot) {

      final user = User.fromMap(snapshot.value);
      // An ID is a key of a record from the database.
      user.id = snapshot.key;

      return user;
    }).toList();
  }

}
