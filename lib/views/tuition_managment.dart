
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/tuition_managment_controller.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/models/tuition.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/data_table_widgets.dart';
import 'package:school_managment_app/widgets/dialog_lifecycle.dart';
import 'package:school_managment_app/widgets/my_base_dialog.dart';
import 'package:school_managment_app/widgets/my_data_table.dart';
import 'package:school_managment_app/widgets/my_text_field.dart';
import 'package:school_managment_app/widgets/my_drop_down.dart';
import 'package:school_managment_app/widgets/my_elevated_button.dart';

/// Displays the tuition management dialog.
///
/// Allows users to define tuition fees for specific majors, school years,
/// and grade levels, as well as view, edit, filter, and delete tuition records.
class TuitionManagment extends StatelessWidget implements DialogLifecycle {
  /// Manages tuition records, form fields, selection, filtering, and pagination.
  final TuitionManagmentController controller = Get.put(
    TuitionManagmentController(),
  );

  TuitionManagment({super.key});

  /// No additional controller cleanup is performed here.
  @override
  void removeController() {
  }

  /// Removes the tuition management controller.
  @override
  void resetFields() {
    Get.delete<TuitionManagmentController>();
  }

  @override
  Widget build(BuildContext context) {
    const double maxContainerWdith = 900;

    return LayoutBuilder(
      builder: (context, constraints) {
        return MyBaseDialog(
          title: 'tuition_management'.tr,
          maxContainerWdith: maxContainerWdith,
          dialogColor: Theme.of(
            context,
          ).colorScheme.studentPaymentBackgroundColor,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(maxWidth: maxContainerWdith),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -----------------------------------------------------------------
                // Tuition form
                // -----------------------------------------------------------------
                Container(
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.containerBackgroundColor,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(66, 70, 69, 69),
                        blurRadius: 15.0,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        // Input field for the tuition amount.
                        // Only numeric characters are accepted.
                        MyTextField(
                          hintText: 'tuition_amount'.tr,
                          errorText: 'only_numbers_allowed'.tr,
                          regex: RegExp(r'^\d*$'),
                          textController: controller.tuitionAmountController,
                        ),

                        // Selects the major, school year, and grade level
                        // associated with the tuition record.
                        Row(
                          children: [
                            // Major selection.
                            // The dropdown is disabled while an existing tuition
                            // record is selected for editing.
                            Expanded(
                              child: Obx(
                                () => IgnorePointer(
                                  ignoring:
                                      controller.selectedTuition.value == null
                                      ? false
                                      : true,
                                  child: MyDropDown<Major>(
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
                              ),
                            ),

                            const SizedBox(width: 10),

                            // School year selection.
                            // Disabled while editing an existing tuition record.
                            Expanded(
                              child: Obx(
                                () => IgnorePointer(
                                  ignoring:
                                      controller.selectedTuition.value == null
                                      ? false
                                      : true,
                                  child: MyDropDown<SchoolYear>(
                                    hint: 'year'.tr,
                                    items: controller.yearDropDownItems,
                                    value: controller.selectedYear.value,
                                    showItemText: (item) =>
                                        item.year.toString(),
                                    fontSize: 15,
                                    onChanged: (value) =>
                                        controller.selectedYear.value = value,
                                    myFocusNode: controller.myFocusNode,
                                    context: context,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Grade level selection.
                            // Disabled while editing an existing tuition record.
                            Expanded(
                              child: Obx(
                                () => IgnorePointer(
                                  ignoring:
                                      controller.selectedTuition.value == null
                                      ? false
                                      : true,
                                  child: MyDropDown(
                                    hint: 'grade_level'.tr,
                                    items: [10, 11, 12],
                                    value: controller.selectedGradeLevel.value,
                                    showItemText: (item) => item.toString(),
                                    fontSize: 15,
                                    onChanged: (value) =>
                                        controller.selectedGradeLevel.value =
                                            value,
                                    myFocusNode: controller.myFocusNode,
                                    context: context,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Form actions.
                        Row(
                          textDirection: TextDirection.ltr,
                          children: [
                            // Clears the form fields and resets the form state.
                            Expanded(
                              child: MyElevatedButton(
                                buttonText: 'reset_fields'.tr,
                                onPressed: controller.resetFields,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Updates the currently selected tuition record.
                            Expanded(
                              child: MyElevatedButton(
                                buttonText: 'update'.tr,
                                onPressed: controller.updateTuition,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Saves a new tuition record.
                            Expanded(
                              child: MyElevatedButton(
                                buttonText: 'save'.tr,
                                onPressed: controller.saveTuition,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // -----------------------------------------------------------------
                // Tuition records table
                // -----------------------------------------------------------------
                Expanded(
                  child: MyDataTable<Tuition>(
                    title: 'tuitions'.tr,

                    // Defines the table columns.
                    // Sorting is enabled for tuition amount and school year.
                    tableHeaders: [
                      {'title': 'id'.tr, 'flex': 5},
                      {'title': 'amount'.tr, 'flex': 10, "needSort": true, "sortCompare": (Tuition a, Tuition b) => a.price.compareTo(b.price)},
                      {'title': 'major'.tr, 'flex': 9},
                      {'title': 'grade_level'.tr, 'flex': 10},
                      {'title': 'year'.tr, 'flex': 9, "needSort": true, "sortCompare": (Tuition a, Tuition b) => controller.getYearTextById(a.yearId).compareTo(controller.getYearTextById(b.yearId))},
                    ],

                    // Pagination configuration and callbacks.
                    rowsPerPage: controller.rowsPerPage,
                    currentPage: controller.currentPage,
                    totalPages: controller.totalPages,
                    onNextPage: controller.loadNextPageData,
                    onPreviousPage: controller.loadPrevoiusPageData,

                    // Supplies the tuition records currently displayed in the table.
                    items: controller.allTuitions,

                    // Builds the cells and actions for each tuition row.
                    cellBuilder: (tuition, index) => [
                      // Checkbox for selecting or deselecting a tuition record.
                      // Obx updates the checkbox when the selected record changes.
                      Obx(() {
                        return Checkbox(
                          value:
                              controller.selectedTuition.value?.id ==
                              tuition.id,
                          onChanged: (bool? newValue) {
                            controller.toggleSelection(tuition);
                          },
                        );
                      }),

                      const SizedBox(width: 35),

                      // Tuition record information.
                      TableWidgets.tableRowCell(
                        text: index.toString(),
                        flex: 2,
                      ),
                      TableWidgets.tableRowCell(
                        text: tuition.price.toString(),
                        flex: 3,
                      ),

                      // Resolves the major ID into its corresponding major name.
                      TableWidgets.tableRowCell(
                        text: controller.getMajorNameById(tuition.majorId),
                        flex: 4,
                      ),

                      const SizedBox(width: 10),

                      TableWidgets.tableRowCell(
                        text: tuition.grade.toString(),
                        flex: 3,
                      ),

                      // Resolves the school year ID into its display value.
                      TableWidgets.tableRowCell(
                        text: controller.getYearTextById(tuition.yearId),
                        flex: 3,
                      ),

                      const SizedBox(width: 20),

                      // Deletes the corresponding tuition record.
                      SizedBox(
                        width: 60,
                        child: IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: (MediaQuery.of(context).size.width * 0.04)
                                .clamp(15, 20),
                            color: Colors.redAccent,
                          ),
                          onPressed: () =>
                              controller.deleteTuition(context, tuition),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],

                    // -----------------------------------------------------------------
                    // Tuition table filters
                    // -----------------------------------------------------------------
                    filterBuilder: Row(
                      children: [
                        // Filters tuition records by major.
                        Expanded(
                          child: Obx(
                            () => MyDropDown<Major>(
                              hint: 'major'.tr,
                              items: controller.majorDropDownItems,
                              value: controller.filterSelectedMajor.value,
                              showItemText: (item) => item.name,
                              fontSize: 15,
                              onChanged: (value){
                                // Return to the first page when the filter changes.
                                controller.currentPage.value = 1;
                                controller.filterSelectedMajor.value = value;
                                controller.loadTuitions(majorId: value!.id);
                              },
                              myFocusNode: controller.myFocusNode,
                              context: context,
                              maxItemListWidth: 240,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Filters tuition records by school year.
                        Expanded(
                          child: Obx(
                            () => MyDropDown<SchoolYear>(
                              hint: 'year'.tr,
                              items: controller.yearDropDownItems,
                              value: controller.filterSelectedYear.value,
                              showItemText: (item) => item.year.toString(),
                              fontSize: 15,
                              onChanged: (value){
                                // Return to the first page when the filter changes.
                                controller.currentPage.value = 1;
                                controller.filterSelectedYear.value = value;
                                controller.loadTuitions(yearId: value!.id);
                              },
                              myFocusNode: controller.myFocusNode,
                              context: context,
                              maxItemListWidth: 240,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Filters tuition records by grade level.
                        Expanded(
                          child: Obx(
                            () => MyDropDown(
                              hint: 'grade_level'.tr,
                              items: [10, 11, 12],
                              value: controller.filterSelectedGrade.value,
                              showItemText: (item) => item.toString(),
                              fontSize: 15,
                              onChanged: (value){
                                // Return to the first page when the filter changes.
                                controller.currentPage.value = 1;
                                controller.filterSelectedGrade.value = value;
                                controller.loadTuitions(grade: value);
                              },
                              myFocusNode: controller.myFocusNode,
                              context: context,
                              maxItemListWidth: 240,
                            ),
                          ),
                        ),

                        const SizedBox(width: 5),

                        // Clears the active filters and restores the unfiltered table.
                        TextButton(
                          child : Text(
                            'reset_filters'.tr,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          onPressed: () => controller.resetFilterFields(),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}