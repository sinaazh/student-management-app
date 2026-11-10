import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/search_fields_controller.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/models/student.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/school_repository.dart';
import 'package:school_managment_app/services/shared_data_service.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/my_snack_bar.dart';

/// Controller (GetX) for the main students data table.
///
/// Responsibilities:
/// - Loads one page of students from the database ([loadAllStudents]).
/// - Re-loads automatically when the search fields or dropdown filters change.
/// - Handles pagination (next / previous page).
/// - Keeps track of the selected row.
/// - Deletes a student after asking for confirmation ([deleteStudent]).
class DataTableController extends GetxController {
  // --- Dependency Injection ---
  // `Get.find()` only works if these objects were registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Holds the values of the search fields and filter dropdowns.
  /// This controller listens to it and reloads the table when it changes.
  final SearchFieldsController searchController = Get.find();

  /// Low-level database controller; passed to [repository] in [onInit].
  final SchoolManagmentDataBaseController dbController = Get.find();

  /// App-wide shared data (the lists of majors and school years).
  final SharedDataService dataService = Get.find();

  /// Handles the actual database operations (read, delete, etc.) for students.
  /// `late` because it needs [dbController], so it is created in [onInit].
  late final SchoolRepository repository;

  // --- Reactive State ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it.

  /// `true` while the table is reloading because a filter changed.
  /// The view can use it to show a loading indicator.
  /// (It is not set for the initial load or for page changes.)
  final RxBool isDataTableLoading = false.obs;

  /// The students of the **current page** only (at most [rowsPerPage] items),
  /// not every student in the database.
  RxList<Student> allStudents = <Student>[].obs;

  /// All available majors, used to turn a major ID into its name.
  /// Kept in sync with the shared data service (see [onInit]).
  RxList<Major> majorsList = <Major>[].obs;

  /// The student whose row is currently selected, or `null` if none is selected.
  Rx<Student?> selectedUser = Rx<Student?>(null);

  /// Total number of students matching the current filters, across all pages.
  RxInt allStudentsCount = 0.obs;

  /// How many students are shown per page.
  int rowsPerPage = 10;

  /// The page currently shown. Starts at 1 (not 0).
  RxInt currentPage = 1.obs;

  /// Total number of pages for the current filters
  /// (0 when there are no matching students).
  RxInt totalPages = 0.obs;

  /// Called by GetX right after the controller is created.
  /// Sets up the repository, loads the first page and starts the filter listeners.
  @override
  void onInit() {
    super.onInit();

    // The repository needs the database controller, so it is created here
    // instead of in the field initializer.
    repository = SchoolRepository(dbController);

    // Copy the shared majors into this controller's own list.
    majorsList.assignAll(dataService.majorItems);

    // Keep the list up to date if the shared majors change later.
    ever(dataService.majorItems, (majors) {
      majorsList.assignAll(majors);
    });

    // First load: page 1 without any filters.
    loadAllStudents();

    // Text filters: `debounce` waits until the user stops typing for 500 ms
    // before reloading, so we don't query the database on every key press.
    debounce(
      searchController.searchFirstName,
      (_) => _applyFilters(),
      time: const Duration(milliseconds: 500),
    );
    debounce(
      searchController.searchLastName,
      (_) => _applyFilters(),
      time: const Duration(milliseconds: 500),
    );

    // Dropdown filters: `everAll` reloads immediately when any one of them
    // changes (no debounce, since a selection is a single deliberate action).
    everAll([
      searchController.selectedMajor,
      searchController.selectedGradeLevel,
      searchController.selectedYear,
    ], (_) => _applyFilters());
  }

  /// Loads one page of students from the repository and updates the table state.
  ///
  /// The page is taken from [currentPage] and its size from [rowsPerPage]
  /// (translated into SQL-style `limit` / `offset`). All filter parameters are
  /// optional; a `null` filter means "don't filter by this".
  ///
  /// Updates [allStudents], [allStudentsCount] and [totalPages].
  ///
  /// [firstName] and [lastName] filter by name, [majorDropdown] by major,
  /// [gradeLevelDropDown] by grade level and [yearDropdown] by school year.
  ///
  /// Note: if you call it without arguments (as the add/delete code does),
  /// the result is **unfiltered**, even if the search fields still contain values.
  Future<void> loadAllStudents({
    String? firstName,
    String? lastName,
    Major? majorDropdown,
    int? gradeLevelDropDown,
    SchoolYear? yearDropdown,
  }) async {
    final results = await repository.getAllStudents(
      firstName: firstName,
      lastName: lastName,
      majorId: majorDropdown?.id, // The repository only needs the ID
      gradLevel: gradeLevelDropDown,
      yearId: yearDropdown?.id, // The repository only needs the ID
      limit: rowsPerPage,
      // Number of rows to skip: page 1 -> 0, page 2 -> 10, page 3 -> 20, ...
      offset: (currentPage.value - 1) * rowsPerPage,
    );

    // Replace the rows of the table with the new page.
    allStudents.assignAll(results.students);

    allStudentsCount.value = results.totalStudentsCount;

    // Round up so a partly filled last page still counts as a page.
    totalPages.value = (results.totalStudentsCount / rowsPerPage).ceil();
  }

