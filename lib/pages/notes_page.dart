import 'dart:convert';

import 'package:flutter/material.dart';

import '../blocs/notes_bloc.dart';
import '../models/note.dart';
import '../models/sqlite_handler.dart';
import '../widgets/note_tile.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key key}) : super(key: key);
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final noteDB = NotesDBHandler();
  List<Map<String, dynamic>> _allNotesInQueryResult = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey _listKey = GlobalKey();

    if (notesBloc.updateNeeded) {
      retrieveAllNotesFromDatabase();
    }
    return Container(
        child: Padding(
      padding: _paddingForView(context),
      child: ListView.separated(
        key: _listKey,
        itemCount: _allNotesInQueryResult.length,
        itemBuilder: (BuildContext context, int index) {
          return _tileGenerator(index);
        },
        padding: EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 0.0),
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(
            height: 10,
          );
        },
      ),
    ));
  }

  EdgeInsets _paddingForView(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double padding;
    double topBottom = 8;
    if (width > 500) {
      padding = (width) * 0.05; // 5% padding of width on both side
    } else {
      padding = 8;
    }
    return EdgeInsets.only(left: padding, right: padding, top: topBottom, bottom: topBottom);
  }

  NoteTile _tileGenerator(int i) {
    return NoteTile(Note(
        _allNotesInQueryResult[i]["id"],
        _allNotesInQueryResult[i]["title"] == null ? "" : utf8.decode(_allNotesInQueryResult[i]["title"]),
        _allNotesInQueryResult[i]["content"] == null ? "" : utf8.decode(_allNotesInQueryResult[i]["content"]),
        DateTime.fromMillisecondsSinceEpoch(_allNotesInQueryResult[i]["date_created"] * 1000),
        DateTime.fromMillisecondsSinceEpoch(_allNotesInQueryResult[i]["date_last_edited"] * 1000),
        Color(_allNotesInQueryResult[i]["note_color"])));
  }

  void retrieveAllNotesFromDatabase() {
    // queries for all the notes from the database ordered by latest edited note. excludes archived notes.
    var _testData = noteDB.selectAllNotes();
    _testData.then((value) {
      setState(() {
        this._allNotesInQueryResult = value;
        notesBloc.updateNeeded = false;
      });
    });
  }
}
