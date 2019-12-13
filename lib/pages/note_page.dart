import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import '../blocs/notes_bloc.dart';
import '../models/note.dart';
import '../models/util.dart';
import '../widgets/options_sheet.dart';

class NotePage extends StatefulWidget {
  final Note noteInEditing;

  NotePage(this.noteInEditing);
  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  var _noteColor;
  bool _isNewNote = false;
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  String _titleFrominitial;
  String _contentFromInitial;
  DateTime _lastEditedForUndo;

  Note _editableNote;

  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _editableNote = widget.noteInEditing;
    _titleController.text = _editableNote.title;
    _contentController.text = _editableNote.content;
    _noteColor = _editableNote.noteColor;
    _lastEditedForUndo = widget.noteInEditing.dateLastEdited;

    _titleFrominitial = widget.noteInEditing.title;
    _contentFromInitial = widget.noteInEditing.content;

    if (widget.noteInEditing.id == -1) {
      _isNewNote = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editableNote.id == -1 && _editableNote.title.isEmpty) {
      FocusScope.of(context).requestFocus(_titleFocus);
    }

    return WillPopScope(
      child: Scaffold(
        key: _globalKey,
        appBar: AppBar(
          brightness: Brightness.light,
          leading: BackButton(
            color: Colors.black,
          ),
          actions: _archiveAction(context),
          elevation: 1,
          backgroundColor: _noteColor,
          title: _pageTitle(),
        ),
        body: _body(context),
        resizeToAvoidBottomPadding: false,
      ),
      onWillPop: () => _readyToPop(context),
    );
  }

  Widget _body(BuildContext ctx) {
    return Container(
        color: _noteColor,
        padding: EdgeInsets.only(left: 16, right: 16, top: 12),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(5),
                  child: EditableText(
                      onChanged: (str) => {updateNoteObject()},
                      maxLines: null,
                      controller: _titleController,
                      focusNode: _titleFocus,
                      style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                      cursorColor: Colors.blue,
                      backgroundCursorColor: Colors.blue),
                ),
              ),
              Divider(
                color: borderColor,
              ),
              Flexible(
                  child: Container(
                      padding: EdgeInsets.all(5),
                      child: EditableText(
                        onChanged: (str) => {updateNoteObject()},
                        maxLines: 300, // arbitrary...
                        controller: _contentController,
                        focusNode: _contentFocus,
                        style: TextStyle(color: Colors.black, fontSize: 20),
                        backgroundCursorColor: Colors.red,
                        cursorColor: Colors.blue,
                      )))
            ],
          ),
          left: true,
          right: true,
          top: false,
          bottom: false,
        ));
  }

  Widget _pageTitle() {
    return Text(_editableNote.id == -1 ? "New Note" : "Edit Note");
  }

  List<Widget> _archiveAction(BuildContext context) {
    List<Widget> actions = [];
    if (widget.noteInEditing.id != -1) {
      actions.add(Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          child: GestureDetector(
            onTap: () => _undo(),
            child: Icon(
              Icons.undo,
              color: fontColor,
            ),
          ),
        ),
      ));
    }
    actions += [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          child: GestureDetector(
            onTap: () => _archivePopup(context),
            child: Icon(
              Icons.archive,
              color: fontColor,
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          child: GestureDetector(
            onTap: () => bottomSheet(context),
            child: Icon(
              Icons.more_vert,
              color: fontColor,
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          child: GestureDetector(
            onTap: () => {_saveAndStartNewNote(context)},
            child: Icon(
              Icons.add,
              color: fontColor,
            ),
          ),
        ),
      )
    ];
    return actions;
  }

  void bottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext ctx) {
          return OptionsSheet(
            color: _noteColor,
            callBackColorTapped: (color) => _changeColor(color, context),
            callBackOptionTapped: bottomSheetOptionTappedHandler,
            lastModified: _editableNote.dateLastEdited,
          );
        });
  }

  void _persistData(BuildContext context) {
    var notesBloc = Provider.of<NotesBloc>(context);

    updateNoteObject();

    if (_editableNote.content.isNotEmpty) {
      if (_editableNote.id == -1) {
        notesBloc.inAddNote.add(_editableNote); // for new note

        notesBloc.added.listen((value) {
          _editableNote.id = value;
        });
      } else {
        notesBloc.inAddNote.add(_editableNote);
      }
    }
  }

