library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import 'package:snooze_compliance/flutterflow_project.dart' as ff;


Future<void> main(List<String> args) async {
  final options = _parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildStarterEditFlow,
      apiKey: options.apiKey,
      baseUrl: options.baseUrl,
      projectName: options.projectName,
      projectId: options.projectId,
      findOrCreate: options.findOrCreate,
      allowNewProject: options.allowNewProject,
      dryRun: options.dryRun,
      commitMessage: options.commitMessage,
    );
  } catch (error) {
    stderr.writeln('Error: ${formatFlutterFlowAIError(error)}');
    exit(1);
  }
}

final class _CliOptions {
  const _CliOptions({
    this.apiKey,
    this.baseUrl,
    this.projectName,
    this.projectId,
    this.findOrCreate = false,
    this.allowNewProject = false,
    this.dryRun = false,
    this.commitMessage,
  });

  final String? apiKey;
  final String? baseUrl;
  final String? projectName;
  final String? projectId;
  final bool findOrCreate;
  final bool allowNewProject;
  final bool dryRun;
  final String? commitMessage;
}

_CliOptions _parseCliOptions(List<String> args) {
  String? apiKey;
  String? baseUrl;
  String? projectName;
  String? projectId;
  String? commitMessage;
  var findOrCreate = false;
  var allowNewProject = false;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--help':
      case '-h':
        _printUsage();
        exit(0);
      case '--api-key':
        apiKey = _requireValue(args, ++i, '--api-key');
      case '--base-url':
        baseUrl = _requireValue(args, ++i, '--base-url');
      case '--project-name':
        projectName = _requireValue(args, ++i, '--project-name');
      case '--project-id':
        projectId = _requireValue(args, ++i, '--project-id');
      case '--commit-message':
        commitMessage = _requireValue(args, ++i, '--commit-message');
      case '--find-or-create':
        findOrCreate = true;
      case '--allow-new-project':
        allowNewProject = true;
      case '--dry-run':
        dryRun = true;
      default:
        stderr.writeln('Unknown option: $arg');
        _printUsage();
        exit(64);
    }
  }

  return _CliOptions(
    apiKey: apiKey,
    baseUrl: baseUrl,
    projectName: projectName,
    projectId: projectId,
    findOrCreate: findOrCreate,
    allowNewProject: allowNewProject,
    dryRun: dryRun,
    commitMessage: commitMessage,
  );
}

String _requireValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    stderr.writeln('Missing value for $flag.');
    _printUsage();
    exit(64);
  }
  return args[index];
}

void _printUsage() {
  stdout.writeln('''
Run the KYA wiring pass.

Usage:
  dart run dsl/edit.dart [options]

Options:
  --api-key <key>           FlutterFlow API key. Defaults to FF_API_KEY.
  --base-url <url>          Override the FlutterFlow API base URL.
  --project-name <name>     Create a new project with this name.
  --project-id <id>         Push into an existing project by ID.
  --find-or-create          Retry by reusing a same-name project before creating.
  --allow-new-project       Bypass the workspace binding guard and create a different project.
  --commit-message <text>   Commit message for the push.
  --dry-run                 Compile and validate without pushing.
  --help, -h                Show this help.
''');
}

// ---------------------------------------------------------------------------
// KYA wiring pass
//
// The build pass (dsl/kya_build.dart) had to declare the eleven stage pages in
// reverse navigation order, because a Navigate only compiles once its target
// page exists. KYA's flow is a cycle — the snooze always returns you to the
// alarm — so three edges could not be wired there and are attached here:
//
//   AlarmStopped     "RESTART DEMO" -> ActiveAlarm
//   AuthorizedSnooze "WAKE ME NOW"  -> ActiveAlarm
//   AuthorizedSnooze countdown ends -> ActiveAlarm
//
// This pass also moves ActiveAlarm onto the root route (the wipe pass'
// placeholder held it during the build) and drops the app-state fields left
// over from the pre-port scaffold.
// ---------------------------------------------------------------------------

// Widget keys from lib/flutterflow_project/pages/*.dart.
const _restartDemoButtonKey = 'Button_ni653ghv';
const _wakeNowButtonKey = 'Button_xu31i1vi';

/// Handle for the already-pushed `kyaDecrement` custom function.
final _decrement = CustomFunctionHandle(
  name: 'kyaDecrement',
  args: {'value': int_},
  returnType: int_,
);

