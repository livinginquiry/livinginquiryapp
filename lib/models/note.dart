import 'dart:convert';

import 'package:flutter/material.dart';

import 'util.dart' as util;

class Worksheet {
  int? id;
  String title;
  WorksheetContent content;
  DateTime dateCreated;
  DateTime dateLastEdited;
  Color? noteColor;
  bool isArchived;
  bool isComplete;

  Worksheet(this.title, this.content, this.dateCreated, this.dateLastEdited, this.noteColor,
      {this.id = -1, this.isArchived = false, this.isComplete = false});

  Map<String, dynamic> toMap(bool forUpdate) {
    var data = {
      'title': utf8.encode(title),
      'content': content == null ? null : jsonEncode(content.toMap()),
      'date_created': util.epochFromDate(dateCreated),
      'date_last_edited': util.epochFromDate(dateLastEdited),
      'note_color': noteColor!.value,
      'is_archived': isArchived ? 1 : 0, //  for later use for integrating archiving
      'is_complete': isComplete ? 1 : 0
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
      Color(json["note_color"]),
      id: json["id"],
      isComplete: (json['is_complete'] ?? 0) == 1);

  void archiveThisNote() {
    isArchived = true;
  }

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
      'is_complete': isComplete
    }.toString();
  }
}

enum WorksheetType { openMic, oneBelief, judgeYourNeighbor }

class WorksheetContent {
  final List<Question>? questions;
  final WorksheetType? type;
  final String? displayName;
  WorksheetContent({required this.questions, required this.type, required this.displayName});

  WorksheetContent.fromYamlMap(String type, Map<dynamic, dynamic> data)
      : this(
            questions: data['questions'] == null
                ? null
                : (data['questions'] as List<dynamic>)
                    .map((p) => Question.fromMap(Map<String, dynamic>.from(p as Map<dynamic, dynamic>)))
                    .toList(),
            type: util.enumFromString(WorksheetType.values, type, snakeCase: true),
            displayName: data['display_name']);

  WorksheetContent.fromMap(Map<dynamic, dynamic> data)
      : this(
            questions: data['questions'] == null
                ? null
                : (data['questions'] as List<dynamic>)
                    .map((p) => Question.fromMap(Map<String, dynamic>.from(p as Map<dynamic, dynamic>)))
                    .toList(),
            type: util.enumFromString(WorksheetType.values, data['type'], snakeCase: true),
            displayName: data['display_name']);

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map['questions'] = questions == null ? null : questions!.map((p) => p.toMap()).toList();
    map['type'] = util.enumToString(type, snakeCase: true);
    map['display_name'] = displayName;
    return map;
  }

  String toReadableFormat() {
    String result = "";
    questions!.asMap().forEach((index, q) {
      result += (index > 0 ? "\n" : "") + q.toFormattedString(index: index + 1);
    });

    return result;
  }

  WorksheetContent clone() {
    return WorksheetContent.fromMap(toMap());
  }
}

enum QuestionType { freeform, multiple }

class Question {
  final QuestionType? type;
  final String? question;

  final String? prompt;
  final List<String>? values;

  String? answer;

  Question({required this.question, this.answer, required this.type, this.prompt, this.values});

  Question.fromMap(Map<dynamic, dynamic> data)
      : this(
            question: data['question'],
            answer: data['answer'],
            prompt: data['prompt'],
            values: data['values'] == null ? null : List<String>.from(data['values']),
            type:
                data['type'] != null ? util.enumFromString(QuestionType.values, data['type']) : QuestionType.freeform);

  // Question.fromYamlMap(Map<dynamic, dynamic> data)
  //     : this(
  //           question: data['question'],
  //           answer: data['answer'],
  //           prompt: data['prompt'],
  //           values: data['values'] == null ? null : List<String>.from(data['values']),
  //           type: data['type'] != null
  //               ? util.getEnumFromString(QuestionType.values, data['type'])
  //               : QuestionType.freeform);

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
}
