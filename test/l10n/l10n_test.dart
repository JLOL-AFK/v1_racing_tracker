import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_wear_app/l10n/l10n.dart';

void main() {
  group('l10n', () {
    testWidgets('AppLocalizationsX extension returns AppLocalizations', (
      tester,
    ) async {
      // We need a MaterialApp to provide the Localizations widget.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              // Use the extension to get the l10n instance.
              // This covers line 7 of lib/l10n/l10n.dart.
              final l10n = context.l10n;

              // Verify that the correct object is returned.
              expect(l10n, isA<AppLocalizations>());

              // Display a value from the localizations to ensure it's
              // loaded.
              return Text(l10n.counterAppBarTitle);
            },
          ),
        ),
      );

      // Verify the text is on screen.
      expect(find.text('Counter'), findsOneWidget);
    });
  });
}
