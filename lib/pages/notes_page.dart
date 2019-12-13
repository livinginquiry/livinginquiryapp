import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../blocs/notes_bloc.dart';
import '../models/note.dart';
import '../widgets/note_tile.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key key}) : super(key: key);
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    var notesBloc = Provider.of<NotesBloc>(context);
    GlobalKey _listKey = GlobalKey();

    return Container(
        child: Padding(
      padding: _paddingForView(context),
      child: StreamBuilder<List<Note>>(
          stream: notesBloc.notes,
          builder: (BuildContext context, AsyncSnapshot<List<Note>> snapshot) {
            // Make sure data exists and is actually loaded
            if (snapshot.hasData) {
              // If there are no notes (data), display this message.
              if (snapshot.data.length == 0) {
                return Text('No notes');
              }

              List<Note> notes = snapshot.data;

              return ListView.separated(
                key: _listKey,
                itemCount: notes.length,
                itemBuilder: (BuildContext context, int index) {
                  return NoteTile(notes[index]);
                },
                padding: EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 0.0),
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 10,
                  );
                },
              );
            }

            // If the data is loading in, display a progress indicator
            // to indicate that. You don't have to use a progress
            // indicator, but the StreamBuilder has to return a widget.
            return Center(
              child: CircularProgressIndicator(),
            );
          }),
    ));
  }

  EdgeInsets _paddingForView(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double padding;
    double topBottom = 8;
    if (width > 500) {
      padding = (width) * 0.05; // 5% padding of width on both side
    } else {
      padding = 8;
    }
    return EdgeInsets.only(left: padding, right: padding, top: topBottom, bottom: topBottom);
  }
}
