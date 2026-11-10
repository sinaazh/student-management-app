import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/data_table_controller.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/models/student.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/school_repository.dart';
import 'package:school_managment_app/services/shared_data_service.dart';
import 'package:school_managment_app/widgets/my_snack_bar.dart';

/// Controller (GetX) that holds the state and logic of the "Add Student" form.
///
/// Responsibilities:
/// - Holds the text controllers and dropdown selections used by the form.
/// - Validates the required fields.
/// - Inserts the student into the database through [SchoolRepository].
/// - Tells the student [DataTableController] to reload after a successful insert.
///
/// The view reads the `Rx` fields (via `Obx`) and calls [saveStudent] and
/// [resetFields]; it should not talk to the database directly.
class AddStudentController extends GetxController {
  // --- Dependency Injection ---
  // `Get.find()` only works if these objects were registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Controller of the students table, used to refresh the list after an insert.
  final DataTableController dataTableController = Get.find();

  /// Low-level database controller; passed to [repository] in [onInit].
  final SchoolManagmentDataBaseController dbController = Get.find();

  /// App-wide shared data (the lists of school years and majors) so the
  /// dropdowns don't have to query the database themselves.
  final SharedDataService dataService = Get.find();

  /// Handles the actual database operations (insert, etc.) for school data.
  /// `late` because it needs [dbController], so it is created in [onInit].
  late final SchoolRepository repository;

  // --- Focus Management ---

  /// Focus node attached to a dropdown/input in the view.
  /// Used by [checkWindowSize] to know whether a dropdown is currently open.
  final FocusNode myFocusNode = FocusNode();

  // --- Reactive State for Dropdowns ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it.

  /// Items shown in the "school year" dropdown.
  RxList<SchoolYear> yearDropDownItems = <SchoolYear>[].obs;

  /// Items shown in the "major" dropdown.
  RxList<Major> majorDropDownItems = <Major>[].obs;

  /// Currently selected grade level, or `null` if nothing is selected yet.
  /// (`RxnInt` is a nullable reactive int.)
  var selectedGradeLevel = RxnInt();

  /// Currently selected [SchoolYear], or `null` if nothing is selected yet.
  Rx<SchoolYear?> selectedYear = Rx<SchoolYear?>(null);

  /// Currently selected [Major], or `null` if nothing is selected yet.
  Rx<Major?> selectedMajor = Rx<Major?>(null);

  // --- Text Editing Controllers for Form Fields ---

  /// First name (required).
  TextEditingController firstNameController = TextEditingController();

  /// Last name (required).
  TextEditingController lastNameController = TextEditingController();

  /// National code / national ID (required).
  TextEditingController nationalCodeController = TextEditingController();

  /// School-specific student code (optional; saved as `null` when left empty).
  /// Note: "studnet" is a typo, kept so the name still matches the view.
  TextEditingController studnetCodeController = TextEditingController();

  /// Discount amount (optional; treated as 0 when empty or not a valid number).
  TextEditingController discountController = TextEditingController();

  /// Called by GetX right after the controller is created.
  /// Sets up the repository and fills the dropdown lists.
  @override
  void onInit() {
    super.onInit();

    // The listener is empty for now, so this currently does nothing.
    // Either add the logic that should run on focus changes or remove it.
    myFocusNode.addListener(() {});

    // The repository needs the database controller, so it is created here
    // instead of in the field initializer.
    repository = SchoolRepository(dbController);

    // Copy the shared lists into this controller's own reactive lists.
    // `assignAll` replaces the content and triggers a single UI update.
    majorDropDownItems.assignAll(dataService.majorItems);
    yearDropDownItems.assignAll(dataService.yearItems);
  }

  /// Called by GetX just before the controller is removed from memory.
  /// Release resources that GetX does not dispose automatically.
  @override
  void onClose() {
    myFocusNode.dispose();
    super.onClose();
  }

  /// Closes an open dropdown menu when the window is resized.
  ///
  /// An open dropdown is a route on the Navigator stack, so if [myFocusNode]
  /// has focus and the Navigator can pop, the top route is popped and the
  /// focus is released. Intended to be called from a layout/resize callback.
  void checkWindowSize(BuildContext context) {
    if (myFocusNode.hasFocus && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      myFocusNode.unfocus();
    }
  }

  /// Returns the form to its initial state: clears every text field and
  /// resets every dropdown selection to `null`.
  void resetFields() {
    firstNameController.clear();
    lastNameController.clear();
    nationalCodeController.clear();
    studnetCodeController.clear();
    discountController.clear();
    selectedGradeLevel.value = null;
    selectedYear.value = null;
    selectedMajor.value = null;
  }

  /// Checks that all required fields are filled in.
  ///
  /// Required: first name, last name, national code, major, year, grade level.
  /// Optional: student code and discount.
  ///
  /// Returns a translated error message for the first problem found,
  /// or `null` if everything is valid.
  String? validateStudentFields() {
    // Required text fields
    if (firstNameController.text.isEmpty) return 'first_name_required'.tr;
    if (lastNameController.text.isEmpty) return 'last_name_required'.tr;
    if (nationalCodeController.text.isEmpty) return 'national_code'.tr;

    // Required dropdown selections
    if (selectedMajor.value == null) return 'major_must_be_selected'.tr;
    if (selectedYear.value == null) return 'year_must_be_selected'.tr;
    if (selectedGradeLevel.value == null) return 'grade_level_must_be_selected'.tr;

    // Everything is valid
    return null;
  }

  /// Validates the form and, if valid, saves the student to the database.
  ///
  /// - Validation fails: shows a warning toast and stops.
  /// - Insert succeeds: shows a success toast and reloads the students table.
  /// - Insert fails: shows an error toast with the database error message.
  Future<void> saveStudent() async {
    final error = validateStudentFields();

    if (error != null) {
      RightSideToast.show(
        title: 'error'.tr,
        message: error,
        messageColor: const Color.fromARGB(255, 233, 181, 68), // amber = warning
        duration: Duration(seconds: 3),
      );
      return;
    }

    // Build the Student from the form. The `!` operators are safe here because
    // validateStudentFields() already confirmed these selections are not null.
    final insertedSuccessfully = await repository.insertStudent(
      student: Student(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        nationalCode: nationalCodeController.text.trim(),
        // Empty student code is stored as null rather than an empty string.
        studentCode: studnetCodeController.text.isEmpty ? null : studnetCodeController.text.trim(),
        majorId: selectedMajor.value!.id,
        yearId: selectedYear.value!.id,
        grade: selectedGradeLevel.value!,
        // Falls back to 0 if the field is empty or not a valid integer.
        discount: int.tryParse(discountController.text.trim()) ?? 0,
      ),
    );

    // The repository returns a map: `status` (bool) and, on failure,
    // `error` (String) with the reason.
    if (insertedSuccessfully['status']) {
      RightSideToast.show(
        title: 'success'.tr,
        message: 'student_added_successfully'.tr,
        messageColor: Colors.green,
      );
      // Refresh the table so the new student appears immediately.
      dataTableController.loadAllStudents();
    } else {
      RightSideToast.show(
        title: 'error'.tr,
        message: insertedSuccessfully['error'],
        messageColor: Colors.red,
      );
    }
  }
}