import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:validators/validators.dart';

import '../blocs/notes_bloc.dart';
import '../models/note.dart';
import '../models/util.dart';
import '../widgets/options_sheet.dart';

const int MAXIMUM_CHARS = 500;

class NotePage extends StatefulWidget {
  final Worksheet worksheet;

  NotePage(this.worksheet);
  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> with WidgetsBindingObserver {
  Worksheet? _worksheet;
  var _noteColor;
  bool _isNewNote = false;
  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  final List<FocusNode> focusNodes = [];
  final List<TextEditingController> _textControllers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _worksheet = widget.worksheet;
    _noteColor = _worksheet!.noteColor;

    if (widget.worksheet.id == -1) {
      _isNewNote = true;
    }

    _worksheet!.content.questions?.forEach((val) {
      focusNodes.add(FocusNode());
      _textControllers.add(TextEditingController());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('state = $state');
    switch (state) {
      case AppLifecycleState.inactive:
        print("Inactive");
        break;
      case AppLifecycleState.paused:
        print("Paused");
        _readyToPop(this.context);
        break;
      case AppLifecycleState.resumed:
        print("Resumed");
        break;
      case AppLifecycleState.detached:
        print("Detached");
        break;
    }
  }

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
        keyboardBarColor: Colors.grey[200],
        nextFocus: true,
        actions: this.focusNodes.map((node) => KeyboardActionsItem(focusNode: node)).toList());
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
          actions: _buildActions(context),
          elevation: 1,
          backgroundColor: Colors.white,
          title: _pageTitle(),
        ),
        body: KeyboardActions(config: _buildConfig(context), child: _body(context)),
        resizeToAvoidBottomInset: true,
      ),
      onWillPop: () => _readyToPop(context),
    );
  }

  Widget _body(BuildContext ctx) {
    return Container(
        /* decoration: BoxDecoration(
            border: Border(top: BorderSide(color: _noteColor, width: 8)),
            color: TinyColor(_noteColor).lighten(15).color), */
        color: _noteColor,
        padding: EdgeInsets.only(left: 16, right: 16, top: 12),
        child: SafeArea(
            child: Column(children: <Widget>[
          FormBuilder(
              // context,
              key: _fbKey,
              autovalidateMode: AutovalidateMode.always,
              initialValue: {},
              // readOnly: true,
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _buildQuestions(this._worksheet!))),
          Center(
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text("Mark as done"),
                  Switch(
                    value: this._worksheet!.isComplete,
                    onChanged: (value) {
                      setState(() {
                        this._worksheet!.isComplete = value;
                        _fbKey.currentState!.save();
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  )
                ]),
          ),
        ])));
  }

  Widget _pageTitle() {
    return Text(_worksheet!.id == -1 ? "New Note" : "Edit Note");
  }

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actions = [];
    actions += [
      // Padding(
      //   padding: EdgeInsets.symmetric(horizontal: 12),
      //   child: InkWell(
      //     child: GestureDetector(
      //       onTap: () => _archivePopup(context),
      //       child: Icon(
      //         Icons.archive,
      //         color: fontColor,
      //       ),
      //     ),
      //   ),
      // ),
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
      ) /* ,
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
      ) */
    ];
    return actions;
  }

  void bottomSheet(BuildContext context) {
    _fbKey.currentState!.save();
    showModalBottomSheet(
        context: context,
        // backgroundColor: Colors.white,
        builder: (BuildContext ctx) {
          return OptionsSheet(
            color: _noteColor,
            callBackColorTapped: (color) => _changeColor(color, context),
            callBackOptionTapped: bottomSheetOptionTappedHandler,
            lastModified: _worksheet!.dateLastEdited,
          );
        });
  }

  void _persistData(BuildContext context) {
    var notesBloc = Provider.of<NotesBloc>(context, listen: false);

    updateNoteObject();

    if ((_worksheet!.content.questions?.length ?? 0) > 0 && _worksheet!.content.questions!.first.answer != null) {
      if (_worksheet!.id == -1) {
        notesBloc.inAddNote.add(_worksheet); // for new note

        notesBloc.added.listen((value) {
          _worksheet!.id = value;
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
    print("new content: ${_worksheet!.content}");
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
          if (_worksheet!.id != -1) {
            _deleteNote(_globalKey.currentContext!);
          } else {
            _exitWithoutSaving(context);
          }
          break;
        }
      case moreOptions.share:
        {
          if ((_worksheet!.content.questions?.length ?? 0) > 0) {
            _fbKey.currentState!.save();
            Share.share("${_worksheet!.content.displayName}\n${_worksheet!.content.toReadableFormat()}");
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
    var notesBloc = Provider.of<NotesBloc>(context, listen: false);
    if (_worksheet!.id != -1) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm ?"),
              content: Text("This note will be deleted permanently"),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      notesBloc.inDeleteNote.add(_worksheet!.id);

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
                TextButton(onPressed: () => {Navigator.of(context).pop()}, child: Text("No"))
              ],
            );
          });
    }
  }

  void _changeColor(Color newColorSelected, BuildContext context) {
    print("note color changed");
    setState(() {
      _noteColor = newColorSelected;
      _worksheet!.noteColor = newColorSelected;
    });
    _persistColorChange(context);
  }

  void _persistColorChange(BuildContext context) {
    if (_worksheet!.id != -1) {
      var notesBloc = Provider.of<NotesBloc>(context, listen: false);
      _worksheet!.noteColor = _noteColor;
      notesBloc.inAddNote.add(_worksheet);
    }
  }

  void _saveAndStartNewNote(BuildContext context) async {
    var notesBloc = Provider.of<NotesBloc>(context, listen: false);
    final content = (await notesBloc.getWorksheets())![_worksheet!.content.type as String]!.clone();
    // final content = notesBloc.getWorksheet(_worksheet.content.type).clone();
    var emptyNote = Worksheet("", content, DateTime.now(), DateTime.now(), getInitialNoteColor());
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => NotePage(emptyNote)));
  }

  Future<bool> _readyToPop(BuildContext context) async {
    //show saved toast after calling _persistData function.
    _fbKey.currentState!.save();
    if (_fbKey.currentState!.validate()) {
      print(_fbKey.currentState!.value);
    }
    _persistData(context);
    return true;
  }

  void _archivePopup(BuildContext context) {
    if (_worksheet!.id != -1) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm ?"),
              content: Text("This note will be archived"),
              actions: <Widget>[
                TextButton(onPressed: () => _archiveThisNote(context), child: Text("Yes")),
                TextButton(onPressed: () => {Navigator.of(context).pop()}, child: Text("No"))
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
    var notesBloc = Provider.of<NotesBloc>(context, listen: false);
    // set archived flag to true and send the entire note object in the database to be updated
    _worksheet!.isArchived = true;
    notesBloc.inSaveNote.add(_worksheet);

    Navigator.of(context).pop(); // pop back to staggered view

    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text("deleted")));
  }

  void _copy() {
    var notesBloc = Provider.of<NotesBloc>(context, listen: false);
    Worksheet copy =
        Worksheet(_worksheet!.title, _worksheet!.content, DateTime.now(), DateTime.now(), _worksheet!.noteColor);
    notesBloc.inAddNote.add(copy);

    notesBloc.added.listen((id) {
      if (id >= 0) {
        // Pop and return true to let the main page know that a note was deleted and that
        // it has to update the note stream.
        Navigator.of(_globalKey.currentContext!).pop();
      }
    });
  }

  List<Widget> _buildQuestions(Worksheet worksheet) {
    final List<Widget> items = [];

    worksheet.content.questions!.asMap().forEach((index, q) {
      items.add(Text(
        q.question == null ? "" : q.question!,
        maxLines: null,
        style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
      ));

      var formItem;

      if (q.type == QuestionType.multiple) {
        formItem = FormBuilderRadioGroup(
          name: q.question!,
          decoration: InputDecoration(labelText: q.prompt == null ? "" : q.prompt),
          initialValue: q.answer,
          // hint: q.prompt == null ? null : Text(q.prompt),
          validator: null,
          options: q.values!
              .map((value) => FormBuilderFieldOption(
                    value: value,
                  ))
              .toList(growable: false),
          onSaved: (dynamic val) => q.answer = val,
          // leadingInput: q.values.length <= 2,
        );
      } else {
        final idx = index;
        // _textControllers[idx].text = (q.answer?.isEmpty ?? true) ? "\u2022 " : q.answer;
        _textControllers[idx].text = q.answer!;
        // final isLast = index == worksheet.content.questions.length - 1;
        final item = FormBuilderTextField(
          maxLines: null,
          readOnly: false,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: <TextInputFormatter>[_BulletFormatter()],
          controller: _textControllers[idx],
          autofocus: index == 0 && _isNewNote,
          focusNode: focusNodes[idx],
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline /* isLast ? TextInputAction.done : TextInputAction.newline */,
          name: q.question!,
          decoration: InputDecoration(labelText: q.prompt == null ? "" : q.prompt),
          validator: FormBuilderValidators.max(MAXIMUM_CHARS),
          onSaved: (val) {
            print("saving $val");
            q.answer = val;
          },
          onSubmitted: (val) {
            print("submitting $val");
            focusNodes[idx].unfocus();
            if (focusNodes.length - 1 > idx) {
              FocusScope.of(context).requestFocus(focusNodes[idx + 1]);
            }
          },
          onEditingComplete: () {
            print("editing complete");
          },
        );
        formItem = item;
      }

      items.add(formItem);
      items.add(SizedBox(height: 20));
    });

    return items;
  }
}

