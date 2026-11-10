import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Manages floating toast notifications displayed on the right side of the screen.
class RightSideToast {
  // Keeps track of the currently displayed toast so it can be removed when
  // another toast is shown.
  static OverlayEntry? _currentEntry; // keeps track of current toast

  /// Displays a floating toast that slides in from the right.
  ///
  /// [title] is the heading displayed at the top of the toast.
  /// [message] is the notification message.
  /// [messageColor] determines the background color of the toast.
  /// [duration] specifies how long the toast remains visible.
  /// [rightPadding] and [topPadding] control its position on the screen.
  /// [maxWidth] limits the maximum width of the toast.
  static void show({
    required String title,
    required String message,
    required Color messageColor,
    Duration duration = const Duration(seconds: 2),
    double rightPadding = 16,
    double topPadding = 20,
    double maxWidth = 340,
  }) {
    // Retrieve the application's root overlay using GetX's global key.
    final overlay = Get.key.currentState?.overlay;
    // final ctx = Get.overlayContext ?? Get.context;
    if (overlay == null) return;

    // final overlay = Overlay.of(ctx);

    // Remove any previously displayed toast before creating a new one.
    _currentEntry?.remove();
    _currentEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        // Position the toast near the top-right corner of the overlay.
        return Positioned(
          top: topPadding,
          right: rightPadding,
          child: Material(
            color: Colors.transparent,
            child: ToastWidget(
              title: title,
              message: message,
              messageColor: messageColor,
              maxWidth: maxWidth,
              onClose: () {
                // Remove the overlay entry when the user presses the close button.
                if (entry.mounted) {
                  entry.remove();
                  _currentEntry = null;
                }
              },
            ),
          ),
        );
      },
    );

    // Store the new entry and insert it into the overlay.
    _currentEntry = entry;
    overlay.insert(entry);

    // Automatically remove the toast after the specified duration.
    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();

        // Clear the reference only if this entry is still the current toast.
        if (_currentEntry == entry) _currentEntry = null;
      }
    });
  }
}

/// A customizable toast notification with a slide-in animation and close button.
class ToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final Color messageColor;
  final double maxWidth;
  final VoidCallback onClose;

  const ToastWidget({
    super.key,
    required this.title,
    required this.message,
    required this.messageColor,
    required this.maxWidth,
    required this.onClose,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

/// Controls the toast's entrance animation and builds its visual layout.
class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configure the animation controller with a 300-millisecond duration.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Define a horizontal slide animation from outside the right edge
    // toward the widget's original position.
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start the entrance animation when the widget is initialized.
    _controller.forward();
  }

  @override
  void dispose() {
    // Release the animation controller when the widget is removed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Apply the slide animation to the toast's visual content.
    return SlideTransition(
      position: _slideAnimation,
      child: ConstrainedBox(
        // Prevent the toast from exceeding its configured maximum width.
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // Use the supplied color as the toast's background.
            color: widget.messageColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display the title and message in a vertically arranged column.
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.message,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),

              // Allow the user to dismiss the toast manually.
              IconButton(
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
