import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/data_table_controller.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/student.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/school_repository.dart';
import 'package:school_managment_app/services/shared_data_service.dart';
import 'package:school_managment_app/widgets/my_snack_bar.dart';

/// Controller (GetX) that holds the state and logic of the "Edit Student" form.
///
/// How it is used:
/// 1. The user selects a row in the students table
///    ([DataTableController.selectedUser]).
/// 2. The view calls [setFields] to copy that student's data into the form.
/// 3. The user changes the values and the view calls [saveStudent], which
///    validates, updates the database and reloads the table.
class EditStudentController extends GetxController {
  // --- Dependency Injection ---
  // `Get.find()` only works if these objects were registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Controller of the students table. Provides the selected student
  /// and is used to refresh the list after an update.
  final DataTableController dataTableController = Get.find();

  /// Low-level database controller; passed to [repository] in [onInit].
  final SchoolManagmentDataBaseController dbController = Get.find();

  /// App-wide shared data (here: the list of majors for the dropdown).
  final SharedDataService dataService = Get.find();

  /// Handles the actual database operations (here: updating a student).
  /// `late` because it needs [dbController], so it is created in [onInit].
  late final SchoolRepository repository;

  // --- Text Editing Controllers for Form Fields ---

  /// First name (required).
  TextEditingController firstNameController = TextEditingController();

  /// Last name (required).
  TextEditingController lastNameController = TextEditingController();

  /// National code / national ID (saved as `null` when left empty).
  TextEditingController nationalCodeController = TextEditingController();

  /// School-specific student code (saved as `null` when left empty).
  /// Note: "studnet" is a typo, kept so the name still matches the view.
  TextEditingController studnetCodeController = TextEditingController();

  /// Discount value (treated as 0 when empty or not a valid number).
  TextEditingController discountController = TextEditingController();

  // --- Reactive State and Data Storage ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it.

  /// Items shown in the "major" dropdown.
  RxList<Major> majorDropDownItems = <Major>[].obs;

  /// ID of the student being edited. Set by [setFields] and sent with the
  /// update so the database knows which row to change.
  int? studentId;

  /// Currently selected grade level, or `null` if none is set.
  RxnInt selectedGradeLevel = RxnInt();

  /// ID of the student's school year. This form has no year dropdown, so the
  /// value is only copied from the student in [setFields] and saved unchanged.
  RxnInt selectedYear = RxnInt();

  /// Currently selected [Major], or `null` if none is selected.
  Rx<Major?> selectedMajor = Rx<Major?>(null);

  /// Focus node attached to a dropdown/input in the view.
  /// Used by [checkWindowSize] to know whether a dropdown is currently open.
  final FocusNode myFocusNode = FocusNode();

  /// Called by GetX right after the controller is created.
  /// Sets up the repository and fills the major dropdown.
  @override
  void onInit() {
    super.onInit();

    // The listener is empty for now, so this currently does nothing.
    // Either add the logic that should run on focus changes or remove it.
    myFocusNode.addListener(() {});

    // The repository needs the database controller, so it is created here
    // instead of in the field initializer.
    repository = SchoolRepository(dbController);

    // Copy the shared majors into this controller's own reactive list.
    majorDropDownItems.assignAll(dataService.majorItems);

    // Keep the dropdown up to date if the shared majors change later.
    ever(dataService.majorItems, (updatedMajors) {
      majorDropDownItems.assignAll(updatedMajors);
    });
  }

  /// Called by GetX just before the controller is removed from memory.
  @override
  void onClose() {
    // Dispose of the FocusNode to prevent memory leaks.
    myFocusNode.dispose();
    super.onClose();
  }

  /// Fills the form with the data of the student currently selected in the
  /// students table ([DataTableController.selectedUser]).
  ///
  /// The view must make sure a student is selected before calling this,
  /// because the `!` below throws if `selectedUser` is `null`.
  void setFields() {
    Student student = dataTableController.selectedUser.value!;

    studentId = student.id;
    firstNameController.text = student.firstName;
    lastNameController.text = student.lastName;
    // Nullable fields: show an empty text field instead of "null".
    nationalCodeController.text = student.nationalCode != null ? student.nationalCode! : "";
    // NOTE: this line reads `student.nationalCode!`, so the student code field
    // gets the national code. It was probably meant to be `student.studentCode!`.
    studnetCodeController.text = student.studentCode != null ? student.nationalCode! : "";
    discountController.text = student.discount.toString();
    selectedGradeLevel.value = student.grade;
    selectedYear.value = student.yearId;
    // The dropdown needs the Major object, not just its ID. This is `null`
    // if the student's major is not in the list.
    selectedMajor.value = majorDropDownItems.firstWhereOrNull((major) => major.id == student.majorId);
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
  /// Required: first name, last name, major. Everything else is optional here
  /// (the national code is optional when editing, unlike on the add form).
  ///
  /// Returns a translated error message for the first problem found,
  /// or `null` if everything is valid.
  String? validateStudentFields() {
    if (firstNameController.text.isEmpty) return 'first_name_required'.tr;
    if (lastNameController.text.isEmpty) return 'last_name_required'.tr;
    if (selectedMajor.value == null) return 'major_must_be_selected'.tr;

    // Everything is valid
    return null;
  }

  /// Validates the form and, if valid, updates the student in the database.
  ///
  /// - Validation fails: shows a warning toast and stops.
  /// - Update succeeds: shows a success toast and reloads the students table.
  /// - Update fails: shows an error toast with the database error message.
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

    // Build the updated Student from the form. The `!` on selectedYear and
    // selectedGradeLevel is safe only because [setFields] filled them from an
    // existing student and validation does not check them. If [saveStudent]
    // runs without [setFields], these throw.
    final updatedSuccessfully = await repository.updateStudent(
      student: Student(
        id: studentId,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        // Empty national/student code is stored as null instead of "".
        nationalCode: nationalCodeController.text.isEmpty ? null : nationalCodeController.text.trim(),
        studentCode: studnetCodeController.text.isEmpty ? null : studnetCodeController.text.trim(),
        majorId: selectedMajor.value!.id,
        yearId: selectedYear.value!,
        grade: selectedGradeLevel.value!,
        // Falls back to 0 if the field is empty or not a valid integer.
        discount: int.tryParse(discountController.text.trim()) ?? 0,
      ),
    );

    // The repository returns a map: `status` (bool) and, on failure,
    // `error` (String) with the reason.
    if (updatedSuccessfully['status']) {
      RightSideToast.show(
        title: 'success'.tr,
        message: 'student_updated_successfully'.tr,
        messageColor: Colors.green,
      );
      // Refresh the table so the changes appear immediately.
      dataTableController.loadAllStudents();
    } else {
      RightSideToast.show(
        title: 'error'.tr,
        message: updatedSuccessfully['error'],
        messageColor: Colors.red,
      );
    }
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