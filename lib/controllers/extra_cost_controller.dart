import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/models/extra_cost.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/school_repository.dart';
import 'package:school_managment_app/services/shared_data_service.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/my_snack_bar.dart';

/// Controller (GetX) for the extra costs page.
///
/// An extra cost is an additional fee (amount + optional description) that
/// belongs to one combination of major, school year and grade level.
///
/// Responsibilities:
/// - Loads one page of extra costs, optionally filtered ([loadExtraCosts]).
/// - Holds the state of the form that is used for both adding and editing:
///   when no row is selected the form adds a new cost, when a row is selected
///   ([selectedExtraCost]) the form edits that cost.
/// - Creates, updates and deletes extra costs ([saveCost], [updateCost],
///   [deleteTuition]).
class ExtraCostController extends GetxController{
  // --- Dependency Injection ---
  // `Get.find()` only works if these objects were registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Low-level database controller; passed to [repository] in [onInit].
  final SchoolManagmentDataBaseController dbController = Get.find();

  /// App-wide shared data (the lists of school years and majors).
  final SharedDataService dataService = Get.find();

  /// Handles the actual database operations (CRUD) for extra costs.
  /// `late` because it needs [dbController], so it is created in [onInit].
  late final SchoolRepository repository;
  
  // --- Focus Management ---

  /// Focus node attached to a dropdown/input in the view.
  /// Disposed in [onClose].
  final FocusNode myFocusNode = FocusNode();

  // --- Text Editing Controllers for Form Fields ---

  /// Amount of the extra cost (required, must be a whole number).
  TextEditingController extraCostAmountController = TextEditingController();

  /// Optional description (saved as `null` when left empty).
  TextEditingController descriptionController = TextEditingController();

  // --- Reactive State for Data Table and Selection ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it.

  /// The extra costs of the **current page** only (at most [rowsPerPage] items).
  RxList<ExtraCost> allExtraCosts = <ExtraCost>[].obs;

  /// The extra cost whose row is currently selected, or `null` if none is.
  /// While it is not `null`, the form is in "edit" mode and [saveCost]
  /// refuses to add a new cost.
  Rx<ExtraCost?> selectedExtraCost = Rx<ExtraCost?>(null);

  // --- Reactive State for Form Dropdowns (Used for Add/Edit) ---

  /// Items shown in the "school year" dropdown of the form.
  RxList<SchoolYear> yearDropDownItems = <SchoolYear>[].obs;

  /// Items shown in the "major" dropdown of the form.
  RxList<Major> majorDropDownItems = <Major>[].obs;

  /// Year selected in the Add/Edit form, or `null` if none is selected.
  Rx<SchoolYear?> selectedYear = Rx<SchoolYear?>(null);

  /// Major selected in the Add/Edit form, or `null` if none is selected.
  Rx<Major?> selectedMajor = Rx<Major?>(null);

  /// Grade level selected in the Add/Edit form, or `null` if none is selected.
  /// (`RxnInt` is a nullable reactive int.)
  var selectedGradeLevel = RxnInt();

  // --- Reactive State for Filter Dropdowns ---
  // These are separate from the form fields above: they only control which
  // extra costs are listed. This controller does not listen to them, so the
  // view is responsible for calling [loadExtraCosts] when a filter changes.

  /// Major filter for the list, or `null` for "all majors".
  Rx<Major?> filterSelectedMajor = Rx<Major?>(null);

  /// School year filter for the list, or `null` for "all years".
  Rx<SchoolYear?> filterSelectedYear = Rx<SchoolYear?>(null);

  /// Grade level filter for the list, or `null` for "all grades".
  Rx<int?> filterSelectedGrade = Rx<int?>(null);

  // --- Pagination State ---

  /// Total number of extra costs matching the current filters, across all pages.
  RxInt allExtraCostsCount = 0.obs;

  /// How many extra costs are shown per page.
  int rowsPerPage = 10;

  /// The page currently shown. Starts at 1 (not 0).
  RxInt currentPage = 1.obs;

  /// Total number of pages for the current filters
  /// (0 when there are no matching extra costs).
  RxInt totalPages = 0.obs;

