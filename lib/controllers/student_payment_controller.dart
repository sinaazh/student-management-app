import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:school_managment_app/controllers/data_table_controller.dart';
import 'package:school_managment_app/controllers/debtor_list_controller.dart';
import 'package:school_managment_app/models/payment.dart';
import 'package:school_managment_app/models/student.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/create_excel_report.dart';
import 'package:school_managment_app/services/school_repository.dart';
import 'package:school_managment_app/services/settings_manager.dart';
import 'package:school_managment_app/services/shared_data_service.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/my_snack_bar.dart';

/// Controller (GetX) for the payment dialog of one student.
///
/// Responsibilities:
/// - Loads one page of the student's payments and the remaining balance.
/// - Holds the state of the form that is used for both adding and editing:
///   when no row is selected the form adds a new payment, when a row is
///   selected ([selectedPayment]) the form edits that payment.
/// - Creates, updates and deletes payments ([savePayment], [updatePayment],
///   [deletePayment]).
/// - Creates an Excel report for the student ([generateStudentReport]).
///
/// The dialog can be opened from two places (see [onInit]): the students table
/// or the debtor list.
class StudentPaymentController extends GetxController {
  // --- Dependency Injection ---
  // `Get.find()` only works if these objects were registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Low-level database controller; passed to [repository] in [onInit].
  final SchoolManagmentDataBaseController dbController = Get.find();
  
  /// Controller of the students table. Its selected student is used when the
  /// dialog is opened from the table (and by the report, see [generateStudentReport]).
  final DataTableController dataTableController = Get.find();

  /// App-wide shared data (the lists of majors and school years), used to turn
  /// IDs into names for the report.
  final SharedDataService dataService = Get.find();
  
  /// Handles the actual database operations (payments and remaining tuition).
  /// `late` because it needs [dbController], so it is created in [onInit].
  late final SchoolRepository repository;

  // --- Text Editing Controllers for Form Fields ---

  /// Payment amount (required, must be a whole number).
  TextEditingController paymentAmountController = TextEditingController();
  
  /// Payment date (required). It is stored as text and must be in a format
  /// that `DateTime.parse` accepts (e.g. "2025-03-21"), because the report
  /// converts it back to a date.
  TextEditingController dateController = TextEditingController();
  
  /// Optional description (saved as `null` when left empty).
  TextEditingController descriptionController = TextEditingController();

  // --- Reactive State ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it.

  /// The payments of the **current page** only (at most [rowsPerPage] items),
  /// not all payments of the student.
  RxList<StudentPayment> studentPayments = <StudentPayment>[].obs;
  
  /// The payment whose row is currently selected, or `null` if none is.
  /// While it is not `null`, the form is in "edit" mode and [savePayment]
  /// refuses to add a new payment.
  Rx<StudentPayment?> selectedPayment = Rx<StudentPayment?>(null);
  
  /// The amount the student still has to pay, as calculated by the repository.
  RxInt remainingTuition = RxInt(0);

  /// The ID of the student/studentYear record whose payments are being managed.
  /// Set in [onInit].
  int? studentId;

  // --- Pagination State ---

  /// Total number of payments of this student, across all pages.
  RxInt allPaymentsCount = 0.obs;

  /// How many payments are shown per page.
  int rowsPerPage = 10;

  /// The page currently shown. Starts at 1 (not 0).
  RxInt currentPage = 1.obs;

  /// Total number of pages (0 when the student has no payments).
  RxInt totalPages = 0.obs;

  /// Called by GetX right after the controller is created.
  /// Finds out which student this dialog is for and loads the payments.
  @override
  void onInit() {
    super.onInit();

    // The repository needs the database controller, so it is created here
    // instead of in the field initializer.
    repository = SchoolRepository(dbController);

    // Find out which student the dialog was opened for:
    // 1. Opened from the debtor list: the dialog arguments contain 'studentId'
    //    (and the debtor list controller exists).
    // 2. Otherwise: use the student selected in the main students table.
    //    The `!` throws if no student is selected.
    if(Get.arguments?['studentId'] != null && Get.isRegistered<DebtorListController>()) {
      studentId = Get.arguments['studentId'];
    } else {
      studentId = dataTableController.selectedUser.value!.id!;
    }

    // First load: page 1 of this student's payments.
    loadPayments();
  }
  
  /// Loads one page of the student's payments and the remaining tuition.
  ///
  /// The page is taken from [currentPage] and its size from [rowsPerPage]
  /// (translated into SQL-style `limit` / `offset`). Updates [studentPayments],
  /// [remainingTuition], [allPaymentsCount] and [totalPages].
  void loadPayments() async {
    final payments = await repository.getAllStudentPayments(
      studentYearId: studentId!,
      limit: rowsPerPage,
      // Number of rows to skip: page 1 -> 0, page 2 -> 10, page 3 -> 20, ...
      offset: (currentPage.value - 1) * rowsPerPage,
    );
    studentPayments.value = payments.payments;

    // The remaining balance is calculated by the repository (a separate query).
    remainingTuition.value = (await repository.getremainingTuition(studentYearId: studentId!))["remaining_tuition"]!;

    allPaymentsCount.value = payments.totalPaymentsCount;

    // Round up so a partly filled last page still counts as a page.
    totalPages.value = (payments.totalPaymentsCount / rowsPerPage).ceil();
  }

