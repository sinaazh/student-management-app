import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/theme_controller.dart';
import 'package:school_managment_app/utils/theme.dart';

/// A reusable base dialog that provides a consistent layout and appearance
/// for dialogs throughout the application.
class MyBaseDialog extends StatelessWidget {
  /// Provides access to the application's current theme settings.
  final ThemeController themeController = Get.find();

  /// The title displayed at the top of the dialog.
  final String title;

  /// The maximum width allocated to the dialog's header.
  final double maxContainerWdith;

  /// The main content displayed inside the dialog.
  final Widget child;

  /// An optional custom background color for the dialog.
  ///
  /// If not provided, the background color is determined by the active theme.
  final Color? dialogColor;

  MyBaseDialog({
    super.key,
    required this.title,
    required this.child,
    required this.maxContainerWdith,
    this.dialogColor,
  });

  @override
  Widget build(BuildContext context) {
    // Rebuilds the dialog whenever the application's theme changes.
    return Obx(() {
      final isDark = themeController.isDark.value;

      // Applies the selected application theme to the dialog and its children.
      return Theme(
        data: isDark ? darkMode : lightMode,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Uses the custom dialog color when provided; otherwise,
              // selects the container background color from the active theme.
              // color: dialogColor ?? Theme.of(context).colorScheme.containerBackgroundColor,
              color:
                  dialogColor ??
                  (isDark
                      ? darkMode.colorScheme.containerBackgroundColor
                      : lightMode.colorScheme.containerBackgroundColor),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
              // Adds a subtle shadow to visually separate the dialog
              // from the background.
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header containing the title and close button.
                SizedBox(
                  width: maxContainerWdith,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? darkMode.colorScheme.primary
                              : lightMode.colorScheme.primary,
                        ),
                      ),

                      // Closes the currently displayed dialog.
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Allows the dialog content to scroll when it exceeds
                // the available vertical space.
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
