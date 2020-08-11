import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

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
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          resizeToAvoidBottomPadding: false,
          appBar: AppBar(
            brightness: Brightness.light,
            actions: _appBarActions(context),
            elevation: 0,
            backgroundColor: Colors.white,
            centerTitle: true,
            title: Text("Living Inquiry"),
            bottom: TabBar(
              unselectedLabelColor: Colors.redAccent,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(80), color: Colors.redAccent),
              tabs: [
                Tab(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(80), border: Border.all(color: Colors.redAccent, width: 1)),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text("DONE"),
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(80), border: Border.all(color: Colors.redAccent, width: 1)),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text("STARTED"),
                    ),
                  ),
                )
              ],
            ),
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
        ));
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
    return TabBarView(
        children: <Widget>[Container(child: NotesPage(showDone: false)), Container(child: NotesPage(showDone: true))]);
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
      PopupMenuButton<String>(
        onSelected: (value) => _moreButtonPressed(context),
        itemBuilder: (BuildContext context) {
          return {'Share all'}.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.more_vert,
            color: fontColor,
          ),
        ),
      ),
    ];
    // return [

    // ];
  }

  void _moreButtonPressed(BuildContext context) async {
    var notesBloc = Provider.of<NotesBloc>(context);
    String result = "";
    (await notesBloc.exportWorksheets()).forEach((v) {
      result += "${v.content.displayName}\n${v.content.toReadableFormat()}\n\n";
    });
    Share.share(result);
  }
}