class _BulletFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final int oldTextLength = oldValue.text.length;
    final int newTextLength = newValue.text.length;
    if (newTextLength - oldTextLength == 1 &&
        newValue.selection.baseOffset == newValue.selection.extentOffset &&
        newValue.text[newValue.selection.extentOffset - 1] == '\n') {
      //TODO: see if the previous line had a leading bullet. If not add it!
      var shift = 2;
      var prefix = newValue.text.substring(0, newValue.selection.extentOffset);
      var start = prefix.substring(0, prefix.length).split('').reversed.join().indexOf('\n', 1);
      if (start < 0) {
        start = 0;
      } else {
        start = prefix.length - start;
      }

      if (prefix[start] != '\u2022') {
        prefix = prefix.substring(0, start) + '\u2022 ' + prefix.substring(start, prefix.length);
        shift += 2;
      }
      final transformed = prefix +
          '\u2022 ' +
          (newValue.selection.base.offset >= newValue.text.length
              ? ''
              : newValue.text.substring(newValue.selection.extentOffset, newValue.text.length));
      return TextEditingValue(
        text: transformed.toString(),
        selection: TextSelection.collapsed(offset: newValue.selection.extentOffset + shift),
      );
    } else if (newTextLength - oldTextLength == 1 &&
        newTextLength > 2 &&
        newValue.selection.baseOffset == newValue.selection.extentOffset &&
        isAlphanumeric(newValue.text[newValue.selection.extentOffset - 1]) &&
        !isUppercase(newValue.text[newValue.selection.extentOffset - 1]) &&
        newValue.text[newValue.selection.extentOffset - 2] == ' ' &&
        newValue.text[newValue.selection.extentOffset - 3] == '\u2022') {
      final text = newValue.text.substring(0, newValue.selection.extentOffset - 1) +
          newValue.text[newValue.selection.extentOffset - 1].toUpperCase() +
          (newValue.selection.base.offset >= newValue.text.length
              ? ''
              : newValue.text.substring(newValue.selection.extentOffset, newValue.text.length));
      return TextEditingValue(text: text, selection: newValue.selection);
    } else
      return newValue;
  }
}
