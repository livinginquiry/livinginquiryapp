import 'package:flutter/material.dart';

class SearchTransitionPainter extends CustomPainter {
  final Offset center;
  final double radius, containerHeight;
  final BuildContext context;

  late Color color;
  late double statusBarHeight, screenWidth;

  SearchTransitionPainter(this.context, this.containerHeight, this.center, this.radius) {
    // color = Colors.white;
    color = Colors.grey.shade100;
    statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    screenWidth = MediaQuery.of(context).size.width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint circlePainter = Paint();

    circlePainter.color = color;
    // canvas.clipRect(Rect.fromLTWH(0, 0, screenWidth, containerHeight + statusBarHeight));
    canvas.clipRect(
        Rect.fromLTWH(0, statusBarHeight, screenWidth, containerHeight - 12)); // subtract 12 to expose bottom of appbar
    canvas.drawCircle(center, radius, circlePainter);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
