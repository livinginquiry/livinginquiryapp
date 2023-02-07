import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:version/version.dart';

import '../constants/constants.dart' as constants;
import 'util.dart' as util;

class Worksheet {
  int id;
  String title;
  WorksheetContent content;
  DateTime dateCreated;
  DateTime dateLastEdited;
  Color noteColor;
  bool isArchived;
  bool isStarred;
  int parentId;
  Set<String>? tags;

  // not persisted
  Set<int>? childIds;

  Worksheet(this.title, this.content, this.dateCreated, this.dateLastEdited, this.noteColor,
      {this.id = -1, this.isArchived = false, this.isStarred = false, this.parentId = -1, this.tags, this.childIds});

  Worksheet.clone(Worksheet other)
      : this(other.title, other.content.clone(), other.dateCreated, other.dateLastEdited, other.noteColor,
            id: other.id,
            isArchived: other.isArchived,
            isStarred: other.isStarred,
            parentId: other.parentId,
            tags: other.tags != null ? Set.from(other.tags!) : null,
            childIds: other.childIds != null ? Set.from(other.childIds!) : null);

  bool get hasParent => parentId != -1;

  Map<String, dynamic> toMap(bool forUpdate) {
    var data = {
      'title': utf8.encode(title),
      'content': jsonEncode(content.toMap()),
      'date_created': util.epochFromDate(dateCreated),
      'date_last_edited': util.epochFromDate(dateLastEdited),
      'note_color': noteColor.value,
      'is_archived': isArchived ? 1 : 0,
      'is_starred': isStarred ? 1 : 0,
      'parent_id': this.parentId,
      'tags': (this.tags?.isNotEmpty ?? false) ? this.tags!.join("|") : null
    };
    if (forUpdate) {
      data["id"] = this.id;
    }
    return data;
  }

  factory Worksheet.fromJson(Map<String, dynamic> json) => Worksheet(
      json["title"] == null ? "" : utf8.decode(json["title"]),
      WorksheetContent.fromMap(jsonDecode(json["content"]) as Map<String, dynamic>),
      DateTime.fromMillisecondsSinceEpoch(json["date_created"] * 1000),
      DateTime.fromMillisecondsSinceEpoch(json["date_last_edited"] * 1000),
      Color(json["note_color"] ?? constants.WORKSHEET_COLORS[0].value),
      id: json["id"] ?? -1,
      isStarred: (json['is_starred'] ?? 0) == 1,
      isArchived: (json['is_archived'] ?? 0) == 1,
      parentId: json["parent_id"] ?? -1,
      tags: json["tags"]?.split("|").toSet());

  @override
  toString() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date_created': util.epochFromDate(dateCreated),
      'date_last_edited': util.epochFromDate(dateLastEdited),
      'note_color': noteColor.toString(),
      'is_archived': isArchived,
      'is_starred': isStarred,
      'parent_id': parentId,
      'tags': tags,
      'childIds': childIds
    }.toString();
  }

  bool operator ==(o) =>
      o is Worksheet &&
      o.id == id &&
      o.title == title &&
      o.content == content &&
      o.dateCreated == dateCreated &&
      o.dateLastEdited == dateLastEdited &&
      o.noteColor == noteColor &&
      o.isArchived == isArchived &&
      o.isStarred == isStarred &&
      o.parentId == parentId &&
      setEquals(o.tags, tags);

  @override
  int get hashCode =>
      Object.hash(id, title, content, dateCreated, dateLastEdited, noteColor, isArchived, isStarred, parentId, tags);
}

//TODO: make this dynamic(?)
enum WorksheetType { openMic, oneBelief, judgeYourNeighbor }

class WorksheetDefinition {
  final Map<String, WorksheetContent> worksheets;
  final Version version;
  WorksheetDefinition(this.version, this.worksheets);

  bool operator ==(o) => o is WorksheetDefinition && o.version == version;

  @override
  int get hashCode => version.hashCode;

