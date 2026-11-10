import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/school_repository.dart';
import 'package:school_managment_app/services/shared_data_service.dart';

/// Controller (GetX) for the payment status pie chart.
///
/// The chart splits students into three groups: fully paid, partially paid and
/// not paid. This controller loads those percentages from the database and
/// holds the state of the filters (school year, major, grade level).
///
/// This controller does not listen to the filter fields. The view must call
/// [loadStudentPaymentStatus] with the selected IDs when a filter changes.
class PieChartController extends GetxController {
  // --- Dependency Injection ---
  // `Get.find()` only works if these objects were registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Low-level database controller; passed to [repository] in [onInit].
  final SchoolManagmentDataBaseController dbController = Get.find();

  /// App-wide shared data (the lists of school years and majors).
  final SharedDataService dataService = Get.find();

  /// Handles the actual database queries for the chart data.
  /// `late` because it needs [dbController], so it is created in [onInit].
  late final SchoolRepository repository;

  /// Focus node attached to a dropdown/input in the view.
  final FocusNode myFocusNode = FocusNode();

  // --- Reactive UI State ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it.

  /// `true` while the chart data is being loaded.
  /// The view can use it to show a loading indicator instead of the chart.
  /// It starts as `true` because the first load begins in [onInit].
  RxBool isLoading = true.obs;

  /// Whether the filter options are visible in the UI (toggled by the view).
  RxBool showFilters = false.obs;
  
  // --- Reactive Chart Data State ---

  /// Number of students included in the current chart data
  /// (all students, or only those matching the filters).
  RxInt allStudentsCount = 0.obs;

  /// Percentage of students who have paid everything.
  RxDouble fullyPaid = 0.0.obs;

  /// Percentage of students who have paid only part of what they owe.
  RxDouble partiallyPaid = 0.0.obs;

  /// Percentage of students who have not paid.
  RxDouble notPaid = 0.0.obs;

  // --- Reactive Filter State ---

  /// Items shown in the "school year" filter dropdown.
  RxList<SchoolYear> yearDropDownItems = <SchoolYear>[].obs;

  /// Items shown in the "major" filter dropdown.
  RxList<Major> majorDropDownItems = <Major>[].obs;

  /// Currently selected year filter, or `null` for "all years".
  Rx<SchoolYear?> selectedYear = Rx<SchoolYear?>(null);

  /// Currently selected major filter, or `null` for "all majors".
  Rx<Major?> selectedMajor = Rx<Major?>(null);

  /// Currently selected grade level filter, or `null` for "all grades".
  /// (`RxnInt` is a nullable reactive int.)
  var selectedGradeLevel = RxnInt();

  /// Called by GetX right after the controller is created.
  /// Sets up the repository, fills the dropdowns and loads the chart data.
  @override
  void onInit() {
    super.onInit();

    // The repository needs the database controller, so it is created here
    // instead of in the field initializer.
    repository = SchoolRepository(dbController);

    // The listener is empty for now, so this currently does nothing.
    // Either add the logic that should run on focus changes or remove it.
    myFocusNode.addListener(() {});

    // Copy the shared lists into this controller's own reactive lists.
    // `assignAll` replaces the content and triggers a single UI update.
    majorDropDownItems.assignAll(dataService.majorItems);
    yearDropDownItems.assignAll(dataService.yearItems);
    
    // First load: chart for all students, without filters.
    loadStudentPaymentStatus();
  }
  
  /// Loads the payment status percentages from the repository and updates
  /// the chart state ([allStudentsCount], [fullyPaid], [partiallyPaid], [notPaid]).
  ///
  /// [isLoading] is `true` while the request runs and `false` when it is done.
  /// All filters are optional; a `null` filter means "don't filter by this".
  ///
  /// [majorId], [yearId] and [grade] are the filter values (IDs, not objects).
  ///
  /// Note: if you call it without arguments, the result is **unfiltered**,
  /// even if the filter dropdowns still have a value selected.
  void loadStudentPaymentStatus({int? majorId, int? yearId, int? grade}) async {
    // These local variables only rename the parameters. They also have the same
    // names as the class fields [selectedMajor] / [selectedYear], so inside this
    // method those names refer to the local ints, not to the Rx fields.
    final selectedMajor = majorId;
    final selectedYear = yearId;
    final selectedGrade = grade;

    // Show the loading state while the data is being fetched.
    isLoading.value = true;

    final paymentsStatus = await repository.getStudentPaymentPercentages(
      majorId: selectedMajor,
      yearId: selectedYear,
      grade: selectedGrade
    );

    // Update the chart values; the UI redraws automatically.
    allStudentsCount.value = paymentsStatus.totalStudents;
    fullyPaid.value = paymentsStatus.fullyPaidPercentage;
    partiallyPaid.value = paymentsStatus.partiallyPaidPercentage;
    notPaid.value = paymentsStatus.notPaidPercentage;

    // Loading finished.
    isLoading.value = false;
  }

  /// Clears all filters and reloads the chart for all students.
  void resetFilterFields() {
    selectedMajor.value = null;
    selectedYear.value = null;
    selectedGradeLevel.value = null;
    
    // Reload without any filters.
    loadStudentPaymentStatus();
  }
}