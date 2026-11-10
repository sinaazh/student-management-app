import 'dart:convert';
import 'dart:io';

/// Saves and loads the app's small user settings in a JSON file.
///
/// The settings are the theme ("light" or "dark"), the language code ("en" or
/// "fa") and the school name. They are stored in `SchoolManager/settings.json`,
/// inside the current working directory of the app (the same folder as the
/// database), for example:
/// `{"theme": "light", "language": "en", "school_name": ""}`.
///
/// [init] must be called (and awaited) once at startup, before any other method.
/// Every read opens and parses the file again, and every save rewrites the
/// whole file.
class SettingsManager {
  /// The full path of the settings file. It is a `late` field, so using any
  /// method before [init] has finished throws a `LateInitializationError`.
  late String settingsPath;

  /// Initializes the settings manager by ensuring the application directory and the settings file exist.
  ///
  /// If the directory or the file are missing, they are created with default values.
  /// (Defaults: theme "light", language "en", empty school name.)
  Future<void> init() async {
    // The folder the app was started from, which depends on how the app is launched.
    String appDir = Directory.current.path;
    final appFolder = Directory('$appDir/SchoolManager'); // Define the dedicated folder path.

    // ✅ Make sure the folder exists
    if (!await appFolder.exists()) {
      await appFolder.create(recursive: true);
    }

    settingsPath = '${appFolder.path}/settings.json';
    final File file = File(settingsPath);

    // Create file if missing, initializing it with default settings.
    if (!await file.exists()) {
      final defaultSettings = {
        "theme": "light",
        "language": "en",
        "school_name": "",
      };
      await file.writeAsString(jsonEncode(defaultSettings), flush: true);
    }
  }

  // -----------------------------
  // Internal File Handlers
  // -----------------------------

  /// Reads the content of the settings file, parses it from JSON, and returns the map.
  ///
  /// If the file does not exist (despite init()), returns a map with default values.
  /// If the file exists but is empty or not valid JSON, `jsonDecode` throws.
  Future<Map<String, dynamic>> _readSettings() async {
    final file = File(settingsPath);

    if (!await file.exists()) {
      return {"theme": "light", "language": "en", "school_name": ""}; // Fallback to defaults
    }

    final content = await file.readAsString();
    // Decode the JSON string into a Dart map.
    return jsonDecode(content);
  }

  /// Writes the provided [data] map back to the settings file in JSON format.
  ///
  /// [data] must contain all settings keys and values to be saved, because the
  /// whole file is replaced.
  Future<void> _writeSettings(Map<String, dynamic> data) async {
    final file = File(settingsPath);
    // Encode the Dart map to a JSON string and write it to the file.
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  // -----------------------------
  // THEME
  // -----------------------------

  /// Retrieves the saved theme mode from the settings file.
  /// Defaults to "light" if the key is missing.
  Future<String> readTheme() async {
    final settings = await _readSettings();
    return settings["theme"] ?? "light";
  }

  /// Saves the new theme mode to the settings file.
  /// It reads the existing settings, updates only the "theme" key, and writes the map back.
  ///
  /// [theme] is the theme string ("dark" or "light").
  Future<void> saveTheme(String theme) async {
    final settings = await _readSettings();
    settings["theme"] = theme;
    await _writeSettings(settings);
  }

  // -----------------------------
  // LANGUAGE
  // -----------------------------

  /// Retrieves the saved language code from the settings file.
  /// Defaults to "en" if the key is missing.
  Future<String> readLanguage() async {
    final settings = await _readSettings();
    return settings["language"] ?? "en";
  }

  /// Saves the new language code to the settings file.
  /// It reads the existing settings, updates only the "language" key, and writes the map back.
  ///
  /// [lang] is the language code (e.g., "en", "fa").
  Future<void> saveLanguage(String lang) async {
    final settings = await _readSettings();
    settings["language"] = lang;
    await _writeSettings(settings);
  }

  // -----------------------------
  // SCHOOL NAME
  // -----------------------------
  
  /// Retrieves the saved school name from the settings file.
  /// It is an empty string if no name has been saved yet.
  ///
  /// NOTE: unlike the other readers, there is no default (`?? ""`). If the file
  /// has no "school_name" key (for example a settings file from an older
  /// version), the value is `null` and the return type `String` makes this throw.
  Future<String> readSchoolName() async {
    final settings = await _readSettings();
    return settings["school_name"];
  }

  /// Saves the new school name to the settings file.
  /// It reads the existing settings, updates only the "school_name" key, and writes the map back.
  ///
  /// [schoolName] is the name to save (an empty string clears it).
  Future<void> saveSchoolName(String schoolName) async {
    final settings = await _readSettings();
    settings["school_name"] = schoolName;
    await _writeSettings(settings);
  }
}