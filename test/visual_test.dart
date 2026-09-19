import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kya/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final (family, asset) in [
      ('Fredoka', 'assets/fonts/Fredoka.ttf'),
      ('Nunito', 'assets/fonts/Nunito.ttf'),
      ('RobotoMono', 'assets/fonts/RobotoMono.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  testWidgets('mobile alarm visual', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const KyaApp(audioEnabled: false, cameraEnabled: false),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/mascot/alby-happy.png'),
        tester.element(find.byType(KyaApp)),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/mobile.png'),
    );
  });

  testWidgets('mobile alarm dark appearance', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(() {
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      tester.view.reset();
    });
    await tester.pumpWidget(
      const KyaApp(audioEnabled: false, cameraEnabled: false),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/mascot/alby-happy.png'),
        tester.element(find.byType(KyaApp)),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/mobile-dark.png'),
    );
  });

  testWidgets('mobile alarm enlarged text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.view.reset();
    });
    await tester.pumpWidget(
      const KyaApp(audioEnabled: false, cameraEnabled: false),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/mascot/alby-happy.png'),
        tester.element(find.byType(KyaApp)),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/mobile-large-text.png'),
    );
  });

  testWidgets('desktop alarm visual', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const KyaApp(audioEnabled: false, cameraEnabled: false),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/mascot/alby-happy.png'),
        tester.element(find.byType(KyaApp)),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/desktop.png'),
    );
  });

  testWidgets('critical flow state visuals', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const KyaApp(audioEnabled: false, cameraEnabled: false),
    );
    final context = tester.element(find.byType(KyaApp));
    await tester.runAsync(
      () => Future.wait([
        for (final asset in [
          'assets/mascot/alby-happy.png',
          'assets/mascot/alby-officer.png',
          'assets/mascot/alby-suspicious.png',
          'assets/mascot/alby-celebrate.png',
        ])
          precacheImage(AssetImage(asset), context),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('snoozeButton')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('trapSnoozeButton')));
      await tester.pumpAndSettle();
    }
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/flow-intro.png'),
    );

    await tester.tap(find.byKey(const Key('startVerificationButton')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/flow-reason.png'),
    );
    await tester.enterText(
      find.byKey(const Key('reasonField')),
      'I only slept four hours because my pillow required additional compliance paperwork.',
    );
    await tester.tap(find.byKey(const Key('reasonNextButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('captcha-0')));
    await tester.tap(find.byKey(const Key('captchaVerifyButton')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/flow-captcha-failed.png'),
    );
    await tester.tap(find.byKey(const Key('captchaVerifyButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('captcha-1')));
    await tester.tap(find.byKey(const Key('captchaVerifyButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('officerField')),
      "I'm just really tired.",
    );
    await tester.tap(find.byKey(const Key('sendTestimonyButton')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('appealButton')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/flow-officer-rejected.png'),
    );

    await tester.tap(find.byKey(const Key('appealButton')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/flow-processing.png'),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/flow-identity.png'),
    );
    await tester.tap(find.byKey(const Key('startIdentityScanButton')));
    await tester.pump(const Duration(seconds: 32));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(KyaApp),
      matchesGoldenFile('../.impeccable/review/flow-approved.png'),
    );
  });
}
