import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../blocs/notes_bloc.dart';
import '../models/note.dart';
import '../widgets/note_tile.dart';

class NotesPage extends StatefulWidget {
  final bool showDone;
  const NotesPage({required this.showDone, Key? key}) : super(key: key);
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> with AutomaticKeepAliveClientMixin<NotesPage> {
  GlobalKey _listKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var notesBloc = Provider.of<NotesBloc>(context);
    notesBloc.loadWorksheets();
    return Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.zero,
          child: StreamBuilder<List<Worksheet>>(
              stream: widget.showDone ? notesBloc.notesDone : notesBloc.notesStarted,
              builder: (BuildContext context, AsyncSnapshot<List<Worksheet>> snapshot) {
                // Make sure data exists and is actually loaded
                if (snapshot.hasData) {
                  // If there are no notes (data), display this message.
                  if (snapshot.data!.length == 0) {
                    return Center(child: Text('Empty'));
                  }

                  List<Worksheet> worksheets = snapshot.data!;

                  return ListView.builder(
                      key: _listKey,
                      itemCount: worksheets.length,
                      itemBuilder: (BuildContext context, int index) {
                        return NoteTile(worksheets[index]);
                      });
                } else {
                  return Center(child: Text('Totes no notes'));
                }
              }),
        ));
  }
}
