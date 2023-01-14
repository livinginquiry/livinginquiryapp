import 'package:flutter/material.dart';

import '../models/util.dart';
import 'color_slider.dart';

enum moreOptions { archive, unarchive, delete, share, copy, star, unstar }

class OptionsSheet extends StatefulWidget {
  final Color color;
  final DateTime? lastModified;
  final bool isArchived;
  final bool isStarred;
  final Future<void> Function(Color) callBackColorTapped;

  const OptionsSheet(
      {Key? key,
      required this.color,
      required this.isArchived,
      required this.isStarred,
      this.lastModified,
      required this.callBackColorTapped,
      this.callBackOptionTapped})
      : super(key: key);

  final void Function(moreOptions)? callBackOptionTapped;

  @override
  _OptionsSheetState createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<OptionsSheet> {
  late Color _worksheetColor;
  late bool _isStarred;

  @override
  void initState() {
    super.initState();
    _worksheetColor = widget.color;
    _isStarred = widget.isStarred;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: new Wrap(
        children: <Widget>[
          new ListTile(
              leading: SizedBox(
                  height: 50,
                  width: 50,
                  child: Switch(
                    value: _isStarred,
                    onChanged: (value) {
                      setState(() {
                        _isStarred = value;
                      });
                      widget.callBackOptionTapped!(value ? moreOptions.star : moreOptions.unstar);
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  )),
              title: new Text("Starred")),
          new ListTile(
              leading:
                  SizedBox(height: 50, width: 50, child: new Icon(widget.isArchived ? Icons.unarchive : Icons.archive)),
              title: new Text(widget.isArchived ? 'Un-Archive' : 'Archive'),
              onTap: () {
                Navigator.of(context).pop();
                widget.callBackOptionTapped!(widget.isArchived ? moreOptions.unarchive : moreOptions.archive);
              }),
          new ListTile(
              leading: SizedBox(height: 50, width: 50, child: Icon(Icons.delete)),
              title: Text('Delete permanently'),
              onTap: () {
                Navigator.of(context).pop();
                widget.callBackOptionTapped!(moreOptions.delete);
              }),
          new ListTile(
              leading: SizedBox(height: 50, width: 50, child: Icon(Icons.content_copy)),
              title: Text('Duplicate'),
              onTap: () {
                Navigator.of(context).pop();
                widget.callBackOptionTapped!(moreOptions.copy);
              }),
          new ListTile(
              leading: SizedBox(height: 50, width: 50, child: Icon(Icons.share)),
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
                // call callBack from worksheetPage here
                worksheetColor: _worksheetColor, // take color from local variable
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

  Future<void> _changeColor(Color color) async {
    widget.callBackColorTapped(color);
    setState(() {});
  }
}
