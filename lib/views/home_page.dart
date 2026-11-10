
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/models/student.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/data_table_widgets.dart';
import 'package:school_managment_app/widgets/my_data_table.dart';
import 'package:school_managment_app/widgets/my_pie_chart.dart';
import 'package:school_managment_app/widgets/search_fields.dart';
import 'package:school_managment_app/controllers/data_table_controller.dart';

/// The main dashboard page of the application.
///
/// Displays an overview of student data through a pie chart, provides
/// student search functionality, and presents a paginated table of students.
class HomePage extends StatelessWidget {
  /// Retrieves the existing [DataTableController] instance.
  ///
  /// The controller manages the student table data, pagination,
  /// selected student, and related operations.
  final DataTableController controller = Get.find();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.mainLayoutBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Dashboard overview section containing the student chart
            // and the search fields.
            Row(
              textDirection: TextDirection.ltr,
              children: [
                // Displays a summary of student data as a pie chart.
                Container(
                  width: (MediaQuery.of(context).size.width * 0.43).clamp(10, 700),
                  height: (MediaQuery.of(context).size.width * 0.4).clamp(10, 430),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.containerBackgroundColor,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: MyPieChart(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10),

                // Provides the search interface for finding students.
                Expanded(child: SearchFields()),
              ],
            ),

            // Student table section.
            // Expanded allows the table to occupy the remaining available height.
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return MyDataTable<Student>(
                      height: constraints.maxHeight,
                      title: 'all_students'.tr,

                      // Defines the columns displayed in the student table.
                      // Sorting is enabled for first name and grade level.
                      tableHeaders: [
                        {'title': 'id'.tr, 'flex': 3},
                        {'title': 'first_name'.tr, 'flex': 11, "needSort": true, "sortCompare": (Student a, Student b) => a.firstName.compareTo(b.firstName)},
                        {'title': 'last_name'.tr, 'flex': 10},
                        {'title': 'national_code'.tr, 'flex': 14},
                        {'title': 'major'.tr, 'flex': 8},
                        {'title': 'grade_level'.tr, 'flex': 11, "needSort": true, "sortCompare": (Student a, Student b) => a.grade.compareTo(b.grade)},
                      ],

                      // Pagination configuration and callbacks.
                      rowsPerPage: controller.rowsPerPage,
                      currentPage: controller.currentPage,
                      totalPages: controller.totalPages,
                      onNextPage: controller.loadNextPageData,
                      onPreviousPage: controller.loadPrevoiusPageData,

                      // Supplies the student records currently displayed in the table.
                      items: controller.allStudents,

                      // Builds the cells and actions for each student row.
                      cellBuilder: (student, index) => [
                          // Checkbox for selecting or deselecting a student.
                          // Obx rebuilds the checkbox when the selected student changes.
                          Obx(() {
                            return Checkbox(
                              value: controller.selectedUser.value?.id == student.id,
                              onChanged: (bool? newValue) {
                                controller.toggleSelection(student);
                              },
                            );
                          }),
                        const SizedBox(width: 35),

                        // Student information columns.
                        TableWidgets.tableRowCell(text: index.toString(), flex: 5),
                        TableWidgets.tableRowCell(text: student.firstName, flex: 10),
                        TableWidgets.tableRowCell(text: student.lastName, flex: 10),
                        TableWidgets.tableRowCell(text: student.nationalCode.toString(), flex: 14),
                        TableWidgets.tableRowCell(text: controller.getMajorNameById(student.majorId) , flex: 13),
                        const SizedBox(width: 5),
                        TableWidgets.tableRowCell(text: student.grade.toString(), flex: 8),

                        // Deletes the corresponding student after invoking
                        // the controller's deletion handler.
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size:
                                (MediaQuery.of(context).size.width * 0.04)
                                    .clamp(15, 20),
                            color: Colors.redAccent,
                          ),
                          onPressed: () => controller.deleteStudent(context, student),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 10),
                      ],
                    );
                  }
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}