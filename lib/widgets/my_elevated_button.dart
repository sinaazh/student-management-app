import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/theme_controller.dart';
import 'package:school_managment_app/utils/theme.dart';

/// A reusable elevated button with customizable text, an optional icon,
/// and theme-based gradient styling.
class MyElevatedButton extends StatelessWidget {
  /// Provides access to the application's theme controller.
  final ThemeController themeController = Get.find();

  /// Text displayed inside the button when no icon is provided.
  final String buttonText;

  /// Callback executed when the button is pressed.
  final Function onPressed;

  /// Optional widget displayed instead of the button text.
  final Widget? icon;

  MyElevatedButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Retrieves the button gradient from the active theme.
    final gradient = Theme.of(context).colorScheme.elevatedButtonGradient;

    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),

        // Adds a shadow when no gradient is defined.
        boxShadow: [
          if (gradient == null)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          // Uses a transparent background when the gradient is available,
          // allowing the Container's gradient to remain visible.
          backgroundColor: gradient != null
              ? Colors.transparent
              : Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // The Container handles the button's shadow.
          elevation: 0,
        ),

        // Executes the provided callback when the button is pressed.
        onPressed: () => onPressed(),

        // Displays the optional icon when provided; otherwise, displays the text.
        child: icon ?? Text(buttonText, style: TextStyle(color: Colors.black)),
      ),
    );
  }
}
