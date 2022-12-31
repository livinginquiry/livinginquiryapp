import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'constants.dart' as constants;
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

class WorksheetContent {
  final List<Question> questions;
  final WorksheetType type;
  final String? displayName;
  final List<WorksheetType>? children;
  WorksheetContent({required this.questions, required this.type, required this.displayName, this.children});

  WorksheetContent.fromYamlMap(String type, Map<dynamic, dynamic> data)
      : this(
            questions:
                ((data['questions'] ?? {throw new BadWorksheetFormat("Questions are required!")}) as List<dynamic>)
                    .map((p) => Question.fromMap(Map<String, dynamic>.from(p as Map<dynamic, dynamic>)))
                    .toList(),
            type: util.enumFromString(WorksheetType.values, type, snakeCase: true) ?? WorksheetType.openMic,
            displayName: data['display_name'],
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
            children: ((data['children'] ?? List<String>.empty()) as List<dynamic>)
                .map((t) => util.enumFromString(WorksheetType.values, t, snakeCase: true)!)
                .toList());

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map['questions'] = questions.map((p) => p.toMap()).toList();
    map['type'] = util.enumToString(type, snakeCase: true);
    map['display_name'] = displayName;
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
}

enum QuestionType { freeform, multiple }

class Question {
  final QuestionType type;
  final String question;

  final String prompt;
  final List<String>? values;

  String answer;

  Question({required this.question, required this.answer, required this.type, required this.prompt, this.values});

  Question.fromMap(Map<dynamic, dynamic> data)
      : this(
            question: data['question'] ?? "",
            answer: data['answer'] ?? "",
            prompt: data['prompt'] ?? "",
            values: data['values'] == null ? null : List<String>.from(data['values']),
            type: data['type'] = util.enumFromString(QuestionType.values, data['type']) ?? QuestionType.freeform);

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map['question'] = question;
    map['answer'] = answer;
    map['prompt'] = prompt;
    map['values'] = values;
    map['type'] = util.enumToString(type);
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
      o.prompt == prompt &&
      listEquals(o.values, values);

  @override
  int get hashCode => Object.hash(question, answer, type, prompt, values);
}

class BadWorksheetFormat implements Exception {
  final String cause;
  BadWorksheetFormat(this.cause);
}
