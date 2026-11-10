import 'package:flutter/material.dart';

/// A compact rectangular toggle for switching between light and dark themes.
class RectThemeToggle extends StatelessWidget {
  // Indicates whether dark mode is currently active.
  final bool isDark;

  // Callback executed when the user taps the toggle.
  final Function onToggle;

  const RectThemeToggle({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Trigger the supplied callback when the toggle is tapped.
      onTap: () => onToggle(),
      child: AnimatedContainer(
        // Animate background and decoration changes when the theme changes.
        duration: const Duration(milliseconds: 300),
        height: 45,
        width: 140,
        decoration: BoxDecoration(
          // Change the toggle's background according to the active theme.
          color: isDark ? Colors.grey[900] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Sliding highlight indicating the currently selected theme.
            AnimatedAlign(
              // Animate the highlight's horizontal position.
              duration: const Duration(milliseconds: 300),
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 70,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  // Use a dark or light background for the selected half.
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),

            // Display the light and dark mode icons above the sliding highlight.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Light mode icon.
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.light_mode,
                      // Highlight the light mode icon when light mode is active.
                      color: isDark ? Colors.white60 : Colors.amber,
                    ),
                  ),
                ),

                // Dark mode icon.
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.dark_mode,
                      // Highlight the dark mode icon when dark mode is active.
                      color: isDark ? Colors.blueGrey[100] : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
