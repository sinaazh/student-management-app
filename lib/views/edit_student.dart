import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/edit_student_controller.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/widgets/my_base_dialog.dart';
import 'package:school_managment_app/widgets/my_drop_down.dart';
import 'package:school_managment_app/widgets/my_elevated_button.dart';
import 'package:school_managment_app/widgets/my_text_field.dart';
import 'package:school_managment_app/widgets/dialog_lifecycle.dart';

/// Displays a dialog for editing an existing student's information.
///
/// Allows users to update the student's personal details, academic major,
/// and tuition discount.
///
/// Uses [EditStudentController] to manage the form state, load the existing
/// student information, and save the updated data.
class EditStudentDialog extends StatelessWidget implements DialogLifecycle {
  /// GetX controller responsible for managing the student editing process.
  ///
  /// Registered when the dialog is created and removed when its lifecycle ends.
  final EditStudentController controller = Get.put(EditStudentController());

  EditStudentDialog({super.key});
  
  /// Resets the form fields and selections.
  ///
  /// Called when the dialog needs to be reused for another editing operation.
  @override
  void resetFields() {
    controller.resetFields();
  }

  /// Removes the editing controller from GetX dependency management.
  ///
  /// Prevents the controller from remaining registered after the dialog closes.
  @override
  void removeController() {
    Get.delete<EditStudentController>();
  }

  @override
  Widget build(BuildContext context) {
    // Maximum width allowed for the dialog's content.
    const double maxContainerWdith = 600;
    // Populate the form fields with the currently selected student's data.
    controller.setFields();
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update responsive layout settings based on the available window size.
        controller.checkWindowSize(context);
        return MyBaseDialog(
          title: 'edit_student'.tr,
          maxContainerWdith: maxContainerWdith,
          child: Container(
            width: constraints.maxWidth,
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

                // National identification code.
                // Accepts letters and numbers.
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

                // Displays the available academic majors.
                // The selected value is managed reactively through GetX.
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

                // Updates the discount applied to the student's tuition.
                // Only numeric characters are accepted.
                MyTextField(
                  hintText: 'discount'.tr,
                  errorText: 'only_numbers_allowed'.tr,
                  regex: RegExp(r'^\d*$'),
                  textController: controller.discountController,
                ),

                // Validates the form and saves the updated student information.
                MyElevatedButton(
                  buttonText: 'save'.tr,
                  onPressed: controller.saveStudent,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}