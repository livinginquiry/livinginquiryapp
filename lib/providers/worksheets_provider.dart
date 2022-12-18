// import 'dart:async';

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yaml/yaml.dart';

import '../models/worksheet.dart';

final worksheetDb = Provider<WorksheetDb>((ref) => WorksheetDb());
final worksheetDbProvider = FutureProvider.autoDispose<Database>((ref) async {
  return ref.watch(worksheetDb).database;
});

final worksheetNotifierProvider =
    AsyncNotifierProvider.autoDispose<WorksheetNotifier, List<Worksheet>>(WorksheetNotifier.new);

final worksheetTypeProvider = Provider<WorksheetTypeRepository>((ref) => WorksheetTypeRepository());
final worksheetRepoProvider = Provider<WorksheetRepository>((ref) => WorksheetRepository(ref));

class WorksheetEventNotifier extends StateNotifier<WorksheetEvent> {
  WorksheetEventNotifier() : super(WorksheetEvent(WorksheetEventType.Default, List.empty()));
}

final worksheetEventProvider =
    StateNotifierProvider<WorksheetEventNotifier, WorksheetEvent>((ref) => WorksheetEventNotifier());

final childWorksheetsProvider = FutureProvider.autoDispose.family<List<Worksheet>, int>((ref, id) async {
  final repo = ref.watch(worksheetRepoProvider);
  return repo.getChildWorksheets(id);
});

class WorksheetDb {
  final databaseName = "notes.db";
  final tableName = "notes";
  static const migrationScripts = [
    'alter table notes add column is_complete integer default 0;',
    "alter table notes add column parent_id integer default -1;",
    "create index idx_notes_parent_id on notes (parent_id);"
  ];

  final fieldMap = {
    "id": "INTEGER PRIMARY KEY AUTOINCREMENT",
    "title": "BLOB",
    "content": "BLOB",
    "date_created": "INTEGER",
    "date_last_edited": "INTEGER",
    "note_color": "INTEGER",
    "is_archived": "INTEGER",
    "is_complete": "INTEGER",
    "parent_id": "INTEGER DEFAULT -1"
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
    Database dbConnection = await openDatabase(dbPath, version: 4, onCreate: (Database db, int version) async {
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

  Future<int> addWorksheet(Worksheet worksheet) async {
    final db = await ref.read(worksheetDbProvider.future);
    return db.insert(
      'notes',
      worksheet.id == -1 ? worksheet.toMap(false) : worksheet.toMap(true),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> archiveWorksheet(Worksheet worksheet) async {
    if (worksheet.id != -1) {
      final db = await ref.read(worksheetDbProvider.future);

      int? idToUpdate = worksheet.id;

      db.update("notes", worksheet.toMap(true), where: "id = ?", whereArgs: [idToUpdate]);
    } else {
      print("Ignoring unsaved note");
    }
  }

  Future<int> deleteWorksheet(int id) async {
    final db = await ref.read(worksheetDbProvider.future);
    return db.delete("notes", where: "id = ?", whereArgs: [id]);
  }

  Future<Worksheet?> getWorksheet(int id) async {
    final db = await ref.read(worksheetDbProvider.future);
    final res = await db.query("notes", where: "id = ?", whereArgs: [id], distinct: true);
    return res.isNotEmpty ? res.map((worksheet) => Worksheet.fromJson(worksheet)).firstOrNull : null;
  }

  Future<List<Worksheet>> getWorksheets() async {
    final db = await ref.read(worksheetDbProvider.future);
    // query all the worksheets sorted by last edited
    var res = await db.query("notes", orderBy: "date_created desc", where: "is_archived = ?", whereArgs: [0]);
    return res.isNotEmpty ? res.map((worksheet) => Worksheet.fromJson(worksheet)).toList() : [];
  }

  Future<List<Worksheet>> getChildWorksheets(int id) async {
    final db = await ref.read(worksheetDbProvider.future);
    final res =
        await db.query("notes", where: "parent_id = ? or id = ?", whereArgs: [id, id], orderBy: "date_created desc");
    return res.isNotEmpty ? res.map((worksheet) => Worksheet.fromJson(worksheet)).toList() : [];
  }

  Future<int> updateChildren(int id) async {
    final db = await ref.read(worksheetDbProvider.future);
    return db.update("notes", {"parent_id": -1}, where: "parent_id = ?", whereArgs: [id]);
  }
}

enum WorksheetEventType { Default, Reloaded, Added, Modified, Archived, Deleted }

class WorksheetEvent {
  WorksheetEvent(this.type, this.worksheets, {this.worksheet, this.worksheetId}) : this.timestamp = DateTime.now();
  final DateTime timestamp;
  final WorksheetEventType type;
  final Worksheet? worksheet;
  final List<Worksheet> worksheets;
  final int? worksheetId;

  bool operator ==(o) => o is WorksheetEvent && o.type == type && o.timestamp == timestamp;
  @override
  int get hashCode => Object.hash(type, timestamp);

  @override
  String toString() {
    return "WorksheetEvent(type: $type, timestamp: $timestamp, worksheet: $worksheet, worksheets: $worksheets, worksheetId: $worksheetId)";
  }
}

class WorksheetNotifier extends AutoDisposeAsyncNotifier<List<Worksheet>> {
  @override
  FutureOr<List<Worksheet>> build() {
    final repo = ref.watch(worksheetRepoProvider);
    return repo.getWorksheets().then((worksheets) {
      final provider = ref.read(worksheetEventProvider.notifier);
      provider.state = WorksheetEvent(WorksheetEventType.Reloaded, worksheets);
      return worksheets;
    });
  }

  Future<int> addWorksheet(Worksheet worksheet) async {
    final repo = ref.watch(worksheetRepoProvider);
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
            worksheet: cloned, worksheetId: cloned.id);
      });

      state = worksheets;
    } else {
      throw new WorksheetDbException("Worksheet couldn't be added!");
    }
    return res;
  }

  Future<void> deleteWorksheet(int id) async {
    final repo = ref.watch(worksheetRepoProvider);
    state = const AsyncLoading();
    final ws = await repo.getWorksheet(id);
    if (ws == null) {
      print("Worksheet $id not found!");
      return;
    }
    final res = await repo.deleteWorksheet(id);

    if (res == 1) {
      await repo.updateChildren(id);
      final asyncWorksheets = await AsyncValue.guard(repo.getWorksheets);
      asyncWorksheets.whenData((worksheets) async {
        final provider = ref.read(worksheetEventProvider.notifier);
        provider.state = WorksheetEvent(WorksheetEventType.Deleted, worksheets, worksheetId: id);
      });
      state = asyncWorksheets;
    } else {
      final exception = new WorksheetDbException("Worksheet $id couldn't be deleted!");
      state = AsyncError(exception, StackTrace.current);
    }
  }

  Future<void> archiveWorksheet(Worksheet worksheet) async {
    final repo = ref.watch(worksheetRepoProvider);
    state = const AsyncLoading();
    await repo.archiveWorksheet(worksheet);
    final worksheets = await AsyncValue.guard(repo.getWorksheets);
    worksheets.whenData((data) {
      final provider = ref.read(worksheetEventProvider.notifier);
      provider.state =
          WorksheetEvent(WorksheetEventType.Archived, data, worksheet: worksheet, worksheetId: worksheet.id);
    });
    state = worksheets;
  }

  List<Worksheet>? getCachedChildren(int id) {
    return state.value?.where((e) => e.parentId == id).toList(growable: false);
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

  Map<String, WorksheetContent>? getCachedInquiryTypes() {
    return _worksheets;
  }
}
