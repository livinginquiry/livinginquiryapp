// import 'dart:async';

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tuple/tuple.dart';
import 'package:yaml/yaml.dart';

import '../models/worksheet.dart';

class WorksheetDb {
  final databaseName = "notes.db";
  final tableName = "notes";
  static const migrationScripts = [
    'alter table notes add column is_complete integer default 0;',
    "alter table notes add column parent_id integer default -1;",
    "create index idx_notes_parent_id on notes (parent_id);",
    "alter table notes add column tags text;"
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
    Database dbConnection = await openDatabase(dbPath, version: 5, onCreate: (Database db, int version) async {
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
      query += "$column $field,";
    });

    query = query.substring(0, query.length - 1);
    query += " )";

    return query;
  }
}

final worksheetDb = Provider<WorksheetDb>((ref) => WorksheetDb());
final worksheetDbProvider = FutureProvider.autoDispose<Database>((ref) async {
  return ref.watch(worksheetDb).database;
});

final worksheetNotifierProvider =
    AsyncNotifierProvider.autoDispose<WorksheetNotifier, WorksheetPayload>(WorksheetNotifier.new);

final worksheetTypeProvider = Provider<WorksheetTypeRepository>((ref) => WorksheetTypeRepository());
final worksheetRepoProvider = Provider<WorksheetRepository>((ref) => WorksheetRepository(ref));
final stopWordsProvider = Provider<StopWordsRepository>((ref) => StopWordsRepository());

class WorksheetEventNotifier extends StateNotifier<WorksheetEvent> {
  WorksheetEventNotifier() : super(WorksheetEvent(WorksheetEventType.Default, List.empty()));
}

final worksheetEventProvider =
    StateNotifierProvider<WorksheetEventNotifier, WorksheetEvent>((ref) => WorksheetEventNotifier());

final childWorksheetsProvider = FutureProvider.autoDispose.family<List<Worksheet>, int>((ref, id) async {
  final repo = ref.watch(worksheetRepoProvider);
  return repo.getChildWorksheets(id);
});

class WorksheetFilter {
  final bool includeDone;
  final bool includeArchived;
  final bool shouldRefresh;
  final String? query;
  WorksheetFilter(this.includeDone, {this.includeArchived = false, this.shouldRefresh = true, this.query});

  bool operator ==(o) =>
      o is WorksheetFilter &&
      o.includeDone == includeDone &&
      o.includeArchived == includeArchived &&
      o.shouldRefresh == shouldRefresh &&
      o.query == query;

  @override
  int get hashCode => Object.hash(includeDone, includeArchived, shouldRefresh, query);

  @override
  String toString() {
    return "WorksheetFilter(includeDone: $includeDone, includeArchived: $includeArchived, shouldRefresh: $shouldRefresh, query: $query)";
  }
}

final filterProvider = StateProvider((ref) => WorksheetFilter(false));

class WorksheetRepository {
  LinkedHashMap<int, Worksheet>? _cache;

  WorksheetRepository(this.ref);
  final Ref ref;

