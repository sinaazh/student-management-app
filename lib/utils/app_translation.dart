import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// 🌍 AppTranslation: Handles dynamic loading and management of translation files.
///
/// This class extends GetX's ['Translations'] abstract class, allowing it to provide
/// language key-value maps to the GetX localization system. It loads translation
/// data from JSON files stored in the application's assets folder.
class AppTranslation extends Translations {

  // A private map to store the loaded translations.
  // The structure is: {'locale_code': {'key': 'translated_value'}}
  final Map<String, Map<String, String>> _translations = {};

  /// Loads all required translation files from the application assets.
  ///
  /// This method iterates through a list of locale names (e.g., ['en', 'ar'])
  /// and asynchronously loads the corresponding JSON files from `assets/lang/`.
  /// The loaded data is then stored in the internal ['translations'] map.
  ///
  /// @param locales A list of locale codes (strings) corresponding to the
  ///                filenames (e.g., 'en' for 'assets/lang/en.json').
  Future<void> loadTranslations(List<String> locales) async {
    for (var locale in locales) {
      // 1. Load the raw JSON string from assets.
      final String jsonString = await rootBundle.loadString('assets/lang/$locale.json');
      
      // 2. Decode the JSON string into a Map<String, dynamic>.
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      // 3. Convert the map values to strings and store them keyed by locale.
      _translations[locale] = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    }
  }

  /// Overrides the getter required by the ['Translations'] class.
  ///
  /// This getter provides the dynamically loaded translation maps to GetX,
  /// enabling methods like `'key'.tr` to function across all defined locales.
  @override
  Map<String, Map<String, String>> get keys => _translations;
}
