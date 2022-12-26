import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

  ///sets the remove icon Color
  final Color? iconColor;

  ///sets the chip background color
  final Color? chipColor;

  ///sets the color of text inside chip
  final Color? textColor;

  ///container decoration
  final InputDecoration? decoration;

  ///set keyboradType
  final TextInputType? keyboardType;

  final Set<String>? suggestions;

  /// list of String to display
  final List<String> tags;

  /// Default `createTagOnSumit = false`
  /// Creates new tag if user submit.
  /// If true they separtor will be ignored.
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
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Form(
            key: _formKey,
            child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if ((widget.suggestions?.isEmpty ?? true) || textEditingValue.text.isEmpty) {
                    return List.empty();
                  } else {
                    return widget.suggestions!
                        .where((String tag) =>
                            tag.toLowerCase().startsWith(textEditingValue.text.toLowerCase()) &&
                            !widget.tags.contains(tag))
                        .toList();
                  }
                },
                displayStringForOption: (String option) => option,
                fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                  return TextField(
                    autocorrect: widget.autocorrect,
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
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

                              ///setting the controller to empty
                              fieldTextEditingController.clear();

                              ///resetting form
                              _formKey.currentState!.reset();

                              fieldFocusNode.requestFocus();
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

                              ///setting the controller to empty
                              fieldTextEditingController.clear();

                              ///resetting form
                              _formKey.currentState!.reset();

                              // setState(() {});
                              widget.onChanged();
                            }
                          },
                  );
                },
                onSelected: (String selection) {
                  print('Selected: $selection');
                },
                optionsViewBuilder:
                    (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      child: Container(
                        // width: 300,
                        color: Colors.white,
                        child: ListView.builder(
                          padding: EdgeInsets.zero, //EdgeInsets.all(10.0),
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Builder(builder: (BuildContext context) {
                                final bool highlight = AutocompleteHighlightedOption.of(context) == index;
                                if (highlight) {
                                  SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
                                    Scrollable.ensureVisible(context, alignment: 0.5);
                                  });
                                }
                                return Container(
                                  color: highlight ? Theme.of(context).focusColor : null,
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    RawAutocomplete.defaultStringForOption(option),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                })),
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
      //if length is 0 it will not occupie any space
      visible: widget.tags.length > 0,
      child: Wrap(
        ///creating a list
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
                  // setState(() {});
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
