import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ChipTags extends StatefulWidget {
  const ChipTags(
    this.formKey, {
    Key? key,
    this.iconColor,
    this.chipColor,
    this.textColor,
    this.textFieldStyle,
    this.decoration,
    this.keyboardType,
    this.suggestions,
    required this.tags,
    required this.onChanged,
    required this.prompt,
    this.autocorrect = false,
    this.stopWords,
    this.focusNode,
    this.textEditingController,
    this.minTextFieldWidth = 160.0,
    this.tagSpacing = 4.0,
    this.delimiters = const [',', ' '],
    this.autoSubmitOnDelim = true,
  }) : super(key: key);

  ///remove icon Color
  final Color? iconColor;

  ///chip background color
  final Color? chipColor;

  ///color of text inside chip
  final Color? textColor;

  ///container decoration
  final InputDecoration? decoration;

  final TextInputType? keyboardType;

  final Set<String>? suggestions;

  final List<String> tags;

  final bool autocorrect;

  final void Function(List<String>) onChanged;

  final Set<String>? stopWords;

  final TextEditingController? textEditingController;
  final FocusNode? focusNode;
  final GlobalKey<FormBuilderState> formKey;
  final String prompt;

  /// The minimum width that the `TextField` should take
  final double minTextFieldWidth;

  /// The spacing between each tag
  final double tagSpacing;

  final List<String> delimiters;
  final bool autoSubmitOnDelim;
  final TextStyle? textFieldStyle;
  @override
  _ChipTagsState createState() => _ChipTagsState();
}

class _ChipTagsState extends State<ChipTags> with SingleTickerProviderStateMixin {
  late final RegExp splitPattern;
  late final GlobalKey<FormBuilderState> _formKey;
  late final FocusNode _fieldFocusNode;
  late final TextEditingController _typeAheadController;

  var _previousText = '';
  @override
  void initState() {
    super.initState();
    splitPattern = new RegExp(r"[,\s]");
    _formKey = widget.formKey;
    _fieldFocusNode = widget.focusNode ?? FocusNode();
    _typeAheadController = widget.textEditingController ?? TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[_buildFormField(), SizedBox(height: 5), _chipListPreview()],
    );
  }

  Widget _buildFormField() {
    return TypeAheadFormField(
      direction: AxisDirection.down,
      hideOnEmpty: true,
      minCharsForSuggestions: 1,
      hideKeyboard: false,
      autoFlipDirection: true,
      hideSuggestionsOnKeyboardHide: false,
      textFieldConfiguration: TextFieldConfiguration(
          controller: _typeAheadController,
          focusNode: _fieldFocusNode,
          autocorrect: widget.autocorrect,
          style: widget.textFieldStyle,
          decoration: widget.decoration ??
              InputDecoration(
                border: const UnderlineInputBorder(),
                labelText: widget.prompt,
                // hintText: "Enter one or more tags separated by spaces",
              ),
          keyboardType: widget.keyboardType ?? TextInputType.text,
          textInputAction: TextInputAction.done,
          onSubmitted: _addTags,
          onChanged: _onTextFieldChange,
          inputFormatters: [_StopWordsFilterFormatter(widget.stopWords, widget.delimiters)]),
      suggestionsCallback: (pattern) {
        final patt = pattern.trim();
        return widget.suggestions!
            .where(
                (String tag) => tag.toLowerCase().startsWith(patt.trim().toLowerCase()) && !widget.tags.contains(tag))
            .toList();
      },
      itemBuilder: (context, suggestion) {
        return ListTile(title: Text(suggestion));
      },
      transitionBuilder: (context, suggestionsBox, controller) {
        return suggestionsBox;
      },
      onSuggestionSelected: (suggestion) {
        setState(() {
          widget.tags.add(suggestion);
        });
        _commitTags();
      },
    );
  }

  Visibility _chipListPreview() {
    return Visibility(
      //if length is 0 it will not occupy any space
      visible: widget.tags.length > 0,
      child: Wrap(
        alignment: WrapAlignment.start,
        textDirection: TextDirection.ltr,
        crossAxisAlignment: WrapCrossAlignment.start,
        // fancy some chips?
        children: widget.tags.map((text) {
          return Padding(
              padding: const EdgeInsets.all(2.0),
              child: FilterChip(
                backgroundColor: widget.chipColor ?? Colors.blue,
                label: Text(
                  text,
                  style: TextStyle(color: widget.textColor ?? Colors.white),
                ),
                avatar: Icon(Icons.remove_circle_outline, color: widget.iconColor ?? Colors.white),
                onSelected: (value) {
                  widget.tags.remove(text);
                  widget.onChanged(widget.tags);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                labelStyle: TextStyle(fontSize: 15),
                labelPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              ));
        }).toList(),
      ),
    );
  }

  void _commitTags() {
    _typeAheadController.clear();
    widget.onChanged(widget.tags);
    _formKey.currentState!.save();
  }

  Set<String> _extractTags(String value) {
    return value
        .split(splitPattern)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .where((s) => widget.stopWords == null ? true : !widget.stopWords!.contains(s.toLowerCase()))
        .toSet();
  }

  void _onTextFieldChange(String string) {
    final previousText = _previousText;
    _previousText = string;

    if (widget.autoSubmitOnDelim) {
      if (string.isEmpty || widget.delimiters.isEmpty) {
        _typeAheadController.clear();
        return;
      }

      // Do not allow the entry of the delimters, this does not account for when
      // the text is set with `TextEditingController` the behaviour of TextEditingContoller
      // should be controller by the developer themselves
      if (string.length == 1 && widget.delimiters.contains(string)) {
        _typeAheadController.clear();
        return;
      }

      if (string.length > previousText.length) {
        // Add case
        final newChar = string[string.length - 1];
        if (widget.delimiters.contains(newChar)) {
          final targetString = string.substring(0, string.length - 1);
          if (targetString.isNotEmpty) {
            _addTags(targetString);
          }
        }
      }
    }
  }

  void _addTags(String newTags) {
    final tags = _extractTags(newTags);
    if (tags.isNotEmpty) {
      setState(() {
        widget.tags.addAll(tags);
      });
      _commitTags();
    }
  }
}

class _StopWordsFilterFormatter extends TextInputFormatter {
  final Set<String>? stopWords;
  final List<String> delimiters;
  _StopWordsFilterFormatter(this.stopWords, this.delimiters);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (stopWords?.isEmpty ?? true) {
      return newValue;
    }
    String text = newValue.text;
    final isStopWord = delimiters.firstWhereOrNull((delim) => text.endsWith(delim)) != null &&
        stopWords!.contains(text.trim().toLowerCase());
    return isStopWord ? oldValue : newValue;
  }
}
