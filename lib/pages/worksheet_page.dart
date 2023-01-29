import 'dart:async';
import 'dart:developer';

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

import '../providers/preferences.dart';
import '../models/util.dart';
import '../models/worksheet.dart';
import '../providers/worksheets_provider.dart';
import '../widgets/chip_tags.dart';
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
  late Worksheet _worksheet, _original;
  var _worksheetColor;
  bool _isNew = false;
  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  final List<Tuple2<TextEditingController, FocusNode>> _fieldControllers = [];
  late final KeyboardActionsConfig _keyboardActionsConfig;

  Set<String> _suggestions = <String>{};

  late Future<Set<String>> _stopWords;
  late final List<String> _tags;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _worksheet = widget.worksheet;
    _tags = widget.worksheet.tags?.toList() ?? <String>[];
    _original = Worksheet.clone(widget.worksheet);
    _worksheetColor = _worksheet.noteColor;
    if (widget.worksheet.id == -1) {
      _isNew = true;
    }

    _worksheet.content.questions.forEach((val) {
      _fieldControllers.add(Tuple2(TextEditingController(text: val.answer), FocusNode()));
    });
    _keyboardActionsConfig = _buildConfig();

    _stopWords = _getStopWords();

    Future.delayed(Duration.zero, () async {
      ref.watch(prefsUtilProvider).setLastWorksheetId(_worksheet.id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _fbKey.currentState!.save();
        await _persistData(context);
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
    _suggestions = ref.read(worksheetNotifierProvider.notifier).getCachedTags();
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
        ]))));
  }

  Widget _buildTags(BuildContext context, TextEditingController controller, FocusNode focusNode, String title,
      String prompt, TextStyle style) {
    return FutureBuilder(
        future: _stopWords,
        builder: (BuildContext context, AsyncSnapshot<Set<String>> snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.only(left: 3.0, right: 3.0, top: 3.0, bottom: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FormBuilderField<List<String>?>(
                      name: title,
                      onChanged: (tags) {
                        if (tags != null) {
                          _tags.clear();
                          _tags.addAll(tags);
                        } else {
                          _tags.clear();
                        }
                        _worksheet.tags = _tags.toSet();
                        _fbKey.currentState!.save();
                      },
                      builder: (FormFieldState field) {
                        return ChipTags(_fbKey,
                            tags: new List.from(_tags),
                            onChanged: (value) => field.didChange(value),
                            suggestions: _suggestions,
                            stopWords: snapshot.data,
                            textEditingController: controller,
                            focusNode: focusNode,
                            minTextFieldWidth: 100.0,
                            prompt: prompt,
                            textFieldStyle: style);
                      }),
                ],
              ),
            );
          } else {
            return CircularProgressIndicator();
          }
        });
  }

  Widget _buildFormColorPicker(BuildContext context, String title, String prompt, TextStyle textStyle) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: 10),
        Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(prompt, style: textStyle),
            ]),
        SizedBox(height: 10),
        Padding(
            padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: SizedBox(
              height: 44,
              width: MediaQuery.of(context).size.width,
              child: FormBuilderField<Color?>(
                  name: title,
                  onChanged: (color) {
                    if (color != null) {
                      _fbKey.currentState!.save();
                      _changeColor(color);
                    }
                  },
                  builder: (FormFieldState field) {
                    return ColorSlider(
                      callBackColorTapped: (color) => field.didChange(color),
                      // call callBack from worksheetPage here
                      worksheetColor: _worksheetColor, // take color from local variable
                    );
                  }),
            ))
      ],
    );
  }

  Widget _buildChildButtons(BuildContext context, String prompt, TextStyle style) {
    if (_worksheet.content.children?.isNotEmpty ?? false) {
      final provider = ref.read(worksheetTypeProvider);
      final childrenTypes = _worksheet.content.children!;
      final contentTypes = provider
          .getCachedInquiryTypes()!
          .entries
          .map((e) => e.value)
          .where((element) => childrenTypes.contains(element.type));
      final label = Text(
        prompt,
        style: style,
      );
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
    String msg = await _persistData(ctx);
    if (msg.isNotEmpty) {
      _showErrorDialog(ctx, msg);
    } else {
      var emptyWorksheet = Worksheet("", content.clone(), DateTime.now(), DateTime.now(), getInitialWorksheetColor(),
          parentId: _worksheet.id);
      Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (ctx) => WorksheetPage(emptyWorksheet)));
    }
  }

  void _showErrorDialog(BuildContext ctx, String message) {
    errorDialog(ctx, "Save Worksheet Error", message);
  }

  Widget _pageTitle() {
    final TextStyle navBarStyle =
        Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.secondary.darken(.2));
    if (_isNew) {
      return Text(_worksheet.content.type.name.titleCase, style: navBarStyle);
    } else {
      final heading = _worksheet.content.questions.firstOrNull?.answer.isNotEmpty ?? false
          ? truncateWithEllipsis(extractAnswerFirstLine(_worksheet.content.questions.first.answer), 35)
          : _worksheet.content.displayName ?? _worksheet.content.type.name.titleCase;
      return Text(heading, style: navBarStyle);
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
            isArchived: _worksheet.isArchived,
            isStarred: _worksheet.isStarred,
            callBackColorTapped: (color) => _changeColor(color),
            callBackOptionTapped: bottomSheetOptionTappedHandler,
            lastModified: _worksheet.dateLastEdited,
          );
        });
  }

  Future<String> _persistData(BuildContext context) async {
    if (_original != _worksheet) {
      final db = ref.read(worksheetNotifierProvider.notifier);
      return db.addWorksheet(_worksheet).then((id) {
        _worksheet.id = id;
        return "";
      }).catchError((e) {
        final msg = "Unable to save worksheet: $e";
        log(msg, error: e, stackTrace: StackTrace.current);
        return msg;
      });
    } else {
      print("Ignoring since no changes");
      return "";
    }
  }

  void bottomSheetOptionTappedHandler(moreOptions tappedOption) {
    switch (tappedOption) {
      case moreOptions.archive:
        {
          _archiveWorksheet(_globalKey.currentContext!);
          break;
        }
      case moreOptions.unarchive:
        {
          _unarchiveWorksheet(_globalKey.currentContext!);
          break;
        }
      case moreOptions.delete:
        {
          _deleteWorksheet(_globalKey.currentContext!);
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
      case moreOptions.star:
        {
          if (!this._worksheet.isStarred) {
            print("I'm starring!!!");
            setState(() {
              this._worksheet.isStarred = true;
              _fbKey.currentState!.save();
            });
          }
          break;
        }
      case moreOptions.unstar:
        {
          if (this._worksheet.isStarred) {
            print("I'm un-starring!!!");
            setState(() {
              this._worksheet.isStarred = false;
              _fbKey.currentState!.save();
            });
          }
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
                          onError: (error, stackTrace) => print("Couldn't delete worksheet: $error, $stackTrace"));
                    },
                    child: Text("Yes")),
                TextButton(onPressed: () => {Navigator.of(context).pop()}, child: Text("No"))
              ],
            );
          });
    }
  }

  void _archiveWorksheet(BuildContext context) {
    if (_worksheet.id != -1) {
      final msg = (_worksheet.childIds?.isEmpty ?? true)
          ? "This worksheet will be archived"
          : "This worksheet and ${_worksheet.childIds!.length} child worksheets will be archived";
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm ?"),
              content: Text(msg),
              actions: <Widget>[
                TextButton(
                    onPressed: () async {
                      final db = ref.read(worksheetNotifierProvider.notifier);
                      db.archiveWorksheet(_worksheet).then(
                          (value) => Navigator.of(context)
                            ..pop()
                            ..pop(),
                          onError: (error, stackTrace) => print("Couldn't archive worksheet: $error, $stackTrace"));
                    },
                    child: Text("Yes")),
                TextButton(onPressed: () => {Navigator.of(context).pop()}, child: Text("No"))
              ],
            );
          });
    } else {
      _exitWithoutSaving(context);
    }
  }

  void _unarchiveWorksheet(BuildContext context) {
    if (_worksheet.id != -1) {
      final msg = (_worksheet.childIds?.isEmpty ?? true)
          ? "This worksheet will be un-archived"
          : "This worksheet and ${_worksheet.childIds!.length} child worksheets will be un-archived";
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm ?"),
              content: Text(msg),
              actions: <Widget>[
                TextButton(
                    onPressed: () async {
                      final db = ref.read(worksheetNotifierProvider.notifier);
                      db.archiveWorksheet(_worksheet, archive: false).then(
                          (value) => Navigator.of(context)
                            ..pop()
                            ..pop(),
                          onError: (error, stackTrace) => print("Couldn't un-archive worksheet: $error, $stackTrace"));
                    },
                    child: Text("Yes")),
                TextButton(onPressed: () => {Navigator.of(context).pop()}, child: Text("No"))
              ],
            );
          });
    } else {
      _exitWithoutSaving(context);
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
    ref.watch(prefsUtilProvider).clearLastWorksheetId();
    _fbKey.currentState!.save();
    final msg = await _persistData(context);
    if (msg.isNotEmpty) {
      _showErrorDialog(context, msg);
      return false;
    } else {
      Navigator.pop(context, _worksheet.id);
      return true;
    }
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
    final TextStyle textFieldStyle = Theme.of(context).textTheme.titleMedium!;
    final TextStyle largerStyle = textFieldStyle.copyWith(fontSize: (textFieldStyle.fontSize ?? 16) + 2);
    worksheet.content.questions.asMap().forEach((index, q) {
      items.add(Text(
        q.question,
        maxLines: null,
        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ));

      var formItem;
      switch (q.type) {
        case QuestionType.multiple:
          {
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
          }
          break;
        case QuestionType.freeform:
          {
            final idx = index;
            formItem = FormBuilderTextField(
              style: largerStyle,
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
          }
          break;
        case QuestionType.meta:
          TextStyle style = largerStyle;
          switch (q.subType) {
            case QuestionSubType.tags:
              formItem = _buildTags(
                  context, _fieldControllers[index].item1, _fieldControllers[index].item2, q.question, q.prompt, style);
              break;
            case QuestionSubType.children:
              formItem = _buildChildButtons(context, q.prompt, style);
              break;
            case QuestionSubType.color_picker:
              formItem = _buildFormColorPicker(context, q.question, q.prompt, style);
              break;
            case null:
              throw FormatException("No subtype provided!");
          }
          break;
      }
      items.add(formItem);
      items.add(SizedBox(height: 20));
    });

    return items;
  }

  Future<Set<String>> _getStopWords() async {
    var provider = ref.read(stopWordsProvider);
    return provider.getStopWords();
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
