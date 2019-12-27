import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import '../blocs/notes_bloc.dart';
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
        title: Text("Living Inquiry"),
      ),
      body: SafeArea(
        child: _body(),
        right: true,
        left: true,
        top: true,
        bottom: true,
      ),
      bottomSheet: _bottomBar(),
      floatingActionButton: FutureBuilder(
        future: _getProfileMenu(),
        builder: (BuildContext context, AsyncSnapshot<List<SpeedDialChild>> snapshot) {
          if (snapshot.hasData) {
            return SpeedDial(
              animatedIcon: AnimatedIcons.menu_close,
              animatedIconTheme: IconThemeData(size: 22.0),
              // child: Icon(Icons.add),
              onOpen: () => print('OPENING DIAL'),
              onClose: () => print('DIAL CLOSED'),
              visible: true,
              curve: Curves.bounceIn,
              children: snapshot.data,
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
      // SpeedDial(
      //   animatedIcon: AnimatedIcons.menu_close,
      //   animatedIconTheme: IconThemeData(size: 22.0),
      //   // child: Icon(Icons.add),
      //   onOpen: () => print('OPENING DIAL'),
      //   onClose: () => print('DIAL CLOSED'),
      //   visible: true,
      //   curve: Curves.bounceIn,
      //   children: _getProfileMenu(),
      // ),

      // UnicornDialer(
      //   parentButtonBackground: Colors.grey[700],
      //   orientation: UnicornOrientation.HORIZONTAL,
      //   parentButton: Icon(Icons.person),
      //   childButtons: _getProfileMenu(),
      // ),
      /* FloatingActionButton(
        onPressed: () => _newNoteTapped(context),
        child: Icon(Icons.add),
        elevation: 20.0,
      ), */
    );
  }

  SpeedDialChild _profileOption({IconData iconData, Function onPressed, String label}) {
    return SpeedDialChild(
      child: Icon(iconData),
      onTap: onPressed,
      label: label,
      labelStyle: TextStyle(fontWeight: FontWeight.w500),
      labelBackgroundColor: Colors.deepOrangeAccent,
    );
  }

  Future<List<SpeedDialChild>> _getProfileMenu() async {
    List<SpeedDialChild> children = [];

    var notesBloc = Provider.of<NotesBloc>(context);
    (await notesBloc.getWorksheets()).forEach((k, v) {
      children.add(_profileOption(
          iconData: Icons.format_list_bulleted, onPressed: () => _newNoteTapped(context, v), label: v.displayName));
    });

    // // Add Children here
    // children.add(_profileOption(iconData: Icons.mic, onPressed: () => _newNoteTapped(context), label: "Open Mic"));
    // children.add(_profileOption(
    //     iconData: Icons.remove_red_eye,
    //     onPressed: () {
    //       print("find shorts, eat shorts");
    //     },
    //     label: "One Belief"));
    // children
    //     .add(_profileOption(iconData: FontAwesomeIcons.balanceScale, onPressed: () {}, label: "Judge Your Neighbor"));

    return children;
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

  void _newNoteTapped(BuildContext ctx, WorksheetContent content) {
    print("nu note");
    // "-1" id indicates the note is not new
    var emptyNote = Worksheet("", content.clone(), DateTime.now(), DateTime.now(), getRandomNoteColor());
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
