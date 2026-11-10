import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// A reusable text field with regex-based input validation and temporary error messages.
class MyTextField extends StatefulWidget {
  final TextEditingController? textController;
  final String hintText;
  final String errorText;
  final RegExp regex;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final double paddingSize;
  final bool readOnly;
  final Icon? prefixIcon;
  final int maxLines;

  const MyTextField({
    super.key,
    required this.hintText,
    required this.errorText,
    this.onChanged,
    required this.regex,
    this.paddingSize = 20,
    this.textController,
    this.readOnly = false,
    this.prefixIcon,
    this.onTap,
    this.maxLines = 1,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

/// Manages input validation feedback and the error message timer.
class _MyTextFieldState extends State<MyTextField> {
  // Tracks whether the validation error message should be displayed.
  final RxBool isErrorVisible = false.obs;

  // Controls how long the validation error remains visible.
  Timer? _timer;

  /// Displays the validation error and automatically hides it after three seconds.
  ///
  /// Cancels any previously scheduled timer to restart the countdown.
  void _showErrorWithTimer() {
    _timer?.cancel();
    isErrorVisible.value = true;

    _timer = Timer(const Duration(seconds: 3), () {
      isErrorVisible.value = false;
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent it from updating state after disposal.
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Add configurable spacing below the text field.
      padding: EdgeInsets.only(bottom: widget.paddingSize),
      child: Obx(
        // Rebuild the TextField when the validation error visibility changes.
        () => TextField(
          controller: widget.textController,
          onChanged: widget.onChanged,
          minLines: 1,
          maxLines: widget.maxLines,
          onTap: widget.onTap,
          readOnly: widget.readOnly,

          // Validate every input change using the supplied regular expression.
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (widget.regex.hasMatch(newValue.text)) {
                // Accept valid input and clear any existing validation error.
                isErrorVisible.value = false;
                _timer?.cancel();
                return newValue;
              } else {
                // Reject invalid input, retain the previous value,
                // and temporarily display the validation error.
                _showErrorWithTimer();
                return oldValue;
              }
            }),
          ],
          decoration: InputDecoration(
            hintText: widget.hintText,

            // Display the error message only while validation feedback is active.
            errorText: isErrorVisible.value ? widget.errorText : null,
            prefixIcon: widget.prefixIcon,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
            ),
          ),
        ),
      ),
    );
  }
}
