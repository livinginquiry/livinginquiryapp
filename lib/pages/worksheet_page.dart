import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:recase/recase.dart';
import 'package:share/share.dart';
import 'package:tuple/tuple.dart';
import 'package:validators/validators.dart';

import '../models/util.dart';
import '../models/worksheet.dart';
import '../providers/worksheets_provider.dart';
import '../widgets/color_slider.dart';
import '../widgets/options_sheet.dart';

const int MAXIMUM_CHARS = 500;

class WorksheetPage extends ConsumerStatefulWidget {
  final Worksheet worksheet;

  const WorksheetPage(this.worksheet, {Key? key}) : super(key: key);
  @override
  _WorksheetPageState createState() => _WorksheetPageState();
}

class _WorksheetPageState extends ConsumerState<WorksheetPage> with WidgetsBindingObserver {
  late Worksheet _worksheet;
  var _worksheetColor;
  bool _isNew = false;
  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  final List<Tuple2<TextEditingController, FocusNode>> _fieldControllers = [];
  late final KeyboardActionsConfig _keyboardActionsConfig;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _worksheet = widget.worksheet;
    _worksheetColor = _worksheet.noteColor;

    if (widget.worksheet.id == -1) {
      _isNew = true;
    }

    _worksheet.content.questions.forEach((val) {
      _fieldControllers.add(Tuple2(TextEditingController(text: val.answer), FocusNode()));
    });
    _keyboardActionsConfig = _buildConfig();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _readyToPop(this.context);
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  KeyboardActionsConfig _buildConfig() {
    return KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
        keyboardBarColor: Colors.grey[200],
        nextFocus: true,
        actions: this._fieldControllers.map((tup) => KeyboardActionsItem(focusNode: tup.item2)).toList());
  }

  @override
  Widget build(BuildContext context) {
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
        body: KeyboardActions(
          config: _keyboardActionsConfig,
          child: _body(context),
          keepFocusOnTappingNode: true,
        ),
        resizeToAvoidBottomInset: true,
      ),
      onWillPop: () => _readyToPop(context),
    );
  }

  Widget _body(BuildContext ctx) {
    return Container(
        color: _worksheetColor,
        padding: EdgeInsets.only(left: 16, right: 16, top: 12),
        child: SafeArea(
            child: SingleChildScrollView(
                child: Column(children: <Widget>[
          FormBuilder(
              key: _fbKey,
              autovalidateMode: AutovalidateMode.always,
              initialValue: {},
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _buildQuestions(this._worksheet))),
          Column(
            children: [
              Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text("Mark as done"),
                    Switch(
                      value: this._worksheet.isComplete,
                      onChanged: (value) {
                        setState(() {
                          this._worksheet.isComplete = value;
                          _fbKey.currentState!.save();
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    )
                  ]),
              _buildChildren(ctx)
            ],
          ),
          new Padding(
            padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: SizedBox(
              height: 44,
              width: MediaQuery.of(context).size.width,
              child: ColorSlider(
                callBackColorTapped: (color) {
                  _fbKey.currentState!.save();
                  _changeColor(color);
                },
                // call callBack from worksheetPage here
                worksheetColor: _worksheetColor, // take color from local variable
              ),
            ),
          )
        ]))));
  }

  Widget _buildChildren(BuildContext context) {
    if (_worksheet.content.children?.isNotEmpty ?? false) {
      final provider = ref.read(worksheetTypeProvider);
      final childrenTypes = _worksheet.content.children!;
      final contentTypes = provider
          .getCachedInquiryTypes()!
          .entries
          .map((e) => e.value)
          .where((element) => childrenTypes.contains(element.type));
      final label = Text("Continue The Work:");
      final buttons = contentTypes.map((e) => _createNewWorksheetButton(context, e)).toList();
      return Row(children: [label, Expanded(child: SizedBox.shrink()), ...buttons]);
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _createNewWorksheetButton(BuildContext context, WorksheetContent content) {
    return TextButton(
      onPressed: () => _createChildWorksheet(context, content),
      child: Text(content.displayName ?? content.type.name.titleCase),
      style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.transparent),
          ),
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white),
    );
  }

  Future<void> _createChildWorksheet(BuildContext ctx, WorksheetContent content) async {
    _fbKey.currentState!.save();
    await _persistData(ctx);
    var emptyWorksheet = Worksheet("", content.clone(), DateTime.now(), DateTime.now(), getInitialWorksheetColor(),
        parentId: _worksheet.id);
    Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (ctx) => WorksheetPage(emptyWorksheet)));
  }

  Widget _pageTitle() {
    if (_isNew) {
      return Text(_worksheet.content.type.name.titleCase);
    } else {
      final heading = _worksheet.content.questions.firstOrNull?.answer.isNotEmpty ?? false
          ? truncateWithEllipsis(extractAnswerFirstLine(_worksheet.content.questions.first.answer), 35)
          : _worksheet.content.displayName ?? _worksheet.content.type.name.titleCase;
      return Text(heading);
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actions = [];
    actions += [
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: InkWell(
              child: GestureDetector(
                  onTap: () => bottomSheet(context),
                  child: Icon(
                    Icons.more_vert,
                    color: fontColor,
                  ))))
    ];
    return actions;
  }

  void bottomSheet(BuildContext context) {
    _fbKey.currentState!.save();
    showModalBottomSheet(
        context: context,
        builder: (BuildContext ctx) {
          return OptionsSheet(
            color: _worksheetColor,
            callBackColorTapped: (color) => _changeColor(color),
            callBackOptionTapped: bottomSheetOptionTappedHandler,
            lastModified: _worksheet.dateLastEdited,
          );
        });
  }

  Future<void> _persistData(BuildContext context) async {
    final db = ref.read(worksheetNotifierProvider.notifier);
    if (_worksheet.content.questions.first.answer.isNotEmpty) {
      final id = await db.addWorksheet(_worksheet);
      _worksheet.id = id;
    }
  }

  void bottomSheetOptionTappedHandler(moreOptions tappedOption) {
    switch (tappedOption) {
      case moreOptions.delete:
        {
          if (_worksheet.id != -1) {
            _deleteWorksheet(_globalKey.currentContext!);
          } else {
            _exitWithoutSaving(context);
          }
          break;
        }
      case moreOptions.share:
        {
          if (_worksheet.content.questions.length > 0) {
            _fbKey.currentState!.save();
            Share.share("${_worksheet.content.displayName}\n${_worksheet.content.toReadableFormat()}");
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

  void _deleteWorksheet(BuildContext context) async {
    if (_worksheet.id != -1) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm ?"),
              content: Text("This worksheet will be deleted permanently"),
              actions: <Widget>[
                TextButton(
                    onPressed: () async {
                      final db = ref.read(worksheetNotifierProvider.notifier);
                      db.deleteWorksheet(_worksheet.id).then(
                          (value) => Navigator.of(context)
                            ..pop()
                            ..pop(),
                          onError: (error, stackTrace) => print("Couldn't delete note: $error, $stackTrace"));
                    },
                    child: Text("Yes")),
                TextButton(onPressed: () => {Navigator.of(context).pop()}, child: Text("No"))
              ],
            );
          });
    }
  }

  // TODO: Use BLOC
  Future<void> _changeColor(Color newColorSelected) async {
    setState(() {
      _worksheetColor = newColorSelected;
      _worksheet.noteColor = newColorSelected;
    });
    _persistColorChange();
  }

  Future<void> _persistColorChange() async {
    if (_worksheet.id != -1) {
      final db = ref.read(worksheetNotifierProvider.notifier);
      _worksheet.noteColor = _worksheetColor;
      db.addWorksheet(_worksheet);
    }
  }

  Future<bool> _readyToPop(BuildContext context) async {
    //show saved toast after calling _persistData function.
    _fbKey.currentState!.save();
    await _persistData(context);
    Navigator.pop(context, _worksheet.id);
    return true;
  }

  void _exitWithoutSaving(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _copy() async {
    final db = ref.read(worksheetNotifierProvider.notifier);
    Worksheet copy =
        Worksheet(_worksheet.title, _worksheet.content, DateTime.now(), DateTime.now(), _worksheet.noteColor);
    final id = await db.addWorksheet(copy);
    if (id > 0) {
      Navigator.of(_globalKey.currentContext!).pop();
    }
  }

  List<Widget> _buildQuestions(Worksheet worksheet) {
    final List<Widget> items = [];

    worksheet.content.questions.asMap().forEach((index, q) {
      items.add(Text(
        q.question,
        maxLines: null,
        style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
      ));

      var formItem;

      if (q.type == QuestionType.multiple) {
        formItem = FormBuilderRadioGroup(
          name: q.question,
          decoration: InputDecoration(labelText: q.prompt),
          initialValue: q.answer,
          validator: null,
          options: q.values!
              .map((value) => FormBuilderFieldOption(
                    value: value,
                  ))
              .toList(growable: false),
          onSaved: (dynamic val) => q.answer = val,
        );
      } else {
        final idx = index;
        final item = FormBuilderTextField(
          maxLines: null,
          readOnly: false,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: <TextInputFormatter>[_BulletFormatter()],
          controller: _fieldControllers[idx].item1,
          autofocus: index == 0 && _isNew, // focus on first field when it's a new worksheet
          focusNode: _fieldControllers[idx].item2,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          name: q.question,
          decoration: InputDecoration(labelText: q.prompt),
          validator: FormBuilderValidators.max(MAXIMUM_CHARS),
          onSaved: (val) {
            q.answer = val ?? "";
          },
          onSubmitted: (val) {
            _fieldControllers[idx].item2.unfocus();
            if (_fieldControllers.length - 1 > idx) {
              FocusScope.of(context).requestFocus(_fieldControllers[idx + 1].item2);
            }
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
