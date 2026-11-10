import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/school_repository.dart';
import 'package:school_managment_app/services/shared_data_service.dart';

/// Controller (GetX) that holds the state of the student search and filter fields.
///
/// It only stores values (the typed names and the selected major, year and
/// grade) and the options for the dropdowns. It does **not** load any data.
/// `DataTableController` observes these values and reloads the students table
/// when they change (names are debounced, dropdowns react immediately).
///
/// The view is responsible for updating [searchFirstName] and [searchLastName]
/// when the user types, because the `TextEditingController`s and these reactive
/// values are two separate things.
class SearchFieldsController extends GetxController {
  // --- Dependency Injection ---
  // `Get.find()` only works if these objects were registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Database controller. Only used to create [repository], which is itself unused.
  final SchoolManagmentDataBaseController dbController = Get.find();

  /// App-wide shared data (the lists of school years and majors).
  final SharedDataService dataService = Get.find();

  /// Created in [onInit] but not used anywhere in this controller
  /// (it does not fetch any data).
  late final SchoolRepository repository;

  // --- Text Editing Controllers for Search Inputs ---

  /// Controller of the first name search field (the text shown in the field).
  TextEditingController firstNameController = TextEditingController();

  /// Controller of the last name search field (the text shown in the field).
  TextEditingController lastNameController = TextEditingController();

  // --- Reactive State for Search/Filter Values ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it and
  // notifies listeners such as `DataTableController`.

  /// First name to search for, or `null` for "no filter".
  /// Observed by `DataTableController`.
  var searchFirstName = RxnString();

  /// Last name to search for, or `null` for "no filter".
  /// Observed by `DataTableController`.
  var searchLastName = RxnString();

  /// Selected grade level filter, or `null` for "all grades".
  /// (`RxnInt` is a nullable reactive int.)
  var selectedGradeLevel = RxnInt();

  /// Selected school year filter, or `null` for "all years".
  Rx<SchoolYear?> selectedYear = Rx<SchoolYear?>(null);

  /// Selected major filter, or `null` for "all majors".
  Rx<Major?> selectedMajor = Rx<Major?>(null);

  // --- Reactive State for Dropdown Options ---

  /// Items shown in the "school year" filter dropdown.
  RxList<SchoolYear> yearDropDownItems = <SchoolYear>[].obs;

  /// Items shown in the "major" filter dropdown.
  RxList<Major> majorDropDownItems = <Major>[].obs;

  // --- Focus Management ---

  /// Focus node attached to a dropdown/input in the view.
  /// Used by [checkWindowSize] to know whether a dropdown is currently open.
  final FocusNode myFocusNode = FocusNode();

  /// Unused placeholder: it always returns `null`.
  /// Remove it, or implement it, if the view does not use it.
  get isMajorDataLoaded => null;

  /// Called by GetX right after the controller is created.
  /// Fills the dropdowns and keeps them in sync with the shared data.
  @override
  void onInit() {
    super.onInit();

    // See the note on [repository]: it is created but never used.
    repository = SchoolRepository(dbController);

    // The listener is empty for now, so this currently does nothing.
    // Either add the logic that should run on focus changes or remove it.
    myFocusNode.addListener(() {});

    // Copy the shared lists into this controller's own reactive lists.
    // `assignAll` replaces the content and triggers a single UI update.
    majorDropDownItems.assignAll(dataService.majorItems);
    yearDropDownItems.assignAll(dataService.yearItems);

    // Keep the dropdowns up to date if the shared lists change later.
    // For majors, the selected filter is also cleared, since the selected
    // major may no longer exist in the new list.
    ever(dataService.majorItems, (majors) {
      majorDropDownItems.assignAll(majors);
      selectedMajor.value = null;
    });

    ever(dataService.yearItems, (years) {
      yearDropDownItems.assignAll(years);
    });

    // Start with all filters cleared.
    resetFilters();
  }

  /// Called by GetX just before the controller is removed from memory.
  @override
  void onClose() {
    // Dispose of the FocusNode to prevent memory leaks.
    myFocusNode.dispose();
    super.onClose();
  }

  /// Clears the text fields and sets every filter value back to `null`.
  ///
  /// Listeners such as `DataTableController` reload the table, but only for
  /// values that actually changed (setting `null` on a value that is already
  /// `null` triggers nothing).
  void resetFilters() {
    firstNameController.clear();
    lastNameController.clear();
    searchFirstName.value = null;
    searchLastName.value = null;
    selectedYear.value = null;
    selectedGradeLevel.value = null;
    selectedMajor.value = null;
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