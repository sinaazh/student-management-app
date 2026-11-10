import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:school_managment_app/controllers/side_bar_controller.dart';
import 'package:school_managment_app/controllers/theme_controller.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/views/add_student.dart';
import 'package:school_managment_app/views/edit_student.dart';
import 'package:school_managment_app/views/extra_costs.dart';
import 'package:school_managment_app/views/settings.dart';
import 'package:school_managment_app/views/student_payment.dart';
import 'package:school_managment_app/views/tuition_managment.dart';
import 'package:school_managment_app/widgets/glowing_dot.dart';
import 'package:school_managment_app/widgets/my_snack_bar.dart';
import 'package:school_managment_app/widgets/dialog_lifecycle.dart';
import 'package:school_managment_app/widgets/show_dialog.dart';

/// Displays the application's main navigation sidebar.
///
/// Supports expandable menu sections, page navigation, and dialog-based
/// actions such as adding students and managing tuition.
class Sidebar extends StatelessWidget {
  // Retrieve the controllers registered in GetX.
  final SidebarController controller = Get.find();
  final ThemeController themeController = Get.find();

  // Defines the sidebar's menu structure, including standalone pages,
  // expandable sections, and dialog-based actions.
  final List<Map<String, dynamic>> menuItems = [
    {
      "title": 'home'.tr,
      "icon": HugeIcons.strokeRoundedHome05,
      "key": "home",
      "page": "/home",
    },
    {
      "title": 'student'.tr,
      "icon": HugeIcons.strokeRoundedStudent,
      "key": "StudentDashboard",
      "sub": [
        {
          "title": 'add_student'.tr,
          "page": "/add_student",
          "dialog": () => AddStudentDialog(),
        },
        {
          "title": 'edit_student'.tr,
          "page": "/edit_student",
          "dialog": () => EditStudentDialog(),
        },
        {
          "title": 'student_payments'.tr,
          "page": "/studentPayment",
          "dialog": () => StudentPaymentDialog(),
        },
      ],
    },
    {
      "title": 'finances'.tr,
      "icon": HugeIcons.strokeRoundedDollarCircle,
      "key": "FinancesDashboard",
      "sub": [
        {
          "title": 'tuition_management'.tr,
          "page": "tuition_managment",
          "dialog": () => TuitionManagment(),
        },
        {
          "title": 'extra_costs'.tr,
          "page": "extra_costs",
          "dialog": () => ExtraCosts(),
        },
        {"title": 'debtor_list'.tr, "key": "debtor", "page": "/debtorList"},
      ],
    },
    {
      "title": 'settings'.tr,
      "icon": HugeIcons.strokeRoundedSetting07,
      "page": "settings",
      "dialog": () => Settings(),
    },
  ];

