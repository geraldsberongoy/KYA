import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:test/test.dart';

import '../dsl/kya_build.dart' as kya;

const _stagePages = [
  'ActiveAlarm',
  'SnoozeDodge',
  'KYAIntroduction',
  'ReasonForSnoozing',
  'WakefulnessCAPTCHA',
  'AISnoozeOfficer',
  'BureaucraticProcessing',
  'IdentityWakeCheck',
  'SnoozeApproval',
  'AuthorizedSnooze',
  'AlarmStopped',
];

void main() {
  late FFProject project;

  setUpAll(() {
    // `snoozeCount` predates the port and is referenced, not declared, by the
    // build pass — so the target project has to carry it.
    final seed = compileApp(
      buildApp((app) => app.state('snoozeCount', int_)),
    ).project;
    project = compileApp(buildApp(kya.buildKyaPort), project: seed).project;
  });

  test('every KYA stage is a page', () {
    for (final name in _stagePages) {
      expect(findPage(project, name: name), isNotNull, reason: 'missing $name');
    }
  });

  test('the alarm is the initial page', () {
    final alarm = findPage(project, name: 'ActiveAlarm');
    expect(alarm, isNotNull);
    expect(alarm!.node.type, FFWidgetType.Scaffold);
  });

  test('shared chrome is extracted into components', () {
    // The status bar is deliberately inline: a component body cannot resolve
    // Navigate('AlarmStopped'), since components compile before pages.
    for (final name in [
      'StepProgress',
      'CaseFooter',
      'OfficialSeal',
      'AlertBanner',
      'ChatBubble',
    ]) {
      expect(
        findComponent(project, name: name),
        isNotNull,
        reason: 'missing component $name',
      );
    }
  });

  test('the ported custom code is registered', () {
    expect(findCustomWidget(project, name: 'KyaFaceScan'), isNotNull);
    expect(findCustomWidget(project, name: 'KyaProgressBar'), isNotNull);
    expect(findCustomAction(project, name: 'kyaStartAlarm'), isNotNull);
    expect(findCustomAction(project, name: 'kyaStopAlarm'), isNotNull);
    expect(findPubDependency(project, name: 'audioplayers'), isNotNull);
    expect(findPubDependency(project, name: 'camera'), isNotNull);
  });
}
