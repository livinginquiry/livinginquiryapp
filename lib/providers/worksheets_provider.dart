import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:livinginquiryapp/providers/worksheet_db.dart';
import 'package:quiver/collection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yaml/yaml.dart';

import '../models/worksheet.dart';

final worksheetDb = Provider<WorksheetDb>((ref) => WorksheetDb());
final worksheetDbProvider = FutureProvider.autoDispose<Database>((ref) async {
  return ref.watch(worksheetDb).database;
});

final worksheetNotifierProvider =
    AsyncNotifierProvider.autoDispose<WorksheetNotifier, WorksheetPayload>(WorksheetNotifier.new);

final staticallyFilteredWorksheetProvider = AsyncNotifierProvider.autoDispose
    .family<WorksheetStaticFilterNotifier, WorksheetPayload, WorksheetFilter>(() => WorksheetStaticFilterNotifier());

final dynamicallyFilteredWorksheetProvider = AsyncNotifierProvider.autoDispose
    .family<WorksheetDynamicFilterNotifier, WorksheetPayload, StateProvider<WorksheetFilter?>>(
        () => WorksheetDynamicFilterNotifier());

final worksheetTypeProvider = Provider<WorksheetTypeRepository>((ref) => WorksheetTypeRepository());
final worksheetRepoProvider = Provider<WorksheetRepository>((ref) => WorksheetRepository(ref));
final stopWordsProvider = Provider<StopWordsRepository>((ref) => StopWordsRepository());

class WorksheetEventNotifier extends StateNotifier<WorksheetEvent> {
  WorksheetEventNotifier() : super(WorksheetEvent(WorksheetEventType.Default));
}

final worksheetEventProvider =
    StateNotifierProvider<WorksheetEventNotifier, WorksheetEvent>((ref) => WorksheetEventNotifier());

final childWorksheetsProvider = FutureProvider.autoDispose.family<List<Worksheet>, int>((ref, id) async {
  final repo = ref.watch(worksheetRepoProvider);
  return repo.getChildWorksheets(id);
});
//
// final childWorksheetsProvider = AsyncNotifierProvider.autoDispose
//     .family<ChildWorksheetNotifier, List<Worksheet>, int>(
//         () => ChildWorksheetNotifier());

enum FilterMode { Yes, No, OnlyYes }

final searchFilterProvider = StateProvider<WorksheetFilter?>((ref) => null);

class WorksheetFilter {
  final FilterMode includeStarred;
  final FilterMode includeArchived;
  final FilterMode includeChildren;

  final bool shouldRefresh;
  final String? query;
  final splitPattern = new RegExp(r"[,\s]");

  WorksheetFilter(
      {this.includeStarred = FilterMode.Yes,
      this.includeArchived = FilterMode.No,
      this.includeChildren = FilterMode.No,
      this.shouldRefresh = true,
      this.query});

  WorksheetFilter copyWith(
      {FilterMode? includeStarred,
      FilterMode? includeArchived,
      FilterMode? includeChildren,
      bool? shouldRefresh,
      String? query}) {
    return WorksheetFilter(
      includeStarred: includeStarred ?? this.includeStarred,
      includeArchived: includeArchived ?? this.includeArchived,
      includeChildren: includeChildren ?? this.includeChildren,
      shouldRefresh: shouldRefresh ?? this.shouldRefresh,
      query: query ?? this.query,
    );
  }

  bool isSearch() {
    return query != null;
  }

  Set<String> getSearchTerms(Set<String> stopWords) {
    return query == null
        ? <String>{}
        : query!.split(splitPattern).map((s) => s.trim()).where((w) => !stopWords.contains(w) && w.isNotEmpty).toSet();
  }

