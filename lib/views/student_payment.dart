
import 'package:flutter/material.dart';
import 'package:school_managment_app/controllers/student_payment_controller.dart';
import 'package:school_managment_app/models/payment.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/data_table_widgets.dart';
import 'package:school_managment_app/widgets/my_base_dialog.dart';
import 'package:school_managment_app/widgets/my_data_table.dart';
import 'package:school_managment_app/widgets/my_elevated_button.dart';
import 'package:school_managment_app/widgets/my_text_field.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/widgets/dialog_lifecycle.dart';

/// Displays the payment management dialog for a selected student.
///
/// Allows users to record new payments, edit or delete existing payments,
/// view the remaining tuition balance, and generate a payment report.
class StudentPaymentDialog extends StatelessWidget implements DialogLifecycle {
  /// Manages payment data, form fields, selection, pagination, and payment operations.
  final StudentPaymentController controller = Get.put(
    StudentPaymentController(),
  );

  StudentPaymentDialog({super.key});

  /// Clears the payment form and resets its temporary state.
  @override
  void resetFields() {
    controller.resetFields();
  }

  /// Removes the payment controller when the dialog is closed.
  @override
  void removeController() {
    Get.delete<StudentPaymentController>();
  }

  @override
  Widget build(BuildContext context) {
    const double maxContainerWdith = 1000;

    return LayoutBuilder(
      builder: (context, constraints) {
        return MyBaseDialog(
          title: 'student_payments'.tr,
          maxContainerWdith: maxContainerWdith,
          dialogColor: Theme.of(
            context,
          ).colorScheme.studentPaymentBackgroundColor,
          child: Container(
            constraints: const BoxConstraints(maxWidth: maxContainerWdith),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  // -----------------------------------------------------------------
                  // Payment form
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Payment amount input.
                              // Only numeric characters are accepted.
                              Expanded(
                                child: MyTextField(
                                  hintText: 'payment_amount'.tr,
                                  errorText: 'only_numbers_allowed'.tr,
                                  regex: RegExp(r'^\d*$'),
                                  textController:
                                      controller.paymentAmountController,
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Payment date input.
                              // The field is read-only; tapping it opens a date picker.
                              Expanded(
                                child: MyTextField(
                                  hintText: 'payment_date'.tr,
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: Colors.grey[400],
                                  ),
                                  errorText: 'only_numbers_allowed'.tr,
                                  regex: RegExp(r'^\d*$'),
                                  readOnly: true,
                                  onTap: () async {
                                    DateTime? currentDate;

                                    // Attempts to use the currently entered date
                                    // as the initial date in the date picker.
                                    if (controller
                                        .dateController
                                        .text
                                        .isNotEmpty) {
                                      currentDate = DateTime.tryParse(
                                        controller.dateController.text,
                                      );
                                    }

                                    // Opens the date picker.
                                    DateTime? pickedDate = await selectDate(
                                      context: context,
                                      initialDate: currentDate,
                                    );

                                    // Updates the field if the user selects a date.
                                    // The date is stored in YYYY-MM-DD format.
                                    if (pickedDate != null) {
                                      controller.dateController.text =
                                          pickedDate.toString().split(" ")[0];
                                    }
                                  },
                                  textController: controller.dateController,
                                ),
                              ),
                            ],
                          ),

                          // Optional payment description.
                          // Supports Persian and English letters, numbers, and spaces.
                          MyTextField(
                            hintText: 'payment_description_optional'.tr,
                            errorText: 'only_letters_numbers_allowed'.tr,
                            regex: RegExp(r'^[\u0600-\u06FFa-zA-Z0-9 ]*$'),
                            maxLines: 2,
                            textController: controller.descriptionController,
                          ),

                          // Displays the student's current remaining tuition.
                          // Obx keeps the displayed amount synchronized with changes
                          // to the controller's reactive remainingTuition value.
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Obx(
                              () => Tooltip(
                                message: 'tuition_extra_cost_if_available'.tr,
                                waitDuration: Duration(milliseconds: 300),
                                showDuration: Duration(seconds: 4),
                                verticalOffset: 10,
                                preferBelow: false,
                                child: Text(
                                  //"Remaining Tuition : \$ ${controller.remainingTuition}",
                                  'remaining_tuition'.trParams({
                                    'remaining_tuition': controller
                                        .remainingTuition
                                        .toString(),
                                  }),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),

                          // Payment form actions.
                          Row(
                            textDirection: TextDirection.ltr,
                            children: [
                              // Clears the form fields.
                              Expanded(
                                child: MyElevatedButton(
                                  buttonText: 'reset_fields'.tr,
                                  onPressed: controller.resetFields,
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Applies changes to the currently selected payment.
                              Expanded(
                                child: MyElevatedButton(
                                  buttonText: 'update'.tr,
                                  onPressed: controller.updatePayment,
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Saves a new payment record.
                              Expanded(
                                child: MyElevatedButton(
                                  buttonText: 'save'.tr,
                                  onPressed: controller.savePayment,
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
                  // Student payment table
                  // -----------------------------------------------------------------
                  Expanded(
                    child: MyDataTable<StudentPayment>(
                      title: 'students_payments'.tr,

                      // Defines the payment table columns.
                      // Sorting is enabled for payment amount and payment date.
                      tableHeaders: [
                        {'title': 'id'.tr, 'flex': 5},
                        {
                          'title': 'amount'.tr,
                          'flex': 10,
                          "needSort": true,
                          "sortCompare": (StudentPayment a, StudentPayment b) =>
                              a.paymentAmount.compareTo(b.paymentAmount),
                        },
                        {
                          'title': 'date'.tr,
                          'flex': 9,
                          "needSort": true,
                          "sortCompare": (StudentPayment a, StudentPayment b) =>
                              a.paymentDate.compareTo(b.paymentDate),
                        },
                        {'title': 'description'.tr, 'flex': 12},
                      ],

                      // Pagination configuration and callbacks.
                      rowsPerPage: controller.rowsPerPage,
                      currentPage: controller.currentPage,
                      totalPages: controller.totalPages,
                      onNextPage: controller.loadNextPageData,
                      onPreviousPage: controller.loadPrevoiusPageData,

                      // Supplies the payment records displayed in the table.
                      items: controller.studentPayments,

                      // Builds the cells and actions for each payment row.
                      cellBuilder: (payment, index) => [
                        // Checkbox for selecting or deselecting a payment.
                        // Obx updates the checkbox when the selected payment changes.
                        Obx(() {
                          return Checkbox(
                            value:
                                controller.selectedPayment.value?.id ==
                                payment.id,
                            onChanged: (bool? newValue) {
                              controller.toggleSelection(payment);
                            },
                          );
                        }),

                        const SizedBox(width: 35),

                        // Payment information columns.
                        TableWidgets.tableRowCell(
                          text: index.toString(),
                          flex: 2,
                        ),
                        const SizedBox(width: 20),
                        TableWidgets.tableRowCell(
                          text: payment.paymentAmount.toString(),
                          flex: 3,
                        ),
                        TableWidgets.tableRowCell(
                          text: payment.paymentDate,
                          flex: 4,
                        ),

                        // Displays the payment description with a tooltip.
                        // Shows "Empty" when no description is available.
                        TableWidgets.tableRowCellWithTooltip(
                          text: payment.paymentDescription ?? "Empty",
                          flex: 4,
                        ),

                        const SizedBox(width: 20),

                        // Deletes the corresponding payment.
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
                                controller.deletePayment(context, payment),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],

                      // Generates a report containing the student's payment information.
                      generateReport: TextButton(
                        onPressed: () async {
                          await controller.generateStudentReport(context);
                        },
                        child: Text(
                          'generate_report'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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

/// Opens a date picker and returns the selected date.
///
/// If [initialDate] is not provided, the current date is used.
/// Returns null if the user dismisses the date picker without selecting a date.
Future<DateTime?> selectDate({
  required BuildContext context,
  DateTime? initialDate,
}) async {
  return await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    confirmText: 'select'.tr,
  );
}
