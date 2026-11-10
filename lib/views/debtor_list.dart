import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/debtor_list_controller.dart';
import 'package:school_managment_app/models/debtor.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/data_table_widgets.dart';
import 'package:school_managment_app/widgets/my_data_table.dart';
import 'package:school_managment_app/widgets/my_drop_down.dart';
import 'package:hugeicons/hugeicons.dart';

/// Displays a paginated list of students with outstanding tuition balances.
///
/// Provides filtering by academic major, school year, and grade level.
/// Each row displays the student's tuition information, including the
/// total amount due, discount, payments made, and remaining balance.
///
/// Also allows users to navigate to individual student payment records
/// and generate student reports.
class DebtorList extends StatelessWidget {
  /// GetX controller responsible for retrieving and managing debtor data,
  /// applying filters, handling pagination, and generating reports.
  final DebtorListController controller = Get.put(DebtorListController());

  DebtorList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the application's main layout background color.
      backgroundColor: Theme.of(context).colorScheme.mainLayoutBackgroundColor,
      // Adapt the data table's height to the available screen space.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(5),
            child: MyDataTable<Debtor>(
              title: 'tuitions'.tr,
              height: constraints.maxHeight,
              headerMaxFontSize: 14,
              headerMinFontSize: 8,
              showLeadingSpace: false,
              // Defines the table columns, their relative widths,
              // and the sorting behavior for supported columns.
              tableHeaders: [
                {'title': 'id'.tr, 'flex': 4},
                {
                  'title': 'full_name'.tr,
                  'flex': 13,
                  "needSort": true,
                  "sortCompare": (Debtor a, Debtor b) =>
                      a.fullName.compareTo(b.fullName),
                },
                {'title': 'major'.tr, 'flex': 10},
                {
                  'title': 'year'.tr,
                  'flex': 9,
                  "needSort": true,
                  "sortCompare": (Debtor a, Debtor b) => controller
                      .getYearTextById(a.yearId)
                      .compareTo(controller.getYearTextById(b.yearId)),
                },
                {
                  'title': 'grade_level'.tr,
                  'flex': 9,
                  "needSort": true,
                  "sortCompare": (Debtor a, Debtor b) =>
                      a.grade.compareTo(b.grade),
                },
                {'title': 'total_tuition'.tr, 'flex': 10},
                {'title': 'discount'.tr, 'flex': 9},
                {'title': 'total_paid'.tr, 'flex': 10},
                {'title': 'remaining'.tr, 'flex': 10},
              ],
              // Pagination configuration and callbacks.
              rowsPerPage: controller.rowsPerPage,
              currentPage: controller.currentPage,
              totalPages: controller.totalPages,
              onNextPage: controller.loadNextPageData,
              onPreviousPage: controller.loadPrevoiusPageData,
              // Supplies the debtor records currently displayed in the table.
              items: controller.allDebtors,

              // Builds the cells for each debtor record.
              // The index is used to display the row number.
              cellBuilder: (debtor, index) => [
                TableWidgets.tableRowCell(text: index.toString(), flex: 2),
                TableWidgets.tableRowCell(
                  text: debtor.fullName,
                  flex: 5,
                  maxFontSize: 15,
                  minFontSize: 8,
                ),

                // Resolve the student's major ID into its corresponding name.
                TableWidgets.tableRowCell(
                  text: controller.getMajorNameById(debtor.majorId),
                  flex: 5,
                  maxFontSize: 15,
                  minFontSize: 8,
                ),

                // Resolve the academic year ID into its displayable year.
                TableWidgets.tableRowCell(
                  text: controller.getYearTextById(debtor.yearId),
                  flex: 4,
                  maxFontSize: 15,
                  minFontSize: 8,
                ),
                TableWidgets.tableRowCell(
                  text: debtor.grade.toString(),
                  flex: 4,
                  maxFontSize: 15,
                  minFontSize: 8,
                ),

                // Display the student's financial information.
                TableWidgets.tableRowCell(
                  text: debtor.totalRequiredPayment.toString(),
                  flex: 4,
                  maxFontSize: 15,
                  minFontSize: 8,
                ),
                TableWidgets.tableRowCell(
                  text: debtor.discount.toString(),
                  flex: 4,
                  maxFontSize: 15,
                  minFontSize: 8,
                ),
                TableWidgets.tableRowCell(
                  text: debtor.totalPaid.toString(),
                  flex: 4,
                  maxFontSize: 15,
                  minFontSize: 8,
                ),
                TableWidgets.tableRowCell(
                  text: debtor.remainingAmount.toString(),
                  flex: 4,
                  maxFontSize: 15,
                  minFontSize: 8,
                ),

                // Opens the payment management page for the selected student.
                SizedBox(
                  width: 60,
                  child: Tooltip(
                    message: 'open_student_payments_page'.tr,
                    waitDuration: Duration(milliseconds: 300),
                    child: IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedMoneyAdd02,
                        size: (MediaQuery.of(context).size.width * 0.04).clamp(
                          15,
                          28,
                        ),
                        color: Colors.green,
                      ),
                      onPressed: () =>
                          controller.openStudentPaymentPage(debtor.id!),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],

              // Filter controls displayed above the table.
              // Each dropdown updates its corresponding filter and reloads
              // the debtor list whenever a new value is selected.
              filterBuilder: Row(
                children: [
                  // Filter debtor records by academic major.
                  Expanded(
                    child: Obx(
                      () => MyDropDown<Major>(
                        hint: 'major'.tr,
                        items: controller.majorDropDownItems,
                        value: controller.selectedMajor.value,
                        showItemText: (item) => item.name,
                        fontSize: 15,
                        onChanged: (value) {
                          // Return to the first page when applying a new filter.
                          controller.currentPage.value = 1;
                          controller.selectedMajor.value = value;
                          controller.loadDebtors(majorId: value!.id);
                        },
                        myFocusNode: controller.myFocusNode,
                        context: context,
                        maxItemListWidth: 240,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filter debtor records by academic year.
                  Expanded(
                    child: Obx(
                      () => MyDropDown<SchoolYear>(
                        hint: 'year'.tr,
                        items: controller.yearDropDownItems,
                        value: controller.selectedYear.value,
                        showItemText: (item) => item.year.toString(),
                        fontSize: 15,
                        onChanged: (value) {
                          controller.currentPage.value = 1;
                          controller.selectedYear.value = value;
                          controller.loadDebtors(yearId: value!.id);
                        },
                        myFocusNode: controller.myFocusNode,
                        context: context,
                        maxItemListWidth: 240,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filter debtor records by grade level.s
                  Expanded(
                    child: Obx(
                      () => MyDropDown(
                        hint: 'grade_level'.tr,
                        items: [10, 11, 12],
                        value: controller.selectedGradeLevel.value,
                        showItemText: (item) => item.toString(),
                        fontSize: 15,
                        onChanged: (value) {
                          controller.currentPage.value = 1;
                          controller.selectedGradeLevel.value = value;
                          controller.loadDebtors(grade: value);
                        },
                        myFocusNode: controller.myFocusNode,
                        context: context,
                        maxItemListWidth: 240,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),

                  // Clear all active filters and restore the default debtor list.
                  TextButton(
                    child: Text(
                      'reset_filters'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => controller.resetFilterFields(),
                  ),
                ],
              ),

              // Generates a report using the current page's context and
              // the report-generation logic implemented in the controller.
              generateReport: TextButton(
                onPressed: () async {
                  await controller.generateStudentReport(context);
                },
                child: Text(
                  'generate_report'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
