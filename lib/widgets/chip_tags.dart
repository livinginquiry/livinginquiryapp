import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ChipTags extends StatefulWidget {
  const ChipTags(
      {Key? key,
      this.iconColor,
      this.chipColor,
      this.textColor,
      this.decoration,
      this.keyboardType,
      this.createTagOnSubmit = false,
      this.suggestions,
      required this.tags,
      required this.onChanged,
      this.autocorrect = false,
      this.stopWords})
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

  final bool createTagOnSubmit;

  final bool autocorrect;

  final void Function() onChanged;

  final Set<String>? stopWords;

  @override
  _ChipTagsState createState() => _ChipTagsState();
}

class _ChipTagsState extends State<ChipTags> with SingleTickerProviderStateMixin {
  late final RegExp splitPattern;
  @override
  void initState() {
    super.initState();
    splitPattern = new RegExp(r"[,\s]");
  }

  ///Form key for TextField
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _typeAheadController = TextEditingController();
  final FocusNode _fieldFocusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Form(
          key: _formKey,
          child: TypeAheadFormField(
            direction: AxisDirection.up,
            hideOnEmpty: true,
            minCharsForSuggestions: 1,
            hideKeyboard: false,
            // autoFlipDirection: true,
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
              onSubmitted: widget.createTagOnSubmit
                  ? (value) {
                      final tags = _extractTags(value);
                      if (tags.isNotEmpty) {
                        widget.tags.addAll(tags);

                        _typeAheadController.clear();

                        ///reset form
                        _formKey.currentState!.reset();

                        _fieldFocusNode.requestFocus();
                        widget.onChanged();
                      }
                    }
                  : null,
              onChanged: widget.createTagOnSubmit
                  ? null
                  : (value) {
                      final tags = _extractTags(value);
                      if (tags.isNotEmpty) {
                        widget.tags.addAll(tags);

                        _typeAheadController.clear();

                        _formKey.currentState!.reset();

                        // setState(() {});
                        widget.onChanged();
                      }
                    },
            ),
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

              _typeAheadController.clear();

              ///reset form
              _formKey.currentState!.reset();

              widget.onChanged();
            },
            onSaved: (value) {},
          ),
        ),
        SizedBox(height: 5),
        _chipListPreview()
      ],
    );
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
        ///create list
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
                  widget.onChanged();
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
