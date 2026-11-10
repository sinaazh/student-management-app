import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/data_table_widgets.dart';

/// Builds the list of widgets used to display an individual table row.
///
/// [T] represents the data model of each table item.
/// The [index] is the item's position in the overall paginated dataset.
typedef RowCellBuilder<T> = List<Widget> Function(T item, int index);

/// Callback invoked when a table header is pressed.
typedef SortCallback = void Function(String headerTitle);

/// Represents the current sorting direction of a table column.
enum SortState { asc, desc }

/// A reusable, generic data table widget with sorting, filtering,
/// pagination, and optional report generation.
///
/// The table uses GetX reactive variables to update its contents and
/// pagination controls when the underlying data changes.
class MyDataTable<T> extends StatelessWidget {
  /// Title displayed at the top of the table.
  final String title;

  /// Optional height of the table container.
  final double? height;

  /// Maximum and minimum font sizes used for table headers.
  final double headerMaxFontSize;
  final double headerMinFontSize;

  /// Determines whether to display additional spacing before the first column.
  final bool showLeadingSpace;

  /// Configuration for the table columns.
  ///
  /// Each header map can contain properties such as:
  /// - `title`: Column title.
  /// - `flex`: Horizontal space allocation.
  /// - `needSort`: Indicates whether sorting is enabled.
  /// - `sortCompare`: Comparison function used to sort the column.
  /// - `padding`: Optional header cell padding.
  final List<Map<String, dynamic>> tableHeaders;

  /// Reactive list containing the records displayed in the table.
  final RxList<T> items;

  /// Builds the cells for an individual row.
  final RowCellBuilder<T> cellBuilder;

  /// Optional widget for generating or exporting a report.
  final Widget? generateReport;

  /// Optional widget containing the table's filtering controls.
  final Widget? filterBuilder;

  /// Optional callback for handling table header presses.
  final SortCallback? onHeaderPressed;

  /// Callbacks used to navigate between pages.
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;

  /// Controls whether the filter section is currently visible.
  final RxBool showFilters = false.obs;

  /// Stores the sorting configuration for each sortable column.
  ///
  /// Each entry contains the current [SortState] and a reactive boolean
  /// indicating which sorting direction icon should be displayed.
  final Map<String, Map<String, dynamic>> columnSortStates = {};

  // Pagination

  /// Current page displayed in the table.
  final RxInt currentPage;

  /// Total number of available pages.
  final RxInt totalPages;

  /// Maximum number of records displayed per page.
  final int rowsPerPage;