// this function will ne used to save the updated editing value of the note to the local variables as user types
  void updateNoteObject() {
    _editableNote.content = _contentController.text;
    _editableNote.title = _titleController.text;
    _editableNote.noteColor = _noteColor;
    print("new content: ${_editableNote.content}");
    print(widget.noteInEditing);
    print(_editableNote);

    print("same title? ${_editableNote.title == _titleFrominitial}");
    print("same content? ${_editableNote.content == _contentFromInitial}");

    if (!(_editableNote.title == _titleFrominitial && _editableNote.content == _contentFromInitial) || (_isNewNote)) {
      // No changes to the note
      // Change last edit time only if the content of the note is mutated in compare to the note which the page was called with.
      _editableNote.dateLastEdited = DateTime.now();
      print("Updating date_last_edited");
    }
  }

  void bottomSheetOptionTappedHandler(moreOptions tappedOption) {
    print("option tapped: $tappedOption");
    switch (tappedOption) {
      case moreOptions.delete:
        {
          if (_editableNote.id != -1) {
            _deleteNote(_globalKey.currentContext);
          } else {
            _exitWithoutSaving(context);
          }
          break;
        }
      case moreOptions.share:
        {
          if (_editableNote.content.isNotEmpty) {
            Share.share("${_editableNote.title}\n${_editableNote.content}");
          }
          break;
        }
      case moreOptions.copy:
        {
          _copy();
          break;
        }
    }
  }

  void _deleteNote(BuildContext context) {
    var notesBloc = Provider.of<NotesBloc>(context);
    if (_editableNote.id != -1) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm ?"),
              content: Text("This note will be deleted permanently"),
              actions: <Widget>[
                FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      notesBloc.inDeleteNote.add(_editableNote.id);

                      // Wait for `deleted` to be set before popping back to the main page. This guarantees there's no
                      // mismatch between what's stored in the database and what's being displayed on the page.
                      // This is usually only an issue with more database heavy actions, but it's a good thing to
                      // add regardless.
                      notesBloc.deleted.listen((deleted) {
                        if (deleted) {
                          // Pop and return true to let the main page know that a note was deleted and that
                          // it has to update the note stream.
                          Navigator.of(context).pop();
                        }
                      });
                    },
                    child: Text("Yes")),
                FlatButton(onPressed: () => {Navigator.of(context).pop()}, child: Text("No"))
              ],
            );
          });
    }
  }

  void _changeColor(Color newColorSelected, BuildContext context) {
    print("note color changed");
    setState(() {
      _noteColor = newColorSelected;
      _editableNote.noteColor = newColorSelected;
    });
    _persistColorChange(context);
  }

  void _persistColorChange(BuildContext context) {
    if (_editableNote.id != -1) {
      var notesBloc = Provider.of<NotesBloc>(context);
      _editableNote.noteColor = _noteColor;
      notesBloc.inAddNote.add(_editableNote);
    }
  }

  void _saveAndStartNewNote(BuildContext context) {
    var emptyNote = Note("", "", DateTime.now(), DateTime.now(), Colors.white);
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => NotePage(emptyNote)));
  }

  Future<bool> _readyToPop(BuildContext context) async {
    //show saved toast after calling _persistData function.

    _persistData(context);
    return true;
  }

  void _archivePopup(BuildContext context) {
    if (_editableNote.id != -1) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm ?"),
              content: Text("This note will be archived"),
              actions: <Widget>[
                FlatButton(onPressed: () => _archiveThisNote(context), child: Text("Yes")),
                FlatButton(onPressed: () => {Navigator.of(context).pop()}, child: Text("No"))
              ],
            );
          });
    } else {
      _exitWithoutSaving(context);
    }
  }

  void _exitWithoutSaving(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _archiveThisNote(BuildContext context) {
    Navigator.of(context).pop();
    var notesBloc = Provider.of<NotesBloc>(context);
    // set archived flag to true and send the entire note object in the database to be updated
    _editableNote.isArchived = true;
    notesBloc.inSaveNote.add(_editableNote);

    Navigator.of(context).pop(); // pop back to staggered view
    // TODO: OPTIONAL show the toast of deletion completion
    Scaffold.of(context).showSnackBar(new SnackBar(content: Text("deleted")));
  }

  void _copy() {
    var notesBloc = Provider.of<NotesBloc>(context);
    Note copy =
        Note(_editableNote.title, _editableNote.content, DateTime.now(), DateTime.now(), _editableNote.noteColor);
    notesBloc.inAddNote.add(copy);

    notesBloc.added.listen((id) {
      if (id >= 0) {
        // Pop and return true to let the main page know that a note was deleted and that
        // it has to update the note stream.
        Navigator.of(_globalKey.currentContext).pop();
      }
    });
  }

  void _undo() {
    _titleController.text = _titleFrominitial; // widget.noteInEditing.title;
    _contentController.text = _contentFromInitial; // widget.noteInEditing.content;
    _editableNote.dateLastEdited = _lastEditedForUndo; // widget.noteInEditing.date_last_edited;
  }
}