  Future<int> addWorksheet(Worksheet worksheet) async {
    final db = await ref.read(worksheetDbProvider.future);
    final result = await db.insert(
      'notes',
      worksheet.id == -1 ? worksheet.toMap(false) : worksheet.toMap(true),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (result > 0) {
      _cache = null;
    }
    return result;
  }

  Future<void> archiveWorksheet(Worksheet worksheet) async {
    if (worksheet.id != -1) {
      final db = await ref.read(worksheetDbProvider.future);

      int? idToUpdate = worksheet.id;

      final result = await db.update("notes", worksheet.toMap(true), where: "id = ?", whereArgs: [idToUpdate]);
      if (result > 0) {
        _cache = null;
      }
    } else {
      print("Ignoring unsaved note");
    }
  }

  Future<int> deleteWorksheet(int id) async {
    final db = await ref.read(worksheetDbProvider.future);
    final result = await db.delete("notes", where: "id = ?", whereArgs: [id]);
    if (result > 0) {
      _cache?.remove(result);
    }
    return result;
  }

  Future<Worksheet?> getWorksheet(int id) async {
    final cached = _cache?[id];
    if (cached != null) {
      return cached;
    } else {
      final db = await ref.read(worksheetDbProvider.future);
      final res = await db.query("notes", where: "id = ?", whereArgs: [id], distinct: true);
      return res.isNotEmpty ? res.map((worksheet) => Worksheet.fromJson(worksheet)).firstOrNull : null;
    }
  }

  Future<List<Worksheet>> getWorksheets(/*{bool includeArchived = false}*/) async {
    final cached = _cache?.values.toList(growable: false);
    if (cached != null) {
      return cached;
    } else {
      final db = await ref.read(worksheetDbProvider.future);

      // query all the worksheets sorted by last edited
      /* var res = await db
          .query("notes", orderBy: "date_created desc", where: "is_archived = ?", whereArgs: [includeArchived ? 1 : 0]);*/
      // include all worksheets for now
      var res = await db.query("notes", orderBy: "date_created desc");
      final List<Worksheet> result =
          res.isNotEmpty ? res.map((worksheet) => Worksheet.fromJson(worksheet)).toList() : [];
      final cache = LinkedHashMap<int, Worksheet>();
      result.forEach((ws) {
        cache[ws.id] = ws;
      });
      _cache = cache;
      return result;
    }
  }

  bool hasCache() {
    return _cache != null;
  }

  Future<List<Worksheet>> getChildWorksheets(int id) async {
    final db = await ref.read(worksheetDbProvider.future);
    final res =
        await db.query("notes", where: "parent_id = ? or id = ?", whereArgs: [id, id], orderBy: "date_created desc");
    return res.isNotEmpty ? res.map((worksheet) => Worksheet.fromJson(worksheet)).toList() : [];
  }

  Future<int> updateChildren(int id) async {
    final db = await ref.read(worksheetDbProvider.future);
    final result = await db.update("notes", {"parent_id": -1}, where: "parent_id = ?", whereArgs: [id]);

    if (result > 0) {
      _cache = null;
    }
    return result;
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

class WorksheetPayload {
  final List<Worksheet> worksheets;
  final WorksheetEvent event;
  WorksheetPayload(this.worksheets, this.event);

  bool operator ==(o) => o is WorksheetPayload && o.event == event && o.worksheets == worksheets;

  @override
  int get hashCode => Object.hash(event, worksheets);

  @override
  String toString() {
    return "WorksheetPayload(event: $event, worksheets: ${worksheets.map((w) => w.id).toList()})";
  }
}

class WorksheetNotifier extends AutoDisposeAsyncNotifier<WorksheetPayload> {
  @override
  FutureOr<WorksheetPayload> build() async {
    final filter = ref.watch(filterProvider);
    WorksheetPayload? oldValue = state.value;
    state = const AsyncLoading();
    final repo = ref.watch(worksheetRepoProvider);
    final wasCached = repo.hasCache();
    final results = await repo.getWorksheets();
    final stopWords = await ref.watch(stopWordsProvider).getStopWords();
    final filteredResults = applyFilter(filter, results, stopWords);
    WorksheetEvent event;
    if (!wasCached ||
        ((oldValue?.worksheets.map((ws) => ws.id).toSet() ?? <int>{}) != filteredResults.map((ws) => ws.id).toSet())) {
      final provider = ref.read(worksheetEventProvider.notifier);
      event = WorksheetEvent(WorksheetEventType.Reloaded, filteredResults);
      provider.state = event;
    } else {
      event = oldValue?.event ?? WorksheetEvent(WorksheetEventType.Default, filteredResults);
    }
    return WorksheetPayload(filteredResults, event);
  }

  Future<int> addWorksheet(Worksheet worksheet) async {
    final repo = ref.watch(worksheetRepoProvider);
    state = const AsyncLoading();
    worksheet.dateLastEdited = DateTime.now();
    final res = await repo.addWorksheet(worksheet);
    if (res > 0) {
      final asyncWorksheets = await AsyncValue.guard(repo.getWorksheets);
      final cloned = Worksheet.clone(worksheet);
      cloned.id = res;
      asyncWorksheets.whenData((worksheets) {
        final provider = ref.read(worksheetEventProvider.notifier);
        final event = WorksheetEvent(
            worksheet.id == -1 ? WorksheetEventType.Added : WorksheetEventType.Modified, worksheets,
            worksheet: cloned, worksheetId: cloned.id);
        provider.state = event;
        state = AsyncValue.data(WorksheetPayload(worksheets, event));
      });
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
        final event = WorksheetEvent(WorksheetEventType.Deleted, worksheets, worksheetId: id);
        provider.state = event;
        state = AsyncValue.data(WorksheetPayload(worksheets, event));
      });
    } else {
      final exception = new WorksheetDbException("Worksheet $id couldn't be deleted!");
      state = AsyncError(exception, StackTrace.current);
    }
  }

  Future<void> archiveWorksheet(Worksheet worksheet) async {
    final repo = ref.watch(worksheetRepoProvider);
    state = const AsyncLoading();
    await repo.archiveWorksheet(worksheet);
    final asyncWorksheets = await AsyncValue.guard(repo.getWorksheets);
    asyncWorksheets.whenData((worksheets) {
      final provider = ref.read(worksheetEventProvider.notifier);
      final event =
          WorksheetEvent(WorksheetEventType.Archived, worksheets, worksheet: worksheet, worksheetId: worksheet.id);
      provider.state = event;
      state = AsyncValue.data(WorksheetPayload(worksheets, event));
    });
  }

  List<Worksheet>? getCachedChildren(int id) {
    return state.value?.worksheets.where((e) => e.parentId == id).toList(growable: false);
  }

  Set<String> getCachedTags() {
    if (state.value?.worksheets.isNotEmpty ?? false) {
      return extractGlobalTags(state.value!.worksheets);
    } else {
      return <String>{};
    }
  }
}

final splitPattern = new RegExp(r"[,\s]");
List<Worksheet> applyFilter(WorksheetFilter filter, List<Worksheet> worksheets, Set<String> stopWords) {
  final base =
      worksheets.where((w) => (filter.includeArchived || !w.isArchived) && (filter.includeDone || !w.isComplete));
  if (filter.query == null) {
    return base.toList();
  } else if (filter.query!.isEmpty) {
    return <Worksheet>[];
  } else {
    final asTags = filter.query!.split(splitPattern).map((s) => s.trim()).where((w) => !stopWords.contains(w)).toSet();
    List<Tuple2<Worksheet, int>> tagged = [];
    List<Worksheet> matched = [];
    base
        .map((w) => Tuple2(
            w, w.tags?.isEmpty ?? true ? 0 : asTags.intersection(w.tags!.map((s) => s.toLowerCase()).toSet()).length))
        .forEach((t) {
      if (t.item2 > 0) {
        tagged.add(t);
      } else {
        if (t.item1.content.questions
                .map((q) => q.answer.toLowerCase())
                .firstWhereOrNull((a) => a.contains(filter.query!)) !=
            null) {
          matched.add(t.item1);
        }
      }
    });
    Set<Worksheet> result = tagged.sorted((t1, t2) => t2.item2.compareTo(t1.item2)).map((t) => t.item1).toSet();
    result.addAll(matched);
    return result.toList();
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
    final doc = loadYaml(await rootBundle.loadString('assets/question_types.yaml')) as Map;
    _worksheets = Map.unmodifiable(doc.map((k, v) => MapEntry(k.toString(), WorksheetContent.fromYamlMap(k, v))));

    return _worksheets;
  }

  Map<String, WorksheetContent>? getCachedInquiryTypes() {
    return _worksheets;
  }
}

class StopWordsRepository {
  Set<String>? _stopWords;

  Future<Set<String>> getStopWords() async {
    if (_stopWords != null) {
      return _stopWords!;
    }
    final String raw = await rootBundle.loadString('assets/stop_words.txt');
    LineSplitter ls = new LineSplitter();
    _stopWords = ls.convert(raw).map((s) => s.trim()).toSet();
    return _stopWords!;
  }
}

Set<String> extractGlobalTags(List<Worksheet> worksheets) {
  return worksheets.fold(HashSet<String>(), (set, ws) {
    if (ws.tags?.isNotEmpty ?? false) {
      set.addAll(ws.tags!);
    }
    return set;
  });
}
