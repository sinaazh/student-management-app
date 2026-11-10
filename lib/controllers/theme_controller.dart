import 'package:get/get.dart';
import 'package:school_managment_app/services/settings_manager.dart';

/// Controller (GetX) for the app's theme mode (light or dark).
///
/// Responsibilities:
/// - Loads the saved theme when the app starts ([loadThemeMode]).
/// - Switches between light and dark and saves the choice ([toggleTheme]).
///
/// It only stores the current mode in [isDark]. The widget that builds the app
/// (or the theme switch) reads [isDark] to decide which theme to show.
class ThemeController extends GetxController {
  // --- Reactive State ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it.

  /// `true` for dark mode, `false` for light mode.
  ///
  /// It starts as `true`, so the app shows the dark theme until
  /// [loadThemeMode] has read the saved value (usually a split second).
  RxBool isDark = true.obs;

  // --- Dependency Injection ---
  // `Get.find()` only works if this object was registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Reads and writes the saved app settings (here: the theme).
  final SettingsManager appSettings = Get.find();

  /// Called by GetX right after the controller is created.
  /// Starts loading the saved theme.
  @override
  void onInit() async {
    super.onInit();
    // Load the saved theme. It is asynchronous, so [isDark] is updated a
    // moment after this method returns.
    loadThemeMode();
  }

  /// Reads the saved theme from the settings and updates [isDark].
  ///
  /// The saved value is the text "light" or "dark". Anything else (including
  /// a missing value) means dark mode.
  void loadThemeMode() async {
    String themeMode = await appSettings.readTheme();

    if (themeMode == "light"){
      isDark.value = false; // Light theme
    }
    else {
      isDark.value = true; // Dark theme (default or saved 'dark')
    }
  }

  /// Switches between light and dark mode and saves the new choice, so it is
  /// restored the next time the app starts.
  void toggleTheme() async {
    // 1. Switch immediately, so the UI updates without waiting for the save.
    isDark.value = !isDark.value;

    // 2. Save the new choice as text ("dark" or "light").
    if (isDark.value){
      await appSettings.saveTheme("dark");
    }
    else{
      await appSettings.saveTheme("light");
    }
  }
}