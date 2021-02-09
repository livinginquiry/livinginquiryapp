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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Builder(builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              setState(() {});
            }
          });
          return Scaffold(
            resizeToAvoidBottomPadding: false,
            appBar: PreferredSize(
                preferredSize: Size(double.infinity, 60),
                child: AppBar(
                  // brightness: Brightness.light,
                  actions: _appBarActions(context),
                  elevation: 0,
                  centerTitle: true,
                  title: Transform(
                      transform: new Matrix4.translationValues(0.0, 2.0, 0.0),
                      child: Container(
                          color: Theme.of(context).backgroundColor,
                          child: TabBar(
                            labelPadding: EdgeInsets.only(left: 5, right: 5),
                            tabs: [
                              Tab(
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                      color: tabController.index == 0
                                          ? Theme.of(context).accentColor
                                          : Theme.of(context).scaffoldBackgroundColor),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text("STARTED"),
                                  ),
                                ),
                              ),
                              Tab(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                    color: tabController.index == 1
                                        ? Theme.of(context).accentColor
                                        : Theme.of(context).scaffoldBackgroundColor,
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text("DONE"),
                                  ),
                                ),
                              )
                            ],
                          ))),
                  bottom: PreferredSize(
                      child: Container(
                        color: Theme.of(context).accentColor,
                        height: 12.0,
                      ),
                      preferredSize: Size.fromHeight(12.0)),
                )),
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
                    foregroundColor: Theme.of(context).accentColor,
                    backgroundColor: Theme.of(context).dialogBackgroundColor,
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
          );
        }));
  }

  SpeedDialChild _profileOption({IconData iconData, Function onPressed, String label}) {
    return SpeedDialChild(
        child: Icon(iconData),
        onTap: onPressed,
        label: label,
        labelStyle: TextStyle(fontWeight: FontWeight.w500),
        labelBackgroundColor: Theme.of(context).backgroundColor,
        backgroundColor: Theme.of(context).colorScheme.background);
  }

  Future<List<SpeedDialChild>> _getProfileMenu() async {
    List<SpeedDialChild> children = [];

    var notesBloc = Provider.of<NotesBloc>(context);
    (await notesBloc.getWorksheets()).forEach((k, v) {
      children.add(_profileOption(
          iconData: Icons.format_list_bulleted, onPressed: () => _newNoteTapped(context, v), label: v.displayName));
    });
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
    var emptyNote = Worksheet("", content.clone(), DateTime.now(), DateTime.now(), getInitialNoteColor());
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
