import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class WorksheetDb {
  final databaseName = "notes.db";
  final tableName = "notes";
  static const migrationScripts = [
    'alter table notes add column is_complete integer default 0;',
    "alter table notes add column parent_id integer default -1;",
    "create index idx_notes_parent_id on notes (parent_id);",
    "alter table notes add column tags text;",
    "update notes set is_archived=1, is_complete=0 where is_complete=1;",
    "alter table notes rename column is_complete to is_starred;"
  ];

  final fieldMap = {
    "id": "INTEGER PRIMARY KEY AUTOINCREMENT",
    "title": "BLOB",
    "content": "BLOB",
    "date_created": "INTEGER",
    "date_last_edited": "INTEGER",
    "note_color": "INTEGER",
    "is_archived": "INTEGER",
    "is_starred": "INTEGER",
    "parent_id": "INTEGER DEFAULT -1",
    "tags": "TEXT"
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
    Database dbConnection = await openDatabase(dbPath, version: 7, onCreate: (Database db, int version) async {
      print("executing create query from onCreate callback: ${_buildCreateQuery()}");
      await db.execute(_buildCreateQuery());
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      print("upgrading from $oldVersion to $newVersion");
      for (var i = oldVersion - 1; i < newVersion - 1; i++) {
        print("executing migration script ${migrationScripts[i]}");
        await db.execute(migrationScripts[i]);
      }
      print("completed migration");
    });

    return dbConnection;
  }

// build the create query dynamically using the column:field dictionary.
  String _buildCreateQuery() {
    String query = "CREATE TABLE IF NOT EXISTS ";
    query += tableName;
    query += "(";
    fieldMap.forEach((column, field) {
      query += "$column $field,";
    });

    query = query.substring(0, query.length - 1);
    query += " )";

    return query;
  }
}
