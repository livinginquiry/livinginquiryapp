import 'package:flutter/material.dart';

import '../models/util.dart';
import 'color_slider.dart';

enum moreOptions { delete, share, copy }

class OptionsSheet extends StatefulWidget {
  final Color color;
  final DateTime? lastModified;
  final void Function(Color) callBackColorTapped;

  final void Function(moreOptions)? callBackOptionTapped;

  const OptionsSheet(
      {Key? key, required this.color, this.lastModified, required this.callBackColorTapped, this.callBackOptionTapped})
      : super(key: key);

  @override
  _OptionsSheetState createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<OptionsSheet> {
  late Color noteColor;

  @override
  void initState() {
    super.initState();
    noteColor = widget.color;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: new Wrap(
        children: <Widget>[
          new ListTile(
              leading: new Icon(Icons.delete),
              title: new Text('Delete permanently'),
              onTap: () {
                Navigator.of(context).pop();
                widget.callBackOptionTapped!(moreOptions.delete);
              }),
          new ListTile(
              leading: new Icon(Icons.content_copy),
              title: new Text('Duplicate'),
              onTap: () {
                Navigator.of(context).pop();
                widget.callBackOptionTapped!(moreOptions.copy);
              }),
          new ListTile(
              leading: new Icon(Icons.share),
              title: new Text('Share'),
              onTap: () {
                Navigator.of(context).pop();
                widget.callBackOptionTapped!(moreOptions.share);
              }),
          new Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: SizedBox(
              height: 44,
              width: MediaQuery.of(context).size.width,
              child: ColorSlider(
                callBackColorTapped: _changeColor,
                // call callBack from notePage here
                noteColor: noteColor, // take color from local variable
              ),
            ),
          ),
          new Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 44,
                child: Center(child: Text(formatDateTime(widget.lastModified!))),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          new ListTile()
        ],
      ),
    );
  }

  // TODO: Use BLOC!
  void _changeColor(Color color) {
    setState(() {
      widget.callBackColorTapped(color);
    });
  }
}
