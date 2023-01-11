import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ChipTags extends StatefulWidget {
  const ChipTags(this.formKey,
      {Key? key,
      this.iconColor,
      this.chipColor,
      this.textColor,
      this.decoration,
      this.keyboardType,
      this.suggestions,
      required this.tags,
      required this.onChanged,
      this.autocorrect = false,
      this.stopWords,
      this.focusNode,
      this.textEditingController})
      : super(key: key);

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

  final Set<String> tags;

  final bool autocorrect;

  final void Function(Set<String>) onChanged;

  final Set<String>? stopWords;

  final TextEditingController? textEditingController;
  final FocusNode? focusNode;
  final GlobalKey<FormBuilderState> formKey;

  @override
  _ChipTagsState createState() => _ChipTagsState();
}

class _ChipTagsState extends State<ChipTags> with SingleTickerProviderStateMixin {
  late final RegExp splitPattern;
  late final GlobalKey<FormBuilderState> _formKey;
  late final FocusNode _fieldFocusNode;
  late final TextEditingController _typeAheadController;
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
      children: <Widget>[
        TypeAheadFormField(
          direction: AxisDirection.down,
          hideOnEmpty: true,
          minCharsForSuggestions: 1,
          hideKeyboard: false,
          autoFlipDirection: true,
          textFieldConfiguration: TextFieldConfiguration(
              controller: _typeAheadController,
              focusNode: _fieldFocusNode,
              autocorrect: widget.autocorrect,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: widget.decoration ??
                  InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hintText: "Enter one or more tags separated by spaces",
                  ),
              keyboardType: widget.keyboardType ?? TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                final tags = _extractTags(value);
                if (tags.isNotEmpty) {
                  widget.tags.addAll(tags);
                  _commitTags();
                }
              }),
          suggestionsCallback: (pattern) {
            return widget.suggestions!
                .where(
                    (String tag) => tag.toLowerCase().startsWith(pattern.toLowerCase()) && !widget.tags.contains(tag))
                .toList();
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              title: Text(suggestion),
            );
          },
          transitionBuilder: (context, suggestionsBox, controller) {
            return suggestionsBox;
          },
          onSuggestionSelected: (suggestion) {
            widget.tags.add(suggestion);
            _commitTags();
          },
          onSaved: (value) {},
        ),
        SizedBox(height: 5),
        _chipListPreview()
      ],
    );
  }

  void _commitTags() {
    _formKey.currentState!.save();
    _typeAheadController.clear();

    _fieldFocusNode.requestFocus();
    widget.onChanged(widget.tags);
  }

  Set<String> _extractTags(String value) {
    return value
        .split(splitPattern)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .where((s) => widget.stopWords == null ? true : !widget.stopWords!.contains(s.toLowerCase()))
        .toSet();
  }

  Visibility _chipListPreview() {
    return Visibility(
      //if length is 0 it will not occupy any space
      visible: widget.tags.length > 0,
      child: Wrap(
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
}
