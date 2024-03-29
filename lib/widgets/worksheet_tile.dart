import 'package:flutter/material.dart';

import '../models/util.dart';
import '../models/worksheet.dart';

class WorksheetTile extends StatelessWidget {
  final Worksheet worksheet;
  final int numChildren;
  final void Function(Worksheet, bool) tileTapped;
  final bool showStatusIcons;
  const WorksheetTile(this.worksheet, this.numChildren, this.tileTapped, {this.showStatusIcons = false, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tileColor = worksheet.noteColor;
    final subtitle = _buildSubtitle();
    final title = _buildTitle();

    var card = Container(
        color: tileColor,
        child: ListTile(
          dense: false,
          title: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Flexible(
                child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            )),
            worksheet.isStarred && showStatusIcons
                ? new IconTheme(data: new IconThemeData(color: Colors.deepOrange), child: new Icon(Icons.star))
                : SizedBox.shrink(),
            worksheet.isArchived && showStatusIcons ? Icon(Icons.archive) : SizedBox.shrink()
          ]),
          subtitle: Column(children: [
            SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[Flexible(child: Text(subtitle))]),
          ]),
          trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      numChildren <= 0
                          ? SizedBox.shrink()
                          : Transform.translate(offset: Offset(0, 0), child: _getIcon())
                    ]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                          padding: EdgeInsets.only(bottom: 3), child: Text(formatDateTime(worksheet.dateCreated))),
                    ])
              ]),
        ));

    return GestureDetector(
      onTap: () => tileTapped(worksheet, numChildren > 0),
      child: card,
    );
  }

  Widget? _getIcon() {
    switch (numChildren) {
      case 0:
        return null;
      case 1:
        return Icon(Icons.filter_1);
      case 2:
        return Icon(Icons.filter_2);
      case 3:
        return Icon(Icons.filter_3);
      case 4:
        return Icon(Icons.filter_4);
      case 5:
        return Icon(Icons.filter_5);
      case 6:
        return Icon(Icons.filter_6);
      case 7:
        return Icon(Icons.filter_7);
      case 8:
        return Icon(Icons.filter_8);
      case 9:
        return Icon(Icons.filter_9);
      default:
        return Icon(Icons.filter_9_plus);
    }
  }

  String _buildTitle() {
    if (worksheet.content.questions.length == 0)
      return "--";
    else if (worksheet.content.questions.first.answer.length == 0)
      return "--";
    else {
      return truncateWithEllipsis(extractAnswerFirstLine(worksheet.content.questions.first.answer), 100);
    }
  }

  String _buildSubtitle() {
    if (worksheet.content.questions.length <= 1)
      return "--";
    else if (worksheet.content.questions[1].answer.length <= 1)
      return "--";
    else {
      var text = worksheet.content.questions[1].answer.split("\n").map((String l) => l.trim()).take(2).join("\n");
      return truncateWithEllipsis(text, 150);
    }
  }
}