  /// Called by GetX right after the controller is created.
  /// Sets up the repository, loads the first page and fills the dropdowns.
  @override
  void onInit() {
    super.onInit();

    // The listener is empty for now, so this currently does nothing.
    // Either add the logic that should run on focus changes or remove it.
    myFocusNode.addListener(() {});

    // The repository needs the database controller, so it is created here
    // instead of in the field initializer.
    repository = SchoolRepository(dbController);

    // First load: page 1 without any filters.
    loadExtraCosts();

    // Copy the shared lists into this controller's own reactive lists.
    // `assignAll` replaces the content and triggers a single UI update.
    majorDropDownItems.assignAll(dataService.majorItems);
    yearDropDownItems.assignAll(dataService.yearItems);

    // Keep the dropdowns up to date if the shared lists change later
    // (e.g. a new year or major is added elsewhere in the app).
    ever(dataService.majorItems, (updatedMajors) {
      majorDropDownItems.assignAll(updatedMajors);
    });

    ever(dataService.yearItems, (updatedYears) {
      yearDropDownItems.assignAll(updatedYears);
    });
  }

  /// Called by GetX just before the controller is removed from memory.
  @override
  void onClose() {
    // Dispose of the FocusNode to prevent memory leaks.
    myFocusNode.dispose();
    super.onClose();
  }
  
  /// Loads one page of extra costs from the repository and updates the table state.
  ///
  /// The page is taken from [currentPage] and its size from [rowsPerPage]
  /// (translated into SQL-style `limit` / `offset`). All filters are optional;
  /// a `null` filter means "don't filter by this".
  ///
  /// Updates [allExtraCosts], [allExtraCostsCount] and [totalPages].
  ///
  /// [majorId], [yearId] and [grade] are the filter values (IDs, not objects).
  ///
  /// Note: if you call it without arguments, the result is **unfiltered**,
  /// even if the filter dropdowns still have a value selected.
  void loadExtraCosts({int? majorId, int? yearId, int? grade}) async {
    // These local variables only rename the parameters. They also have the same
    // names as the class fields [selectedMajor] / [selectedYear], so inside this
    // method those names refer to the local ints, not to the Rx fields.
    final selectedMajor = majorId;
    final selectedYear = yearId;
    final selectedGrade = grade;

    final extraCosts = await repository.getAllExtraCosts(
      majorId: selectedMajor,
      yearId: selectedYear,
      grade: selectedGrade,
      limit: rowsPerPage,
      // Number of rows to skip: page 1 -> 0, page 2 -> 10, page 3 -> 20, ...
      offset: (currentPage.value - 1) * rowsPerPage,
    );

    // Replace the rows of the table with the new page.
    allExtraCosts.assignAll(extraCosts.extraCosts);

    allExtraCostsCount.value = extraCosts.totalExtraCostsCount;

    // Round up so a partly filled last page still counts as a page.
    totalPages.value = (extraCosts.totalExtraCostsCount / rowsPerPage).ceil();
  }

  /// Moves to the next page.
  /// Does nothing if the last page is already shown.
  Future<void> loadNextPageData() async {
    if (currentPage.value == totalPages.value) return;

    currentPage.value++;

    // NOTE: these are the values of the Add/Edit *form* (selectedMajor,
    // selectedYear, selectedGradeLevel), not the list filters
    // (filterSelectedMajor, filterSelectedYear, filterSelectedGrade).
    loadExtraCosts(
      majorId: selectedMajor.value?.id ,
      yearId: selectedYear.value?.id,
      grade: selectedGradeLevel.value
    );
  }

  /// Moves to the previous page.
  /// Does nothing if the first page is already shown.
  /// ("Prevoius" is a typo, kept so the name still matches the view.)
  Future<void> loadPrevoiusPageData() async {
    if (currentPage.value <= 1) return;

    currentPage.value--;

    // NOTE: same as in [loadNextPageData]: this uses the form values,
    // not the list filters.
    loadExtraCosts(
      majorId: selectedMajor.value?.id ,
      yearId: selectedYear.value?.id,
      grade: selectedGradeLevel.value
    );
  }

