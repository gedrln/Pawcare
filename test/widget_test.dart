import 'package:flutter_test/flutter_test.dart';
import 'package:pawcare/main.dart';

void main() {
  testWidgets(
    'Pawcare dashboard loads',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const PawcareApp(),
      );

      expect(
        find.text('Welcome to Pawcare'),
        findsOneWidget,
      );

      expect(
        find.text('My Pets'),
        findsOneWidget,
      );

      expect(
        find.text('Schedule'),
        findsOneWidget,
      );

      expect(
        find.text('Settings'),
        findsOneWidget,
      );
    },
  );
}