  // Color used to highlight the currently selected menu item.
  final Color selectedButtonColor = Color.fromARGB(255, 201, 19, 251);

  Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      // Use the theme's configured background color for the sidebar.
      color: Theme.of(context).colorScheme.containerBackgroundColor,
      child: SizedBox(
        // Set the sidebar width to 20% of the screen width.
        width: MediaQuery.of(context).size.width * 0.2,
        // constraints: const BoxConstraints(
        //   maxWidth: 260, // never go beyond 260
        // ),
        // decoration: BoxDecoration(
        //   color: Theme.of(context).colorScheme.containerBackgroundColor,
        // ),
        child: ConstrainedBox(
          // Prevent the sidebar from exceeding 260 pixels in width.
          constraints: const BoxConstraints(maxWidth: 260),
          child: ListView(
            children: [
              // Build each menu entry using the appropriate menu-item widget.
              ...menuItems.map((item) => buildMenuItem(context, item)),
            ],
          ),
        ),
      ),
    );
  }

  /// Determines whether a menu entry should be displayed as a standalone item
  /// or as an expandable section containing sub-items.
  Widget buildMenuItem(BuildContext context, Map<String, dynamic> item) {
    // Retrieve the optional list of child menu items.
    final subItems = item["sub"] as List<Map<String, dynamic>>?;

    if (subItems != null && subItems.isNotEmpty) {
      return buildExpansionItem(context, item, subItems);
    } else {
      return buildSingleItem(context, item);
    }
  }

  /// Builds an expandable menu section and its associated sub-items.
  Widget buildExpansionItem(
    BuildContext context,
    Map<String, dynamic> item,
    List<Map<String, dynamic>> subItems,
  ) {
    // Rebuild the section when its expanded state or selected page changes.
    return Obx(() {
      // Check whether this menu section is currently expanded.
      final isExpanded = controller.expandedMenus[item["key"]] ?? false;

      // Find the sub-item corresponding to the currently highlighted page.
      final selectedIndex = subItems.indexWhere(
        (s) => s["page"] == controller.highlightedPage.value,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main menu header.
          ListTile(
            // Display the menu icon only when the screen is wider than 300 pixels.
            leading: MediaQuery.of(context).size.width > 300
                ? HugeIcon(
                    icon: item["icon"],
                    size: (MediaQuery.of(context).size.width * 0.04).clamp(
                      15,
                      32,
                    ),
                    color: isExpanded
                        ? selectedButtonColor
                        : Theme.of(context).colorScheme.buttonColor,
                  )
                : null,
            title: Text(
              item["title"],
              style: TextStyle(
                // Highlight the header when its section is expanded.
                color: isExpanded
                    ? selectedButtonColor
                    : Theme.of(context).colorScheme.buttonColor,
                fontSize: 23, // max starting size
              ),
              maxLines: 1, // keep in one line
              overflow: TextOverflow.ellipsis,
            ),
            // title: AutoSizeText(
            //   item["title"],
            //   style: TextStyle(
            //     color: isExpanded
            //         ? selectedButtonColor
            //         : Theme.of(context).colorScheme.buttonColor,
            //     fontSize: 23, // max starting size
            //   ),
            //   maxLines: 1, // keep in one line
            //   minFontSize: 14, // won’t shrink below 14
            //   overflow: TextOverflow.ellipsis,
            // ),

            // Show the appropriate expansion indicator on wider screens.
            trailing: MediaQuery.of(context).size.width > 500
                ? Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isExpanded
                        ? selectedButtonColor
                        : Theme.of(context).colorScheme.buttonColor,
                  )
                : null,

            // Toggle the section's expanded state when the header is tapped.
            // Disable expansion interaction on screens 300 pixels wide or narrower.
            onTap: MediaQuery.of(context).size.width > 300
                ? () => controller.toggleMenu(item["key"])
                : null,
          ),

          // Animate the vertical expansion and collapse of the sub-item section.
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: ConstrainedBox(
              // Remove the height restriction when expanded; otherwise, collapse the section.
              constraints: isExpanded
                  ? const BoxConstraints() // expanded
                  : const BoxConstraints(maxHeight: 0), // collapsed
              child: Padding(
                padding: const EdgeInsets.only(left: 25),
                child: SizedBox(
                  // Allocate vertical space based on the number of sub-items.
                  height: subItems.length * 48,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vertical line and indicator showing the selected sub-item.
                      Stack(
                        children: [
                          // Draw the full-height vertical navigation line.
                          Container(
                            width: 2,
                            color: const Color.fromARGB(255, 216, 215, 215),
                            height: subItems.length * 40,
                          ),

                          // Highlight the position of the currently selected sub-item.
                          if (selectedIndex != -1)
                            Positioned(
                              top: selectedIndex * 40,
                              child: Container(
                                width: 2,
                                height: 40,
                                color: const Color.fromARGB(255, 220, 67, 247),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Build and display all sub-items beside the vertical indicator.
                      Expanded(
                        child: Column(
                          children: subItems
                              .map((item) => buildSubItem(context, item))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Builds an individual sub-item inside an expandable menu section.
  Widget buildSubItem(BuildContext context, Map<String, dynamic> subItem) {
    // Rebuild the item when the highlighted page or selected student changes.
    return Obx(() {
      // Determine whether this sub-item corresponds to the active page.
      final isSelected = controller.highlightedPage.value == subItem["page"];

      // Show an indicator when a student is selected and the sub-item
      // provides student-specific actions.
      final shouldShowDot =
          (subItem["page"] == "/studentPayment" ||
              subItem["page"] == "/edit_student") &&
          controller.dataTableController.selectedUser.value != null;

      return Material(
        // Apply a different background color to the selected sub-item.
        color: isSelected
            ? Theme.of(context).colorScheme.selectedSubItemBackgroundColor
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        // decoration: BoxDecoration(
        //   color: isSelected
        //       ? Theme.of(context).colorScheme.selectedSubItemBackgroundColor
        //       : Colors.transparent,
        //   borderRadius: BorderRadius.circular(12),
        // ),
        child: ListTile(
          dense: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subItem["title"],
                style: TextStyle(
                  color: isSelected
                      ? selectedButtonColor
                      : Theme.of(context).colorScheme.buttonColor,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // AutoSizeText(
              //   subItem["title"],
              //   style: TextStyle(
              //     color: isSelected
              //         ? selectedButtonColor
              //         : Theme.of(context).colorScheme.buttonColor,
              //     fontSize: 15,
              //   ),
              //   maxLines: 1,
              //   minFontSize: 10,
              //   overflow: TextOverflow.ellipsis,
              // ),

              // Display a glowing indicator for student-specific actions
              // when a student is currently selected.
              if (shouldShowDot) ...[SizedBox(width: 5), GlowingDot(size: 10)],
            ],
          ),
          selected: isSelected,
          onTap: () {
            // These actions require a student to be selected before opening.
            final requiresSelection = [
              "/edit_student",
              "/studentPayment",
            ].contains(subItem["page"]);

            // Retrieve the currently selected student from the data table controller.
            final selectedUser =
                controller.dataTableController.selectedUser.value;

            if (subItem.containsKey("dialog")) {
              // Prevent student-specific dialogs from opening without a selection.
              if (requiresSelection && selectedUser == null) {
                RightSideToast.show(
                  title: "Error",
                  message: "No student is selected",
                  messageColor: const Color.fromARGB(255, 233, 181, 68),
                  duration: Duration(seconds: 3),
                );
                return;
              }

              // Update the selected sidebar item before opening its dialog.
              controller.selectItem(subItem["page"]);

              // Open the dialog with a blurred background.
              ShowMyDialog.showDialogWithBlur(builder: subItem["dialog"]).then((
                _,
              ) {
                // Reset the dialog's fields and remove its controller
                // when it implements the DialogLifecycle interface.
                if (subItem["dialog"] is DialogLifecycle) {
                  final dialog = subItem["dialog"] as DialogLifecycle;
                  dialog.resetFields();
                  dialog.removeController();
                }

                // Restore the sidebar selection after the dialog closes.
                controller.selectItem(controller.selectedPage.value);
              });
            } else {
              // Navigate directly to the page when no dialog is configured.
              controller.selectPage(subItem["page"]);
            }
          },
        ),
      );
    });
  }

  // Builds a standalone menu item that does not contain sub-items.
  Widget buildSingleItem(BuildContext context, Map<String, dynamic> item) {
    // Rebuild the item when the highlighted page changes.
    return Obx(() {
      // Determine whether this standalone item represents the active page.
      final isSelected = controller.highlightedPage.value == item["page"];

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          // Display the menu icon only on screens wider than 300 pixels.
          leading: MediaQuery.of(context).size.width > 300
              ? HugeIcon(
                  icon: item["icon"],
                  size: (MediaQuery.of(context).size.width * 0.04).clamp(
                    15,
                    32,
                  ),
                  color: isSelected
                      ? selectedButtonColor
                      : Theme.of(context).colorScheme.buttonColor,
                )
              : null,
          title: Text(
            item["title"],
            style: TextStyle(
              color: isSelected
                  ? selectedButtonColor
                  : Theme.of(context).colorScheme.buttonColor, // text color
              fontSize: 23, // max starting size
            ),
            maxLines: 1, // keep in one line
            overflow: TextOverflow.ellipsis,
          ),
          // title: AutoSizeText(
          //   item["title"],
          //   style: TextStyle(
          //     color: isSelected
          //         ? selectedButtonColor
          //         : Theme.of(context).colorScheme.buttonColor, // text color
          //     fontSize: 23, // max starting size
          //   ),
          //   maxLines: 1, // keep in one line
          //   minFontSize: 14, // won’t shrink below 14
          //   overflow: TextOverflow.ellipsis,
          // ),
          selected: isSelected,
          // onTap: () => controller.selectPage(item["page"]),
          onTap: () {
            if (item.containsKey("dialog")) {
              // Update the selected item and open its associated dialog.
              controller.selectItem(item["page"]);
              ShowMyDialog.showDialogWithBlur(builder: item["dialog"]).then((
                _,
              ) {
                // Perform dialog cleanup when the dialog implements DialogLifecycle.
                if (item["dialog"] is DialogLifecycle) {
                  final dialog = item["dialog"] as DialogLifecycle;
                  dialog.resetFields();
                  dialog.removeController();
                }

                // Restore the previous page selection after closing the dialog.
                controller.selectItem(controller.selectedPage.value);
              });
            } else {
              // Navigate directly to the selected page.
              controller.selectPage(item["page"]);
            }
          },
        ),
      );
    });
  }
}
