import 'package:flutter/material.dart';
import 'package:school_managment_app/controllers/extra_cost_controller.dart';
import 'package:school_managment_app/models/extra_cost.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/data_table_widgets.dart';
import 'package:school_managment_app/widgets/dialog_lifecycle.dart';
import 'package:school_managment_app/widgets/my_base_dialog.dart';
import 'package:school_managment_app/widgets/my_data_table.dart';
import 'package:school_managment_app/widgets/my_drop_down.dart';
import 'package:school_managment_app/widgets/my_elevated_button.dart';
import 'package:school_managment_app/widgets/my_text_field.dart';
import 'package:get/get.dart';

/// Displays a dialog for managing additional school fees.
///
/// Provides functionality to create, edit, view, filter, and delete
/// additional cost records.
///
/// Each additional cost is associated with an academic year, major,
/// and grade level. The dialog also provides a paginated table for
/// displaying and managing existing records.
///
/// Uses [ExtraCostController] to manage form state, record selection,
/// filtering, pagination, and database operations.
class ExtraCosts extends StatelessWidget implements DialogLifecycle{
  /// GetX controller responsible for managing additional cost records
  /// and handling all related operations.
  final ExtraCostController controller = Get.put(
    ExtraCostController(),
  );
  
  ExtraCosts({super.key});

  /// Resets the form fields and selected record.
  ///
  /// Called when the dialog needs to be reused for another operation.
  @override
  void removeController() {
  }

  /// Removes the controller from GetX dependency management
  /// when the dialog is closed.
  @override
  void resetFields() {
    Get.delete<ExtraCostController>();
  }

