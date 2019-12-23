import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final fontColor = Color(0xff595959);
final borderColor = Color(0xffd3d3d3);

String formatDateTime(DateTime dt) {
  var dtInLocal = dt.toLocal();
  var now = DateTime.now().toLocal();
  var dateString = "Edited ";

  var diff = now.difference(dtInLocal);

  if (now.day == dtInLocal.day) {
    // creates format like: 12:35 PM,
    var todayFormat = DateFormat("h:mm a");
    dateString += todayFormat.format(dtInLocal);
  } else if ((diff.inDays) == 1 || (diff.inSeconds < 86400 && now.day != dtInLocal.day)) {
    var yesterdayFormat = DateFormat("h:mm a");
    dateString += "Yesterday, " + yesterdayFormat.format(dtInLocal);
  } else if (now.year == dtInLocal.year && diff.inDays > 1) {
    var monthFormat = DateFormat("MMM d");
    dateString += monthFormat.format(dtInLocal);
  } else {
    var yearFormat = DateFormat("MMM d y");
    dateString += yearFormat.format(dtInLocal);
  }

  return dateString;
}

int epochFromDate(DateTime dt) {
  return dt.millisecondsSinceEpoch ~/ 1000;
}

T getEnumFromString<T>(Iterable<T> values, String value) {
  return values.firstWhere((type) => enumToString(type) == value, orElse: () => null);
}

String enumToString<T>(T enm) {
  return enm.toString().split('.').last;
}

List<String> enumToStringValues<T>(Iterable<T> values) {
  return values.map((T val) => enumToString(val)).toList();
}
