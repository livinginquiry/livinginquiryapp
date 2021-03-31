import "dart:math";

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'constants.dart' as constants;

final fontColor = Color(0xff595959);
final borderColor = Color(0xffd3d3d3);

final _random = Random();
String formatDateTime(DateTime dt) {
  var dtInLocal = dt.toLocal();
  var now = DateTime.now().toLocal();
  var dateString = "";

  var diff = now.difference(dtInLocal);

  if (now.day == dtInLocal.day) {
    // creates format like: 12:35 PM,
    final todayFormat = DateFormat("h:mm a");
    dateString += todayFormat.format(dtInLocal);
  } else if ((diff.inDays) == 1 || (diff.inSeconds < 86400 && now.day != dtInLocal.day)) {
    final yesterdayFormat = DateFormat("h:mm a");
    dateString += "Yesterday, " + yesterdayFormat.format(dtInLocal);
  } else if (now.year == dtInLocal.year && diff.inDays > 1) {
    final monthFormat = DateFormat("MMM d");
    dateString += monthFormat.format(dtInLocal);
  } else {
    final yearFormat = DateFormat("MMM d y");
    dateString += yearFormat.format(dtInLocal);
  }

  return dateString;
}

int epochFromDate(DateTime dt) {
  return dt.millisecondsSinceEpoch ~/ 1000;
}

T enumFromString<T>(Iterable<T> values, String value, {snakeCase = false}) {
  return values.firstWhere((type) => enumToString(type, snakeCase: snakeCase) == value, orElse: () => null);
}

String enumToString<T>(T enm, {snakeCase = false}) {
  final enumName = enm.toString().split('.').last;
  return snakeCase ? StringUtils.camelCaseToLowerUnderscore(enumName) : enumName;
}

List<String> enumToStringValues<T>(Iterable<T> values, {snakeCase = false}) {
  return values.map((T val) => enumToString(val, snakeCase: snakeCase)).toList();
}

String toHexString(Color color) {
  return "#${color.red.toRadixString(16).padLeft(2, "0")}"
      "${color.green.toRadixString(16).padLeft(2, "0")}"
      "${color.blue.toRadixString(16).padLeft(2, "0")}";
}

Color getInitialNoteColor() {
  return constants.NOTE_COLORS[0];
}

String truncateWithEllipsis(String text, int maxLen) {
  if (text.length > maxLen) {
    return text.substring(0, maxLen - 3) + "...";
  } else {
    return text;
  }
}