/// App-state fields from the pre-port scaffold that nothing references now.
const _staleAppStateFields = {
  'currentCaseId',
  'officerPersonality',
  'searchQuery',
};

void buildStarterEditFlow(App app) {
  final startAlarm = app.existingCustomAction('kyaStartAlarm');

  // -- AlarmStopped: RESTART DEMO returns to a fully reset alarm ------------
  app.editPage(ff.Pages.alarmStopped, (page) {
    page.ensureActions(
      ff.Pages.alarmStopped.widgets.byKey(_restartDemoButtonKey),
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        UpdateAppState.set(ff.AppState.alarmReturned, false),
        UpdateAppState.set(ff.AppState.dodgeCount, 0),
        UpdateAppState.set(ff.AppState.reasonText, ''),
        UpdateAppState.set(ff.AppState.reasonError, ''),
        UpdateAppState.set(ff.AppState.captchaBed, false),
        UpdateAppState.set(ff.AppState.captchaCoffee, false),
        UpdateAppState.set(ff.AppState.captchaLaptop, false),
        UpdateAppState.set(ff.AppState.captchaPillow, false),
        UpdateAppState.set(ff.AppState.captchaDumbbell, false),
        UpdateAppState.set(ff.AppState.captchaAirplane, false),
        UpdateAppState.set(ff.AppState.captchaFailed, false),
        UpdateAppState.set(ff.AppState.captchaAttempt, 0),
        UpdateAppState.set(ff.AppState.officerTestimony, ''),
        UpdateAppState.set(ff.AppState.officerRejected, false),
        UpdateAppState.set(ff.AppState.processingTick, 0),
        UpdateAppState.set(ff.AppState.identityTick, 0),
        UpdateAppState.set(ff.AppState.identityScanning, false),
        UpdateAppState.set(ff.AppState.identityComplete, false),
        UpdateAppState.set(ff.AppState.secondsLeft, 30),
        startAlarm(),
        Navigate(ff.Pages.activeAlarm),
      ],
    );
  });

  // -- AuthorizedSnooze: WAKE ME NOW ends the snooze early ------------------
  app.editPage(ff.Pages.authorizedSnooze, (page) {
    page.ensureActions(
      ff.Pages.authorizedSnooze.widgets.byKey(_wakeNowButtonKey),
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        UpdateAppState.set(ff.AppState.alarmReturned, true),
        UpdateAppState.set(ff.AppState.dodgeCount, 0),
        startAlarm(),
        Navigate(ff.Pages.activeAlarm),
      ],
    );
  });

  // -- AuthorizedSnooze: the 30-second countdown, and the alarm's return ----
  app.editPageOnLoad(ff.Pages.authorizedSnooze, [
    UpdateAppState.set(ff.AppState.secondsLeft, 30),
    StartPeriodic('kyaSnooze', durationMillis: 1000),
    UpdateAppState.set(
      ff.AppState.secondsLeft,
      CustomFunction(_decrement, args: {'value': AppState(ff.AppState.secondsLeft)}),
    ),
    If(
      Equals(AppState(ff.AppState.secondsLeft), 0),
      then: [
        StopPeriodic('kyaSnooze'),
        UpdateAppState.set(ff.AppState.alarmReturned, true),
        UpdateAppState.set(ff.AppState.dodgeCount, 0),
        startAlarm(),
        Navigate(ff.Pages.activeAlarm),
      ],
    ),
  ]);

  // -- Scaffold leftovers the port does not use ----------------------------
  //
  // `aiSnoozeOfficerFormSendMessageItem` belonged to the deleted placeholder
  // AISnoozeOfficer page's chat form; it no longer compiles and nothing calls
  // it. The two collections are from the same scaffold — KYA runs entirely
  // local, with no account or backend.
  app.removeCustomFunction('aiSnoozeOfficerFormSendMessageItem');
  app.removeCollection('snooze_requests');
  app.removeCollection('compliance_logs');

  app.raw((project) {
    // The placeholder that held '/' during the build is gone, so the alarm
    // can take the root route back. '' is the normalized root path.
    final alarm = findPage(project, name: 'ActiveAlarm');
    if (alarm != null) {
      alarm.ensurePageRouteSettings().routePath = '';
    }

    // Drop the leftovers from the pre-port scaffold.
    project.appState.fields.removeWhere(
      (field) => _staleAppStateFields.contains(field.parameter.identifier.name),
    );
  });
}