  bool apply(Worksheet worksheet, Set<String>? searchTerms) {
    if ((includeArchived == FilterMode.No && worksheet.isArchived) ||
        (includeArchived == FilterMode.OnlyYes && !worksheet.isArchived)) {
      return false;
    }

    if ((includeStarred == FilterMode.No && worksheet.isStarred) ||
        (includeStarred == FilterMode.OnlyYes && !worksheet.isStarred)) {
      return false;
    }

    if ((includeChildren == FilterMode.No && worksheet.hasParent) ||
        (includeChildren == FilterMode.OnlyYes && !worksheet.hasParent)) {
      return false;
    }

    if (query == null) {
      //not searching so just return true
      return true;
    }

    if (searchTerms?.isEmpty ?? true) {
      // we're searching but no terms were supplied so return false to indicate no matches
      return false;
    } else {
      final commonTags = worksheet.tags?.isEmpty ?? true
          ? <String>{}
          : searchTerms!.intersection(worksheet.tags!.map((s) => s.toLowerCase()).toSet());

      // all the words not matched by tags in this worksheet
      final remaining = Set.from(searchTerms!.difference(commonTags));
      final answers = worksheet.content.questions.map((q) => q.answer.toLowerCase()).toList(growable: false);

      // of the remaining words, find the first NOT included in the worksheet text
      final notFound =
          remaining.firstWhereOrNull((word) => answers.firstWhereOrNull((answer) => answer.contains(word)) == null);

      return notFound == null;
    }
  }

  List<Worksheet> applyAll(List<Worksheet> worksheets, Set<String> stopWords) {
    final searchTerms = getSearchTerms(stopWords);
    return worksheets.where((ws) => apply(ws, searchTerms)).toList(growable: false);
  }

  bool operator ==(o) =>
      o is WorksheetFilter &&
      o.includeStarred == includeStarred &&
      o.includeArchived == includeArchived &&
      o.includeChildren == includeChildren &&
      o.shouldRefresh == shouldRefresh &&
      o.query == query;

  @override
  int get hashCode => Object.hash(includeStarred, includeArchived, includeChildren, shouldRefresh, query);

