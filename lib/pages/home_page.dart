import 'package:flutter/material.dart';

import '../models/note.dart';
import '../models/util.dart';
import 'note_page.dart';
import 'notes_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        brightness: Brightness.light,
        actions: _appBarActions(context),
        elevation: 1,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text("Living Inquiry Notes"),
      ),
      body: SafeArea(
        child: _body(),
        right: true,
        left: true,
        top: true,
        bottom: true,
      ),
      bottomSheet: _bottomBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newNoteTapped(context),
        child: Icon(Icons.add),
        elevation: 20.0,
      ),
    );
  }

  Widget _body() {
    return Container(child: NotesPage());
  }

  Widget _bottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [],
    );
  }

  void _newNoteTapped(BuildContext ctx) {
    // "-1" id indicates the note is not new
    var emptyNote = new Note(-1, "", "", DateTime.now(), DateTime.now(), Colors.white);
    Navigator.push(ctx, MaterialPageRoute(builder: (ctx) => NotePage(emptyNote)));
  }

  List<Widget> _appBarActions(BuildContext context) {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          child: GestureDetector(
            onTap: () => _moreButtonPressed(context),
            child: Icon(
              Icons.more_vert,
              color: fontColor,
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _moreButtonPressed(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nothing here!'),
          content: const Text('This literally does nothing'),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
