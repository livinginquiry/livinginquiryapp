import 'package:flutter/material.dart';

import '../models/constants.dart' as constants;

class ColorSlider extends StatefulWidget {
  final void Function(Color) callBackColorTapped;
  final Color worksheetColor;
  const ColorSlider({required this.callBackColorTapped, required this.worksheetColor, Key? key}) : super(key: key);
  @override
  _ColorSliderState createState() => _ColorSliderState();
}

class _ColorSliderState extends State<ColorSlider> {
  final Color borderColor = Color(0xffd3d3d3);
  final Color foregroundColor = Color(0xff595959);

  final _check = Icon(Icons.check);

  late Color worksheetColor;
  late int indexOfCurrentColor;
  @override
  void initState() {
    super.initState();
    this.worksheetColor = widget.worksheetColor;
    indexOfCurrentColor = constants.WORKSHEET_COLORS.indexOf(worksheetColor);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(constants.WORKSHEET_COLORS.length, (index) {
          return GestureDetector(
              onTap: () => _colorChangeTapped(index),
              child: Padding(
                  padding: EdgeInsets.only(left: 6, right: 6),
                  child: Container(
                      child: new CircleAvatar(
                        child: _checkOrNot(index),
                        foregroundColor: foregroundColor,
                        backgroundColor: constants.WORKSHEET_COLORS[index],
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
      worksheetColor = constants.WORKSHEET_COLORS[indexOfColor];
      indexOfCurrentColor = indexOfColor;
      widget.callBackColorTapped(constants.WORKSHEET_COLORS[indexOfColor]);
    });
  }

  Widget? _checkOrNot(int index) {
    if (indexOfCurrentColor == index) {
      return _check;
    }
    return null;
  }
}