  @override
  String toString() {
    return "WorksheetFilter(includeStarred: $includeStarred, "
        "includeArchived: $includeArchived, includeChildren: $includeChildren, "
        "shouldRefresh: $shouldRefresh, query: $query)";
  }
}

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

  Future<void> archiveWorksheet(Worksheet worksheet, {bool archive = true}) async {
    if (worksheet.id != -1) {
      final db = await ref.read(worksheetDbProvider.future);

      int idToUpdate = worksheet.id;
      worksheet.dateLastEdited = DateTime.now();
      worksheet.isArchived = archive;
      final result = await db.update("notes", worksheet.toMap(true), where: "id = ?", whereArgs: [idToUpdate]);
      if (result > 0) {
        final children = await getChildWorksheets(idToUpdate);
        Future.wait(children.whereNot((ws) => ws.id == idToUpdate).map((ws) => archiveWorksheet(ws, archive: archive)));
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
      _cache?.remove(id);
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
    final worksheets = res.isNotEmpty ? res.map((worksheet) => Worksheet.fromJson(worksheet)).toList() : <Worksheet>[];
    if (worksheets.isNotEmpty) {
      Worksheet? parent;
      final childIds = <int>{};
      worksheets.forEach((ws) {
        if (ws.id == id) {
          parent = ws;
        } else {
          childIds.add(ws.id);
        }
      });
      parent?.childIds = childIds.isEmpty ? null : childIds;
    }
    return worksheets;
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

enum WorksheetEventType { Default, Reloaded, Added, Modified, Archived, UnArchived, Deleted, Searching }

class WorksheetEvent {
  WorksheetEvent(this.type, {this.worksheet, this.worksheetId}) : this.timestamp = DateTime.now();
  final DateTime timestamp;
  final WorksheetEventType type;
  final Worksheet? worksheet;
  final int? worksheetId;

  bool operator ==(o) => o is WorksheetEvent && o.type == type && o.timestamp == timestamp;
  @override
  int get hashCode => Object.hash(type, timestamp);

  @override
  String toString() {
    return "WorksheetEvent(type: $type, timestamp: $timestamp, worksheet: $worksheet, worksheetId: $worksheetId)";
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
    return _buildPayload();
  }

  Future<WorksheetPayload> _buildPayload(
      {WorksheetEventType eventType = WorksheetEventType.Reloaded, Worksheet? worksheet, int? worksheetId}) async {
    state = const AsyncLoading();
    final repo = ref.watch(worksheetRepoProvider);
    final results = await repo.getWorksheets();
    final parentMap = results.fold(ListMultimap<int, int>(), (acc, ws) {
      if (ws.hasParent) {
        acc.add(ws.parentId, ws.id);
      }
      return acc;
    });

    results.forEach((ws) {
      ws.childIds = parentMap[ws.id].isEmpty ? null : parentMap[ws.id].toSet();
    });

    final provider = ref.read(worksheetEventProvider.notifier);
    WorksheetEvent event = WorksheetEvent(eventType, worksheet: worksheet, worksheetId: worksheetId);
    provider.state = event;
    return WorksheetPayload(results, event);
  }

  Future<int> addWorksheet(Worksheet worksheet) async {
    final repo = ref.watch(worksheetRepoProvider);
    worksheet.dateLastEdited = DateTime.now();
    final res = await repo.addWorksheet(worksheet);
    if (res > 0) {
      final cloned = Worksheet.clone(worksheet);
      cloned.id = res;
      state = await AsyncValue.guard(() => _buildPayload(
          eventType: worksheet.id == -1 ? WorksheetEventType.Added : WorksheetEventType.Modified,
          worksheetId: worksheet.id,
          worksheet: cloned));
    } else {
      throw new WorksheetDbException("Worksheet couldn't be added!");
    }
    return res;
  }

  Future<void> deleteWorksheet(int id) async {
    final repo = ref.watch(worksheetRepoProvider);
    final ws = await repo.getWorksheet(id);
    if (ws == null) {
      print("Worksheet $id not found!");
      return;
    }
    final res = await repo.deleteWorksheet(id);

    if (res == 1) {
      await repo.updateChildren(id);
      state = await AsyncValue.guard(() => _buildPayload(eventType: WorksheetEventType.Deleted, worksheetId: id));
    } else {
      final exception = new WorksheetDbException("Worksheet $id couldn't be deleted!");
      state = AsyncError(exception, StackTrace.current);
    }
  }

  Future<void> archiveWorksheet(Worksheet worksheet, {bool archive = true}) async {
    final repo = ref.watch(worksheetRepoProvider);
    await repo.archiveWorksheet(worksheet, archive: archive);
    state = await AsyncValue.guard(() => _buildPayload(
        eventType: archive ? WorksheetEventType.Archived : WorksheetEventType.UnArchived,
        worksheet: worksheet,
        worksheetId: worksheet.id));
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

abstract class WorksheetFilterNotifier<Arg> extends AutoDisposeFamilyAsyncNotifier<WorksheetPayload, Arg> {
  Future<WorksheetPayload> getFilteredResults(WorksheetFilter filter) async {
    final payload = await ref.watch(worksheetNotifierProvider.future);
    final stopWords = await ref.watch(stopWordsProvider).getStopWords();
    final worksheets = payload.worksheets;
    final filteredResults = filter.applyAll(worksheets, stopWords);
    final isSearching = filter.isSearch();
    WorksheetEvent event = WorksheetEvent(isSearching ? WorksheetEventType.Searching : WorksheetEventType.Reloaded);
    return WorksheetPayload(filteredResults, event);
  }
}

class WorksheetStaticFilterNotifier extends WorksheetFilterNotifier<WorksheetFilter> {
  @override
  FutureOr<WorksheetPayload> build(WorksheetFilter filter) async {
    return getFilteredResults(filter);
  }
}

class WorksheetDynamicFilterNotifier extends WorksheetFilterNotifier<StateProvider<WorksheetFilter?>> {
  @override
  FutureOr<WorksheetPayload> build(StateProvider<WorksheetFilter?> filterProvider) async {
    final filter = ref.watch(filterProvider);
    if (filter == null) {
      return WorksheetPayload(<Worksheet>[], WorksheetEvent(WorksheetEventType.Default));
    }
    return getFilteredResults(filter);
  }
}
//
// class ChildWorksheetNotifier extends AutoDisposeFamilyAsyncNotifier<List<Worksheet>, int> {
//   @override
//   FutureOr<List<Worksheet>> build(int id) async {
//
//   }
// }

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