  /// Reloads the table using the current search fields and dropdown filters.
  ///
  /// Always goes back to page 1, because the old page number may not exist
  /// anymore with the new filters. Shows the loading state while it works.
  Future<void> _applyFilters() async {
    isDataTableLoading.value = true;
    currentPage.value = 1;
    try {
      await loadAllStudents(
        firstName: searchController.searchFirstName.value,
        lastName: searchController.searchLastName.value,
        majorDropdown: searchController.selectedMajor.value,
        gradeLevelDropDown: searchController.selectedGradeLevel.value,
        yearDropdown: searchController.selectedYear.value,
      );
    } finally {
      // `finally` makes sure the loading state is reset even if loading throws.
      isDataTableLoading.value = false;
    }
  }

  /// Moves to the next page (keeping the current filters).
  /// Does nothing if the last page is already shown.
  Future<void> loadNextPageData() async {
    if (currentPage.value == totalPages.value) return;

    currentPage.value++;

    // Not awaited, so this method returns before the data has arrived.
    loadAllStudents(
      firstName: searchController.searchFirstName.value,
      lastName: searchController.searchLastName.value,
      majorDropdown: searchController.selectedMajor.value,
      gradeLevelDropDown: searchController.selectedGradeLevel.value,
      yearDropdown: searchController.selectedYear.value,
    );
  }

  /// Moves to the previous page (keeping the current filters).
  /// Does nothing if the first page is already shown.
  /// ("Prevoius" is a typo, kept so the name still matches the view.)
  Future<void> loadPrevoiusPageData() async {
    if (currentPage.value <= 1) return;

    currentPage.value--;

    // Not awaited, so this method returns before the data has arrived.
    loadAllStudents(
      firstName: searchController.searchFirstName.value,
      lastName: searchController.searchLastName.value,
      majorDropdown: searchController.selectedMajor.value,
      gradeLevelDropDown: searchController.selectedGradeLevel.value,
      yearDropdown: searchController.selectedYear.value,
    );
  }

  /// Returns the name of the major with the given [majorId].
  ///
  /// Throws a null-check error if no major has this ID, because of the `!`.
  String getMajorNameById(int majorId) {
    return majorsList.firstWhereOrNull((major) => major.id == majorId)!.name;
  }

  /// Selects or deselects a table row.
  ///
  /// Tapping the row that is already selected deselects it
  /// ([selectedUser] becomes `null`); tapping any other row selects that one.
  /// Rows are compared by `id`.
  void toggleSelection(Student user) {
    if (selectedUser.value?.id == user.id) {
      selectedUser.value = null;
    } else {
      selectedUser.value = user;
    }
  }

  /// Asks the user to confirm, then deletes [student].
  ///
  /// [context] is only used to read the current theme for the dialog color.
  ///
  /// - Confirmed and successful: shows a success toast and reloads the table.
  /// - Confirmed but failed (e.g. a database constraint): shows an error toast.
  /// - Cancelled or dismissed: nothing happens.
  void deleteStudent(BuildContext context, Student student) async {
    // `Get.dialog` returns the value passed to `Get.back(result: ...)`,
    // or `null` if the dialog was dismissed (e.g. by tapping outside it).
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.containerBackgroundColor,
        title: Text('confirm_deletion'.tr),
        // The translation contains {grade} and {major} placeholders.
        content: Text(
          'delete_student_confirmation'.trParams({
            'grade': student.grade.toString(),
            'major': getMajorNameById(student.majorId),
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // `== true` also covers the `null` (dismissed) case.
    if (confirm == true) {
      // The repository returns a map: `status` (bool) and, on failure,
      // `error` (String) with the reason.
      final deletedSuccessfully = await repository.deleteStudent(
        student: student,
      );
      if (deletedSuccessfully['status']) {
        RightSideToast.show(
          title: 'success'.tr,
          message: 'student_deleted_successfully'.tr,
          messageColor: Colors.green,
        );
        // Refresh the table so the deleted row disappears.
        loadAllStudents();
      } else {
        RightSideToast.show(
          title: 'error'.tr,
          message: deletedSuccessfully['error'],
          messageColor: Colors.red,
        );
      }
    }
  }
}