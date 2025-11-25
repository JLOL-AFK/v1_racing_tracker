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
        // 1. ARRANGE: Build the widget in its initial state.
        await tester.pumpWidget(const MaterialApp(home: TrackerScreen()));

        // 2. ASSERT (Initial State): Before any interaction, verify that
        // the simulation is OFF. The UI should show the 'outlined' icon.
        expect(
          find.byIcon(Icons.radar_outlined),
          findsOneWidget,
          reason: 'Initially, the simulation should be off.',
        );
        expect(
          find.byIcon(Icons.radar),
          findsNothing,
          reason: 'The solid radar icon should not be present at the start.',
        );

        // 3. ACT: Find the IconButton and tap it.
        await tester.tap(find.byType(IconButton));

        // 4. SETTLE: Wait for the setState() call and any associated
        // animations from the tap to complete.
        // `pumpAndSettle` is appropriate here because this state change
        // does not involve a non-terminating timer.
        await tester.pumpAndSettle();

        // 5. ASSERT (Final State): After the tap, verify that the
        // simulation is ON. The UI must now show the solid 'radar' icon.
        expect(
          find.byIcon(Icons.radar),
          findsOneWidget,
          reason: 'After tapping, the solid radar icon should be visible.',
        );
        expect(
          find.byIcon(Icons.radar_outlined),
          findsNothing,
          reason: 'The icon should be gone after tracking mode is enabled.',
        );
      });
      testWidgets('dot data model (angles) changes during simulation', (
        tester,
      ) async {
        //Create a GlobalKey to access the widget's state.
        final screenKey = GlobalKey<TrackerScreenState>();

        //Build the widget, passing the key to it.
        await tester.pumpWidget(
          MaterialApp(home: TrackerScreen(key: screenKey)),
        );

        //Start the simulation.
        await tester.tap(find.byType(IconButton));
        await tester.pump(); // Process the setState from the tap

        //Advance the clock to create the first dots.
        await tester.pump(const Duration(milliseconds: 101));
        await tester.pump();
        // Process the setState from the timer's callback

        //Access the state via the GlobalKey
        final state = screenKey.currentState;
        expect(state, isNotNull);
        expect(
          state!.dots,
          isNotEmpty,
          // Use ! since we expect it to be non-null
          reason: 'Dots list should not be empty.',
        );

        // Make a copy of the initial angles.
        final initialAngles = state.dots.map((dot) => dot.angle).toList();

        // Advance the clock again to make the dots "move".
        await tester.pump(const Duration(milliseconds: 101));
        await tester.pump(); // Process the resulting setState

        // Get the new angles.
        final finalAngles = state.dots.map((dot) => dot.angle).toList();

        //Verify that the angles have actually changed.
        expect(
          finalAngles,
          isNot(equals(initialAngles)),
          reason: 'The angles of the dots should change.',
        );
      });
    });
  });
}
