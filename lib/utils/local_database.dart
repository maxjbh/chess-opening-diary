import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart' as web;
import 'package:flutter/foundation.dart' show kIsWeb;
class LocalDatabase{
  //Singleton instance
  static final LocalDatabase _singleton = LocalDatabase._();

  //Singleton accessor
  static LocalDatabase get instance => _singleton;

  // Completer is used for transforming synchronous code into asynchronous code.
  Completer<Database>? _dbOpenCompleter;

  //a private constructor
  LocalDatabase._();

  // Sembast database object
  //Database _database;

  // Database object accessor
  Future<Database> get database async {
    // If completer is null, AppDatabaseClass is newly instantiated, so database is not yet opened
    //_deleteDatabase();
    if (_dbOpenCompleter == null) {
      _dbOpenCompleter = Completer();
      // Calling _openDatabase will also complete the completer with database instance

      _openDatabase(kIsWeb);
    }
    // If the database is already opened, awaiting the future will happen instantly.
    // Otherwise, awaiting the returned future will take some time - until complete() is called
    // on the Completer in _openDatabase() below.
    return _dbOpenCompleter!.future;
  }

  //opens the sembast database, will only get called once
  Future _openDatabase(bool onWeb) async {
    // Get a platform-specific directory where persistent app data can be stored
    var appDocumentDir;
    if(onWeb){
      appDocumentDir =null;
    }else{
      appDocumentDir = await getApplicationDocumentsDirectory();
    }
    // Path with the form: /platform-specific-directory/demo.db
    final dbPath = join((appDocumentDir==null ? '' : appDocumentDir.path), 'local.db');

    Database database;
    //web
    if(onWeb){
      var webFactory = web.databaseFactoryWeb;
      database = await webFactory.openDatabase(dbPath);
    }else{
      database = await databaseFactoryIo.openDatabase(dbPath);
    }

    // Any code awaiting the Completer's future will now start executing
    _dbOpenCompleter!.complete(database);
  }
  Future _deleteDatabase() async{
    // Get a platform-specific directory where persistent app data can be stored
    final appDocumentDir = await getApplicationDocumentsDirectory();
    // Path with the form: /platform-specific-directory/demo.db
    final dbPath = join(appDocumentDir.path, 'local.db');
    await databaseFactoryIo.deleteDatabase(dbPath);
    //supposed to close the db before deleting

  }
}