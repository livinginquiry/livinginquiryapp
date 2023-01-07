import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livinginquiryapp/models/constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final prefsUtilProvider = Provider<PrefsUtil>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  return PrefsUtil(sharedPreferences: sharedPrefs);
});

class PrefsUtil {
  PrefsUtil({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  int getLastWorksheetId() {
    return sharedPreferences.getInt(lastWorksheetIdKey) ?? -1;
  }

  void setLastWorksheetId(int id) {
    sharedPreferences.setInt(lastWorksheetIdKey, id);
  }

  void clearLastWorksheetId() {
    sharedPreferences.setInt(lastWorksheetIdKey, -1);
  }
}