  MyDataTable({
    super.key,
    required this.title,
    required this.tableHeaders,
    required this.items,
    required this.cellBuilder,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.onNextPage,
    required this.onPreviousPage,
    this.generateReport,
    this.filterBuilder,
    this.onHeaderPressed,
    this.height = 510,
    this.showLeadingSpace = true,
    this.headerMaxFontSize = 20,
    this.headerMinFontSize = 14,
  }) {
    // Initialize sorting information for columns that provide both
    // a sorting flag and a comparison function.
    for (var header in tableHeaders) {
      if (header["needSort"] != null && header["sortCompare"] != null) {
        columnSortStates[header['title']] = {
          "status": SortState.asc,
          "iconStatus": true.obs,
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieves the active color scheme for styling the table.
    final theme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.containerBackgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(66, 147, 146, 146),
            blurRadius: 15.0,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section containing the table title, report action,
            // and optional filter visibility control.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Displays the report widget when no filter widget is provided.
                if (generateReport != null && filterBuilder == null)
                  generateReport!,
                Row(
                  children: [
                    if (generateReport != null) generateReport!,

                    SizedBox(width: 10),

                    // Toggles the visibility of the filter section.
                    if (filterBuilder != null)
                      Obx(
                        () => TextButton(
                          child: Text(
                            showFilters.value
                                ? 'hide_filters'.tr
                                : 'show_filters'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () =>
                              showFilters.value = !showFilters.value,
                        ),
                      ),
                  ],
                ),
                // Previous filter button implementation.
                // if (filterBuilder != null)
                //   Obx(
                //     () => TextButton(
                //       child: Text(
                //         showFilters.value
                //             ? 'hide_filters'.tr
                //             : 'show_filters'.tr,
                //         style: TextStyle(
                //           fontSize: 16,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //       onPressed: () => showFilters.value = !showFilters.value,
                //     ),
                //   ),
              ],
            ),

            // Expands or collapses the filter section with an animation.
            if (filterBuilder != null)
              Obx(
                () => AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: filterBuilder!,
                  ),
                  crossFadeState: showFilters.value
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ),

            const SizedBox(height: 16),

            // Table header containing the configured column titles
            // and their corresponding sorting controls.
            Container(
              decoration: BoxDecoration(
                color: theme.dataTableRowColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10.0),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              child: Row(
                children: [
                  // Reserves space for leading row controls, such as checkboxes.
                  if (showLeadingSpace) const SizedBox(width: 72),

                  ...tableHeaders.take(tableHeaders.length).map((header) {
                    return Expanded(
                      flex: header['flex'],
                      child: GestureDetector(
                        onTap: () {
                          // Sorting is enabled only when the column provides
                          // both a sorting flag and a comparison function.
                          if (header["needSort"] != null &&
                              header["sortCompare"] != null) {
                            // Toggle the sorting direction and update
                            // the corresponding arrow icon.
                            switch (columnSortStates[header['title']]!["status"]) {
                              case SortState.asc:
                                columnSortStates[header['title']]!["status"] =
                                    SortState.desc;
                                columnSortStates[header['title']]!["iconStatus"]
                                        .value =
                                    false;
                                break;
                              case SortState.desc:
                                columnSortStates[header['title']]!["status"] =
                                    SortState.asc;
                                columnSortStates[header['title']]!["iconStatus"]
                                        .value =
                                    true;
                                break;
                            }

                            // Retrieves the comparison function configured
                            // for the selected column.
                            final compare =
                                header["sortCompare"] as int Function(T a, T b);

                            final currentStatus =
                                columnSortStates[header['title']]!["status"]
                                    as SortState;

                            // Sorts the reactive item list according to
                            // the selected column and sorting direction.
                            items.sort((a, b) {
                              final result = compare(a, b);
                              return currentStatus == SortState.asc
                                  ? result
                                  : -result;
                            });
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Displays the current sorting direction.
                            if (header["needSort"] != null &&
                                header["sortCompare"] != null)
                              Obx(() {
                                return Icon(
                                  columnSortStates[header['title']]!["iconStatus"]
                                          .value
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 23,
                                );
                              }),

                            // Builds the column title using the shared
                            // table header cell widget.
                            TableWidgets.tableHeaderCell(
                              text: header["title"],
                              flex: header['flex'],
                              padding: header["padding"] ?? EdgeInsets.zero,
                              maxFontSize: headerMaxFontSize,
                              minFontSize: headerMinFontSize,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Final column for row-specific actions.
                  TableWidgets.autoSizeText(
                    text: 'action'.tr,
                    maxFontSize: 17,
                    minFontSize: 10,
                    fontWeightBold: true,
                  ),
                ],
              ),
            ),

            // Table body with alternating row backgrounds.
            Expanded(
              child: Obx(() {
                // Displays a loading indicator and an empty-state message
                // when the item list contains no records.
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('no_records_found_yet'.tr),
                        SizedBox(height: 12),
                        CircularProgressIndicator(
                          color: Colors.blue,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  );
                }

                // Isolates table painting to help limit unnecessary repaints.
                return RepaintBoundary(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      // Builds the row cells and calculates the item's
                      // position across all pages rather than just this page.
                      final cells = cellBuilder(
                        item,
                        (((currentPage.value - 1) * rowsPerPage) + index + 1),
                      );

                      // Alternates the background color of consecutive rows.
                      final isEven = index.isEven;
                      final backgroundColor = isEven
                          ? Colors.transparent
                          : theme.dataTableRowColor;

                      return RepaintBoundary(
                        child: Container(
                          decoration: BoxDecoration(color: backgroundColor),
                          padding: const EdgeInsets.symmetric(
                            vertical: 15.0,
                            horizontal: 16.0,
                          ),
                          child: Row(children: cells),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),

            // Pagination controls are displayed only when the screen
            // is wider than 500 pixels and at least one page is available.
            Obx(() {
              if (MediaQuery.of(context).size.width <= 500 ||
                  totalPages.value <= 0) {
                return SizedBox.shrink();
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Previous-page button is disabled on the first page.
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: currentPage.value > 1 ? onPreviousPage : null,
                  ),

                  // Displays the current page and total number of pages.
                  Padding(
                    padding: const EdgeInsets.only(right: 20, left: 20),
                    child: Text('${currentPage.value} / ${totalPages.value}'),
                  ),

                  // Next-page button is disabled on the last page.
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: currentPage.value < totalPages.value
                        ? onNextPage
                        : null,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
