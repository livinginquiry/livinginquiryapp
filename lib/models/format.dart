import 'dart:developer';
import 'dart:math' show max, min;

import 'package:flutter/services.dart';
import 'package:validators/validators.dart';
import 'package:tuple/tuple.dart';

final bullet = '\u2022';
final bulletSpace = '$bullet ';

abstract class BulletFormatter extends TextInputFormatter {
  Tuple2<String?, String> getLastLines(TextEditingValue newValue) {
    var prefix = newValue.text.substring(0, newValue.selection.extentOffset);

    var index = prefix.lastIndexOf('\n');
    index = index < 0 ? 0 : index + 1;
    var endOfLineIndex = newValue.text.indexOf('\n', index);
    endOfLineIndex = endOfLineIndex < 0 ? newValue.text.length : endOfLineIndex;
    prefix = newValue.text.substring(0, endOfLineIndex);

    if (prefix.isEmpty) {
      return Tuple2(null, prefix);
    }
    final lines = prefix.split("\n");
    if (lines.length == 1) {
      return Tuple2(null, lines.first);
    } else {
      return Tuple2(lines[lines.length - 2], lines[lines.length - 1]);
    }
  }

  int getLeftmostIndex(TextSelection selection) {
    if (selection.isCollapsed) {
      return selection.baseOffset;
    } else {
      // ios doesn't seem to work this way (?)
      // return selection.affinity == TextAffinity.upstream ? selection.extentOffset : selection.baseOffset;
      return min(selection.extentOffset, selection.baseOffset);
    }
  }

  int getRightmostIndex(TextSelection selection) {
    if (selection.isCollapsed) {
      return selection.baseOffset;
    } else {
      // ios doesn't seem to work this way (?)
      // return selection.affinity == TextAffinity.upstream ? selection.baseOffset : selection.extentOffset;
      return max(selection.extentOffset, selection.baseOffset);
    }
  }

  bool crPressed(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.selection.isCollapsed || newValue.text.isEmpty) {
      // if selection isn't collapsed they couldn't have entered CR since it would have deleted the selected text
      return false;
    } else if (getLeftmostIndex(oldValue.selection) == newValue.selection.baseOffset - 1 &&
        newValue.text[newValue.selection.baseOffset - 1] == '\n') {
      return true;
    } else if (oldValue.text.isNotEmpty &&
        getLeftmostIndex(oldValue.selection) == newValue.selection.baseOffset &&
        oldValue.text[max(0, getRightmostIndex(oldValue.selection) - 1)] == ' ' &&
        newValue.text[max(0, newValue.selection.baseOffset - 1)] == '\n') {
      // for some reason, on Android when a soft-keyboard auto-suggestion is selected it adds a trailing space
      // which magically disappears when CR is typed
      return true;
    } else {
      return false;
    }
  }

  /// returns a new TextEditingValue with text inserted at selection.baseOffset. Any active TextSelection
  /// is collapsed
  TextEditingValue insertBullet(TextEditingValue newValue, {int? index}) {
    final insertionPoint = index ?? newValue.selection.extentOffset;
    final prefix = newValue.text.substring(0, insertionPoint);
    var suffix = newValue.text.substring(insertionPoint, newValue.text.length);

    final newOffset = insertionPoint <= newValue.selection.extentOffset
        ? newValue.selection.extentOffset + bulletSpace.length
        : newValue.selection.extentOffset;
    return TextEditingValue(text: prefix + bulletSpace + suffix, selection: TextSelection.collapsed(offset: newOffset));
  }

  bool precededByBullet(TextEditingValue value) {
    var pos = min(value.text.length - 1, getLeftmostIndex(value.selection));
    while (pos > 0 && value.text[pos] != '\n') {
      if (value.text[pos--] == bullet) {
        return true;
      }
    }
    return false;
  }

  // get start of line starting from cursor (exclusive)
  int getStart(int cursor, String s) {
    if (cursor == 0 || s.isEmpty) {
      return 0;
    }
    var index = min(cursor - 1, s.length - 1);
    while (index >= 0 && s[index] != '\n') {
      index--;
    }
    return index + 1;
  }

  // get end of line starting from index (inclusive)
  int getEnd(int index, String s) {
    if (index == 0 || s.isEmpty) {
      return 0;
    }
    index = min(index, s.length - 1);
    while (index < s.length && s[index] != '\n') {
      ++index;
    }
    return index;
  }

  bool isCursorAtStart(TextEditingValue value) {
    int index = getLeftmostIndex(value.selection);
    if (index == 0) {
      return true;
    }
    int start = getStart(index, value.text);
    return index == start || value.text.substring(start, index) == bulletSpace;
  }

  bool isDelete(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.selection.isCollapsed) {
      return false;
    } else if (oldValue.selection.isCollapsed &&
        newValue.selection.isCollapsed &&
        oldValue.text.length - newValue.text.length > 0) {
      return true;
    } else if (!oldValue.selection.isCollapsed &&
        oldValue.text.length - (oldValue.selection.baseOffset - oldValue.selection.extentOffset).abs() ==
            newValue.text.length) {
      return true;
    }
    return false;
  }

  /// capitalize the first letter of the current line (if exists)
  TextEditingValue capitalizeFirstLetter(TextEditingValue newValue, {TextEditingValue? oldValue, int? cursor}) {
    if (!newValue.selection.isCollapsed ||
        (oldValue != null && (!isCursorAtStart(oldValue) || isDelete(oldValue, newValue)))) {
      return newValue;
    }
    final startPos = cursor ?? getLeftmostIndex(newValue.selection);
    var leftIndex = getStart(startPos, newValue.text);
    var rightIndex = getEnd(startPos, newValue.text);
    final prefix = newValue.text.substring(0, rightIndex);

    while (leftIndex < rightIndex && !isAlphanumeric(prefix[leftIndex])) {
      leftIndex++;
    }
    if (leftIndex < rightIndex && isAlphanumeric(prefix[leftIndex]) && isLowercase(prefix[leftIndex])) {
      final capitalized =
          "${newValue.text.substring(0, leftIndex)}${newValue.text[leftIndex].toUpperCase()}${newValue.text.substring(leftIndex + 1, newValue.text.length)}";
      return TextEditingValue(text: capitalized, selection: newValue.selection, composing: newValue.composing);
    } else {
      return newValue;
    }
  }

  /// returns a new TextEditingValue with text from [startIndex,endIndex) Any active TextSelection
  /// is collapsed
  TextEditingValue deleteText(int startIndex, int endIndex, TextEditingValue newValue) {
    final prefix = newValue.text.substring(0, startIndex);
    final suffix = newValue.text.substring(endIndex, newValue.text.length);
    return TextEditingValue(
      text: prefix + suffix,
      selection: TextSelection.collapsed(offset: newValue.selection.extentOffset - (endIndex - startIndex)),
    );
  }
}

