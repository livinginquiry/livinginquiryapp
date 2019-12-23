import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import '../blocs/notes_bloc.dart';
import '../models/note.dart';
import '../models/util.dart';
import '../widgets/options_sheet.dart';

class NotePage extends StatefulWidget {
  final Worksheet worksheet;

  NotePage(this.worksheet);
  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  Worksheet _worksheet;
  var _noteColor;
  bool _isNewNote = false;

  // DateTime _lastEditedForUndo;

  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    _worksheet = widget.worksheet;
    _noteColor = _worksheet.noteColor;
    // _lastEditedForUndo = widget.worksheet.dateLastEdited;

    if (widget.worksheet.id == -1) {
      _isNewNote = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (_worksheet.id == -1 && _worksheet.title.isEmpty) {
    //   FocusScope.of(context).requestFocus(_titleFocus);
    // }

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
        resizeToAvoidBottomPadding: true,
      ),
      onWillPop: () => _readyToPop(context),
    );
  }

  Widget _body(BuildContext ctx) {
    return Container(
        color: _noteColor,
        padding: EdgeInsets.only(left: 16, right: 16, top: 12),
        child: SafeArea(
            child: SingleChildScrollView(
                child: Column(children: <Widget>[
          FormBuilder(
              // context,
              key: _fbKey,
              autovalidate: true,
              initialValue: {},
              // readOnly: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _buildQuestions(this._worksheet)))
        ]))));

    //   child: Builder(
    //       builder: (context) => Form(
    //           key: _formKey,
    //           child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.stretch, children: _buildQuestions(this._worksheet)))),
    //   left: true,
    //   right: true,
    //   top: false,
    //   bottom: false,
    // ));

    /* return Container(
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
                                )); */
  }

  Widget _pageTitle() {
    return Text(_worksheet.id == -1 ? "New Note" : "Edit Note");
  }

  List<Widget> _archiveAction(BuildContext context) {
    List<Widget> actions = [];
    // if (widget.worksheet.id != -1) {
    // actions.add(Padding(
    //   padding: EdgeInsets.symmetric(horizontal: 12),
    //   child: InkWell(
    //     child: GestureDetector(
    //       onTap: () => _undo(),
    //       child: Icon(
    //         Icons.undo,
    //         color: fontColor,
    //       ),
    //     ),
    //   ),
    // ));
    // }
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
            lastModified: _worksheet.dateLastEdited,
          );
        });
  }

  void _persistData(BuildContext context) {
    var notesBloc = Provider.of<NotesBloc>(context);

    updateNoteObject();

    if ((_worksheet.content.questions?.length ?? 0) > 0 && _worksheet.content.questions.first.answer != null) {
      if (_worksheet.id == -1) {
        notesBloc.inAddNote.add(_worksheet); // for new note

        notesBloc.added.listen((value) {
          _worksheet.id = value;
        });
      } else {
        notesBloc.inAddNote.add(_worksheet);
      }
    }
  }

  // this function will ne used to save the updated editing value of the note to the local variables as user types
  void updateNoteObject() {
    // final content = WorksheetContent(questions: [
    //   Question(question: "what?", answer: _contentController.text, type: QuestionType.freeform, prompt: "huh?")
    // ], type: NoteType.open_mic);

    // final note = Worksheet(
    //     _titleController.text, content, _worksheet.dateCreated, _worksheet.dateLastEdited, _noteColor,
    //     id: _worksheet.id);
    // _worksheet = note;
    print("new content: ${_worksheet.content}");
    print(widget.worksheet);
    print(_worksheet);

    // print("same title? ${_worksheet.title == _titleFrominitial}");
    // print("same content? ${_worksheet.content == _contentFromInitial}");

    // if (!(_worksheet.title == _titleFrominitial && _worksheet.content == _contentFromInitial) || (_isNewNote)) {
    //   // No changes to the note
    //   // Change last edit time only if the content of the note is mutated in compare to the note which the page was called with.
    //   _worksheet.dateLastEdited = DateTime.now();
    //   print("Updating date_last_edited");
    // }
  }

  void bottomSheetOptionTappedHandler(moreOptions tappedOption) {
    print("option tapped: $tappedOption");
    switch (tappedOption) {
      case moreOptions.delete:
        {
          if (_worksheet.id != -1) {
            _deleteNote(_globalKey.currentContext);
          } else {
            _exitWithoutSaving(context);
          }
          break;
        }
      case moreOptions.share:
        {
          if ((_worksheet.content.questions?.length ?? 0) > 0) {
            Share.share("${_worksheet.title}\n${_worksheet.content.toMap()}");
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
    if (_worksheet.id != -1) {
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
                      notesBloc.inDeleteNote.add(_worksheet.id);

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
      _worksheet.noteColor = newColorSelected;
    });
    _persistColorChange(context);
  }

  void _persistColorChange(BuildContext context) {
    if (_worksheet.id != -1) {
      var notesBloc = Provider.of<NotesBloc>(context);
      _worksheet.noteColor = _noteColor;
      notesBloc.inAddNote.add(_worksheet);
    }
  }

  void _saveAndStartNewNote(BuildContext context) async {
    var notesBloc = Provider.of<NotesBloc>(context);
    final content = (await notesBloc.getWorksheets())[_worksheet.content.type].clone();
    // final content = notesBloc.getWorksheet(_worksheet.content.type).clone();
    var emptyNote = Worksheet("", content, DateTime.now(), DateTime.now(), Colors.white);
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => NotePage(emptyNote)));
  }

  Future<bool> _readyToPop(BuildContext context) async {
    //show saved toast after calling _persistData function.
    _fbKey.currentState.save();
    if (_fbKey.currentState.validate()) {
      print(_fbKey.currentState.value);
    }
    _persistData(context);
    return true;
  }

  void _archivePopup(BuildContext context) {
    if (_worksheet.id != -1) {
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
    _worksheet.isArchived = true;
    notesBloc.inSaveNote.add(_worksheet);

    Navigator.of(context).pop(); // pop back to staggered view
    // TODO: OPTIONAL show the toast of deletion completion
    Scaffold.of(context).showSnackBar(new SnackBar(content: Text("deleted")));
  }

  void _copy() {
    var notesBloc = Provider.of<NotesBloc>(context);
    Worksheet copy =
        Worksheet(_worksheet.title, _worksheet.content, DateTime.now(), DateTime.now(), _worksheet.noteColor);
    notesBloc.inAddNote.add(copy);

    notesBloc.added.listen((id) {
      if (id >= 0) {
        // Pop and return true to let the main page know that a note was deleted and that
        // it has to update the note stream.
        Navigator.of(_globalKey.currentContext).pop();
      }
    });
  }

  List<Widget> _buildQuestions(Worksheet worksheet) {
    final List<Widget> items = [];
    worksheet.content.questions.forEach((q) {
      items.add(Text(
        q.question == null ? "" : q.question,
        maxLines: null,
        style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
      ));

      var formItem;

      if (q.type == QuestionType.multiple) {
        formItem = FormBuilderRadio(
          attribute: q.question,
          decoration: InputDecoration(labelText: q.prompt == null ? "" : q.prompt),
          initialValue: q.answer,
          // hint: q.prompt == null ? null : Text(q.prompt),
          validators: [],
          options: q.values
              .map((value) => FormBuilderFieldOption(
                    value: value,
                  ))
              .toList(growable: false),
          onSaved: (val) => q.answer = val,
        );
      } else {
        formItem = FormBuilderTextField(
          attribute: q.question,
          initialValue: q.answer,
          decoration: InputDecoration(labelText: q.prompt == null ? "" : q.prompt),
          validators: [
            FormBuilderValidators.max(500),
          ],
          onSaved: (val) => q.answer = val,
        );
      }
      items.add(formItem);
      items.add(SizedBox(height: 12));
    });

    return items;
  }
}