  @override
  toString() {
    return "WorksheetDefinition(version: $version)";
  }
}

const FALLBACK_WORKSHEET_VERSION = "0.0.1";
final _FALLBACK_VERSION = Version(0, 0, 1);

class WorksheetContent {
  final List<Question> questions;
  final WorksheetType type;
  final String? displayName;
  final List<WorksheetType>? children;
  final Version version;
  WorksheetContent(
      {required List<Question> questions,
      required this.type,
      required this.displayName,
      required Version version,
      this.children})
      : this.version = version,
        this.questions = _FALLBACK_VERSION.compareTo(version) == 0 ? _insertMetaFields(questions, type) : questions;

  WorksheetContent.fromYamlMap(String type, Map<dynamic, dynamic> data, Version version)
      : this(
            questions:
                ((data['questions'] ?? {throw new BadWorksheetFormat("Questions are required!")}) as List<dynamic>)
                    .map((p) => Question.fromMap(Map<String, dynamic>.from(p as Map<dynamic, dynamic>)))
                    .toList(),
            type: util.enumFromString(WorksheetType.values, type, snakeCase: true) ?? WorksheetType.openMic,
            displayName: data['display_name'],
            version: version,
            children: ((data['children'] ?? List<String>.empty()) as List<dynamic>)
                .map((t) => util.enumFromString(WorksheetType.values, t, snakeCase: true)!)
                .toList());

  WorksheetContent.fromMap(Map<dynamic, dynamic> data)
      : this(
            questions:
                ((data['questions'] ?? {throw new BadWorksheetFormat("Questions are required!")}) as List<dynamic>)
                    .map((p) => Question.fromMap(Map<String, dynamic>.from(p as Map<dynamic, dynamic>)))
                    .toList(),
            type: util.enumFromString(WorksheetType.values, data['type'], snakeCase: true) ?? WorksheetType.openMic,
            displayName: data['display_name'],
            version: Version.parse(data['version'] ?? FALLBACK_WORKSHEET_VERSION),
            children: ((data['children'] ?? List<String>.empty()) as List<dynamic>)
                .map((t) => util.enumFromString(WorksheetType.values, t, snakeCase: true)!)
                .toList());

  // TODO: devise better versioning strategy!
  static List<Question> _insertMetaFields(List<Question> questions, WorksheetType type) {
    if (questions.isNotEmpty) {
      if (type == WorksheetType.judgeYourNeighbor &&
          questions.firstWhereOrNull((q) => q.type == QuestionType.meta && q.subType == QuestionSubType.children) ==
              null) {
        questions.insert(
            questions.length - 1,
            Question(
                question: "Continue the Work",
                answer: "",
                type: QuestionType.meta,
                subType: QuestionSubType.children,
                prompt: ""));
      }
      if (questions.firstWhereOrNull((q) => q.type == QuestionType.meta && q.subType == QuestionSubType.tags) == null) {
        questions.add(Question(
            question: "Tags",
            answer: "",
            type: QuestionType.meta,
            subType: QuestionSubType.tags,
            prompt: "Enter tags separated by comma or space."));
      }
      if (questions.firstWhereOrNull((q) => q.type == QuestionType.meta && q.subType == QuestionSubType.color_picker) ==
          null) {
        questions.add(Question(
            question: "Settings",
            answer: "",
            type: QuestionType.meta,
            subType: QuestionSubType.color_picker,
            prompt: "Pick background color."));
      }
    }

    return questions;
  }

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map['questions'] = questions.map((p) => p.toMap()).toList();
    map['type'] = util.enumToString(type, snakeCase: true);
    map['display_name'] = displayName;
    map['version'] = version.toString();
    map['children'] = children?.map((t) => util.enumToString(t, snakeCase: true)).toList() ?? List.empty();
    return map;
  }

  String toReadableFormat() {
    String result = "";
    questions.asMap().forEach((index, q) {
      result += (index > 0 ? "\n" : "") + q.toFormattedString(index: index + 1);
    });

    return result;
  }

  WorksheetContent clone() {
    return WorksheetContent.fromMap(toMap());
  }

  bool operator ==(o) =>
      o is WorksheetContent &&
      listEquals(o.questions, questions) &&
      o.type == type &&
      o.displayName == displayName &&
      listEquals(o.children, children);

  @override
  int get hashCode => Object.hash(questions, type, displayName, children);

  @override
  toString() {
    return "WorksheetContent(displayName: $displayName, type: $type, children: $children, questions: $questions)";
  }
}

