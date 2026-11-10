import 'dart:math' as math;
// import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_managment_app/controllers/pie_chart_controller.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/utils/pie_chart_colors.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/widgets/my_drop_down.dart';

/// Displays student payment statistics in a doughnut-style pie chart.
///
/// The chart shows the distribution of fully paid, partially paid,
/// and unpaid students. It also provides filters for major, school year,
/// and grade level.
class MyPieChart extends StatelessWidget {
  /// Controller responsible for loading payment statistics,
  /// managing filter selections, and maintaining chart data.
  final PieChartController controller = Get.find();

  MyPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculates chart dimensions based on the available space.
        // Using the smaller constraint keeps the chart proportional
        // when its parent has different width and height values.
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final baseRadius = size * 0.15;
        final centerRadius = size * 0.25;

        // Scales the center text according to the chart's available size.
        final fontSizeNumber = size * 0.12; // 12% of chart width
        final fontSizeLabel = size * 0.045; // 6% of chart width

        // Rebuilds the chart whenever its reactive controller values change.
        return Obx(() {
          // Displays a loading indicator while payment statistics are being loaded.
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 4,
              ),
            );
          }

          return Column(
            children: [
              // Chart title and filter controls.
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous implementation using AutoSizeText.
                    // AutoSizeText(
                    //   'payment_statistics'.tr,
                    //   style: TextStyle(
                    //     color: Theme.of(context).colorScheme.primary,
                    //     fontSize: 17,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    //   maxLines: 1,
                    //   minFontSize: 6,
                    //   overflow: TextOverflow.ellipsis,
                    // ),

                    // Displays the localized chart title.
                    Text(
                      'payment_statistics'.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      // minFontSize: 6,
                      overflow: TextOverflow.ellipsis,
                    ),

                    Row(
                      children: [
                        // Resets the selected filters to their default values.
                        IconButton(
                          icon: Icon(Icons.refresh),
                          iconSize: 20,
                          onPressed: () => controller.resetFilterFields(),
                        ),
                        SizedBox(width: 10),

                        // Toggles the visibility of the chart filters.
                        GestureDetector(
                          onTap: () => controller.showFilters.value =
                              !controller.showFilters.value,
                          child: Obx(
                            () => Text(
                              controller.showFilters.value
                                  ? 'hide_filters'.tr
                                  : 'show_filters'.tr,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              // minFontSize: 6,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Previous implementation using AutoSizeText.
                            // () => AutoSizeText(
                            //   controller.showFilters.value ? 'hide_filters'.tr : 'show_filters'.tr,
                            //   style: TextStyle(
                            //     color: Theme.of(context).colorScheme.primary,
                            //     fontSize: 15,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            //   maxLines: 1,
                            //   minFontSize: 6,
                            //   overflow: TextOverflow.ellipsis,
                            // ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expands or collapses the filter section with an animation.
              Obx(
                () => AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: buildFilters(
                      controller: controller,
                      context: context,
                    ),
                  ),
                  crossFadeState: controller.showFilters.value
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ),

              // Pie chart and its central student count.
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        // Removes spacing between the chart sections.
                        sectionsSpace: 0,

                        // Sets the starting angle of the chart sections.
                        startDegreeOffset: 220,

                        // Creates the empty space in the center of the doughnut chart.
                        centerSpaceRadius: centerRadius,

                        // Defines the three payment-status sections.
                        sections: [
                          // Students who have fully paid their tuition.
                          PieChartSectionData(
                            value: controller.fullyPaid.value,
                            gradient: const LinearGradient(
                              colors: fullyPaidGradient,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            radius: baseRadius * 1.2,
                            showTitle: false,
                          ),

                          // Students who have partially paid their tuition.
                          PieChartSectionData(
                            value: controller.partiallyPaid.value,
                            gradient: const LinearGradient(
                              colors: partiallyPaidGradient,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            radius: baseRadius * 1.0,
                            showTitle: false,
                          ),

                          // Students who have not paid their tuition.
                          PieChartSectionData(
                            value: controller.notPaid.value,
                            gradient: const LinearGradient(
                              colors: notPaidGradient,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            radius: baseRadius * 0.8,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),

                    // Displays the total number of students in the center
                    // of the doughnut chart.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.allStudentsCount.toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: fontSizeNumber,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          // minFontSize: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'students'.tr,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: fontSizeLabel,
                          ),
                          maxLines: 1,
                          // minFontSize: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Previous implementation using AutoSizeText.
                        // AutoSizeText(
                        //   controller.allStudentsCount.toString(),
                        //   style: TextStyle(
                        //     color: Theme.of(context).colorScheme.primary,
                        //     fontSize: fontSizeNumber,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        //   maxLines: 1,
                        //   minFontSize: 2,
                        //   overflow: TextOverflow.ellipsis,
                        // ),
                        // AutoSizeText(
                        //   'students'.tr,
                        //   style: TextStyle(
                        //     color: Colors.grey,
                        //     fontSize: fontSizeLabel,
                        //   ),
                        //   maxLines: 1,
                        //   minFontSize: 2,
                        //   overflow: TextOverflow.ellipsis,
                        // ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 5),

              // Displays the payment-status legend below the chart.
              // Each entry includes its gradient indicator, localized label,
              // and corresponding percentage value.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: pieChartHint(
                      size: size,
                      textColor: Theme.of(context).colorScheme.primary,
                      color: fullyPaidGradient,
                      paidStatus: 'fully_paid',
                      paidPercentage: "${controller.fullyPaid.value} %",
                    ),
                  ),
                  Expanded(
                    child: pieChartHint(
                      size: size,
                      textColor: Theme.of(context).colorScheme.primary,
                      color: partiallyPaidGradient,
                      paidStatus: 'partially_paid',
                      paidPercentage: "${controller.partiallyPaid.value} %",
                    ),
                  ),
                  Expanded(
                    child: pieChartHint(
                      size: size,
                      textColor: Theme.of(context).colorScheme.primary,
                      color: notPaidGradient,
                      paidStatus: 'not_paid',
                      paidPercentage: "${controller.notPaid.value} %",
                    ),
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }
}

/// Builds an individual legend entry for the payment-status chart.
///
/// Displays a colored gradient indicator, a localized payment-status label,
/// and its corresponding percentage. A tooltip provides the complete
/// payment status and percentage when the entry is hovered over.
Widget pieChartHint({
  required double size,
  required Color textColor,
  required List<Color> color,
  required String paidStatus,
  required String paidPercentage,
}) {
  return Tooltip(
    message: "${paidStatus.tr} $paidPercentage",
    waitDuration: Duration(milliseconds: 300),
    verticalOffset: -50,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Circular indicator using the gradient of the corresponding chart section.
        Container(
          width: size * 0.03,
          height: size * 0.03,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: color,
            ),
          ),
        ),
        const SizedBox(width: 5),

        // Displays the localized payment-status label.
        Flexible(
          child: Text(
            paidStatus.tr,
            style: TextStyle(color: textColor, fontSize: size * 0.035),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Previous implementation using AutoSizeText.
          // child: AutoSizeText(
          //   paidStatus.tr,
          //   style: TextStyle(color: textColor, fontSize: size * 0.035),
          //   maxLines: 1,
          //   minFontSize: 6,
          //   overflow: TextOverflow.ellipsis,
          // ),
        ),
        const SizedBox(width: 7),

        // Displays the percentage associated with the payment status.
        Text(
          paidPercentage,
          style: TextStyle(color: textColor, fontSize: size * 0.04),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Previous implementation using AutoSizeText.
        // AutoSizeText(
        //   paidPercentage,
        //   style: TextStyle(color: textColor, fontSize: size * 0.04),
        //   maxLines: 1,
        //   minFontSize: 1,
        //   overflow: TextOverflow.ellipsis,
        // ),
      ],
    ),
  );
}

/// Builds the filter controls used to narrow down student payment statistics.
///
/// Provides dropdowns for selecting a major, school year, and grade level.
/// Changing a filter updates the selected value and reloads the chart data
/// using the selected filter.
Widget buildFilters({
  required PieChartController controller,
  required BuildContext context,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 40),
    child: Row(
      children: [
        // Major filter.
        Expanded(
          child: Obx(
            () => MyDropDown<Major>(
              hint: 'major'.tr,
              items: controller.majorDropDownItems,
              value: controller.selectedMajor.value,
              showItemText: (item) => item.name,
              fontSize: 15,
              onChanged: (value) {
                // Updates the selected major and reloads payment statistics.
                controller.selectedMajor.value = value;
                controller.loadStudentPaymentStatus(majorId: value!.id);
              },
              myFocusNode: controller.myFocusNode,
              context: context,
              maxItemListWidth: 240,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // School year filter.
        Expanded(
          child: Obx(
            () => MyDropDown<SchoolYear>(
              hint: 'year'.tr,
              items: controller.yearDropDownItems,
              value: controller.selectedYear.value,
              showItemText: (item) => item.year.toString(),
              fontSize: 15,
              onChanged: (value) {
                // Updates the selected school year and reloads payment statistics.
                controller.selectedYear.value = value;
                controller.loadStudentPaymentStatus(yearId: value!.id);
              },
              myFocusNode: controller.myFocusNode,
              context: context,
              maxItemListWidth: 240,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Grade-level filter.
        Expanded(
          child: Obx(
            () => MyDropDown(
              hint: 'grade_level'.tr,
              items: [10, 11, 12],
              value: controller.selectedGradeLevel.value,
              showItemText: (item) => item.toString(),
              fontSize: 15,
              onChanged: (value) {
                // Updates the selected grade and reloads payment statistics.
                controller.selectedGradeLevel.value = value;
                controller.loadStudentPaymentStatus(grade: value);
              },
              myFocusNode: controller.myFocusNode,
              context: context,
              maxItemListWidth: 240,
            ),
          ),
        ),
      ],
    ),
  );
}
