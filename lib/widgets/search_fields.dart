import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/search_fields_controller.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/my_drop_down.dart';
import 'package:school_managment_app/widgets/my_elevated_button.dart';
import 'package:school_managment_app/widgets/my_text_field.dart';

/// Displays the student search panel with text fields and dropdown filters.
class SearchFields extends StatelessWidget {
  // Retrieve the existing search controller registered in GetX.
  final SearchFieldsController controller = Get.find();

  SearchFields({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculate the panel width as 20% of the available screen width.
    final width = (MediaQuery.of(context).size.width * 0.2).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Update the controller's window-size information for responsive behavior.
        controller.checkWindowSize(context);

        return Container(
          width: width,
          // Set the panel height based on screen width, with a maximum of 430 pixels.
          height: (MediaQuery.of(context).size.width * 0.4).clamp(10, 430),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.containerBackgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            // Allow the search panel's contents to scroll when they exceed its height.
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search panel heading.
                  Padding(
                    padding: const EdgeInsets.only(left: 5, bottom: 10),
                    child: SizedBox(
                      width: width / 2,
                      child: Text(
                        'search_students'.tr,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Filter students by first name.
                  // The regular expression allows English letters and spaces only.
                  MyTextField(
                    hintText: 'search_by_name'.tr,
                    errorText: "Only letters are allowed",
                    regex: RegExp(r'^[ a-zA-Z ]*$'),
                    paddingSize: 10,
                    textController: controller.firstNameController,
                    onChanged: (value) =>
                        controller.searchFirstName.value = value,
                  ),

                  // Filter students by last name.
                  // The regular expression allows English letters and spaces only.
                  MyTextField(
                    hintText: 'search_by_lastname'.tr,
                    errorText: "Only letters are allowed",
                    regex: RegExp(r'^[a-zA-Z ]*$'),
                    paddingSize: 10,
                    textController: controller.lastNameController,
                    onChanged: (value) =>
                        controller.searchLastName.value = value,
                  ),

                  // School-year filter. Obx rebuilds the dropdown when its selected value changes.
                  Obx(
                    () => MyDropDown<SchoolYear>(
                      hint: 'year'.tr,
                      items: controller.yearDropDownItems,
                      value: controller.selectedYear.value,
                      showItemText: (item) => item.year.toString(),
                      fontSize: 15,
                      onChanged: (value) =>
                          controller.selectedYear.value = value,
                      myFocusNode: controller.myFocusNode,
                      context: context,
                    ),
                  ),

                  SizedBox(height: 10),

                  // Grade-level filter with the available grade options.
                  Obx(
                    () => MyDropDown(
                      hint: 'grade_level'.tr,
                      items: [10, 11, 12],
                      value: controller.selectedGradeLevel.value,
                      showItemText: (item) => item.toString(),
                      fontSize: 15,
                      onChanged: (value) =>
                          controller.selectedGradeLevel.value = value,
                      myFocusNode: controller.myFocusNode,
                      context: context,
                    ),
                  ),

                  SizedBox(height: 10),

                  // Major filter. The dropdown displays each major's name.
                  Obx(
                    () => MyDropDown<Major>(
                      hint: 'major'.tr,
                      items: controller.majorDropDownItems,
                      value: controller.selectedMajor.value,
                      showItemText: (item) => item.name,
                      fontSize: 15,
                      onChanged: (value) =>
                          controller.selectedMajor.value = value,
                      myFocusNode: controller.myFocusNode,
                      context: context,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Clear all search fields and selected filters.
                  MyElevatedButton(
                    buttonText: 'reset_search'.tr,
                    onPressed: controller.resetFilters,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
