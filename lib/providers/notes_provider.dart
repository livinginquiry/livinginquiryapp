// import 'dart:async';

import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yaml/yaml.dart';

import '../models/note.dart';

final worksheetDb = Provider<WorksheetDb>((ref) => WorksheetDb());
final worksheetDbProvider = FutureProvider.autoDispose<Database>((ref) async {
  return ref.watch(worksheetDb).database;
});

final worksheetNotifierProvider =
    AsyncNotifierProvider.autoDispose<WorksheetNotifier, List<Worksheet>>(WorksheetNotifier.new);

final worksheetTypeProvider = Provider<WorksheetTypeRepository>((ref) => WorksheetTypeRepository());

class WorksheetEventNotifier extends StateNotifier<WorksheetEvent> {
  WorksheetEventNotifier() : super(WorksheetEvent(WorksheetEventType.Default, List.empty()));
}

final worksheetEventProvider =
    StateNotifierProvider<WorksheetEventNotifier, WorksheetEvent>((ref) => WorksheetEventNotifier());

class WorksheetDb {
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
      print("executing create query from onCreate callback");
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
}

class WorksheetRepository {
  WorksheetRepository(this.ref);
  final Ref ref;

  Future<int> addWorksheet(Worksheet note) async {
    final db = await ref.read(worksheetDbProvider.future);
    return db.insert(
      'notes',
      note.id == -1 ? note.toMap(false) : note.toMap(true),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> archiveWorksheet(Worksheet note) async {
    if (note.id != -1) {
      final db = await ref.read(worksheetDbProvider.future);

      int? idToUpdate = note.id;

      db.update("notes", note.toMap(true), where: "id = ?", whereArgs: [idToUpdate]);
    } else {
      print("Ignoring unsaved note");
    }
  }

  Future<int> deleteWorksheet(int id) async {
    final db = await ref.read(worksheetDbProvider.future);
    return db.delete("notes", where: "id = ?", whereArgs: [id]);
  }

  Future<List<Worksheet>> getWorksheets() async {
    final db = await ref.read(worksheetDbProvider.future);
    // query all the notes sorted by last edited
    var res = await db.query("notes", orderBy: "date_last_edited desc", where: "is_archived = ?", whereArgs: [0]);
    List<Worksheet> notes = res.isNotEmpty ? res.map((note) => Worksheet.fromJson(note)).toList() : [];

    return notes;
  }
}

enum WorksheetEventType { Default, Reloaded, Added, Modified, Archived, Deleted }

class WorksheetEvent {
  WorksheetEvent(this.type, this.worksheets, {this.worksheet}) : this.timestamp = DateTime.now();
  final DateTime timestamp;
  final WorksheetEventType type;
  final Worksheet? worksheet;
  final List<Worksheet> worksheets;

  bool operator ==(o) => o is WorksheetEvent && o.type == type && o.timestamp == timestamp;
  @override
  int get hashCode => Object.hash(type, timestamp);
}

class WorksheetNotifier extends AutoDisposeAsyncNotifier<List<Worksheet>> {
  @override
  FutureOr<List<Worksheet>> build() {
    return WorksheetRepository(ref).getWorksheets().then((worksheets) {
      final provider = ref.read(worksheetEventProvider.notifier);
      provider.state = WorksheetEvent(WorksheetEventType.Reloaded, worksheets);
      return worksheets;
    });
  }

  Future<int> addWorksheet(Worksheet worksheet) async {
    final repo = WorksheetRepository(ref);
    state = const AsyncLoading();
    worksheet.dateLastEdited = DateTime.now();
    final res = await repo.addWorksheet(worksheet);
    if (res > 0) {
      final worksheets = await AsyncValue.guard(repo.getWorksheets);
      final cloned = Worksheet.clone(worksheet);
      cloned.id = res;
      worksheets.whenData((data) {
        final provider = ref.read(worksheetEventProvider.notifier);
        provider.state = WorksheetEvent(
            worksheet.id == -1 ? WorksheetEventType.Added : WorksheetEventType.Modified, data,
            worksheet: cloned);
      });
      state = worksheets;
    } else {
      throw new WorksheetDbException("Worksheet couldn't be added!");
    }
    return res;
  }

  Future<void> deleteWorksheet(int id) async {
    final repo = WorksheetRepository(ref);
    state = const AsyncLoading();
    final res = await repo.deleteWorksheet(id);
    if (res == 1) {
      final worksheets = await AsyncValue.guard(repo.getWorksheets);
      worksheets.whenData((data) {
        final provider = ref.read(worksheetEventProvider.notifier);
        provider.state = WorksheetEvent(WorksheetEventType.Deleted, data);
      });
      state = worksheets;
    } else {
      throw new WorksheetDbException("Worksheet couldn't be deleted!");
    }
  }

  Future<void> archiveWorksheet(Worksheet worksheet) async {
    final repo = WorksheetRepository(ref);
    state = const AsyncLoading();
    await repo.archiveWorksheet(worksheet);
    final worksheets = await AsyncValue.guard(repo.getWorksheets);
    worksheets.whenData((data) {
      final provider = ref.read(worksheetEventProvider.notifier);
      provider.state = WorksheetEvent(WorksheetEventType.Archived, data, worksheet: worksheet);
    });
    state = worksheets;
  }
}

class WorksheetDbException implements Exception {
  final String cause;
  WorksheetDbException(this.cause);
}

class WorksheetTypeRepository {
  Map<String, WorksheetContent>? _worksheets;

  Future<Map<String, WorksheetContent>?> getInquiryTypes() async {
    if (_worksheets != null) {
      return _worksheets;
    }
    var doc = loadYaml(await rootBundle.loadString('assets/question_types.yaml')) as Map;
    _worksheets = Map.unmodifiable(doc.map((k, v) => MapEntry(k.toString(), WorksheetContent.fromYamlMap(k, v))));

    return _worksheets;
  }
}