  @override
  Widget build(BuildContext context) {
    // Maximum width allowed for the dialog.
    const double maxContainerWdith = 1000;
    return LayoutBuilder(
      builder: (context, constraints) {
        return MyBaseDialog(
          title: 'extra_cost'.tr,
          maxContainerWdith: maxContainerWdith,
          // Use a dedicated background color for the additional costs dialog.
          dialogColor: Theme.of(
            context,
          ).colorScheme.studentPaymentBackgroundColor,
          child: Container(
            // Limit the dialog height to 80% of the available screen height.
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(maxWidth: maxContainerWdith),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------------------------------------------------------
                // ADDITIONAL COST FORM
                // ---------------------------------------------------------

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
                        // Amount and description of the additional cost.
                        Row(
                          children: [
                            // Additional cost amount. Only numeric characters
                            // are accepted.
                            Expanded(
                              child: MyTextField(
                                hintText: 'extra_cost_amount'.tr,
                                errorText: 'only_numbers_allowed'.tr,
                                regex: RegExp(r'^\d*$'),
                                textController: controller.extraCostAmountController,
                              ),
                            ),
                            SizedBox(width: 10),

                            // Optional description of the additional cost.
                            // Accepts Persian and English letters, numbers,
                            // and spaces.
                            Expanded(
                              child: MyTextField(
                                hintText: 'extra_cost_description_optional'.tr,
                                errorText: 'only_letters_numbers_allowed'.tr,
                                regex: RegExp(r'^[\u0600-\u06FFa-zA-Z0-9 ]*$'),
                                maxLines: 2,
                                textController: controller.descriptionController,
                              ),
                            ),
                          ],
                        ),
                        // Academic information associated with the cost.
                        Row(
                          children: [
                            // Selects the major to which the additional cost applies.
                            //
                            // The dropdown becomes disabled when an existing
                            // record is selected for editing.
                            Expanded(
                              child: Obx(
                                () => IgnorePointer(
                                  ignoring:
                                      controller.selectedExtraCost.value == null
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

                            // Selects the academic year associated with the cost.
                            // Locked while an existing record is selected.
                            Expanded(
                              child: Obx(
                                () => IgnorePointer(
                                  ignoring:
                                      controller.selectedExtraCost.value == null
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
                            
                            // Selects the grade level to which the cost applies.
                            // Locked while an existing record is selected.
                            Expanded(
                              child: Obx(
                                () => IgnorePointer(
                                  ignoring:
                                      controller.selectedExtraCost.value == null
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

                        // Form actions:
                        // Reset clears the current form and selection.
                        // Update modifies the currently selected record.
                        // Save creates a new additional cost record.
                        Row(
                          textDirection: TextDirection.ltr,
                          children: [
                            Expanded(
                              child: MyElevatedButton(
                                buttonText: 'reset_fields'.tr,
                                onPressed: controller.resetFields,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MyElevatedButton(
                                buttonText: 'update'.tr,
                                onPressed: controller.updateCost,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MyElevatedButton(
                                buttonText: 'save'.tr,
                                onPressed: controller.saveCost,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ---------------------------------------------------------
                // ADDITIONAL COSTS TABLE
                // ---------------------------------------------------------

                // Displays existing additional cost records with pagination,
                // sorting, filtering, selection, and deletion capabilities.
                Expanded(
                  child: MyDataTable<ExtraCost>(
                    title: 'extra_costs'.tr,
                    // Defines the table columns and sorting behavior.
                    tableHeaders: [
                      {'title': 'id'.tr, 'flex': 4},
                      {'title': 'amount'.tr, 'flex': 10, "needSort": true, "sortCompare": (ExtraCost a, ExtraCost b) => a.price.compareTo(b.price)},
                      {'title': 'major'.tr, 'flex': 9},
                      {'title': 'grade_level'.tr, 'flex': 7},
                      {'title': 'year'.tr, 'flex': 8, "needSort": true, "sortCompare": (ExtraCost a, ExtraCost b) => controller.getYearTextById(a.yearId).compareTo(controller.getYearTextById(b.yearId))},
                      {'title': 'description'.tr, 'flex': 12},
                    ],
                    // Pagination configuration and navigation callbacks.
                    rowsPerPage: controller.rowsPerPage,
                    currentPage: controller.currentPage,
                    totalPages: controller.totalPages,
                    onNextPage: controller.loadNextPageData,
                    onPreviousPage: controller.loadPrevoiusPageData,
                    // Supplies the additional cost records displayed in the table.
                    items: controller.allExtraCosts,

                    // Builds the table cells for each additional cost record.
                    cellBuilder: (extraCost, index) => [
                      // Checkbox for selecting a record to edit.
                      // The selected state is determined by comparing record IDs.
                      Obx(() {
                        return Checkbox(
                          value:
                              controller.selectedExtraCost.value?.id ==
                              extraCost.id,
                          onChanged: (bool? newValue) {
                            controller.toggleSelection(extraCost);
                          },
                        );
                      }),
                      const SizedBox(width: 35),
                      TableWidgets.tableRowCell(
                        text: index.toString(),
                        flex: 2,
                      ),
                      // Additional cost amount.
                      const SizedBox(width: 20),
                      TableWidgets.tableRowCell(
                        text: extraCost.price.toString(),
                        flex: 3,
                      ),
                      // Resolve the major ID into its corresponding name.
                      const SizedBox(width: 10),
                      TableWidgets.tableRowCell(
                        text: controller.getMajorNameById(extraCost.majorId),
                        flex: 5,
                      ),
                      // Grade level associated with the additional cost.
                      const SizedBox(width: 5),
                      TableWidgets.tableRowCell(
                        text: extraCost.grade.toString(),
                        flex: 3,
                      ),
                      // Resolve the academic year ID into its displayable year.
                      TableWidgets.tableRowCell(
                        text: controller.getYearTextById(extraCost.yearId),
                        flex: 3,
                      ),
                      // Display the description.
                      // A localized placeholder is shown when no description exists.
                      TableWidgets.tableRowCellWithTooltip(
                        text: extraCost.description ?? 'empty'.tr,
                        flex: 5,
                      ),
                      const SizedBox(width: 20),

                      // Deletes the corresponding additional cost record.
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
                              controller.deleteTuition(context, extraCost),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                    // -----------------------------------------------------
                    // TABLE FILTERS
                    // -----------------------------------------------------

                    // Allows users to filter additional cost records
                    // by major, academic year, and grade level.
                    filterBuilder: Row(
                      children: [
                        // Filter records by academic major.
                        Expanded(
                          child: Obx(
                            () => MyDropDown<Major>(
                              hint: 'major'.tr,
                              items: controller.majorDropDownItems,
                              value: controller.filterSelectedMajor.value,
                              showItemText: (item) => item.name,
                              fontSize: 15,
                              onChanged: (value){
                                controller.currentPage.value = 1;
                                controller.filterSelectedMajor.value = value;
                                controller.loadExtraCosts(majorId: value!.id);
                              },
                              myFocusNode: controller.myFocusNode,
                              context: context,
                              maxItemListWidth: 240,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Filter records by academic year.
                        Expanded(
                          child: Obx(
                            () => MyDropDown<SchoolYear>(
                              hint: 'year'.tr,
                              items: controller.yearDropDownItems,
                              value: controller.filterSelectedYear.value,
                              showItemText: (item) => item.year.toString(),
                              fontSize: 15,
                              onChanged: (value){
                                controller.currentPage.value = 1;
                                controller.filterSelectedYear.value = value;
                                controller.loadExtraCosts(yearId: value!.id);
                              },
                              myFocusNode: controller.myFocusNode,
                              context: context,
                              maxItemListWidth: 240,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Filter records by grade level.
                        Expanded(
                          child: Obx(
                            () => MyDropDown(
                              hint: 'grade_level'.tr,
                              items: [10, 11, 12],
                              value: controller.filterSelectedGrade.value,
                              showItemText: (item) => item.toString(),
                              fontSize: 15,
                              onChanged: (value){
                                controller.currentPage.value = 1;
                                controller.filterSelectedGrade.value = value;
                                controller.loadExtraCosts(grade: value);
                              },
                              myFocusNode: controller.myFocusNode,
                              context: context,
                              maxItemListWidth: 240,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),

                        // Clears all active filters and restores the default list.
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