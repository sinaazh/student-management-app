import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/models/debtor.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/create_excel_report.dart';
import 'package:school_managment_app/services/school_repository.dart';
import 'package:school_managment_app/services/settings_manager.dart';
import 'package:school_managment_app/services/shared_data_service.dart';
import 'package:school_managment_app/views/student_payment.dart';
import 'package:school_managment_app/widgets/my_snack_bar.dart';
import 'package:school_managment_app/widgets/show_dialog.dart';

/// Controller (GetX) for the debtors page.
///
/// Responsibilities:
/// - Loads one page of debtors (students with an unpaid balance) from the database.
/// - Holds the filter state (school year, major, grade level) and pagination state.
/// - Opens the payment dialog for a debtor and refreshes the list afterwards.
/// - Generates an Excel report for each debtor ([generateStudentReport]).
class DebtorListController extends GetxController {
  // --- Dependency Injection ---
  // `Get.find()` only works if these objects were registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Low-level database controller; passed to [repository] in [onInit].
  final SchoolManagmentDataBaseController dbController = Get.find();

  /// App-wide shared data (the lists of school years and majors).
  final SharedDataService dataService = Get.find();

  /// Handles the actual database operations (debtors list, report data, etc.).
  /// `late` because it needs [dbController], so it is created in [onInit].
  late final SchoolRepository repository;

  // --- Focus Management ---

  /// Focus node attached to a dropdown/input in the view.
  /// Disposed in [onClose].
  final FocusNode myFocusNode = FocusNode();

  // --- Reactive State for Debtor List ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it.

  /// The debtors of the **current page** only (at most [rowsPerPage] items).
  RxList<Debtor> allDebtors = <Debtor>[].obs;

  // --- Reactive State for Filter Dropdowns ---

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

  // --- Pagination State ---

  /// Total number of debtors matching the current filters, across all pages.
  RxInt allDebtorsCount = 0.obs;

  /// How many debtors are shown per page.
  int rowsPerPage = 20;

  /// The page currently shown. Starts at 1 (not 0).
  RxInt currentPage = 1.obs;

  /// Total number of pages for the current filters
  /// (0 when there are no matching debtors).
  RxInt totalPages = 0.obs;

  /// Called by GetX right after the controller is created.
  /// Sets up the repository, fills the dropdowns and loads the first page.
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

    // Keep the dropdowns up to date if the shared lists change later
    // (e.g. a new year or major is added elsewhere in the app).
    ever(dataService.majorItems, (updatedMajors) {
      majorDropDownItems.assignAll(updatedMajors);
    });

    ever(dataService.yearItems, (updatedYears) {
      yearDropDownItems.assignAll(updatedYears);
    });

