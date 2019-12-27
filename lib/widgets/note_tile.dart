import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:tinycolor/tinycolor.dart';

import '../models/note.dart';
import '../models/util.dart';
import '../pages/note_page.dart';

class NoteTile extends StatefulWidget {
  final Worksheet note;
  NoteTile(this.note);
  @override
  _NoteTileState createState() => _NoteTileState();
}

class _NoteTileState extends State<NoteTile> {
  WorksheetContent _content;
  double _fontSize;
  Color _tileColor;
  String _title;

  @override
  Widget build(BuildContext context) {
    _content = widget.note.content;
    _fontSize = _determineFontSizeForContent();
    _tileColor = widget.note.noteColor;
    _title = widget.note.title;

    final subtitle = _content.displayName == null ? _content.type : _content.displayName;
    final title = (_content.questions?.length ?? 0) == 0
        ? "--"
        : ((_content.questions.first.answer?.length ?? 0) == 0 ? "--" : _content.questions.first.answer);

    var card = Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.1, 0.1],
                colors: [_tileColor, TinyColor(_tileColor).lighten(15).color]),
            borderRadius: BorderRadius.all(const Radius.circular(8))),
        padding: EdgeInsets.all(8),
        child: ListTile(
          dense: true,
          title: Text(
            title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Text(subtitle),
          trailing: Text(formatDateTime(
              widget.note.dateLastEdited == null ? widget.note.dateCreated : widget.note.dateLastEdited)),
        ));

    return GestureDetector(
      onTap: () => _noteTapped(context),
      child: card,
    );
  }

  void _noteTapped(BuildContext ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (ctx) => NotePage(widget.note)));
  }

  Widget constructChild() {
    List<Widget> tiles = [];

    if (widget.note.title.length != 0) {
      tiles.add(
        AutoSizeText(
          _title,
          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
          maxLines: widget.note.title.length == 0 ? 1 : 3,
          textScaleFactor: 1.5,
        ),
      );
      tiles.add(
        Divider(
          color: Colors.transparent,
          height: 6,
        ),
      );
    }

    debugPrint("dacontent ${_content.toMap()}");
    final text = _content.displayName == null ? _content.type : _content.displayName;
    tiles.add(AutoSizeText(
      text,
      style: TextStyle(fontSize: _fontSize),
      maxLines: 10,
      textScaleFactor: 1,
    ));

    // tiles.add(AutoSizeText(
    //   _content,
    //   style: TextStyle(fontSize: _fontSize),
    //   maxLines: 10,
    //   textScaleFactor: 1.5,
    // ));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: tiles);
  }

  double _determineFontSizeForContent() {
    final text = (widget.note.content.questions?.length ?? 0) > 0 ? widget.note.content.questions.first.answer : "";

    int charCount = text.length + widget.note.title.length;
    double fontSize = 20;
    if (charCount > 110) {
      fontSize = 12;
    } else if (charCount > 80) {
      fontSize = 14;
    } else if (charCount > 50) {
      fontSize = 16;
    } else if (charCount > 20) {
      fontSize = 18;
    }

    return fontSize;
  }
}
