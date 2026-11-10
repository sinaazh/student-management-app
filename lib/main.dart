import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/data_table_controller.dart';
import 'package:school_managment_app/controllers/language_controller.dart';
import 'package:school_managment_app/controllers/search_fields_controller.dart';
import 'package:school_managment_app/controllers/side_bar_controller.dart';
import 'package:school_managment_app/controllers/theme_controller.dart';
import 'package:school_managment_app/routes/app_pages.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/settings_manager.dart';
import 'package:school_managment_app/services/shared_data_service.dart';
import 'package:school_managment_app/utils/app_translation.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/controllers/pie_chart_controller.dart';

/// Initializes application services and dependencies before launching the app.
///
/// The order of the steps matters, because each object finds the ones before
/// it with `Get.find()`:
/// 1. [SettingsManager]: the theme and language controllers read from it.
/// 2. Theme and language controllers: they start loading the saved values in
///    the background.
/// 3. Database, then [SharedDataService] (needs the database).
/// 4. Search fields, data table, pie chart, sidebar (the data table needs the
///    search fields and the shared data, the sidebar needs the data table).
/// 5. Translations, then `runApp`.
///
/// The other controllers (add/edit student, debtors, tuition, extra costs,
/// settings, payments) are not created here, but later by the pages that use them.
void main() async {
  // Ensure Flutter bindings are initialized before performing asynchronous setup.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and register the settings manager.
  // This loads the application's saved preferences.
  SettingsManager settings = SettingsManager();
  await settings.init();
  Get.put(settings);

  // Register the controllers responsible for theme and language management.
  // Their `onInit` starts reading the saved theme and language, but it is not
  // awaited here, so the values may not be ready yet (see [MyApp]).
  Get.put(ThemeController());
  Get.put(LanguageController());

  // Initialize the database controller before registering it.
  // Awaiting initialization ensures the database is ready before the app starts.
  await Get.putAsync<SchoolManagmentDataBaseController>(
    () async => await SchoolManagmentDataBaseController().init(),
  );

  // Initialize and register the service responsible for shared application data.
  await Get.putAsync<SharedDataService>(
    () async => await SharedDataService().init(),
  );

  // Register the controllers used by the search fields, data tables,
  // pie chart, and sidebar.
  // These are created once and stay in memory, so each one loads its data once
  // here, at startup.
  Get.put(SearchFieldsController());
  Get.put(DataTableController());
  Get.put(PieChartController());
  Get.put(SidebarController());

  // Load the application's supported language translations.
  final AppTranslation translations = AppTranslation();
  await translations.loadTranslations(['en_US', 'fa_IR']); // load JSONs

  // Register the translation manager with GetX.
  Get.put(translations);

  // Launch the application after all required initialization is complete.
  runApp(MyApp(translations: translations));
}

/// Root widget of the application.
///
/// Configures GetX navigation, localization, themes, and application routes.
class MyApp extends StatelessWidget {
  // Receives the initialized translation manager from main().
  final AppTranslation translations;

  const MyApp({super.key, required this.translations});

  @override
  Widget build(BuildContext context) {
    // Retrieve the globally registered theme and language controllers.
    final ThemeController themeController = Get.find();
    final LanguageController langController = Get.find();

    // Rebuild the application configuration when the selected language
    // or theme changes.
    return Obx(() {
      // Retrieve the currently selected language from the language controller.
      final selectedAppLanguage = langController.selectedLanguage.value;

      return GetMaterialApp(
        // Hide the debug banner in the application interface.
        debugShowCheckedModeBanner: false,

        // Configure the translation manager used by GetX localization.
        translations: translations,

        // Set the application's active locale using the selected language.
        // NOTE: `selectedLanguage` is `null` until LanguageController has
        // finished reading the saved language, so the `!` throws if that has
        // not happened by the time the app is built.
        locale: Locale(selectedAppLanguage!.languageCode, selectedAppLanguage.countryCode), // default locale

        // Use English (United States) if the selected locale is unavailable.
        fallbackLocale: const Locale('en', 'US'),

        // Register the application's light and dark theme configurations.
        theme: lightMode,
        darkTheme: darkMode,

        // Select the active theme based on the theme controller's state.
        // (`isDark` starts as `true` until the saved theme has been read.)
        themeMode: themeController.isDark.value ? ThemeMode.dark : ThemeMode.light,

        // Set the initial route displayed when the application starts.
        initialRoute: AppPages.initial,

        // Register the application's available routes.
        getPages: AppPages.routes,
      );
    });
  }
}