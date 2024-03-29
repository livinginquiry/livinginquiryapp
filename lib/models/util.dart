import 'package:basic_utils/basic_utils.dart' as basic_utils;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/constants.dart' as constants;
import '../constants/theme.dart';

final fontColor = Color(0xff595959);
final borderColor = Color(0xffd3d3d3);

final _todayFormat = DateFormat("h:mm a");
final _monthFormat = DateFormat("MMM d");
final _yearFormat = DateFormat("MMM d y");
String formatDateTime(DateTime dt) {
  switch (getDateBucket(dt).bucket) {
    case WorksheetBucket.Today:
    case WorksheetBucket.Yesterday:
      return _todayFormat.format(dt);
    case WorksheetBucket.DayOfWeek:
    case WorksheetBucket.LastWeek:
    case WorksheetBucket.Month:
      return _monthFormat.format(dt);
    case WorksheetBucket.Year:
      return _yearFormat.format(dt);
  }
}

int epochFromDate(DateTime dt) {
  return dt.millisecondsSinceEpoch ~/ 1000;
}

T? enumFromString<T>(Iterable<T> values, String? value, {snakeCase = false}) {
  return value == null ? null : values.firstWhereOrNull((type) => enumToString(type, snakeCase: snakeCase) == value);
}

String enumToString<T>(T enm, {snakeCase = false}) {
  final enumName = enm.toString().split('.').last;
  return snakeCase ? basic_utils.StringUtils.camelCaseToLowerUnderscore(enumName) : enumName;
}

List<String> enumToStringValues<T>(Iterable<T> values, {snakeCase = false}) {
  return values.map((T val) => enumToString(val, snakeCase: snakeCase)).toList();
}

String toHexString(Color color) {
  return "#${color.red.toRadixString(16).padLeft(2, "0")}"
      "${color.green.toRadixString(16).padLeft(2, "0")}"
      "${color.blue.toRadixString(16).padLeft(2, "0")}";
}

Color getInitialWorksheetColor([int colorIndex = 0]) {
  return constants.WORKSHEET_COLORS[colorIndex];
}

String extractAnswerFirstLine(String answerText) {
  return answerText.replaceAll("\u2022", "").split("\n").map((String l) => l.trim()).first;
}

String truncateWithEllipsis(String text, int maxLen) {
  if (text.length > maxLen) {
    return text.substring(0, maxLen - 3) + "...";
  } else {
    return text;
  }
}

enum WorksheetBucket { Today, Yesterday, DayOfWeek, LastWeek, Month, Year }

class WorksheetBucketHolder implements Comparable<WorksheetBucketHolder> {
  WorksheetBucketHolder(this.bucket, this.name);
  final WorksheetBucket bucket;
  final String name;

  @override
  int compareTo(WorksheetBucketHolder other) {
    return bucket.index.compareTo(other.bucket.index);
  }

  bool operator ==(o) => o is WorksheetBucketHolder && o.name == name && o.bucket == bucket;

  @override
  int get hashCode => Object.hash(bucket, name);
}

final DayOfWeekFormat = (date) => DateFormat('EEEE').format(date);
final MonthFormat = (date) => DateFormat('MMMM').format(date);
final toBucketHolder = (bucket, date) => WorksheetBucketHolder(bucket, worksheetBucketToString(bucket, date));

WorksheetBucketHolder getDateBucket(DateTime time) {
  final now = DateUtils.dateOnly(DateTime.now());
  final then = DateUtils.dateOnly(time);
  final diff = now.difference(then);
  if (DateUtils.isSameDay(now, then)) {
    return toBucketHolder(WorksheetBucket.Today, then);
  } else if (diff.inDays == 1) {
    return toBucketHolder(WorksheetBucket.Yesterday, then);
  } else if (diff.inDays < 7 && then.weekday < now.weekday) {
    return toBucketHolder(WorksheetBucket.DayOfWeek, then);
  } else if (now.subtract(Duration(days: now.weekday + 7)).compareTo(then) <= 0) {
    return toBucketHolder(WorksheetBucket.LastWeek, then);
  } else if (diff.inDays < 365) {
    return toBucketHolder(WorksheetBucket.Month, then);
  } else {
    return toBucketHolder(WorksheetBucket.Year, then);
  }
}

// TODO: externalize strings
String worksheetBucketToString(WorksheetBucket bucket, DateTime dt) {
  switch (bucket) {
    case WorksheetBucket.Today:
      return "Today";
    case WorksheetBucket.Yesterday:
      return "Yesterday";
    case WorksheetBucket.DayOfWeek:
      return DayOfWeekFormat(dt);
    case WorksheetBucket.LastWeek:
      return "Last Week";
    case WorksheetBucket.Month:
      return MonthFormat(dt);
    case WorksheetBucket.Year:
      return dt.year.toString();
  }
}

Future<bool> confirmationDialog(BuildContext context, String title, String message) async {
  final res = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Confirm'),
            onPressed: () {
              print('Confirmed');
              Navigator.pop(context, true);
            },
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              print("cancelled");
              Navigator.pop(context, false);
            },
          ),
        ],
      );
    },
  );
  return res ?? false;
}

Future<void> errorDialog(BuildContext context, String title, String message) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [SizedBox(height: 40, width: 40, child: Icon(Icons.error, color: Colors.red)), Text(title)]),
        content: Row(mainAxisAlignment: MainAxisAlignment.start, children: [Text(message, softWrap: true)]),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

// https://stackoverflow.com/a/67989242
extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}

final navBarColor = lightTheme.colorScheme.secondary.darken(.2);
final navBarStyle = lightTheme.textTheme.titleMedium!.copyWith(color: navBarColor);