    // First load: page 1 without any filters.
    loadDebtors();
  }

  /// Called by GetX just before the controller is removed from memory.
  @override
  void onClose() {
    // Dispose of the FocusNode to prevent memory leaks.
    myFocusNode.dispose();
    super.onClose();
  }

  /// Loads one page of debtors from the repository and updates the table state.
  ///
  /// The page is taken from [currentPage] and its size from [rowsPerPage]
  /// (translated into SQL-style `limit` / `offset`). All filters are optional;
  /// a `null` filter means "don't filter by this".
  ///
  /// Updates [allDebtors], [allDebtorsCount] and [totalPages].
  ///
  /// [majorId], [yearId] and [grade] are the filter values (IDs, not objects).
  ///
  /// Note: if you call it without arguments, the result is **unfiltered**,
  /// even if the filter dropdowns still have a value selected.
  void loadDebtors({int? majorId, int? yearId, int? grade}) async {
    // These local variables only rename the parameters. They also have the same
    // names as the class fields [selectedMajor] / [selectedYear], so inside this
    // method those names refer to the local ints, not to the Rx fields.
    final selectedMajor = majorId;
    final selectedYear = yearId;
    final selectedGrade = grade;

    final debtors = await repository.getDebtorsList(
      majorId: selectedMajor,
      yearId: selectedYear,
      grade: selectedGrade,
      limit: rowsPerPage,
      // Number of rows to skip: page 1 -> 0, page 2 -> 20, page 3 -> 40, ...
      offset: (currentPage.value - 1) * rowsPerPage,
    );

    // Replace the rows of the table with the new page.
    allDebtors.assignAll(debtors.debtors);

    allDebtorsCount.value = debtors.totalDebtorsCount;

    // Round up so a partly filled last page still counts as a page.
    totalPages.value = (debtors.totalDebtorsCount / rowsPerPage).ceil();
  }

  /// Moves to the next page (keeping the current filters).
  /// Does nothing if the last page is already shown.
  Future<void> loadNextPageData() async {
    if (currentPage.value == totalPages.value) return;

    currentPage.value++;

    loadDebtors(
      majorId: selectedMajor.value?.id,
      yearId: selectedYear.value?.id,
      grade: selectedGradeLevel.value,
    );
  }

  /// Moves to the previous page (keeping the current filters).
  /// Does nothing if the first page is already shown.
  /// ("Prevoius" is a typo, kept so the name still matches the view.)
  Future<void> loadPrevoiusPageData() async {
    if (currentPage.value <= 1) return;

    currentPage.value--;

    loadDebtors(
      majorId: selectedMajor.value?.id,
      yearId: selectedYear.value?.id,
      grade: selectedGradeLevel.value,
    );
  }

  /// Opens the payment dialog for the student with the given [studentID].
  ///
  /// When the dialog is closed, the debtor list is reloaded, because the
  /// user may have made a payment that changes who is still a debtor.
  void openStudentPaymentPage(int studentID) {
    ShowMyDialog.showDialogWithBlur(
      builder: () => StudentPaymentDialog(),
      // The dialog reads the student ID from these arguments.
      argument: {"studentId": studentID},
    ).then((_) => loadDebtors());
  }

  /// Returns the name of the major with the given [majorId].
  ///
  /// Throws a null-check error if no major has this ID, because of the `!`.
  String getMajorNameById(int majorId) {
    return majorDropDownItems
        .firstWhereOrNull((major) => major.id == majorId)!
        .name;
  }

  /// Returns the year of the school year with the given [yearId] as text
  /// (e.g. "2024").
  ///
  /// Throws a null-check error if no school year has this ID, because of the `!`.
  String getYearTextById(int yearId) {
    return yearDropDownItems
        .firstWhereOrNull((year) => year.id == yearId)!
        .year
        .toString();
  }

  /// Clears all filters, goes back to page 1 and reloads the unfiltered list.
  void resetFilterFields() {
    selectedMajor.value = null;
    selectedYear.value = null;
    selectedGradeLevel.value = null;
    // Back to the first page, then reload without filters.
    currentPage.value = 1;
    loadDebtors();
  }

  /// Creates one Excel (.xlsx) report per debtor in [allDebtors] and saves them
  /// in a folder chosen by the user.
  ///
  /// Steps:
  /// 1. Ask the user for a destination folder (stop if they cancel).
  /// 2. For each debtor, load the student's info, payments and remaining balance.
  /// 3. Build the report file with [StudentReportService.generateReport].
  /// 4. Show one success toast at the end, or an error toast if anything fails.
  ///
  /// [context] is only used to detect right-to-left layouts, so the report
  /// matches the app's text direction.
  Future<void> generateStudentReport(BuildContext context) async {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final SettingsManager appSettings = Get.find();
    // The school name is printed in the header of each report.
    String schoolName = await appSettings.readSchoolName();

    try {
      // Let the user pick the destination folder. Returns `null` if cancelled.
      final directory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select report destination folder',
      );

      if (directory == null) {
        return;
      }

      // One report (one file) per debtor, created one after another.
      for (Debtor debtor in allDebtors) {
        // Load everything the report needs for this student.
        // limit/offset use the same page values as the debtor list.
        final result = await repository.getStudentInfoForReport(
          studentYearId: debtor.id!,
          limit: rowsPerPage,
          offset: (currentPage.value - 1) * rowsPerPage,
        );

        final student = result.studentInfo;
        final payments = result.studentPayments;
        // Map with the amounts: tuition, extra_costs and remaining_tuition.
        final studentRemainingPayment = result.studentRemainingPayment;

        await StudentReportService.generateReport(
          schoolName: schoolName,
          studentName: "${student.firstName} ${student.lastName}",
          studentCode: student.studentCode!,
          nationalCode: int.parse(student.nationalCode!),
          // Convert the stored IDs into readable text for the report.
          major: dataService.majorItems
              .firstWhere((item) => item.id == student.majorId)
              .name,
          grade: student.grade,
          academicYear: dataService.yearItems
              .firstWhere((item) => item.id == student.yearId)
              .year
              .toString(),
          tuition: studentRemainingPayment["tuition"]!,
          extraFees: studentRemainingPayment["extra_costs"]!,
          discountAmount: student.discount!,
          remaining: studentRemainingPayment["remaining_tuition"]!,
          suggestedFileName: "${student.firstName} ${student.lastName}",
          // Convert each payment into the map format the report service expects.
          payments: payments.map((payment) {
            return <String, Object>{
              'amount': payment.paymentAmount,
              'date': DateTime.parse(payment.paymentDate),
              'description': payment.paymentDescription ?? '',
            };
          }).toList(),
          isRTL: isRTL,
          filePath: '$directory/${student.firstName} ${student.lastName}.xlsx',
        );
      }

      RightSideToast.show(
        title: 'success'.tr,
        message: 'student_report_generated_successfully'.tr,
        messageColor: Colors.green,
      );
    } catch (e) {
      // Any error (database, parsing, file writing) ends up here.
      // The error itself is not shown or logged, only a generic message.
      RightSideToast.show(
        title: 'error'.tr,
        message: 'student_report_generation_failed'.tr,
        messageColor: Colors.red,
      );
    }
  }
}