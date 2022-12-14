import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

import '../models/note.dart';

class DbProvider {
  final databaseName = "notes.db";
  final tableName = "notes";
  static const migrationScripts = ['alter table notes add column is_complete integer default 0;'];

  final fieldMap = {
    "id": "INTEGER PRIMARY KEY AUTOINCREMENT",
    "title": "BLOB",
    "content": "BLOB",
    "date_created": "INTEGER",
    "date_last_edited": "INTEGER",
    "note_color": "INTEGER",
    "is_archived": "INTEGER",
    "is_complete": "INTEGER"
  };

  Database? _database;

  Future<Database> get database async => _database ??= await initDB();

  deleteDb() async {
    var path = await getDatabasesPath();
    await deleteDatabase(path);
  }

  initDB() async {
    var path = await getDatabasesPath();
    var dbPath = join(path, 'notes.db');
    // ignore: argument_type_not_assignable
    Database dbConnection = await openDatabase(dbPath, version: 2, onCreate: (Database db, int version) async {
      await db.execute(_buildCreateQuery());
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      print("upgrading from $oldVersion to $newVersion");
      for (var i = oldVersion - 1; i < newVersion - 1; i++) {
        await db.execute(migrationScripts[i]);
      }
    });

    await dbConnection.execute(_buildCreateQuery());
    return dbConnection;
  }

// build the create query dynamically using the column:field dictionary.
  String _buildCreateQuery() {
    String query = "CREATE TABLE IF NOT EXISTS ";
    query += tableName;
    query += "(";
    fieldMap.forEach((column, field) {
      print("$column : $field");
      query += "$column $field,";
    });

    query = query.substring(0, query.length - 1);
    query += " )";

    return query;
  }

  Future<int> addNote(Worksheet note) async {
    // Get a reference to the database
    final Database db = await database;

    // Insert the Notes into the correct table.
    return await db.insert(
      'notes',
      note.id == -1 ? note.toMap(false) : note.toMap(true),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> copyNote(Worksheet note) async {
    final Database db = await (database as FutureOr<Database>);
    try {
      await db.insert("notes", note.toMap(false), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print(e);
      return false;
    }
    return true;
  }

  Future<void> archiveNote(Worksheet note) async {
    if (note.id != -1) {
      final Database db = await (database as FutureOr<Database>);

      int idToUpdate = note.id;

      db.update("notes", note.toMap(true), where: "id = ?", whereArgs: [idToUpdate]);
    }
  }

  Future<bool> deleteNote(int id) async {
    final Database db = await (database as FutureOr<Database>);
    try {
      await db.delete("notes", where: "id = ?", whereArgs: [id]);
      return true;
    } catch (e) {
      print("Error deleting $id: ${e.toString()}");
      return false;
    }
  }

  Future<List<Worksheet>> getWorksheets() async {
    final Database db = await (database as FutureOr<Database>);
    // query all the notes sorted by last edited
    var res = await db.query("notes", orderBy: "date_last_edited desc", where: "is_archived = ?", whereArgs: [0]);
    List<Worksheet> notes = res.isNotEmpty ? res.map((note) => Worksheet.fromJson(note)).toList() : [];

    return notes;
  }
}