class DefaultBulletFormatter extends BulletFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final lines = getLastLines(newValue);
    var updatedValue = newValue;
    final prevLineBulleted = lines.item1?.startsWith(bullet) ?? false;

    if (crPressed(oldValue, newValue)) {
      if ((lines.item1?.isNotEmpty ?? false) && !prevLineBulleted) {
        var startCurrLine = getStart(getLeftmostIndex(updatedValue.selection), updatedValue.text);
        var startPrevLine = getStart(startCurrLine - 2, updatedValue.text);
        // bullet prev line
        updatedValue = insertBullet(updatedValue, index: startPrevLine);
        // bullet this line
        updatedValue = insertBullet(updatedValue);
        updatedValue = capitalizeFirstLetter(updatedValue);
      } else if (prevLineBulleted && lines.item1!.substring(1).trim().isEmpty) {
        // delete previous empty bullet
        var startCurrLine = getStart(getLeftmostIndex(updatedValue.selection), updatedValue.text);
        var startPrevLine = getStart(startCurrLine - 2, updatedValue.text);
        updatedValue = deleteText(startPrevLine, startCurrLine - 1, newValue);
      } else if (prevLineBulleted) {
        // bullet this line
        updatedValue = capitalizeFirstLetter(updatedValue);
        updatedValue = insertBullet(updatedValue);
      }
    } else {
      updatedValue = capitalizeFirstLetter(updatedValue, oldValue: oldValue);
    }

    return updatedValue;
  }
}

enum TurnaroundState {
  PrevEmpty,
  PrevEmptyWithText,
  PrevBullet,
  PrevBulletEmptyText,
  PrevLineNoBullet,
  BulletNoText,
  BulletWithText
}

class IllegalTurnaroundState implements Exception {
  IllegalTurnaroundState();
}

class TurnaroundBulletFormatter extends BulletFormatter {
  TurnaroundState getState(TextEditingValue oldValue, TextEditingValue newValue) {
    final lines = getLastLines(newValue);
    if (lines.item2.startsWith(bullet)) {
      return lines.item2.length > 2 && isAlphanumeric(lines.item2[2])
          ? TurnaroundState.BulletWithText
          : TurnaroundState.BulletNoText;
    } else if ((lines.item1?.startsWith(bullet) ?? false)) {
      return lines.item1!.length > 2 && isAlphanumeric(lines.item1![2])
          ? TurnaroundState.PrevBullet
          : TurnaroundState.PrevBulletEmptyText;
    } else if (lines.item1?.isEmpty ?? true) {
      return lines.item2.isEmpty ? TurnaroundState.PrevEmpty : TurnaroundState.PrevEmptyWithText;
    } else if (lines.item1?.isNotEmpty ?? false) {
      return TurnaroundState.PrevLineNoBullet;
    } else {
      throw IllegalTurnaroundState();
    }
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final state = getState(oldValue, newValue);
    var updatedValue = newValue;
    switch (state) {
      case TurnaroundState.PrevBullet:
      case TurnaroundState.PrevLineNoBullet:
        if (crPressed(oldValue, updatedValue)) {
          updatedValue = insertBullet(updatedValue);
          updatedValue = capitalizeFirstLetter(updatedValue);
        }
        break;
      case TurnaroundState.PrevBulletEmptyText:
        if (crPressed(oldValue, updatedValue)) {
          // delete prev bullet
          var prefix = newValue.text.substring(0, newValue.selection.baseOffset);
          updatedValue = deleteText(prefix.lastIndexOf(bullet), prefix.lastIndexOf('\n'), newValue);
        }
        break;
      case TurnaroundState.PrevEmpty:
      case TurnaroundState.BulletNoText:
      case TurnaroundState.PrevEmptyWithText:
      case TurnaroundState.BulletWithText:
        updatedValue = capitalizeFirstLetter(newValue, oldValue: oldValue);
        break;
    }
    return updatedValue;
  }
}
