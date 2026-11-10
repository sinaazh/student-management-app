import 'package:get/get.dart';
import 'package:school_managment_app/controllers/data_table_controller.dart';
import 'package:school_managment_app/controllers/debtor_list_controller.dart';

/// Controller (GetX) for the sidebar navigation.
///
/// Responsibilities:
/// - Tracks which page is shown in the main area ([selectedPage]).
/// - Tracks which sidebar item is highlighted ([highlightedPage]).
/// - Tracks which collapsible menu sections are open ([expandedMenus]).
/// - Opens the "StudentDashboard" section automatically while a student is
///   selected in the students table.
/// - Removes the debtor list controller from memory when the user leaves that page.
class SidebarController extends GetxController {
  // --- Dependency Injection ---
  // `Get.find()` only works if this object was registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Controller of the students table. Used here only to watch which student
  /// is selected ([DataTableController.selectedUser]).
  final DataTableController dataTableController = Get.find();

  // --- Reactive State ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it.

  /// Route name of the page shown in the main content area. Starts at '/home'.
  var selectedPage = '/home'.obs;

  /// Route name of the sidebar item that is highlighted. Starts at '/home'.
  ///
  /// It can differ from [selectedPage]: for example a parent menu item can stay
  /// highlighted while one of its sub-pages is displayed (see [selectItem]).
  var highlightedPage = '/home'.obs;

  /// Whether each collapsible menu section is open (`true`) or closed (`false`).
  /// The keys are the section names (e.g. "StudentDashboard"). A section that
  /// has no entry yet counts as closed.
  var expandedMenus = <String, bool>{}.obs;

  /// Called by GetX right after the controller is created.
  /// Starts watching the selected student.
  @override
  void onInit(){
    super.onInit();

    // `ever` runs the callback every time `selectedUser` changes (it does not
    // run for the value that is already set when this line executes).
    // A selected student opens the "StudentDashboard" section, no selection
    // closes it. This listener lives as long as the controller does.
    ever(dataTableController.selectedUser, (status) => status != null ? expandedMenus["StudentDashboard"] = true : expandedMenus["StudentDashboard"] = false );
  }

  /// Opens the menu section with the given [key] if it is closed, and closes
  /// it if it is open (e.g. "StudentDashboard").
  void toggleMenu(String key) {
    expandedMenus[key] = !(expandedMenus[key] ?? false);
  }

  /// Opens the page with the given [routeName] (e.g. '/debtorList') and
  /// highlights its sidebar item.
  ///
  /// It also frees memory: when the new page is not '/debtorList', the
  /// [DebtorListController] is deleted if it exists. The next time the user
  /// opens the debtor list, a fresh controller is created and loads its data again.
  void selectPage(String routeName) {
    selectedPage.value = routeName; // changes the displayed page
    highlightedPage.value = routeName; // highlights the matching sidebar item
    
    // Page-specific controllers are removed when the user leaves their page.
    if (routeName != "/debtorList") {
      if (Get.isRegistered<DebtorListController>()) {
        Get.delete<DebtorListController>();
      }
    }
  }

  /// Highlights the sidebar item with the given [routeName] without changing
  /// the displayed page.
  ///
  /// Useful for highlighting a parent menu when one of its sub-routes
  /// (e.g. '/students/add') is selected.
  void selectItem(String routeName) {
    highlightedPage.value = routeName; // only changes the highlight
  }
}