  /// Fills the form with the data of [extraCost] (used when a row is selected).
  void setFields(ExtraCost extraCost) {
    extraCostAmountController.text = extraCost.price.toString();
    descriptionController.text = extraCost.description ?? "";

    // The dropdowns need the Major / SchoolYear objects, not just their IDs.
    // A value is `null` if its ID is not found in the list.
    selectedMajor.value = majorDropDownItems.firstWhereOrNull((major) => major.id == extraCost.majorId);
    selectedYear.value = yearDropDownItems.firstWhereOrNull((year) => year.id == extraCost.yearId);
    selectedGradeLevel.value = extraCost.grade;
  }

  /// Returns the form to its initial state: clears the text fields, resets the
  /// dropdowns and deselects the selected extra cost (back to "add" mode).
  void resetFields() {
    extraCostAmountController.clear();
    descriptionController.clear();
    selectedMajor.value = null;
    selectedYear.value = null;
    selectedGradeLevel.value = null;
    selectedExtraCost.value = null;
  }

  /// Clears all list filters, goes back to page 1 and reloads the unfiltered list.
  void resetFilterFields() async {
    currentPage.value = 1;
    filterSelectedMajor.value = null;
    filterSelectedYear.value = null;
    filterSelectedGrade.value = null;
    loadExtraCosts();
  }

  /// Returns the name of the major with the given [majorId].
  ///
  /// Throws a null-check error if no major has this ID, because of the `!`.
  String getMajorNameById(int majorId) {
    return majorDropDownItems.firstWhereOrNull((major) => major.id == majorId)!.name;
  }

  /// Returns the year of the school year with the given [yearId] as text
  /// (e.g. "2024").
  ///
  /// Throws a null-check error if no school year has this ID, because of the `!`.
  String getYearTextById(int yearId) {
    return yearDropDownItems.firstWhereOrNull((year) => year.id == yearId)!.year.toString();
  }

  /// Checks that all required fields of the form are filled in.
  ///
  /// Required: amount, major, school year and grade level.
  /// The description is optional.
  ///
  /// Returns a translated error message for the first problem found,
  /// or `null` if everything is valid.
  String? validateExtraCostFields() {
    if (extraCostAmountController.text.isEmpty) return 'cost_amount_required'.tr;
    if (selectedMajor.value == null) return 'major_must_be_selected'.tr;
    if (selectedYear.value == null) return 'year_must_be_selected'.tr;
    if (selectedGradeLevel.value == null) return 'grade_level_must_be_selected'.tr;

    // Everything is valid
    return null;
  }

  /// Validates the form and, if valid, saves a **new** extra cost.
  ///
  /// - A row is selected (edit mode): shows a warning toast and stops, so an
  ///   edit can't accidentally create a duplicate.
  /// - Validation fails: shows a warning toast and stops.
  /// - Insert succeeds: shows a success toast, reloads the list and clears the form.
  /// - Insert fails: shows an error toast with the database error message.
  void saveCost() async {
    // A selected row means the form currently holds an existing cost.
    if (selectedExtraCost.value != null) {
      RightSideToast.show(
        title: 'error'.tr,
        message: 'deselect_extra_cost_before_adding'.tr,
        messageColor: Color.fromARGB(255, 233, 181, 68), // amber = warning
        duration: const Duration(seconds: 5),
      );
      return;
    }
    final error = validateExtraCostFields();
    if (error != null) {
      RightSideToast.show(
        title: 'error'.tr,
        message: error,
        messageColor: const Color.fromARGB(255, 233, 181, 68),
        duration: Duration(seconds: 3),
      );
      return;
    }

    // The `!` operators are safe here because validation already confirmed
    // these selections are not null. `int.parse` throws if the amount is not
    // a valid whole number.
    final insertedSuccessfully = await repository.insertExtraCost(
      extraCost: ExtraCost(
        price: int.parse(extraCostAmountController.text),
        // Empty description is stored as null instead of "".
        description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
        majorId: selectedMajor.value!.id, 
        yearId: selectedYear.value!.id, 
        grade: selectedGradeLevel.value!, 
      ),
    );
    
    // The repository returns a map: `status` (bool) and, on failure,
    // `error` (String) with the reason.
    if (insertedSuccessfully['status']) {
      RightSideToast.show(
        title: 'success'.tr,
        message: 'tuition_added_successfully'.tr,
        messageColor: Colors.green,
      );
      // Refresh the list so the new cost appears, then clear the form.
      loadExtraCosts();
      resetFields();
    } else {
      RightSideToast.show(
        title: 'error'.tr,
        message: insertedSuccessfully['error'],
        messageColor: Colors.red,
        duration: Duration(seconds: 4),
      );
    }
  }