  /// Moves to the next page of payments.
  /// Does nothing if the last page is already shown.
  Future<void> loadNextPageData() async {
    if (currentPage.value == totalPages.value) return;

    currentPage.value++;

    loadPayments();
  }

  /// Moves to the previous page of payments.
  /// Does nothing if the first page is already shown.
  /// ("Prevoius" is a typo, kept so the name still matches the view.)
  Future<void> loadPrevoiusPageData() async {
    if (currentPage.value <= 1) return;

    currentPage.value--;

    loadPayments();
  }

  /// Fills the form with the data of [payment] (used when a row is selected).
  void setFields(StudentPayment payment) {
    paymentAmountController.text = payment.paymentAmount.toString();
    dateController.text = payment.paymentDate.toString();
    descriptionController.text = payment.paymentDescription ?? "";
  }

  /// Returns the form to its initial state: clears the text fields and
  /// deselects the selected payment (back to "add" mode).
  void resetFields() {
    paymentAmountController.clear();
    dateController.clear();
    descriptionController.clear();
    if (selectedPayment.value != null) {
      selectedPayment.value = null;
    }
  }

  /// Checks that the required fields (amount and date) are filled in.
  ///
  /// It does not check that the amount is a number or that the date has a
  /// valid format.
  ///
  /// Returns a translated error message for the first problem found,
  /// or `null` if everything is valid.
  String? validatePaymentFields() {
    if (paymentAmountController.text.isEmpty) return 'payment_amount_required'.tr;
    if (dateController.text.isEmpty) return 'payment_date_required'.tr;

    // Everything is valid
    return null;
  }

  /// Validates the form and, if valid, saves a **new** payment for [studentId].
  ///
  /// - A row is selected (edit mode): shows a warning toast and stops, so an
  ///   edit can't accidentally create a duplicate.
  /// - Validation fails: shows a warning toast and stops.
  /// - Insert succeeds: shows a success toast, reloads the payments and clears the form.
  /// - Insert fails: shows an error toast with the database error message.
  Future<void> savePayment() async {
    // A selected row means the form currently holds an existing payment.
    if (selectedPayment.value != null) {
      RightSideToast.show(
        title: 'error'.tr,
        message: 'deselect_payment_before_adding'.tr,
        messageColor: Color.fromARGB(255, 233, 181, 68), // amber = warning
        duration: const Duration(seconds: 5),
      );
      return;
    }
    final error = validatePaymentFields();
    if (error != null) {
      RightSideToast.show(
        title: 'error'.tr,
        message: error,
        messageColor: const Color.fromARGB(255, 233, 181, 68),
        duration: Duration(seconds: 3),
      );
      return;
    }
    
    // `int.parse` throws if the amount is not a valid whole number.
    final insertedSuccessfully = await repository.insertStudentPayment(
      payment: StudentPayment(
        studentID: studentId,
        paymentAmount: int.parse(paymentAmountController.text),
        paymentDate: dateController.text,
        // Empty description is stored as null instead of "".
        paymentDescription: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      ),
    );

    // The repository returns a map: `status` (bool) and, on failure,
    // `error` (String) with the reason.
    if (insertedSuccessfully['status']) {
      RightSideToast.show(
        title: 'success'.tr,
        message: 'payment_added_successfully'.tr,
        messageColor: Colors.green,
      );
      // Refresh the list and balance, then clear the form.
      loadPayments();
      resetFields();
    } else {
      RightSideToast.show(
        title: 'error'.tr,
        message: insertedSuccessfully['error'],
        messageColor: Colors.red,
      );
    }
  }

  /// Validates the form and, if valid, updates the selected payment.
  ///
  /// - No row selected: shows a warning toast and stops.
  /// - Validation fails: shows a warning toast and stops.
  /// - Update succeeds: shows a success toast, reloads the payments and clears the form.
  /// - Update fails: shows an error toast with the database error message.
  Future<void> updatePayment() async {
    final error = validatePaymentFields();

    // A payment must be selected to be updated.
    if (selectedPayment.value == null) {
      RightSideToast.show(
        title: 'error'.tr,
        message: 'select_payment_before_updating'.tr,
        messageColor: const Color.fromARGB(255, 233, 181, 68),
        duration: Duration(seconds: 3),
      );
      return;
    } else if (error != null) {
      // Field validation failed.
      RightSideToast.show(
        title: 'error'.tr,
        message: error,
        messageColor: const Color.fromARGB(255, 233, 181, 68),
        duration: Duration(seconds: 3),
      );
      return;
    }

    final updatedSuccessfully = await repository.updateStudentPayment(
      payment: StudentPayment(
        id: selectedPayment.value!.id,
        // NOTE: this uses the student selected in the students table, not
        // [studentId] (which [savePayment] uses). If the dialog was opened from
        // the debtor list, this can be a different student, or `null` (crash).
        studentID: dataTableController.selectedUser.value!.id!,
        paymentAmount: int.parse(paymentAmountController.text),
        paymentDate: dateController.text,
        paymentDescription: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      ),
    );
    
    if (updatedSuccessfully['status']) {
      RightSideToast.show(
        title: 'success'.tr,
        message: 'payment_updated_successfully'.tr,
        messageColor: Colors.green,
      );
      loadPayments();
      resetFields();
    } else {
      RightSideToast.show(
        title: 'error'.tr,
        message: updatedSuccessfully['error'],
        messageColor: Colors.red,
      );
    }
  }

