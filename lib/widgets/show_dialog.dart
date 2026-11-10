import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Provides a reusable dialog with an animated blurred background.
class ShowMyDialog {
  // Static method, can be called without creating an instance

  /// Displays a dialog with a blur effect behind it and a fade/scale entrance animation.
  ///
  /// [builder] creates the widget displayed inside the dialog.
  /// [argument] optionally passes data to the dialog through GetX navigation arguments.
  static showDialogWithBlur({
    required Widget Function() builder,
    Object? argument,
  }) {
    return Get.dialog(
      // Pass optional arguments to the dialog.
      arguments: argument,
      Stack(
        children: [
          // Animated blur background that also detects taps outside the dialog.
          GestureDetector(
            onTap: () => Get.back(), // tap outside closes dialog
            child: TweenAnimationBuilder<double>(
              // Animate the blur intensity from no blur to a sigma of 3.
              tween: Tween(begin: 0.0, end: 3.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return BackdropFilter(
                  // Apply the animated blur to the content behind this layer.
                  filter: ImageFilter.blur(sigmaX: value, sigmaY: value),
                  child: Container(color: Colors.transparent),
                );
              },
            ),
          ),

          // Center the dialog and animate its opacity and scale.
          Center(
            child: TweenAnimationBuilder<double>(
              // Animate the dialog from transparent and scaled down to its full size.
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return Opacity(
                  // Keep the opacity within its valid range.
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    // Scale the dialog from zero to its original size.
                    scale: value,
                    child:
                        builder(), // Build the widget supplied by the caller.
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Keep the barrier transparent so the custom blur effect remains visible.
      barrierColor: Colors.transparent,
    );
  }
}
