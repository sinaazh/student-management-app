import 'package:flutter/material.dart';

/// A small animated green dot with a glowing effect.
///
/// The dot continuously fades in and out to create a pulsing animation.
/// Its dimensions can be customized through the [size] parameter.
class GlowingDot extends StatefulWidget {
  /// The width and height of the dot.
  final double size;

  const GlowingDot({super.key, this.size = 10});

  @override
  GlowingDotState createState() => GlowingDotState();
}

/// Manages the pulsing animation and visual appearance of [GlowingDot].
class GlowingDotState extends State<GlowingDot>
    with SingleTickerProviderStateMixin {
  /// Controls the opacity animation of the dot.
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Starts a repeating one-second animation that reverses direction
    // after reaching each endpoint, creating a continuous pulsing effect.
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true); // keep pulsing
  }

  @override
  void dispose() {
    // Releases the animation controller when the widget is removed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Uses the animation controller's value to animate the dot's opacity.
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          // Adds a soft green shadow to create the glowing appearance.
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(
                255,
                68,
                198,
                72,
              ).withValues(alpha: 0.6),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
