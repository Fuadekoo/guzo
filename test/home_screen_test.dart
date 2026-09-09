import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/app/guzo_app.dart';
import 'package:guzo/education/sequence_library.dart';
import 'package:guzo/game/guzo_game.dart';
import 'package:guzo/utils/constants.dart';
import 'package:guzo/widgets/category_tile.dart';
import 'package:guzo/screens/mode_selection_screen.dart';
import 'package:guzo/widgets/guzo_nav_bar.dart';

/// Puts the test surface into the portrait phone shape the app actually runs
/// in. The default 800x600 test window is landscape, which pushes the lower
/// half of the menu off-screen and makes taps miss.
void _usePortraitPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('HomeScreen', () {
    testWidgets('shows the branding, progress card and category grid', (
      WidgetTester tester,
    ) async {
      _usePortraitPhone(tester);
      await tester.pumpWidget(const GuzoApp());

      expect(find.text(GuzoStrings.appName), findsOneWidget);
      expect(find.text(GuzoStrings.tagline), findsOneWidget);
      expect(find.text(GuzoStrings.quickPlay), findsOneWidget);
      expect(find.text(GuzoStrings.chooseCategory), findsOneWidget);
      expect(find.byType(CategoryTile), findsNWidgets(4));
      expect(find.byType(GuzoNavBar), findsOneWidget);
    });

    testWidgets('lists every educational category', (
      WidgetTester tester,
    ) async {
      _usePortraitPhone(tester);
      await tester.pumpWidget(const GuzoApp());

      expect(find.text(GuzoStrings.englishLetters), findsOneWidget);
      expect(find.text(GuzoStrings.numbers), findsOneWidget);
      expect(find.text(GuzoStrings.amharicLetters), findsOneWidget);
      expect(find.text(GuzoStrings.challenges), findsOneWidget);
    });

    testWidgets('a category tile opens its mode list', (
      WidgetTester tester,
    ) async {
      _usePortraitPhone(tester);
      await tester.pumpWidget(const GuzoApp());

      await tester.tap(find.text(GuzoStrings.englishLetters));
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectionScreen), findsOneWidget);
      // Every English mode in the library should be listed.
      expect(find.text(SequenceLibrary.englishAlphabet.name), findsOneWidget);
    });

    testWidgets('choosing a mode starts a run with that sequence', (
      WidgetTester tester,
    ) async {
      _usePortraitPhone(tester);
      await tester.pumpWidget(const GuzoApp());

      await tester.tap(find.text(GuzoStrings.amharicLetters));
      await tester.pumpAndSettle();
      await tester.tap(find.text(SequenceLibrary.amharicHaFamily.name));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final GameWidget<GuzoGame> widget = tester.widget(
        find.byType(GameWidget<GuzoGame>),
      );
      expect(widget.game?.sequence, SequenceLibrary.amharicHaFamily);
    });

    testWidgets('QUICK PLAY opens the Flame game screen', (
      WidgetTester tester,
    ) async {
      _usePortraitPhone(tester);
      await tester.pumpWidget(const GuzoApp());

      await tester.tap(find.text(GuzoStrings.quickPlay));
      // The Flame loop never goes idle, so pumpAndSettle would time out here.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GameWidget<GuzoGame>), findsOneWidget);
    });

    testWidgets('what is still unbuilt says so instead of failing silently', (
      WidgetTester tester,
    ) async {
      _usePortraitPhone(tester);
      await tester.pumpWidget(const GuzoApp());

      // Settings lands in a later phase; every category tile now works.
      await tester.tap(find.text(GuzoStrings.settings));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('the Play tab starts a run', (WidgetTester tester) async {
      _usePortraitPhone(tester);
      await tester.pumpWidget(const GuzoApp());

      await tester.tap(find.byIcon(Icons.sports_esports_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GameWidget<GuzoGame>), findsOneWidget);
    });
  });
}
