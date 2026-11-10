/// A language the app can be switched to, as shown in the language dropdown.
///
/// The supported languages are listed in `LanguageController.languageDropDownItems`.
/// Together, [languageCode] and [countryCode] form the `Locale` used by the app
/// (for example `Locale('fa', 'IR')`).
class Language {
  /// The translation key of the language's display name (e.g., "language_english").
  /// It is not the display text itself: the view must show it with `.tr`, which
  /// gives the name in the current app language (e.g., "English", "Persian").
  /// This is used for display in a language selection dropdown.
  final String languageName;

  /// The two-letter ISO 639-1 code for the language (e.g., "en" for English, "fa" for Farsi/Persian).
  /// This is the primary identifier used for loading translation files.
  /// It is also the value saved in the app settings.
  final String languageCode;

  /// The two-letter ISO 3166-1 alpha-2 code for the country or region (e.g., "US" for United States, "IR" for Iran).
  /// This is used in combination with the languageCode to define a specific locale,
  /// often affecting date/number formats and currency symbols.
  final String countryCode;

  /// Primary constructor for creating an immutable Language object.
  /// All three values are required.
  Language({
    required this.languageName, 
    required this.languageCode,
    required this.countryCode,
  });
}