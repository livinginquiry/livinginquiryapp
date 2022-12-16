import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../models/util.dart';
import '../models/worksheet.dart';
import '../pages/worksheet_page.dart';

class WorksheetTile extends StatefulWidget {
  final Worksheet worksheet;
  WorksheetTile(this.worksheet);
  @override
  _WorksheetTileState createState() => _WorksheetTileState();
}

class _WorksheetTileState extends State<WorksheetTile> {
  WorksheetContent? _content;
  double? _fontSize;
  Color? _tileColor;
  late String _title;

  @override
  Widget build(BuildContext context) {
    _content = widget.worksheet.content;
    _fontSize = _determineFontSizeForContent();
    _tileColor = widget.worksheet.noteColor;
    _title = widget.worksheet.title;

    final subtitle = _buildSubtitle(_content);
    final title = _buildTitle(_content);

    var card = Container(
        color: _tileColor,
        child: ListTile(
          dense: false,
          title: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(children: [
            SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[Flexible(child: Text(subtitle))]),
            SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[Text(formatDateTime(widget.worksheet.dateLastEdited))])
          ]),
        ));

    return GestureDetector(
      onTap: () => _worksheetTapped(context),
      child: card,
    );
  }

  void _worksheetTapped(BuildContext ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (ctx) => WorksheetPage(widget.worksheet)));
  }

  Widget constructChild() {
    List<Widget> tiles = [];

    if (widget.worksheet.title.length != 0) {
      tiles.add(
        AutoSizeText(
          _title,
          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
          maxLines: widget.worksheet.title.length == 0 ? 1 : 3,
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

    final text = _content!.displayName == null ? _content!.type : _content!.displayName!;
    tiles.add(AutoSizeText(
      text as String,
      style: TextStyle(fontSize: _fontSize),
      maxLines: 10,
      textScaleFactor: 1,
    ));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: tiles);
  }

  double _determineFontSizeForContent() {
    final text = widget.worksheet.content.questions.length > 0 ? widget.worksheet.content.questions.first.answer : "";

    int charCount = text.length + widget.worksheet.title.length;
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

  String _buildTitle(WorksheetContent? content) {
    if (_content!.questions.length == 0)
      return "--";
    else if (_content!.questions.first.answer.length == 0)
      return "--";
    else {
      return truncateWithEllipsis(extractAnswerFirstLine(_content!.questions.first.answer), 100);
    }
  }

  String _buildSubtitle(WorksheetContent? content) {
    if (_content!.questions.length <= 1)
      return "--";
    else if (_content!.questions[1].answer.length <= 1)
      return "--";
    else {
      var text = _content!.questions[1].answer.split("\n").map((String l) => l.trim()).take(2).join("\n");
      return truncateWithEllipsis(text, 150);
    }
  }
}