  /// Updates the currently selected extra cost with the values from the form.
  ///
  /// Only checks that the amount is not empty. It uses the ID of
  /// [selectedExtraCost], so a row must be selected, otherwise the `!` throws.
  ///
  /// - Update succeeds: shows a success toast, reloads the list and clears the form.
  /// - Update fails: shows an error toast with the database error message.
  void updateCost() async {
    if (extraCostAmountController.text.isEmpty) {
      RightSideToast.show(
        title: 'error'.tr,
        message: 'tuition_amount_required'.tr,
        messageColor: const Color.fromARGB(255, 233, 181, 68),
        duration: Duration(seconds: 3),
      );
      return;
    }

    final updatedSuccessfully = await repository.updateExtraCost(
      extraCost: ExtraCost(
        id: selectedExtraCost.value!.id, // ID of the selected record
        price: int.parse(extraCostAmountController.text),
        description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
        majorId: selectedMajor.value!.id, 
        yearId: selectedYear.value!.id, 
        grade: selectedGradeLevel.value!, 
      ),
    );

    if (updatedSuccessfully['status']) {
      RightSideToast.show(
        title: 'success'.tr,
        message: 'tuition_record_updated_successfully'.tr,
        messageColor: Colors.green,
      );
      loadExtraCosts();
      resetFields(); // Clear the form and leave edit mode
    } else {
      RightSideToast.show(
        title: 'error'.tr,
        message: updatedSuccessfully['error'],
        messageColor: Colors.red,
      );
    }
  }

  /// Asks the user to confirm, then deletes [extraCost].
  ///
  /// [context] is only used to read the current theme for the dialog color.
  ///
  /// - Confirmed and successful: shows a success toast, reloads the list and clears the form.
  /// - Confirmed but failed: shows an error toast with the database error message.
  /// - Cancelled or dismissed: nothing happens.
  void deleteTuition(BuildContext context, ExtraCost extraCost) async {
    // `Get.dialog` returns the value passed to `Get.back(result: ...)`,
    // or `null` if the dialog was dismissed (e.g. by tapping outside it).
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.containerBackgroundColor,
        title: Text('confirm_deletion'.tr),
        content: Text('delete_extra_cost_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr, style: TextStyle(color: Colors.red),),
          ),
        ],
      ),
    );

    // `== true` also covers the `null` (dismissed) case.
    if (confirm == true) {
      final deletedSuccessfully = await repository.deleteExtraCost(extraCost: extraCost);
      if (deletedSuccessfully['status']) {
        RightSideToast.show(
          title: 'success'.tr,
          message: 'extra_cost_deleted_successfully'.tr,
          messageColor: Colors.green,
        );
        loadExtraCosts();
        resetFields(); // Clear the form and leave edit mode
      } else {
        RightSideToast.show(
          title: 'error'.tr,
          message: deletedSuccessfully['error'],
          messageColor: Colors.red,
        );
      }
    }
  }

  /// Selects or deselects a table row.
  ///
  /// - Tapping the selected row deselects it and clears the form (back to "add" mode).
  /// - Tapping any other row selects it and fills the form with its data
  ///   (edit mode).
  ///
  /// Rows are compared by `id`.
  void toggleSelection(ExtraCost extraCost) async {
    if (selectedExtraCost.value?.id == extraCost.id) {
      selectedExtraCost.value = null;
      // Clear the form too, so the user starts with an empty "add" form.
      // (The description field is not part of this check.)
      if (extraCostAmountController.text.isNotEmpty ||  selectedMajor.value != null || selectedYear.value != null || selectedGradeLevel.value != null) {
        resetFields();
      }
    } else {
      selectedExtraCost.value = extraCost;
      // Fill the form with the selected record's data.
      setFields(extraCost);
    }
  }
}