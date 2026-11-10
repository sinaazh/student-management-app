import 'package:get/get.dart';
import 'package:school_managment_app/views/debtor_list.dart';
import 'package:school_managment_app/views/home_page.dart';
import 'package:school_managment_app/views/main_layout.dart';
import 'app_routes.dart';

/// Defines all application routes, mapping symbolic names (from AppRoutes) to widget pages.
///
/// GetX uses this list for named navigation (for example `Get.toNamed(...)`).
/// It is passed to `GetMaterialApp` as `getPages: AppPages.routes`, together
/// with `initialRoute: AppPages.initial`.
class AppPages {
  /// The initial route for the application when it first launches.
  static const initial = AppRoutes.main;

  /// The complete list of GetPage objects defining the entire app's navigation structure.
  ///
  /// None of the pages has a `binding`, so the controllers they need must be
  /// created elsewhere (for example in `main` or inside the views).
  static final routes = [
    // 1. Main Layout Route
    GetPage(
      // Route name: the value of AppRoutes.main
      name: AppRoutes.main,
      // Widget to build: The core structure containing the sidebar and content area.
      page: () => MainLayout(),
    ),

    // 2. Home Page Route
    GetPage(
      // Route name: the value of AppRoutes.home
      name: AppRoutes.home,
      // Widget to build: The main dashboard content.
      page: () => HomePage(),
    ),

    // 3. Debtor List Route
    GetPage(
      // Route name: the value of AppRoutes.debtorList
      name: AppRoutes.debtorList,
      // Widget to build: The screen displaying students with outstanding payments.
      page: () => DebtorList(),
    ),
  ];
}