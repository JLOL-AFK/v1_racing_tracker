import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Data model for a single tracked dot.

class TrackedDot {

  TrackedDot({
    required this.id,
    required this.color,
    required this.angle,
    this.size = 8.0,
  });
  String id;
  Color color;
  double angle; // Angle in radians (0 to 2*pi)
  double size;
}


class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> with SingleTickerProviderStateMixin {
  // Configuration
  final double _ringPadding = 7;//20.0; // Space from edge of screen
  final double _strokeWidth = 1.0; // Thickness of the ring

  // State
  List<TrackedDot> _dots = [];
  bool _isSimulating = false;
  Timer? _simulationTimer;

  // Modern color palette for the dots
  final List<Color> _palette = [
    const Color(0xFF00E5FF), // Cyan
    const Color(0xFFFF4081), // Pink
    const Color(0xFF76FF03), // Lime Green
    const Color(0xFFFFEA00), // Yellow
    const Color(0xFFAA00FF), // Purple
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with a few random dots
    _randomizeDots();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  /// Randomizes positions and colors of dots to simulate finding new targets
  void _randomizeDots() {
    final random = Random();
    // Generate between 3 and 5 dots
    int count = 3 + random.nextInt(3);

    List<TrackedDot> newDots = [];
    for (int i = 0; i < count; i++) {
      newDots.add(TrackedDot(
        id: 'dot_$i',
        color: _palette[random.nextInt(_palette.length)],
        angle: random.nextDouble() * 2 * pi,
      ));
    }

    setState(() {
      _dots = newDots;
    });
  }

  /// Toggles the automatic tracking simulation
  void _toggleSimulation() {
    setState(() {
      _isSimulating = !_isSimulating;
    });

    if (_isSimulating) {
      // Update positions every 2 seconds to simulate live data
      _simulationTimer = Timer.periodic(const Duration(milliseconds: 144), (timer) {
        _animateDotsRandomly();
      });
    } else {
      _simulationTimer?.cancel();
    }
  }

  /// Slight random movement for the simulation effect
  void _animateDotsRandomly() {
    final random = Random();
    setState(() {
      for (var dot in _dots) {
        // Move dot by a small random amount (-0.5 to +0.5 radians)
        final change = random.nextDouble() - 0.5;
        dot.angle = (dot.angle + change) % (2 * pi);
      }
    });
  }

  /// User interaction: Drag a dot around the ring
  void _updateDotPosition(TrackedDot dot, Offset localPosition, Offset center) {
    // Calculate angle from center to touch point using atan2
    // atan2 returns -pi to +pi. We normalize this to 0 to 2pi logic if needed,
    // but standard trig works fine with raw values for positioning.
    double touchAngle = atan2(localPosition.dy - center.dy, localPosition.dx - center.dx);

    setState(() {
      dot.angle = touchAngle;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using LayoutBuilder to ensure we know the screen size (crucial for watches)

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine center and radius based on the shortest side (usually diameter on watch)
          final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
          final double diameter = min(constraints.maxWidth, constraints.maxHeight);
          final double radius = (diameter / 2) - _ringPadding;

          return Stack(
            children: [
              // 1. The Visual Ring (Track)
              Center(
                child: Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,//white24,
                      width: _strokeWidth,
                    ),
                    // Optional: Add a faint glow or gradient for modern look
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.1),//withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              ),

              // 2. Center Controls (Simulation Toggle)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isSimulating ? Icons.radar : Icons.radar_outlined,
                        color: _isSimulating ? const Color(0xFF00E5FF) : Colors.grey,
                        size: 32,
                      ),
                      onPressed: _toggleSimulation,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSimulating ? "TRACKING" : "MANUAL",
                      style: TextStyle(
                        color: _isSimulating ? const Color(0xFF00E5FF) : Colors.grey,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if(!_isSimulating)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: GestureDetector(
                          onTap: _randomizeDots,
                          child: const Text(
                            "Reset",
                            style: TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ),
                      )
                  ],
                ),
              ),

              // 3. The Dots
              ..._dots.map((dot) {
                // Convert polar coordinates (angle, radius) to Cartesian (x, y)
                // x = center_x + r * cos(theta)
                // y = center_y + r * sin(theta)
                // We subtract half the dot size to center the widget on the calculated point.
                final double x = center.dx + radius * cos(dot.angle) - (dot.size / 2);
                final double y = center.dy + radius * sin(dot.angle) - (dot.size / 2);

                return Positioned(
                  left: x,
                  top: y,
                  child: GestureDetector(
                    // Hit testing for small dots can be tricky, so we add a transparent margin
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (details) {
                      // Disable manual movement if simulation is running to avoid conflict
                      if (!_isSimulating) {
                        // We need the touch position relative to the whole stack/screen
                        // Since we are inside a Positioned widget, 'details.globalPosition' is safest
                        // provided the stack covers the screen.
                        RenderBox box = context.findRenderObject() as RenderBox;
                        Offset localTouch = box.globalToLocal(details.globalPosition);
                        _updateDotPosition(dot, localTouch, center);
                      }
                    },
                    child: Container(
                      width: dot.size,
                      height: dot.size,
                      decoration: BoxDecoration(
                        color: dot.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dot.color.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}