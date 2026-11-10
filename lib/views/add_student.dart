import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/add_student_controller.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/widgets/my_elevated_button.dart';
import 'package:school_managment_app/widgets/my_text_field.dart';
import 'package:school_managment_app/widgets/my_base_dialog.dart';
import 'package:school_managment_app/widgets/my_drop_down.dart';
import 'package:school_managment_app/widgets/dialog_lifecycle.dart';

/// Displays a dialog for adding a new student to the school management system.
///
/// Provides input fields for the student's personal information and allows
/// selecting their major, academic year, grade level, and applicable discount.
///
/// Uses [AddStudentController] to manage form state, dropdown selections,
/// validation, and student creation.
class AddStudentDialog extends StatelessWidget implements DialogLifecycle {
  /// GetX controller responsible for managing the add-student form.
  ///
  /// Registered when this dialog is created and removed when its lifecycle ends.
  final AddStudentController controller = Get.put(AddStudentController());

  AddStudentDialog({super.key});

  /// Resets all form fields and selections when the dialog is reused.
  @override
  void resetFields() {
    controller.resetFields();
  }

  /// Removes the dialog's controller from GetX dependency management.
  ///
  /// This prevents the controller from remaining in memory after the dialog
  /// is closed.
  @override
  void removeController() {
    Get.delete<AddStudentController>();
  }

  @override
  Widget build(BuildContext context) {
    // Maximum width allowed for the dialog's content.
    const double maxContainerWdith = 600;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update the controller's responsive layout settings based on
        // the available window dimensions.
        controller.checkWindowSize(context);
        return MyBaseDialog(
          title: 'add_student'.tr,
          maxContainerWdith: maxContainerWdith,
          child: Container(
            constraints: const BoxConstraints(maxWidth: maxContainerWdith),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Student's first name. Only alphabetic characters and spaces
                // are accepted.
                MyTextField(
                  hintText: 'first_name'.tr,
                  errorText: 'only_letters_allowed'.tr,
                  regex: RegExp(r'^[a-zA-Z ]*$'),
                  textController: controller.firstNameController,
                ),

                // Student's last name. Uses the same character restrictions
                // as the first name field.
                MyTextField(
                  hintText: 'last_name'.tr,
                  errorText: 'only_letters_allowed'.tr,
                  regex: RegExp(r'^[a-zA-Z ]*$'),
                  textController: controller.lastNameController,
                ),

                // National identification code. Accepts letters and numbers.
                MyTextField(
                  hintText: 'national_code'.tr,
                  errorText: 'only_letters_numbers_allowed'.tr,
                  regex: RegExp(r'^[a-zA-Z0-9]*$'),
                  textController: controller.nationalCodeController,
                ),

                // Student identification code assigned by the school.
                MyTextField(
                  hintText: 'student_code'.tr,
                  errorText: 'only_letters_numbers_allowed'.tr,
                  regex: RegExp(r'^[a-zA-Z0-9]*$'),
                  textController: controller.studnetCodeController,      
                ),
                
                // Displays available majors and updates the selected major
                // reactively whenever the user makes a selection.
                Obx(
                  () => MyDropDown<Major>(
                    hint: 'major'.tr,
                    items: controller.majorDropDownItems,
                    value: controller.selectedMajor.value,
                    showItemText: (item) => item.name,
                    fontSize: 15,
                    onChanged: (value) => controller.selectedMajor.value = value,
                    myFocusNode: controller.myFocusNode,
                    context: context,
                  ),
                ),

                const SizedBox(height: 20),

                // Allows the user to select the academic year in which
                // the student will be enrolled.
                Obx(
                  () => MyDropDown<SchoolYear>(
                    hint: 'year'.tr,
                    items: controller.yearDropDownItems,
                    value: controller.selectedYear.value,
                    showItemText: (item) => item.year.toString(),
                    fontSize: 15,
                    onChanged: (value) => controller.selectedYear.value = value,
                    myFocusNode: controller.myFocusNode,
                    context: context,
                  ),
                ),

                const SizedBox(height: 20),

                // Selects the student's grade level.
                // The available options are grades 10, 11, and 12.
                Obx(
                  () => MyDropDown(
                    hint: 'grade_level'.tr,
                    items: [10, 11, 12],
                    value: controller.selectedGradeLevel.value,
                    showItemText: (item) => item.toString(),
                    fontSize: 15,
                    onChanged: (value) => controller.selectedGradeLevel.value = value,
                    myFocusNode: controller.myFocusNode,
                    context: context,
                  ),
                ),

                const SizedBox(height: 20),

                // Optional discount applied to the student's tuition.
                // Only numeric characters are accepted.
                MyTextField(
                  hintText: 'discount'.tr,
                  errorText: 'only_numbers_allowed'.tr,
                  regex: RegExp(r'^\d*$'),
                  textController: controller.discountController,
                ),

                // Validates the form and handles student creation.
                MyElevatedButton(buttonText: 'save'.tr, onPressed: controller.saveStudent),
              ],
            ),
          ),
        );
      },
    );
  }
}