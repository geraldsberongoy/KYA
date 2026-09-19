import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kya/main.dart';

void main() {
  testWidgets('complete KYA flow remains finishable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 880));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const KyaApp(audioEnabled: false, cameraEnabled: false),
    );

    expect(find.text('Good morning!'), findsOneWidget);
    await tester.tap(find.byKey(const Key('snoozeButton')));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('trapSnoozeButton')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Snooze Termination\nRequest'), findsOneWidget);

    await tester.tap(find.byKey(const Key('startVerificationButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reasonField')),
      'I only slept four hours because my pillow required additional compliance paperwork.',
    );
    await tester.tap(find.byKey(const Key('reasonNextButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('captcha-0')));
    await tester.tap(find.byKey(const Key('captchaVerifyButton')));
    await tester.pumpAndSettle();
    expect(find.text('Verification failed.'), findsOneWidget);
    // Selecting again must unlock the second attempt even if retry is skipped.
    await tester.tap(find.byKey(const Key('captcha-1')));
    await tester.tap(find.byKey(const Key('captchaVerifyButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('officerField')),
      "I'm just really tired.",
    );
    await tester.tap(find.byKey(const Key('sendTestimonyButton')));
    await tester.pumpAndSettle();
    expect(find.textContaining('REJECTED.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('appealButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appealButton')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();

    expect(find.text('Identity Wake Check'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startIdentityScanButton')));
    await tester.pump(const Duration(seconds: 32));
    await tester.pumpAndSettle();

    expect(find.text('KYA Verified!'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startSnoozeButton')));
    await tester.pumpAndSettle();
    expect(
      find.text('Authorized unconsciousness\nin progress'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('wakeNowButton')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back!'), findsOneWidget);
  });
}