  /// Asks the user to confirm, then deletes [payment].
  ///
  /// [context] is only used to read the current theme for the dialog color.
  ///
  /// - Confirmed and successful: shows a success toast, reloads the payments and clears the form.
  /// - Confirmed but failed: shows an error toast with the database error message.
  /// - Cancelled or dismissed: nothing happens.
  Future<void> deletePayment(BuildContext context, StudentPayment payment) async {
    // `Get.dialog` returns the value passed to `Get.back(result: ...)`,
    // or `null` if the dialog was dismissed (e.g. by tapping outside it).
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.containerBackgroundColor,
        title: Text('confirm_deletion'.tr),
        content: Text('delete_payment_confirmation'.tr),
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
      final deletedSuccessfully = await repository.deleteStudentPayment(payment: payment);
      if (deletedSuccessfully['status']) {
        RightSideToast.show(
          title: 'success'.tr,
          message: 'payment_deleted_successfully'.tr,
          messageColor: Colors.green,
        );
        loadPayments();
        resetFields();
      } else {
        RightSideToast.show(
          title: 'error'.tr,
          message: deletedSuccessfully['error'],
          messageColor: Colors.red,
        );
      }
    }
  }
  
  /// Selects or deselects a payment row.
  ///
  /// - Tapping the selected row deselects it and clears the form (back to "add" mode).
  /// - Tapping any other row selects it and fills the form with its data
  ///   (edit mode).
  ///
  /// Rows are compared by `id`.
  void toggleSelection(StudentPayment payment) {
    if (selectedPayment.value?.id == payment.id) {
      selectedPayment.value = null;
      // Clear the form too, so the user starts with an empty "add" form.
      if (paymentAmountController.text.isNotEmpty || dateController.text.isNotEmpty || descriptionController.text.isNotEmpty) {
        resetFields();
      }
    } else {
      selectedPayment.value = payment;
      setFields(payment);
    }
  }

  /// Creates an Excel (.xlsx) report with the student's details, payments and
  /// remaining balance.
  ///
  /// [context] is only used to detect right-to-left layouts, so the report
  /// matches the app's text direction.
  ///
  /// No file path is passed here, so [StudentReportService.generateReport]
  /// decides where to save. It returns the text "Cancelled" if the user
  /// cancels, in which case no toast is shown. Any error shows a generic
  /// failure toast.
  Future<void> generateStudentReport(BuildContext context) async {

    // NOTE: the student comes from the students table selection, while the
    // payments and balance below belong to [studentId]. When the dialog was
    // opened from the debtor list, these can be two different students (or
    // `selectedUser` is `null` and this throws).
    final Student student = dataTableController.selectedUser.value!;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    try{
      final SettingsManager appSettings = Get.find();

      // The school name is printed in the header of the report.
      String schoolName = await appSettings.readSchoolName();
      
      // Map with the amounts: tuition, extra_costs and remaining_tuition.
      final Map<String,int> tuitionInfo = await repository.getremainingTuition(studentYearId: studentId!);

      final path = await StudentReportService.generateReport(
        schoolName: schoolName,
        studentName: "${student.firstName} ${student.lastName}",
        studentCode: student.studentCode!,
        nationalCode: int.parse(student.nationalCode!),
        // Convert the stored IDs into readable text for the report.
        major: dataService.majorItems.firstWhere((item) => item.id == student.majorId).name,
        grade: student.grade,
        academicYear: dataService.yearItems.firstWhere((item) => item.id == student.yearId).year.toString(),
        tuition: tuitionInfo["tuition"]!,
        extraFees: tuitionInfo["extra_costs"]!,
        discountAmount: student.discount!,
        remaining: tuitionInfo["remaining_tuition"]!,
        suggestedFileName: "${student.firstName} ${student.lastName}",
        // Only the payments on the current page are included, because
        // [studentPayments] holds just one page.
        payments: studentPayments.map((payment) {
          return <String, Object>{
            'amount': payment.paymentAmount,
            'date': DateTime.parse(payment.paymentDate),
            'description': payment.paymentDescription ?? '',
          };
        }).toList(),
        isRTL: isRTL,    
      );
      
      if (path == "Cancelled"){
        return ;
      }

      RightSideToast.show(
        title: 'success'.tr,
        message: 'student_report_generated_successfully'.tr,
        messageColor: Colors.green,
      );
    } catch(e){
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