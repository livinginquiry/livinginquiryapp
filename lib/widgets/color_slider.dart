import 'package:flutter/material.dart';

import '../models/constants.dart' as constants;

class ColorSlider extends StatefulWidget {
  final void Function(Color?) callBackColorTapped;
  final Color? noteColor;
  ColorSlider({required this.callBackColorTapped, required this.noteColor});
  @override
  _ColorSliderState createState() => _ColorSliderState();
}

class _ColorSliderState extends State<ColorSlider> {
  final Color borderColor = Color(0xffd3d3d3);
  final Color foregroundColor = Color(0xff595959);

  final _check = Icon(Icons.check);

  Color? noteColor;
  int? indexOfCurrentColor;
  @override
  void initState() {
    super.initState();
    this.noteColor = widget.noteColor;
    indexOfCurrentColor = constants.NOTE_COLORS.indexOf(noteColor);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(constants.NOTE_COLORS.length, (index) {
          return GestureDetector(
              onTap: () => _colorChangeTapped(index),
              child: Padding(
                  padding: EdgeInsets.only(left: 6, right: 6),
                  child: Container(
                      child: new CircleAvatar(
                        child: _checkOrNot(index),
                        foregroundColor: foregroundColor,
                        backgroundColor: constants.NOTE_COLORS[index],
                      ),
                      width: 38.0,
                      height: 38.0,
                      padding: const EdgeInsets.all(1.0), // border width
                      decoration: new BoxDecoration(
                        color: borderColor, // border color
                        shape: BoxShape.circle,
                      ))));
        }));
  }

  void _colorChangeTapped(int indexOfColor) {
    setState(() {
      noteColor = constants.NOTE_COLORS[indexOfColor];
      indexOfCurrentColor = indexOfColor;
      widget.callBackColorTapped(constants.NOTE_COLORS[indexOfColor]);
    });
  }

  Widget? _checkOrNot(int index) {
    if (indexOfCurrentColor == index) {
      return _check;
    }
    return null;
  }
}