enum QuestionType { freeform, multiple, meta }

enum QuestionSubType { tags, children, color_picker, turnaround }

class Question {
  final QuestionType type;
  final QuestionSubType? subType;
  final String question;

  final String prompt;
  final List<String>? values;

  String answer;

  Question(
      {required this.question,
      required this.answer,
      required this.type,
      required this.prompt,
      this.values,
      this.subType});

  Question.fromMap(Map<dynamic, dynamic> data)
      : this(
            question: data['question'] ?? "",
            answer: data['answer'] ?? "",
            prompt: data['prompt'] ?? "",
            values: data['values'] == null ? null : List<String>.from(data['values']),
            type: util.enumFromString(QuestionType.values, data['type']?.trim()) ?? QuestionType.freeform,
            subType: util.enumFromString(QuestionSubType.values, data['sub_type']?.trim()));

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map['question'] = question;
    map['answer'] = answer;
    map['prompt'] = prompt;
    map['values'] = values;
    map['type'] = util.enumToString(type);
    map['sub_type'] = util.enumToString(subType);
    return map;
  }

  String toFormattedString({int index = -1}) {
    return "$question\n$answer\n";
  }

  bool operator ==(o) =>
      o is Question &&
      o.question == question &&
      o.answer == answer &&
      o.type == type &&
      o.subType == subType &&
      o.prompt == prompt &&
      listEquals(o.values, values);

  @override
  int get hashCode => Object.hash(question, answer, type, subType, prompt, values);

  @override
  toString() {
    return "Question(question: $question, answer: $answer, type: $type, prompt: $prompt, subType: $subType)";
  }
}

class BadWorksheetFormat implements Exception {
  final String cause;
  BadWorksheetFormat(this.cause);
}

enum FilterMode { Yes, No, OnlyYes }

enum FilterOverrideKey { None, Starred, All }

class WorksheetFilter {
  final FilterMode includeStarred;
  final FilterMode includeArchived;
  final FilterMode includeChildren;

  final bool shouldRefresh;
  final String? query;
  final FilterOverrideKey overrideKey;
  final splitPattern = new RegExp(r"[,\s]");

  WorksheetFilter(
      {this.includeStarred = FilterMode.Yes,
      this.includeArchived = FilterMode.No,
      this.includeChildren = FilterMode.No,
      this.shouldRefresh = true,
      this.overrideKey = FilterOverrideKey.None,
      this.query});

  WorksheetFilter copyWith(
      {FilterMode? includeStarred,
      FilterMode? includeArchived,
      FilterMode? includeChildren,
      bool? shouldRefresh,
      FilterOverrideKey? overrideKey,
      String? query}) {
    return WorksheetFilter(
      includeStarred: includeStarred ?? this.includeStarred,
      includeArchived: includeArchived ?? this.includeArchived,
      includeChildren: includeChildren ?? this.includeChildren,
      shouldRefresh: shouldRefresh ?? this.shouldRefresh,
      overrideKey: overrideKey ?? this.overrideKey,
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
      o.overrideKey == overrideKey &&
      o.query == query;

  @override
  int get hashCode => Object.hash(includeStarred, includeArchived, includeChildren, shouldRefresh, overrideKey, query);

  @override
  String toString() {
    return "WorksheetFilter(includeStarred: $includeStarred, "
        "includeArchived: $includeArchived, includeChildren: $includeChildren, "
        "shouldRefresh: $shouldRefresh, overrideKey: $overrideKey, query: $query)";
  }
}
