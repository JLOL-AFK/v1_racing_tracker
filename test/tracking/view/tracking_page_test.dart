import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_wear_app/tracking/view/tracking_page.dart';

void main() {
  group('TrackingScreen', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TrackerScreen()));
      expect(find.byType(TrackerScreen), findsOneWidget);
    });

    group('IconButton Simulation Toggle', () {
      testWidgets('correctly enters tracking mode on first tap', (
        tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: TrackerScreen()));

        expect(find.byIcon(Icons.radar_outlined), findsOneWidget);
        expect(find.byIcon(Icons.radar), findsNothing);

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.radar), findsOneWidget);
        expect(find.byIcon(Icons.radar_outlined), findsNothing);
      });

      testWidgets('dot data model (angles) changes during simulation', (
        tester,
      ) async {
        final screenKey = GlobalKey<TrackerScreenState>();
        await tester.pumpWidget(
          MaterialApp(home: TrackerScreen(key: screenKey)),
        );

        await tester.tap(find.byType(IconButton));
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 101));
        await tester.pump();

        final state = screenKey.currentState;
        expect(state, isNotNull);
        expect(state!.dots, isNotEmpty);

        final initialAngles = state.dots.map((dot) => dot.angle).toList();

        await tester.pump(const Duration(milliseconds: 101));
        await tester.pump();

        final finalAngles = state.dots.map((dot) => dot.angle).toList();

        expect(finalAngles, isNot(equals(initialAngles)));
      });

      testWidgets('dots stop moving when simulation is toggled off', (
        tester,
      ) async {
        final screenKey = GlobalKey<TrackerScreenState>();
        await tester.pumpWidget(
          MaterialApp(home: TrackerScreen(key: screenKey)),
        );

        // Turn ON
        await tester.tap(find.byType(IconButton));
        await tester.pump(const Duration(milliseconds: 144));
        await tester.pump();

        final state = screenKey.currentState!;
        final anglesAfterFirstTick = state.dots.map((d) => d.angle).toList();

        await tester.pump(const Duration(milliseconds: 144));
        await tester.pump();

        final anglesAfterSecondTick = state.dots.map((d) => d.angle).toList();
        expect(anglesAfterFirstTick, isNot(equals(anglesAfterSecondTick)));

        // Turn OFF
        await tester.tap(find.byType(IconButton));
        await tester.pump();

        final anglesAfterSimOff = state.dots.map((d) => d.angle).toList();

        // Wait to prove no movement
        await tester.pump(const Duration(milliseconds: 144));
        await tester.pump();

        final finalAngles = state.dots.map((d) => d.angle).toList();

        expect(finalAngles, equals(anglesAfterSimOff));
      });

      testWidgets('dragging a dot along its circular path updates its angle', (
        tester,
      ) async {
        // 1. ARRANGE: Build with GlobalKey immediately
        final screenKey = GlobalKey<TrackerScreenState>();
        await tester.pumpWidget(
          MaterialApp(home: TrackerScreen(key: screenKey)),
        );
        await tester.pumpAndSettle();

        final state = screenKey.currentState!;
        expect(
          state.dots,
          isNotEmpty,
          reason: 'Dots should exist from initState.',
        );

        // 2. IDENTIFY TARGETS
        final targetDotData = state.dots.first;
        final firstDotInitialAngle = targetDotData.angle;

        // Find the specific widget using the Key (ensure you added Key(dot.id)
        // in the App code!)
        final firstDotFinder = find.byKey(Key(targetDotData.id));
        expect(
          firstDotFinder,
          findsOneWidget,
          reason: 'Could not find the specific dot widget',
        );

        // Find the Stack to get the screen dimensions
        final stackFinder = find.byKey(const Key('tracker_stack'));
        final size = tester.getSize(stackFinder);

        // --- FIX: MATCH APP GEOMETRY EXACTLY ---
        // App uses: radius = (diameter / 2) - _ringPadding (7)
        final double diameter = min(size.width, size.height);
        final radius = (diameter / 2) - 7.0;

        // 3. CALCULATE GEOMETRY
        // Define a target angle (move it 45 degrees / pi/4)
        const angleDelta = pi / 4;
        final targetAngle = firstDotInitialAngle + angleDelta;

        // Calculate coordinates relative to the center (0,0)
        final initialX = radius * cos(firstDotInitialAngle);
        final initialY = radius * sin(firstDotInitialAngle);

        final finalX = radius * cos(targetAngle);
        final finalY = radius * sin(targetAngle);

        // Calculate the vector to drag the finger
        final dragOffset = Offset(finalX - initialX, finalY - initialY);

        // 4. ACT
        await tester.drag(firstDotFinder, dragOffset);
        await tester.pump(); // Rebuild to run the logic inside onPanUpdate

        // 5. ASSERT
        // Re-read the state
        final firstDotFinalAngle = state.dots
            .firstWhere((d) => d.id == targetDotData.id)
            .angle;

        // Helper to handle the "wrap around" (e.g., -3.14 vs 3.14)
        // Since the App uses atan2, results are in range -PI to +PI.
        // We normalize everything to that range for comparison.
        double normalizeToPi(double value) {
          var angle = value;
          while (angle <= -pi) {
            angle += 2 * pi;
          }
          while (angle > pi) {
            angle -= 2 * pi;
          }
          return angle;
        }

        expect(
          normalizeToPi(firstDotFinalAngle),
          closeTo(
            normalizeToPi(targetAngle),
            0.05,
          ), // Tolerance allows for minor float math noise
          reason: 'The dot angle should match the angle of the drag gesture.',
        );
      });
    });
  });
}
