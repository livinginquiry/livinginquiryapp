import 'dart:convert';

import 'package:flutter/material.dart';

import 'util.dart' as util;

class Note {
  int id;
  String title;
  String content;
  DateTime dateCreated;
  DateTime dateLastEdited;
  Color noteColor;
  bool isArchived;

  Note(this.title, this.content, this.dateCreated, this.dateLastEdited, this.noteColor,
      {this.id = -1, this.isArchived = false});

  Map<String, dynamic> toMap(bool forUpdate) {
    var data = {
      'title': utf8.encode(title),
      'content': utf8.encode(content),
      'date_created': util.epochFromDate(dateCreated),
      'date_last_edited': util.epochFromDate(dateLastEdited),
      'note_color': noteColor.value,
      'is_archived': isArchived ? 1 : 0 //  for later use for integrating archiving
    };
    if (forUpdate) {
      data["id"] = this.id;
    }
    return data;
  }

  factory Note.fromJson(Map<String, dynamic> json) => Note(
      json["title"] == null ? "" : utf8.decode(json["title"]),
      json["content"] == null ? "" : utf8.decode(json["content"]),
      DateTime.fromMillisecondsSinceEpoch(json["date_created"] * 1000),
      DateTime.fromMillisecondsSinceEpoch(json["date_last_edited"] * 1000),
      Color(json["note_color"]),
      id: json["id"]);

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
      'is_archived': isArchived
    }.toString();
  }
}
