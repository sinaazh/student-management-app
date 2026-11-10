import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:school_managment_app/models/language.dart';
import 'package:school_managment_app/services/settings_manager.dart';

/// Controller (GetX) for the app's language setting.
///
/// Responsibilities:
/// - Loads the saved language when the app starts and applies it ([loadLanguage]).
/// - Changes the language at runtime and saves the choice ([changeLanguage]).
/// - Provides the list of supported languages for the language dropdown.
///
/// Supported languages: English (`en_US`) and Persian (`fa_IR`).
class LanguageController extends GetxController {
  
  /// Focus node attached to the language dropdown in the view.
  /// Used by [checkWindowSize] to know whether the dropdown is currently open.
  final FocusNode myFocusNode = FocusNode();

  // --- Dependency Injection ---
  // `Get.find()` only works if this object was registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Reads and writes the saved app settings (here: the language code).
  final SettingsManager appSettings = Get.find();

  // --- Data and State ---

  /// The languages the user can choose from.
  ///
  /// `languageName` is a translation key (not display text), so the view should
  /// show it with `.tr`. To add a language, add an item here and add its
  /// translations and locale handling in [loadLanguage] and [changeLanguage].
  final languageDropDownItems = [
    Language(languageName: "language_english", languageCode: "en", countryCode: "US"),
    Language(languageName: "language_persian",  languageCode: "fa", countryCode: "IR"),
  ];

  /// The language currently selected in the dropdown.
  /// It is `null` until [loadLanguage] has finished reading the saved setting.
  Rx<Language?> selectedLanguage = Rx<Language?>(null);

  /// Called by GetX right after the controller is created.
  /// Starts loading the saved language and sets up the focus node.
  @override
  void onInit() {
    super.onInit();

    // Load the user's saved language. It is asynchronous, so the language is
    // applied a moment after this method returns.
    loadLanguage();

    // The listener is empty for now, so this currently does nothing.
    // Either add the logic that should run on focus changes or remove it.
    myFocusNode.addListener(() {});
  }

  /// Called by GetX just before the controller is removed from memory.
  @override
  void onClose() {
    // Dispose of the FocusNode to prevent memory leaks.
    myFocusNode.dispose();
    super.onClose();
  }
  
  /// Reads the saved language code from the settings, applies it to the app
  /// and selects it in the dropdown.
  ///
  /// Any unknown or missing code falls back to English.
  void loadLanguage() async {
    String appLanguage = await appSettings.readLanguage();

    // `Get.updateLocale` switches the app's language immediately and rebuilds
    // the widgets that use translations.
    switch(appLanguage){
      case "en":
        Get.updateLocale(const Locale('en', 'US'));
        selectedLanguage.value = findLanguage("en");
        break;
      case "fa":
        Get.updateLocale(const Locale('fa', 'IR'));
        selectedLanguage.value = findLanguage("fa");
        break;
      default:
        // Unrecognized saved value: fall back to English.
        Get.updateLocale(const Locale('en', 'US'));
        selectedLanguage.value = findLanguage("en");
    }
  }

  /// Returns the [Language] from [languageDropDownItems] whose code matches
  /// [languageCode] (e.g. "en" or "fa").
  ///
  /// Throws a [StateError] if no language has this code (`firstWhere` without
  /// `orElse`), so only call it with codes that exist in the list.
  Language findLanguage(String languageCode) {
    return languageDropDownItems.firstWhere(
      (language) => language.languageCode == languageCode,
    );
  }

  /// Switches the app to [language], saves the choice and applies the new locale.
  ///
  /// Called by the view when the user picks a language in the dropdown.
  void changeLanguage({required Language language}) async {
    // Update the dropdown selection first.
    selectedLanguage.value = language;

    // Save the code so [loadLanguage] can restore it on the next start.
    await appSettings.saveLanguage(language.languageCode);

    // Apply the new locale. Anything other than Persian falls back to English.
    if (language.languageCode == 'fa') {
      Get.updateLocale(const Locale('fa', 'IR'));
    } else {
      Get.updateLocale(const Locale('en', 'US'));
    }
  }

  /// Closes an open dropdown menu when the window is resized.
  ///
  /// An open dropdown is a route on the Navigator stack, so if [myFocusNode]
  /// has focus and the Navigator can pop, the top route is popped and the
  /// focus is released. Intended to be called from a layout/resize callback.
  ///
  /// [context] is the widget's [BuildContext], needed to reach the Navigator.
  void checkWindowSize(BuildContext context) {
    if (myFocusNode.hasFocus && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      myFocusNode.unfocus();
    }
  }
}