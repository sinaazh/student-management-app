import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/controllers/theme_controller.dart';
import 'package:get/get.dart';

/// A reusable, generic dropdown widget with customizable styling,
/// item display text, and selection handling.
///
/// [T] represents the data type of the dropdown items.
class MyDropDown<T> extends StatelessWidget {
  /// Provides access to the application's current theme settings.
  final ThemeController themeController = Get.find();

  /// Placeholder text displayed when no item is selected.
  final String hint;

  /// Available options displayed in the dropdown menu.
  final List<T> items;

  /// Currently selected dropdown item.
  final T? value;

  /// Font size used for the hint and dropdown item text.
  final double fontSize;

  /// Maximum allowed width of the dropdown menu.
  final double maxItemListWidth;

  /// Callback invoked when the selected item changes.
  final Function(T?) onChanged;

  /// Focus node used to manage the dropdown's focus state.
  final FocusNode myFocusNode;

  /// Build context used for accessing screen dimensions.
  final BuildContext context;

  /// Converts a dropdown item into the text displayed to the user.
  final String Function(T) showItemText; // function to get display text

  MyDropDown({
    super.key,
    required this.hint,
    required this.items,
    this.value,
    required this.fontSize,
    this.maxItemListWidth = 280,
    required this.onChanged,
    required this.myFocusNode,
    required this.context,
    required this.showItemText,
  });

  @override
  Widget build(BuildContext context) {
    // Rebuilds the dropdown whenever the application theme changes.
    return Obx(() {
      final isDark = themeController.isDark.value;

      // Removes the default underline from the dropdown button.
      return DropdownButtonHideUnderline(
        child: DropdownButton2<T>(
          focusNode: myFocusNode,
          isExpanded: true,
          value: value,

          // Displays the hint when no dropdown item is selected.
          hint: Text(
            hint,
            style: TextStyle(
              // color: Theme.of(context).colorScheme.dropdownHintColor,
              color: isDark
                  ? darkMode.colorScheme.dropdownHintColor
                  : lightMode.colorScheme.dropdownHintColor,
              fontSize: fontSize,
            ),
          ),

          // Converts each available item into a dropdown menu entry.
          // showItemText determines the text displayed for each item.
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    showItemText(item),
                    style: TextStyle(
                      fontSize: fontSize,
                      // color: Theme.of(context).colorScheme.dropdownTextColor,
                      color: isDark
                          ? darkMode.colorScheme.dropdownTextColor
                          : lightMode.colorScheme.dropdownTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),

          // Passes the newly selected value to the parent widget.
          onChanged: onChanged,

          // Styling for the closed dropdown button.
          buttonStyleData: ButtonStyleData(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              // color: Theme.of(context).colorScheme.dropdownButtonColor,
              color: isDark
                  ? darkMode.colorScheme.dropdownButtonColor
                  : lightMode.colorScheme.dropdownButtonColor,
            ),
            elevation: 2,
          ),

          // Styling and sizing for the dropdown menu when opened.
          dropdownStyleData: DropdownStyleData(
            direction: DropdownDirection.textDirection,
            maxHeight: 200,

            // Calculates the menu width as 25% of the screen width,
            // constrained by the specified minimum and maximum widths.
            width: (MediaQuery.of(context).size.width * 0.25).clamp(
              50,
              maxItemListWidth,
            ),

            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              // color: Theme.of(context).colorScheme.dropdownBackgroundColor,
              color: isDark
                  ? darkMode.colorScheme.dropdownBackgroundColor
                  : lightMode.colorScheme.dropdownBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),

          // Controls the height and horizontal padding of individual menu items.
          menuItemStyleData: MenuItemStyleData(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: fontSize),
          ),

          // Configures the dropdown arrow icon and its appearance.
          iconStyleData: IconStyleData(
            icon: Icon(
              Icons.arrow_drop_down,
              size: 30,
              color: isDark ? Colors.grey : Colors.grey[600],
            ),
          ),
        ),
      );
    });
  }
}
