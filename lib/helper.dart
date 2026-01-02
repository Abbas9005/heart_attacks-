import 'package:shared_preferences/shared_preferences.dart';
class PreferencesHelper {
  static const String nameKey = 'name';
  static const String ageKey = 'age';
  static const String genderKey = 'gender';
  static const String familyHistoryKey = 'familyHistory';
  static Future<void> saveProfileData({
    required String name,
    required int age,
    required String gender,
    required bool familyHistory,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(nameKey, name);
    await prefs.setInt(ageKey, age);
    await prefs.setString(genderKey, gender);
    await prefs.setBool(familyHistoryKey, familyHistory);
  }
  static Future<Map<String, dynamic>> getProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(nameKey) ?? '';
    final age = prefs.getInt(ageKey) ?? 25;
    final gender = prefs.getString(genderKey) ?? 'Male';
    final familyHistory = prefs.getBool(familyHistoryKey) ?? false;
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'familyHistory': familyHistory,
    };
  }
}
