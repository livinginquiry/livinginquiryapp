import '../models/worksheet.dart';

enum StringKey { emptyWorksheets }

class Strings {
  Strings._();

  static const _base = {StringKey.emptyWorksheets: 'No Worksheets Found'};
  static const _overrides = {
    FilterOverrideKey.Starred: {StringKey.emptyWorksheets: 'Mark any worksheet as Starred to see it here'}
  };

  static String getString(StringKey key, [FilterOverrideKey? overrideKey]) {
    return (overrideKey ?? FilterOverrideKey.None) != FilterOverrideKey.None
        ? (Strings._overrides[overrideKey!]?[key] ?? Strings._base[key]!)
        : Strings._base[key]!;
  }
}
