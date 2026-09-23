library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import 'package:snooze_compliance/flutterflow_project.dart' as ff;


Future<void> main(List<String> args) async {
  final options = _parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildKyaPort,
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
Run the KYA build pass (one-shot: it declares every page).

Usage:
  dart run dsl/kya_build.dart [options]

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
// KYA — Know Your Alarm
//
// Port of github.com/geraldsberongoy/KYA (lib/main.dart). The source is one
// stateful widget driving an eleven-value `KyaStage` enum; each stage becomes
// a page here, and the stage-local fields become app state so the flow
// survives navigation between them.
// ---------------------------------------------------------------------------

// Uploaded asset storage paths — never Flutter bundle paths.
const _albyHappy =
    'projects/snooze-compliance-cxmajk/assets/e645bed3062b0bbf/alby-happy.png';
const _albySuspicious =
    'projects/snooze-compliance-cxmajk/assets/db6ca6a9d62cec12/alby-suspicious.png';
const _albyOfficer =
    'projects/snooze-compliance-cxmajk/assets/1cb6348a7f29d367/alby-officer.png';
const _albyCelebrate =
    'projects/snooze-compliance-cxmajk/assets/44cc2ce9507d0195/alby-celebrate.png';
const _fredokaFont =
    'projects/snooze-compliance-cxmajk/assets/0854f1d71d9ed13c/Fredoka.ttf';
const _nunitoFont =
    'projects/snooze-compliance-cxmajk/assets/38b76d3d513d727e/Nunito.ttf';
const _robotoMonoFont =
    'projects/snooze-compliance-cxmajk/assets/170c09abe9d7b47c/RobotoMono.ttf';

// KyaColors, verbatim from the source.
const _yellow = 0xFFFFD93D;
const _blue = 0xFF2F8CFF;
const _red = 0xFFFF4655;
const _green = 0xFF66CC78;
const _cream = 0xFFFFFDF5;
const _ink = 0xFF17191C;
const _gray = 0xFF687280;
const _navy = 0xFF162333;
const _white = 0xFFFFFFFF;

const _reasons = [
  'I am tired',
  'I require additional sleep',
  'Alarm was premature',
  'I accidentally became conscious',
];

const _processingTasks = [
  'Reviewing your sleep history...',
  'Contacting your pillow...',
  'Consulting the International Sleep Authority...',
  'Evaluating vibes...',
  'Determining whether you are actually tired...',
  'Almost there...',
];

const _mono = NamedTextStyle('labelMedium');
const _monoSmall = NamedTextStyle('labelSmall');

DslWidget _primaryButton(
  Object label, {
  required int color,
  Object? onTap,
  String? name,
  Object? visible,
  bool disabled = false,
}) => Button(
  label,
  color: Colors.hex(color),
  textColor: Colors.hex(_white),
  width: double.infinity,
  height: 58,
  borderRadius: 16,
  padding: EdgeInsets.symmetric(vertical: 14),
  onTap: onTap,
  name: name,
  visible: visible,
  disabled: disabled,
);

DslWidget _secondaryButton(
  Object label, {
  Object? onTap,
  String? name,
  Object? visible,
  bool dark = false,
}) => Button(
  label,
  variant: ButtonVariant.outlined,
  textColor: dark ? Colors.hex(_white) : Colors.primaryText,
  width: double.infinity,
  height: 52,
  borderRadius: 15,
  padding: EdgeInsets.symmetric(vertical: 12),
  onTap: onTap,
  name: name,
  visible: visible,
);

// The status bar is a plain Dart helper rather than a FlutterFlow component:
// components compile before pages, so a component body can never resolve
// Navigate('AlarmStopped').
DslWidget _statusBar({required bool showCase, required String name}) => Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 18),
      name: name,
      child: Row(
        crossAxis: CrossAxis.center,
        children: [
          Text('6:00', style: _mono, color: Colors.primaryText),
          Expanded(
            Text(
              'CASE KYA-0018',
              style: _monoSmall,
              color: Colors.secondaryText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.fade,
              visible: showCase,
            ),
          ),
          IconButton(
            'close',
            size: 24,
            color: Colors.primaryText,
            onTap: [Navigate('AlarmStopped')],
          ),
        ],
      ),
    );

void buildKyaPort(App app) {
  // -------------------------------------------------------------------------
  // Theme — KyaColors plus the Fredoka / Nunito / RobotoMono type scale.
  // -------------------------------------------------------------------------
  app.themeColor('primary', _blue);
  app.themeColor('secondary', _gray);
  app.themeColor('tertiary', _green);
  app.themeColor('alternate', 0xFFD5D8DC, dark: 0xFF3A424C);
  app.themeColor('primaryBackground', _cream, dark: 0xFF14181E);
  app.themeColor('secondaryBackground', _white, dark: 0xFF242A32);
  app.themeColor('primaryText', _ink, dark: 0xFFF8F4EA);
  app.themeColor('secondaryText', _gray, dark: 0xFFB6BDC6);
  app.themeColor('accent1', _yellow);
  app.themeColor('accent2', _navy);
  app.themeColor('accent3', 0xFFFFF4C8);
  app.themeColor('accent4', 0xFFFFE6E8);
  app.themeColor('success', _green);
  app.themeColor('warning', _yellow);
  app.themeColor('error', _red);
  app.themeColor('info', _blue);
  app.darkMode(enabled: true);

  app.customFont('Fredoka', files: [CustomFontFile(fontFilePath: _fredokaFont)]);
  app.customFont('Nunito', files: [CustomFontFile(fontFilePath: _nunitoFont)]);
  app.customFont(
    'RobotoMono',
    files: [CustomFontFile(fontFilePath: _robotoMonoFont)],
  );
  app.primaryFont('Nunito');
  app.secondaryFont('Fredoka');

  // KYA's type scale mapped onto the ten style slots the DSL exposes:
  //   headlineMedium = the 52px Fredoka display, headlineSmall = 34px,
  //   titleLarge = 27px, titleMedium = 20px, titleSmall = 16px button text,
  //   labelMedium / labelSmall = the RobotoMono bureaucracy.
  app.typography('headlineMedium',
      fontFamily: 'Fredoka', fontSize: 52, fontWeight: 700);
  app.typography('headlineSmall',
      fontFamily: 'Fredoka', fontSize: 34, fontWeight: 700);
  app.typography('titleLarge',
      fontFamily: 'Fredoka', fontSize: 27, fontWeight: 600);
  app.typography('titleMedium',
      fontFamily: 'Nunito', fontSize: 20, fontWeight: 800);
  app.typography('titleSmall',
      fontFamily: 'Nunito', fontSize: 16, fontWeight: 800);
  app.typography('bodyLarge',
      fontFamily: 'Nunito', fontSize: 17, fontWeight: 600);
  app.typography('bodyMedium',
      fontFamily: 'Nunito', fontSize: 15, fontWeight: 600);
  app.typography('bodySmall',
      fontFamily: 'Nunito', fontSize: 13, fontWeight: 600);
  app.typography('labelMedium',
      fontFamily: 'RobotoMono', fontSize: 12, fontWeight: 800);
  app.typography('labelSmall',
      fontFamily: 'RobotoMono', fontSize: 10, fontWeight: 700);

  // -------------------------------------------------------------------------
  // App state — the _KyaFlowState fields, hoisted so the flow survives
  // page-to-page navigation.
  // -------------------------------------------------------------------------
  // `snoozeCount` already exists on the project; redeclaring it with a
  // different payload would trip the ensure-only guard, so it is used as-is.
  app.state('alarmReturned', bool_.withDefault(false),
      description: 'True once the 30-second snooze has expired.');
  app.state('dodgeCount', int_.withDefault(0),
      description: 'How many times the hostile snooze button has dodged.');
  app.state('selectedReason', string.withDefault(_reasons[0]));
  app.state('reasonText', string.withDefault(''));
  app.state('reasonError', string.withDefault(''));
  app.state('captchaBed', bool_.withDefault(false));
  app.state('captchaCoffee', bool_.withDefault(false));
  app.state('captchaLaptop', bool_.withDefault(false));
  app.state('captchaPillow', bool_.withDefault(false));
  app.state('captchaDumbbell', bool_.withDefault(false));
  app.state('captchaAirplane', bool_.withDefault(false));
  app.state('captchaFailed', bool_.withDefault(false));
  app.state('captchaAttempt', int_.withDefault(0));
  app.state('officerTestimony', string.withDefault(''));
  app.state('officerRejected', bool_.withDefault(false));
  app.state('processingTick', int_.withDefault(0));
  app.state('identityTick', int_.withDefault(0));
  app.state('identityScanning', bool_.withDefault(false));
  app.state('identityComplete', bool_.withDefault(false));
  app.state('secondsLeft', int_.withDefault(30));

  // -------------------------------------------------------------------------
  // Pub dependencies for the ported custom code.
  // -------------------------------------------------------------------------
  app.pubDependency('audioplayers', '^6.8.1');
  app.pubDependency('camera', '^0.12.1');

  // -------------------------------------------------------------------------
  // Custom functions — the arithmetic and copy switches the DSL expression
  // surface has no operators for.
  // -------------------------------------------------------------------------
  final increment = app.customFunction(
    'kyaIncrement',
    args: {'value': int_},
    returns: int_,
    description: 'Adds one to a counter.',
    code: r'''
int kyaIncrement(int value) {
  return value + 1;
}
''',
  );

  final decrement = app.customFunction(
    'kyaDecrement',
    args: {'value': int_},
    returns: int_,
    description: 'Subtracts one from a counter, clamped at zero.',
    code: r'''
int kyaDecrement(int value) {
  return value <= 0 ? 0 : value - 1;
}
''',
  );

  final countdownLabel = app.customFunction(
    'kyaCountdownLabel',
    args: {'seconds': int_},
    returns: string,
    description: 'Formats the authorized snooze countdown as 00:00:SS.',
    code: r'''
String kyaCountdownLabel(int seconds) {
  final clamped = seconds < 0 ? 0 : seconds;
  return '00:00:${clamped.toString().padLeft(2, '0')}';
}
''',
  );

  final hasSufficientReason = app.customFunction(
    'kyaHasSufficientReason',
    args: {'text': string},
    returns: bool_,
    description: 'The 50-character "sleepy context" gate on the reason form.',
    code: r'''
bool kyaHasSufficientReason(String text) {
  return text.trim().length >= 50;
}
''',
  );

  final anyCaptchaSelected = app.customFunction(
    'kyaAnyCaptchaSelected',
    args: {
      'bed': bool_,
      'coffee': bool_,
      'laptop': bool_,
      'pillow': bool_,
      'dumbbell': bool_,
      'airplane': bool_,
    },
    returns: bool_,
    description: 'True when at least one CAPTCHA tile is selected.',
    code: r'''
bool kyaAnyCaptchaSelected(
  bool bed,
  bool coffee,
  bool laptop,
  bool pillow,
  bool dumbbell,
  bool airplane,
) {
  return bed || coffee || laptop || pillow || dumbbell || airplane;
}
''',
  );

  final processingValue = app.customFunction(
    'kyaProcessingValue',
    args: {'tick': int_},
    returns: double_,
    description: 'The dishonest progress curve: .16 .38 .68 .97 .94 .97 1.0',
    code: r'''
double kyaProcessingValue(int tick) {
  const values = [0.16, 0.38, 0.68, 0.97, 0.94, 0.97, 1.0];
  if (tick <= 0) return 0;
  if (tick > values.length) return 1;
  return values[tick - 1];
}
''',
  );

  final processingPercent = app.customFunction(
    'kyaProcessingPercent',
    args: {'tick': int_},
    returns: string,
    description: 'Percentage readout beside the processing bar.',
    code: r'''
String kyaProcessingPercent(int tick) {
  const values = [0.16, 0.38, 0.68, 0.97, 0.94, 0.97, 1.0];
  final value = tick <= 0
      ? 0.0
      : tick > values.length
          ? 1.0
          : values[tick - 1];
  return '${(value * 100).round()}%';
}
''',
  );

  final processingComplete = app.customFunction(
    'kyaProcessingComplete',
    args: {'tick': int_},
    returns: bool_,
    description: 'True once the fake review has burned through every step.',
    code: r'''
bool kyaProcessingComplete(int tick) {
  return tick >= 7;
}
''',
  );

  final processingNote = app.customFunction(
    'kyaProcessingNote',
    args: {'tick': int_},
    returns: string,
    description: 'The wait-time joke under the progress bar.',
    code: r'''
String kyaProcessingNote(int tick) {
  const values = [0.16, 0.38, 0.68, 0.97, 0.94, 0.97, 1.0];
  final value = tick <= 0
      ? 0.0
      : tick > values.length
          ? 1.0
          : values[tick - 1];
  return value >= 0.94
      ? 'This may take several mornings.'
      : 'This may take a few seconds.';
}
''',
  );

  final taskState = app.customFunction(
    'kyaTaskState',
    args: {'tick': int_, 'index': int_},
    returns: string,
    description: 'done / active / pending for one processing checklist row.',
    code: r'''
String kyaTaskState(int tick, int index) {
  final completed = (tick / 2).floor().clamp(0, 3);
  if (index < completed) return 'done';
  if (index == completed) return 'active';
  return 'pending';
}
''',
  );

  final identityValue = app.customFunction(
    'kyaIdentityValue',
    args: {'tick': int_},
    returns: double_,
    description: 'Face-scan progress across the 30 second scan.',
    code: r'''
double kyaIdentityValue(int tick) {
  if (tick <= 0) return 0;
  if (tick >= 30) return 1;
  return tick / 30;
}
''',
  );

  final identityComplete = app.customFunction(
    'kyaIdentityComplete',
    args: {'tick': int_},
    returns: bool_,
    description: 'True once the face scan has run its full 30 seconds.',
    code: r'''
bool kyaIdentityComplete(int tick) {
  return tick >= 30;
}
''',
  );

  final identityPrompt = app.customFunction(
    'kyaIdentityPrompt',
    args: {'tick': int_, 'scanning': bool_, 'complete': bool_},
    returns: string,
    description: 'Front / left / right instruction during the face scan.',
    code: r'''
String kyaIdentityPrompt(int tick, bool scanning, bool complete) {
  if (complete) return 'Identity confirmed. Somehow.';
  if (!scanning) return 'Center your face to begin';
  if (tick < 10) return 'Face front. Pretend you read the terms.';
  if (tick < 20) return 'Turn left. Avoid eye contact with responsibility.';
  return 'Turn right. Check for unfinished tasks.';
}
''',
  );

  final identityPhase = app.customFunction(
    'kyaIdentityPhase',
    args: {'tick': int_},
    returns: string,
    description: 'The PHASE - seconds readout under the scan frame.',
    code: r'''
String kyaIdentityPhase(int tick) {
  final phase = tick < 10
      ? 'FRONT'
      : tick < 20
          ? 'LEFT'
          : 'RIGHT';
  final secondsRemaining = 10 - (tick % 10);
  return '$phase • $secondsRemaining seconds';
}
''',
  );

  final scanButtonLabel = app.customFunction(
    'kyaScanButtonLabel',
    args: {'scanning': bool_, 'complete': bool_},
    returns: string,
    description: 'Label for the face-scan button across its three states.',
    code: r'''
String kyaScanButtonLabel(bool scanning, bool complete) {
  if (complete) return 'IDENTITY CONFIRMED';
  if (scanning) return 'SCANNING...';
  return 'BEGIN FACE SCAN';
}
''',
  );

  // -------------------------------------------------------------------------
  // Custom actions — the looping alarm, ported from the audioplayers usage in
  // _startAlarm / _silenceAlarm.
  // -------------------------------------------------------------------------
  final startAlarm = app.customAction(
    'kyaStartAlarm',
    description: 'Starts the looping alarm tone. Never throws.',
    code: r'''
import 'package:audioplayers/audioplayers.dart';

AudioPlayer? _kyaAlarmPlayer;

Future<void> kyaStartAlarm() async {
  try {
    final player = _kyaAlarmPlayer ??= AudioPlayer();
    if (player.state == PlayerState.playing) return;
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('audios/modern-alarm-1.mp3'));
  } catch (_) {
    // Browsers may block autoplay; the next interaction retries it.
  }
}
''',
  );

  final stopAlarm = app.customAction(
    'kyaStopAlarm',
    description: 'Silences the alarm. Audio is never critical to the escape.',
    code: r'''
import 'package:audioplayers/audioplayers.dart';

AudioPlayer? _kyaAlarmStopPlayer;

Future<void> kyaStopAlarm() async {
  try {
    await (_kyaAlarmStopPlayer ??= AudioPlayer()).stop();
  } catch (_) {
    // Audio is never critical to the escape path.
  }
}
''',
  );

  // -------------------------------------------------------------------------
  // Custom widgets — the linear progress bar the DSL has no widget for, and
  // the live camera face-scan frame.
  // -------------------------------------------------------------------------
  final dynamic progressBar = app.customWidget(
    'KyaProgressBar',
    parameters: {
      'value': double_,
      'barArgb': int_,
      'trackArgb': int_,
      'thickness': double_,
    },
    description: 'Rounded linear progress bar in KYA colors.',
    code: r'''
import 'package:flutter/material.dart';

class KyaProgressBar extends StatelessWidget {
  const KyaProgressBar({
    super.key,
    this.width,
    this.height,
    required this.value,
    required this.barArgb,
    required this.trackArgb,
    required this.thickness,
  });

  final double? width;
  final double? height;
  final double value;
  final int barArgb;
  final int trackArgb;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? thickness,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(thickness / 2),
        child: LinearProgressIndicator(
          minHeight: thickness,
          value: value.clamp(0.0, 1.0),
          color: Color(barArgb),
          backgroundColor: Color(trackArgb),
        ),
      ),
    );
  }
}
''',
  );

  final dynamic faceScan = app.customWidget(
    'KyaFaceScan',
    parameters: {
      'progress': double_,
      'scanning': bool_,
      'complete': bool_,
    },
    description: 'Live front-camera preview with the mock KYC scan overlay.',
    code: r'''
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class KyaFaceScan extends StatefulWidget {
  const KyaFaceScan({
    super.key,
    this.width,
    this.height,
    required this.progress,
    required this.scanning,
    required this.complete,
  });

  final double? width;
  final double? height;
  final double progress;
  final bool scanning;
  final bool complete;

  @override
  State<KyaFaceScan> createState() => _KyaFaceScanState();
}

class _KyaFaceScanState extends State<KyaFaceScan> {
  static const _navy = Color(0xFF162333);
  static const _blue = Color(0xFF2F8CFF);
  static const _green = Color(0xFF66CC78);

  CameraController? _controller;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_loading || _controller != null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('noCamera', 'No camera');
      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Camera unavailable — demo scan still works.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = _controller;
    final cameraReady = camera?.value.isInitialized ?? false;
    return SizedBox(
      width: widget.width,
      height: widget.height ?? 330,
      child: Container(
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: widget.complete ? _green : _blue,
            width: 3,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (cameraReady)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: CameraPreview(camera!),
                ),
              )
            else
              Icon(
                widget.complete
                    ? Icons.verified_user_rounded
                    : Icons.face_rounded,
                color: widget.complete ? _green : Colors.white70,
                size: 122,
              ),
            Container(
              width: 205,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(110),
                border: Border.all(color: Colors.white54, width: 3),
              ),
            ),
            if (widget.scanning)
              Align(
                alignment: Alignment(0, (widget.progress * 2) - 1),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 58),
                  height: 3,
                  decoration: const BoxDecoration(
                    color: _blue,
                    boxShadow: [
                      BoxShadow(color: _blue, blurRadius: 14, spreadRadius: 3),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 16,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MOCK KYC • DEMO MODE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'RobotoMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (_loading)
              const CircularProgressIndicator(color: Colors.white),
            if (_error != null)
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
''',
  );

  // -------------------------------------------------------------------------
  // Components — the shared chrome from the source's private widgets.
  // -------------------------------------------------------------------------
  final dynamic stepProgress = app.component(
    'StepProgress',
    description: 'STEP n OF 4 header with its progress bar.',
    params: {
      'step': int_.withDefault(1),
      'label': string.withDefault(''),
      'value': double_.withDefault(0.25),
    },
    body: Column(
      crossAxis: CrossAxis.stretch,
      spacing: 9,
      children: [
        Row(
          children: [
            Text('STEP ', style: _mono, color: Colors.primaryText),
            Text(Param('step'), style: _mono, color: Colors.primaryText),
            Text(' OF 4', style: _mono, color: Colors.primaryText),
            Expanded(
              Text(
                Param('label'),
                style: _monoSmall,
                color: Colors.secondaryText,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        progressBar(
          name: 'StepProgressBar',
          value: Param('value'),
          barArgb: _blue,
          trackArgb: 0xFFDCE0E5,
          thickness: 8.0,
        ),
      ],
    ),
  );

  final dynamic caseFooter = app.component(
    'CaseFooter',
    description: 'Form / case / risk strip printed under the intro screen.',
    body: Text(
      'FORM KYA-001B  •  CASE ID: KYA-0018  •  RISK: SLEEPY',
      style: _monoSmall,
      color: Colors.secondaryText,
      textAlign: TextAlign.center,
    ),
  );

  final dynamic officialSeal = app.component(
    'OfficialSeal',
    description: 'The bureaucratic seal — rounded badge or squared document.',
    params: {'square': bool_.withDefault(false)},
    body: Stack(
      width: 82,
      height: 82,
      children: [
        Container(
          width: 82,
          height: 82,
          color: Colors.accent3,
          borderRadius: 24,
          borderColor: Colors.secondary,
          borderWidth: 2,
          alignment: Alignment.center,
          visible: Not(Param('square')),
          child: Icon('badge', size: 43, color: Colors.accent2),
        ),
        Container(
          width: 82,
          height: 82,
          color: Colors.accent3,
          borderRadius: 12,
          borderColor: Colors.secondary,
          borderWidth: 2,
          alignment: Alignment.center,
          visible: Param('square'),
          child: Icon('description', size: 43, color: Colors.accent2),
        ),
      ],
    ),
  );

  final dynamic alertBanner = app.component(
    'AlertBanner',
    description: 'Red rejection banner used by the CAPTCHA failure state.',
    params: {
      'title': string.withDefault(''),
      'message': string.withDefault(''),
    },
    body: Container(
      padding: 14,
      borderRadius: 12,
      color: Colors.accent4,
      borderColor: Colors.error,
      borderWidth: 1,
      child: Row(
        crossAxis: CrossAxis.center,
        spacing: 10,
        children: [
          Icon('cancel', size: 22, color: Colors.error),
          Expanded(
            Column(
              crossAxis: CrossAxis.start,
              children: [
                Text(Param('title'), style: Styles.titleSmall, color: Colors.error),
                Text(
                  Param('message'),
                  style: Styles.bodyMedium,
                  color: Colors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  final dynamic chatBubble = app.component(
    'ChatBubble',
    description: 'One line of the AI Snooze Officer transcript.',
    params: {
      'text': string.withDefault(''),
      'fromOfficer': bool_.withDefault(true),
      'rejected': bool_.withDefault(false),
    },
    body: Column(
      crossAxis: CrossAxis.stretch,
      children: [
        Row(
          mainAxis: MainAxis.start,
          visible: Param('fromOfficer'),
          children: [
            Flexible(
              Container(
                padding: 15,
                borderRadius: 12,
                color: Colors.secondaryBackground,
                visible: Not(Param('rejected')),
                child: Text(
                  Param('text'),
                  style: Styles.bodyMedium,
                  color: Colors.primaryText,
                ),
              ),
            ),
            Flexible(
              Container(
                padding: 15,
                borderRadius: 12,
                color: Colors.accent4,
                borderColor: Colors.error,
                borderWidth: 1,
                visible: Param('rejected'),
                child: Text(
                  Param('text'),
                  style: Styles.bodyMedium,
                  color: Colors.primaryText,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxis: MainAxis.end,
          visible: Not(Param('fromOfficer')),
          children: [
            Flexible(
              Container(
                padding: 15,
                borderRadius: 12,
                color: Colors.primary,
                child: Text(
                  Param('text'),
                  style: Styles.bodyMedium,
                  color: Colors.hex(_white),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // Checklist row on the processing screen: done / active / pending.
  DslWidget processingRow(int index) => Row(
        crossAxis: CrossAxis.center,
        spacing: 12,
        children: [
          Icon(
            'check_circle',
            size: 24,
            color: Colors.success,
            visible: Equals(
              CustomFunction(taskState,
                  args: {'tick': AppState('processingTick'), 'index': index}),
              'done',
            ),
          ),
          ProgressBar.circular(
            size: 32,
            thickness: 3,
            visible: Equals(
              CustomFunction(taskState,
                  args: {'tick': AppState('processingTick'), 'index': index}),
              'active',
            ),
          ),
          Icon(
            'radio_button_unchecked',
            size: 24,
            color: Colors.secondaryText,
            visible: Equals(
              CustomFunction(taskState,
                  args: {'tick': AppState('processingTick'), 'index': index}),
              'pending',
            ),
          ),
          Expanded(
            Text(
              _processingTasks[index],
              style: Styles.bodyMedium,
              color: Colors.primaryText,
            ),
          ),
        ],
      );

  // One CAPTCHA tile. Tapping toggles its own app-state flag.
  DslWidget captchaTile(String label, String icon, String field) => Expanded(
        Container(
          height: 104,
          borderRadius: 12,
          color: Colors.secondaryBackground,
          borderColor: Colors.alternate,
          borderWidth: 1,
          alignment: Alignment.center,
          onTap: [
            UpdateAppState.toggle(field),
            UpdateAppState.set('captchaFailed', false),
          ],
          child: Stack(
            children: [
              Column(
                mainAxis: MainAxis.center,
                spacing: 6,
                children: [
                  Icon(icon, size: 34, color: Colors.primaryText),
                  Text(label, style: Styles.titleSmall, color: Colors.primaryText),
                ],
              ),
              Row(
                mainAxis: MainAxis.end,
                crossAxis: CrossAxis.start,
                visible: AppState(field),
                children: [
                  Icon('check_circle', size: 22, color: Colors.primary),
                ],
              ),
            ],
          ),
        ),
      );

  // -------------------------------------------------------------------------
  // AlarmStopped — the escape hatch. No forms, no appeals.
  // -------------------------------------------------------------------------
  app.page(
    'AlarmStopped',
    route: '/alarm-stopped',
    description: 'Stage 11: safety outranks the joke — the alarm just stops.',
    onLoad: [stopAlarm()],
    body: Scaffold(
      body: Container(
        color: Colors.hex(0xFFF0F2F4),
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            Expanded(
              Column(
                scrollable: true,
                padding: 24,
                spacing: 12,
                crossAxis: CrossAxis.stretch,
                children: [
                  Spacer(height: 28),
                  Icon('alarm_off', size: 78, color: Colors.secondaryText),
                  Text(
                    'Alarm stopped.',
                    style: Styles.headlineSmall,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'No forms. No appeals.\nSafety outranks the joke.',
                    style: Styles.bodyLarge,
                    color: Colors.secondaryText,
                    textAlign: TextAlign.center,
                  ),
                  Spacer(height: 28),
                  _primaryButton(
                    'RESTART DEMO',
                    color: _ink,
                    name: 'RestartDemoButton',
                    onTap: [
                      UpdateAppState.set('alarmReturned', false),
                      UpdateAppState.set('dodgeCount', 0),
                      UpdateAppState.set('reasonText', ''),
                      UpdateAppState.set('reasonError', ''),
                      UpdateAppState.set('captchaBed', false),
                      UpdateAppState.set('captchaCoffee', false),
                      UpdateAppState.set('captchaLaptop', false),
                      UpdateAppState.set('captchaPillow', false),
                      UpdateAppState.set('captchaDumbbell', false),
                      UpdateAppState.set('captchaAirplane', false),
                      UpdateAppState.set('captchaFailed', false),
                      UpdateAppState.set('captchaAttempt', 0),
                      UpdateAppState.set('officerTestimony', ''),
                      UpdateAppState.set('officerRejected', false),
                      UpdateAppState.set('processingTick', 0),
                      UpdateAppState.set('identityTick', 0),
                      UpdateAppState.set('identityScanning', false),
                      UpdateAppState.set('identityComplete', false),
                      UpdateAppState.set('secondsLeft', 30),
                      startAlarm(),
                      // Navigate('ActiveAlarm') is wired in the follow-up pass.
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // AuthorizedSnooze — thirty real seconds, then the alarm returns.
  // -------------------------------------------------------------------------
  app.page(
    'AuthorizedSnooze',
    route: '/authorized-snooze',
    description: 'Stage 10: the 30-second countdown, then the alarm is back.',
    onLoad: [
      UpdateAppState.set('secondsLeft', 30),
      StartPeriodic('kyaSnooze', durationMillis: 1000),
      UpdateAppState.set(
        'secondsLeft',
        CustomFunction(decrement, args: {'value': AppState('secondsLeft')}),
      ),
      If(
        Equals(AppState('secondsLeft'), 0),
        then: [
          StopPeriodic('kyaSnooze'),
          UpdateAppState.set('alarmReturned', true),
          UpdateAppState.set('dodgeCount', 0),
          startAlarm(),
          // Navigate('ActiveAlarm') is wired in the follow-up pass.
        ],
      ),
    ],
    body: Scaffold(
      body: Container(
        color: Colors.accent2,
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            _statusBar(name: 'SnoozingStatusBar', showCase: true),
            Expanded(
              Column(
                scrollable: true,
                padding: 24,
                spacing: 12,
                crossAxis: CrossAxis.stretch,
                children: [
                  Spacer(height: 28),
                  Icon('bedtime', size: 70, color: Colors.accent1),
                  Text(
                    'Authorized unconsciousness\nin progress',
                    style: Styles.headlineSmall,
                    color: Colors.hex(_white),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    CustomFunction(
                      countdownLabel,
                      args: {'seconds': AppState('secondsLeft')},
                    ),
                    style: Styles.headlineMedium,
                    color: Colors.accent1,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Please sleep efficiently.',
                    style: Styles.titleSmall,
                    color: Colors.hex(0xB3FFFFFF),
                    textAlign: TextAlign.center,
                  ),
                  Spacer(height: 28),
                  _secondaryButton(
                    'WAKE ME NOW',
                    dark: true,
                    name: 'WakeNowButton',
                    onTap: [
                      UpdateAppState.set('alarmReturned', true),
                      UpdateAppState.set('dodgeCount', 0),
                      startAlarm(),
                      // Navigate('ActiveAlarm') is wired in the follow-up pass.
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // SnoozeApproval — the punchline: authorized, for thirty seconds.
  // -------------------------------------------------------------------------
  app.page(
    'SnoozeApproval',
    route: '/snooze-approval',
    description: 'Stage 9: KYA verified, alarm silenced, 30 seconds granted.',
    onLoad: [stopAlarm()],
    body: Scaffold(
      body: Container(
        color: Colors.hex(0xFFE8FFE8),
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            _statusBar(name: 'ApprovalStatusBar', showCase: true),
            Expanded(
              Column(
                scrollable: true,
                padding: 24,
                spacing: 8,
                crossAxis: CrossAxis.stretch,
                children: [
                  Spacer(height: 28),
                  Image(
                    _albyCelebrate,
                    isNetwork: false,
                    width: 230,
                    height: 230,
                    fit: ImageFit.contain,
                    name: 'AlbyCelebrates',
                  ),
                  Text(
                    'KYA Verified!',
                    style: Styles.headlineSmall,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Identity confirmed. Alarm silenced.',
                    style: Styles.bodyLarge,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  Container(
                    width: double.infinity,
                    padding: 20,
                    borderRadius: 12,
                    color: Colors.secondaryBackground,
                    borderColor: Colors.success,
                    borderWidth: 2,
                    child: Column(
                      spacing: 8,
                      children: [
                        Text(
                          'AUTHORIZED SNOOZE PERIOD',
                          style: _mono,
                          color: Colors.primaryText,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '00:00:30',
                          style: Styles.headlineMedium,
                          color: Colors.primaryText,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '(You wish.)',
                          style: Styles.titleSmall,
                          color: Colors.primaryText,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Spacer(height: 28),
                  _primaryButton(
                    'YAY...',
                    color: _blue,
                    name: 'StartSnoozeButton',
                    onTap: [
                      UpdateAppState.set('secondsLeft', 30),
                      Navigate('AuthorizedSnooze'),
                    ],
                  ),
                  Text(
                    'Remember: productivity is a choice.\nSo is suffering.',
                    style: Styles.bodyMedium,
                    color: Colors.hex(0xFF315A37),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // IdentityWakeCheck — step 4, a live camera scan that proves nothing.
  // -------------------------------------------------------------------------
  app.page(
    'IdentityWakeCheck',
    route: '/identity-wake-check',
    description: 'Stage 8: mock KYC face scan before the alarm can be silenced.',
    body: Scaffold(
      body: Container(
        color: Colors.primaryBackground,
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            _statusBar(name: 'IdentityStatusBar', showCase: true),
            Expanded(
              Column(
                scrollable: true,
                padding: EdgeInsets.only(left: 22, right: 22, top: 8, bottom: 24),
                spacing: 14,
                crossAxis: CrossAxis.stretch,
                children: [
                  stepProgress(
                    name: 'IdentityStep',
                    step: 4,
                    label: 'Identity check',
                    value: 1.0,
                  ),
                  Text(
                    'Identity Wake Check',
                    style: Styles.titleLarge,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'One final scan before the alarm can be silenced.',
                    style: Styles.bodyMedium,
                    color: Colors.secondaryText,
                    textAlign: TextAlign.center,
                  ),
                  faceScan(
                    name: 'IdentityFaceScan',
                    progress: CustomFunction(
                      identityValue,
                      args: {'tick': AppState('identityTick')},
                    ),
                    scanning: AppState('identityScanning'),
                    complete: AppState('identityComplete'),
                  ),
                  Text(
                    CustomFunction(
                      identityPrompt,
                      args: {
                        'tick': AppState('identityTick'),
                        'scanning': AppState('identityScanning'),
                        'complete': AppState('identityComplete'),
                      },
                    ),
                    style: Styles.titleMedium,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    CustomFunction(
                      identityPhase,
                      args: {'tick': AppState('identityTick')},
                    ),
                    style: _mono,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                    visible: AppState('identityScanning'),
                  ),
                  progressBar(
                    name: 'IdentityBar',
                    value: CustomFunction(
                      identityValue,
                      args: {'tick': AppState('identityTick')},
                    ),
                    barArgb: _blue,
                    trackArgb: 0xFFDCE0E5,
                    thickness: 9.0,
                  ),
                  _primaryButton(
                    CustomFunction(
                      scanButtonLabel,
                      args: {
                        'scanning': AppState('identityScanning'),
                        'complete': AppState('identityComplete'),
                      },
                    ),
                    color: _blue,
                    name: 'StartIdentityScanButton',
                    onTap: [
                      If(
                        Not(AppState('identityScanning')),
                        then: [
                          UpdateAppState.set('identityScanning', true),
                          UpdateAppState.set('identityComplete', false),
                          UpdateAppState.set('identityTick', 0),
                          StartPeriodic('kyaScan', durationMillis: 1000),
                          UpdateAppState.set(
                            'identityTick',
                            CustomFunction(
                              increment,
                              args: {'value': AppState('identityTick')},
                            ),
                          ),
                          If(
                            CustomFunction(
                              identityComplete,
                              args: {'tick': AppState('identityTick')},
                            ),
                            then: [
                              StopPeriodic('kyaScan'),
                              UpdateAppState.set('identityComplete', true),
                              UpdateAppState.set('identityScanning', false),
                              stopAlarm(),
                              Wait(900),
                              Navigate('SnoozeApproval'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'Live preview only. Nothing is recorded, uploaded, or stored.',
                    style: Styles.bodySmall,
                    color: Colors.secondaryText,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // BureaucraticProcessing — the dishonest wait, on an 850ms timer.
  // -------------------------------------------------------------------------
  app.page(
    'BureaucraticProcessing',
    route: '/bureaucratic-processing',
    description: 'Stage 7: fake review that stalls at 97% and admits nothing.',
    onLoad: [
      UpdateAppState.set('processingTick', 0),
      StartPeriodic('kyaProcessing', durationMillis: 850),
      UpdateAppState.set(
        'processingTick',
        CustomFunction(increment, args: {'value': AppState('processingTick')}),
      ),
      If(
        CustomFunction(
          processingComplete,
          args: {'tick': AppState('processingTick')},
        ),
        then: [
          StopPeriodic('kyaProcessing'),
          UpdateAppState.set('identityTick', 0),
          UpdateAppState.set('identityScanning', false),
          UpdateAppState.set('identityComplete', false),
          Navigate('IdentityWakeCheck'),
        ],
      ),
    ],
    body: Scaffold(
      body: Container(
        color: Colors.primaryBackground,
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            _statusBar(name: 'ProcessingStatusBar', showCase: true),
            Expanded(
              Column(
                scrollable: true,
                padding: EdgeInsets.only(left: 24, right: 24, top: 14, bottom: 26),
                spacing: 16,
                crossAxis: CrossAxis.stretch,
                children: [
                  Text(
                    'Processing your request...',
                    style: Styles.titleLarge,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  officialSeal(name: 'ProcessingSeal', square: true),
                  processingRow(0),
                  processingRow(1),
                  processingRow(2),
                  processingRow(3),
                  processingRow(4),
                  processingRow(5),
                  Row(
                    crossAxis: CrossAxis.center,
                    spacing: 10,
                    children: [
                      Expanded(
                        progressBar(
                          name: 'ProcessingBar',
                          value: CustomFunction(
                            processingValue,
                            args: {'tick': AppState('processingTick')},
                          ),
                          barArgb: _blue,
                          trackArgb: 0xFFDCE0E5,
                          thickness: 12.0,
                        ),
                      ),
                      Text(
                        CustomFunction(
                          processingPercent,
                          args: {'tick': AppState('processingTick')},
                        ),
                        style: _mono,
                        color: Colors.primaryText,
                      ),
                    ],
                  ),
                  Text(
                    CustomFunction(
                      processingNote,
                      args: {'tick': AppState('processingTick')},
                    ),
                    style: Styles.bodyMedium,
                    color: Colors.secondaryText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // AISnoozeOfficer — step 3, an argument you are going to lose.
  // -------------------------------------------------------------------------
  app.page(
    'AISnoozeOfficer',
    route: '/ai-snooze-officer',
    description: 'Stage 6: Alby, now an AI Snooze Compliance Officer.',
    body: Scaffold(
      body: Container(
        color: Colors.primaryBackground,
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            _statusBar(name: 'OfficerStatusBar', showCase: true),
            Expanded(
              Column(
                scrollable: true,
                padding: EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 24),
                spacing: 12,
                crossAxis: CrossAxis.stretch,
                children: [
                  stepProgress(
                    name: 'OfficerStep',
                    step: 3,
                    label: 'Officer review',
                    value: 0.75,
                  ),
                  Image(
                    _albyOfficer,
                    isNetwork: false,
                    width: 150,
                    height: 150,
                    fit: ImageFit.contain,
                    name: 'AlbyOfficer',
                  ),
                  Text(
                    'AI Snooze Officer',
                    style: Styles.titleLarge,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  chatBubble(
                    name: 'OfficerGreeting',
                    text:
                        "Good morning. I'm Alby, your AI Snooze Officer. Please provide a valid reason for your snooze request.",
                    fromOfficer: true,
                    rejected: false,
                  ),
                  chatBubble(
                    name: 'OfficerUserReply',
                    text: AppState('officerTestimony'),
                    fromOfficer: false,
                    rejected: false,
                    visible: AppState('officerRejected'),
                  ),
                  chatBubble(
                    name: 'OfficerRejection',
                    text:
                        'REJECTED.\n\nInsufficient justification. Please provide supporting documentation such as a photo, doctor’s note, sleep study, or a 100-word essay.',
                    fromOfficer: true,
                    rejected: true,
                    visible: AppState('officerRejected'),
                  ),
                  TextField(
                    name: 'officerField',
                    label: 'Your testimony',
                    hint: "I'm just really tired...",
                    maxLines: 3,
                    visible: Not(AppState('officerRejected')),
                  ),
                  _primaryButton(
                    'SUBMIT TESTIMONY',
                    color: _blue,
                    name: 'SendTestimonyButton',
                    visible: Not(AppState('officerRejected')),
                    onTap: [
                      If(
                        Equals(
                          WidgetState('officerField', WidgetStateProperty.text),
                          '',
                        ),
                        then: [Snackbar('The officer requires testimony.')],
                        orElse: [
                          UpdateAppState.set(
                            'officerTestimony',
                            WidgetState(
                              'officerField',
                              WidgetStateProperty.text,
                            ),
                          ),
                          UpdateAppState.set('officerRejected', true),
                        ],
                      ),
                    ],
                  ),
                  _primaryButton(
                    'SUBMIT APPEAL ANYWAY',
                    color: _blue,
                    name: 'AppealButton',
                    visible: AppState('officerRejected'),
                    onTap: [Navigate('BureaucraticProcessing')],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // WakefulnessCAPTCHA — step 2, and the first rejection is rigged.
  // -------------------------------------------------------------------------
  app.page(
    'WakefulnessCAPTCHA',
    route: '/wakefulness-captcha',
    description: 'Stage 5: the CAPTCHA that fails you once on principle.',
    body: Scaffold(
      body: Container(
        color: Colors.primaryBackground,
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            _statusBar(name: 'CaptchaStatusBar', showCase: true),
            Expanded(
              Column(
                scrollable: true,
                padding: EdgeInsets.only(left: 22, right: 22, top: 8, bottom: 24),
                spacing: 16,
                crossAxis: CrossAxis.stretch,
                children: [
                  stepProgress(
                    name: 'CaptchaStep',
                    step: 2,
                    label: 'Wakefulness',
                    value: 0.5,
                  ),
                  Row(
                    crossAxis: CrossAxis.start,
                    spacing: 8,
                    children: [
                      Expanded(
                        Column(
                          crossAxis: CrossAxis.start,
                          spacing: 8,
                          children: [
                            Text(
                              "Verify you're awake.",
                              style: Styles.titleLarge,
                              color: Colors.primaryText,
                            ),
                            Text(
                              'Select all objects you would rather be using right now.',
                              style: Styles.bodyMedium,
                              color: Colors.primaryText,
                            ),
                          ],
                        ),
                      ),
                      Image(
                        _albySuspicious,
                        isNetwork: false,
                        width: 92,
                        height: 92,
                        fit: ImageFit.contain,
                        name: 'AlbyInspects',
                      ),
                    ],
                  ),
                  Row(
                    spacing: 10,
                    crossAxis: CrossAxis.stretch,
                    children: [
                      captchaTile('Bed', 'bed', 'captchaBed'),
                      captchaTile('Coffee', 'coffee', 'captchaCoffee'),
                      captchaTile('Laptop', 'laptop_mac', 'captchaLaptop'),
                    ],
                  ),
                  Row(
                    spacing: 10,
                    crossAxis: CrossAxis.stretch,
                    children: [
                      captchaTile(
                        'Pillow',
                        'airline_seat_flat',
                        'captchaPillow',
                      ),
                      captchaTile(
                        'Dumbbell',
                        'fitness_center',
                        'captchaDumbbell',
                      ),
                      captchaTile('Airplane', 'flight', 'captchaAirplane'),
                    ],
                  ),
                  alertBanner(
                    name: 'CaptchaFailureBanner',
                    title: 'Verification failed.',
                    message: 'Sleeping behavior detected.',
                    visible: AppState('captchaFailed'),
                  ),
                  _primaryButton(
                    'VERIFY SELECTION',
                    color: _blue,
                    name: 'CaptchaVerifyButton',
                    visible: Not(AppState('captchaFailed')),
                    onTap: [
                      If(
                        CustomFunction(
                          anyCaptchaSelected,
                          args: {
                            'bed': AppState('captchaBed'),
                            'coffee': AppState('captchaCoffee'),
                            'laptop': AppState('captchaLaptop'),
                            'pillow': AppState('captchaPillow'),
                            'dumbbell': AppState('captchaDumbbell'),
                            'airplane': AppState('captchaAirplane'),
                          },
                        ),
                        then: [
                          If(
                            Equals(AppState('captchaAttempt'), 0),
                            then: [
                              UpdateAppState.set('captchaFailed', true),
                              UpdateAppState.set('captchaAttempt', 1),
                              UpdateAppState.set('captchaBed', false),
                              UpdateAppState.set('captchaCoffee', false),
                              UpdateAppState.set('captchaLaptop', false),
                              UpdateAppState.set('captchaPillow', false),
                              UpdateAppState.set('captchaDumbbell', false),
                              UpdateAppState.set('captchaAirplane', false),
                            ],
                            orElse: [
                              UpdateAppState.set('officerRejected', false),
                              UpdateAppState.set('officerTestimony', ''),
                              Navigate('AISnoozeOfficer'),
                            ],
                          ),
                        ],
                        orElse: [
                          Snackbar('Select at least one suspicious object.'),
                        ],
                      ),
                    ],
                  ),
                  _primaryButton(
                    'TRY AGAIN',
                    color: _blue,
                    name: 'CaptchaRetryButton',
                    visible: AppState('captchaFailed'),
                    onTap: [
                      UpdateAppState.set('captchaFailed', false),
                      UpdateAppState.set('captchaAttempt', 1),
                      UpdateAppState.set('captchaBed', false),
                      UpdateAppState.set('captchaCoffee', false),
                      UpdateAppState.set('captchaLaptop', false),
                      UpdateAppState.set('captchaPillow', false),
                      UpdateAppState.set('captchaDumbbell', false),
                      UpdateAppState.set('captchaAirplane', false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // ReasonForSnoozing — step 1 of 4, the redundant paperwork.
  // -------------------------------------------------------------------------
  app.page(
    'ReasonForSnoozing',
    route: '/reason-for-snoozing',
    description: 'Stage 4: reason radio group plus the 50-character essay.',
    body: Scaffold(
      body: Container(
        color: Colors.primaryBackground,
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            _statusBar(name: 'ReasonStatusBar', showCase: true),
            Expanded(
              Column(
                scrollable: true,
                padding: EdgeInsets.only(left: 22, right: 22, top: 8, bottom: 24),
                spacing: 16,
                crossAxis: CrossAxis.stretch,
                children: [
                  stepProgress(
                    name: 'ReasonStep',
                    step: 1,
                    label: 'Application',
                    value: 0.25,
                  ),
                  Text(
                    'Why are you snoozing?',
                    style: Styles.titleLarge,
                    color: Colors.primaryText,
                  ),
                  Container(
                    borderRadius: 16,
                    borderColor: Colors.alternate,
                    borderWidth: 1,
                    color: Colors.secondaryBackground,
                    padding: 8,
                    child: RadioGroup(
                      name: 'reasonRadio',
                      options: _reasons,
                      selected: AppState('selectedReason'),
                      activeColor: Colors.primary,
                      onChanged: [
                        UpdateAppState.set('selectedReason', WidgetValue()),
                      ],
                    ),
                  ),
                  Text(
                    'Explain why.',
                    style: Styles.titleMedium,
                    color: Colors.primaryText,
                  ),
                  TextField(
                    name: 'reasonField',
                    label: 'Your statement',
                    hint: "I'm tired...",
                    maxLines: 4,
                  ),
                  Text(
                    'Minimum 50 characters of sleepy context.',
                    style: Styles.bodySmall,
                    color: Colors.secondaryText,
                  ),
                  Text(
                    AppState('reasonError'),
                    style: Styles.bodyMedium,
                    color: Colors.error,
                    visible: Not(Equals(AppState('reasonError'), '')),
                  ),
                  _primaryButton(
                    'NEXT',
                    color: _blue,
                    name: 'ReasonNextButton',
                    onTap: [
                      If(
                        CustomFunction(
                          hasSufficientReason,
                          args: {
                            'text': WidgetState(
                              'reasonField',
                              WidgetStateProperty.text,
                            ),
                          },
                        ),
                        then: [
                          UpdateAppState.set(
                            'reasonText',
                            WidgetState('reasonField', WidgetStateProperty.text),
                          ),
                          UpdateAppState.set('reasonError', ''),
                          Navigate('WakefulnessCAPTCHA'),
                        ],
                        orElse: [
                          UpdateAppState.set(
                            'reasonError',
                            'Your response lacks sufficient sleepy context.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // KYAIntroduction — the institution introduces itself.
  // -------------------------------------------------------------------------
  app.page(
    'KYAIntroduction',
    route: '/kya-introduction',
    description: 'Stage 3: Snooze Termination Request cover sheet.',
    body: Scaffold(
      body: Container(
        color: Colors.primaryBackground,
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            _statusBar(name: 'IntroStatusBar', showCase: false),
            Expanded(
              Column(
                scrollable: true,
                padding: 24,
                spacing: 8,
                children: [
                  Spacer(height: 28),
                  Text(
                    'KYA™',
                    style: Styles.headlineMedium,
                    color: Colors.accent1,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Know Your Alarm',
                    style: Styles.titleMedium,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  Spacer(height: 20),
                  officialSeal(name: 'IntroSeal', square: false),
                  Spacer(height: 10),
                  Text(
                    'Snooze Termination\nRequest',
                    style: Styles.titleLarge,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'To comply with the International Sleep Prevention Act, all users must complete Know Your Alarm verification.',
                    style: Styles.bodyLarge,
                    color: Colors.secondaryText,
                    textAlign: TextAlign.center,
                  ),
                  Spacer(height: 28),
                  _primaryButton(
                    'START VERIFICATION',
                    color: _blue,
                    name: 'StartVerificationButton',
                    onTap: [
                      UpdateAppState.set('reasonError', ''),
                      Navigate('ReasonForSnoozing'),
                    ],
                  ),
                  caseFooter(name: 'IntroCaseFooter'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // SnoozeDodge — the signature trap: the button dodges twice, then yields.
  // -------------------------------------------------------------------------
  app.page(
    'SnoozeDodge',
    route: '/snooze-dodge',
    description: 'Stage 2: the snooze control dodges twice inside safe bounds.',
    body: Scaffold(
      body: Container(
        color: Colors.accent1,
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            _statusBar(name: 'DodgeStatusBar', showCase: false),
            Expanded(
              Column(
                scrollable: true,
                padding: 24,
                spacing: 8,
                children: [
                  Image(
                    _albySuspicious,
                    isNetwork: false,
                    width: 188,
                    height: 188,
                    fit: ImageFit.contain,
                    name: 'AlbyBlocks',
                  ),
                  Text(
                    'Hold on!',
                    style: Styles.headlineSmall,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "You can't snooze just yet.\nLet's complete a quick verification first!",
                    style: Styles.bodyLarge,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Almost! :)',
                    style: Styles.titleSmall,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                    visible: Equals(AppState('dodgeCount'), 1),
                  ),
                  Text(
                    'Fine. One more try.',
                    style: Styles.titleSmall,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                    visible: Equals(AppState('dodgeCount'), 2),
                  ),
                  Container(
                    height: 215,
                    child: Column(
                      mainAxis: MainAxis.center,
                      crossAxis: CrossAxis.stretch,
                      children: [
                        // First position: centred, low — inside thumb reach.
                        Row(
                          mainAxis: MainAxis.center,
                          visible: Equals(AppState('dodgeCount'), 0),
                          children: [
                            Button(
                              'SNOOZE',
                              color: Colors.hex(_red),
                              textColor: Colors.hex(_white),
                              width: 190,
                              height: 58,
                              borderRadius: 16,
                              name: 'DodgeSnoozeCenter',
                              onTap: [
                                HapticFeedback(),
                                UpdateAppState.set('dodgeCount', 1),
                              ],
                            ),
                          ],
                        ),
                        // Second position: dodged up and left.
                        Row(
                          mainAxis: MainAxis.start,
                          visible: Equals(AppState('dodgeCount'), 1),
                          children: [
                            Button(
                              'SNOOZE',
                              color: Colors.hex(_red),
                              textColor: Colors.hex(_white),
                              width: 190,
                              height: 58,
                              borderRadius: 16,
                              name: 'DodgeSnoozeLeft',
                              onTap: [
                                HapticFeedback(),
                                UpdateAppState.set('dodgeCount', 2),
                              ],
                            ),
                          ],
                        ),
                        // Third position: dodged right, and this time it yields.
                        Row(
                          mainAxis: MainAxis.end,
                          visible: Equals(AppState('dodgeCount'), 2),
                          children: [
                            Button(
                              'SNOOZE',
                              color: Colors.hex(_red),
                              textColor: Colors.hex(_white),
                              width: 190,
                              height: 58,
                              borderRadius: 16,
                              name: 'DodgeSnoozeRight',
                              onTap: [Navigate('KYAIntroduction')],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // ActiveAlarm — the ringing moment the product opens inside.
  // -------------------------------------------------------------------------
  app.page(
    'ActiveAlarm',
    // The wipe pass' KyaBootstrap still owns '/' during this compile (removals
    // are applied after page declarations); the follow-up pass moves this page
    // back to the root route.
    route: '/active-alarm',
    isInitial: true,
    description: 'Stage 1: the alarm rings, with a dominant red snooze.',
    onLoad: [startAlarm()],
    body: Scaffold(
      body: Container(
        color: Colors.accent1,
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            _statusBar(name: 'AlarmStatusBar', showCase: false),
            Expanded(
              Column(
                scrollable: true,
                padding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 22),
                spacing: 6,
                children: [
                  Spacer(height: 28),
                  Image(
                    _albyHappy,
                    isNetwork: false,
                    width: 225,
                    height: 225,
                    fit: ImageFit.contain,
                    name: 'AlbyHappy',
                    visible: Not(AppState('alarmReturned')),
                  ),
                  Image(
                    _albySuspicious,
                    isNetwork: false,
                    width: 225,
                    height: 225,
                    fit: ImageFit.contain,
                    name: 'AlbySuspicious',
                    visible: AppState('alarmReturned'),
                  ),
                  Text(
                    'Good morning!',
                    style: Styles.headlineSmall,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                    visible: Not(AppState('alarmReturned')),
                  ),
                  Text(
                    'Welcome back!',
                    style: Styles.headlineSmall,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                    visible: AppState('alarmReturned'),
                  ),
                  Text(
                    'Rise and shine!\nA productive day awaits!',
                    style: Styles.bodyLarge,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                    visible: Not(AppState('alarmReturned')),
                  ),
                  Text(
                    'Your authorized unconsciousness period has expired.',
                    style: Styles.bodyLarge,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                    visible: AppState('alarmReturned'),
                  ),
                  Text(
                    '6:00 AM',
                    style: Styles.headlineMedium,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                  ),
                  Spacer(height: 28),
                  _primaryButton(
                    'SNOOZE',
                    color: _red,
                    name: 'SnoozeButton',
                    visible: Not(AppState('alarmReturned')),
                    onTap: [
                      startAlarm(),
                      UpdateAppState.set('dodgeCount', 0),
                      UpdateAppState.increment(ff.AppState.snoozeCount, 1),
                      Navigate('SnoozeDodge'),
                    ],
                  ),
                  Text(
                    '30 minutes',
                    style: Styles.bodySmall,
                    color: Colors.primaryText,
                    textAlign: TextAlign.center,
                    visible: Not(AppState('alarmReturned')),
                  ),
                  _primaryButton(
                    'REQUEST ANOTHER SNOOZE',
                    color: _red,
                    name: 'SnoozeAgainButton',
                    visible: AppState('alarmReturned'),
                    onTap: [
                      startAlarm(),
                      UpdateAppState.set('dodgeCount', 0),
                      UpdateAppState.increment(ff.AppState.snoozeCount, 1),
                      Navigate('SnoozeDodge'),
                    ],
                  ),
                  _secondaryButton(
                    'Stop Alarm',
                    name: 'StopAlarmButton',
                    onTap: [Navigate('AlarmStopped')],
                  ),
                  Text(
                    'Discipline today. A better you tomorrow!',
                    style: Styles.bodySmall,
                    color: Colors.hex(0xFF795800),
                    textAlign: TextAlign.center,
                    visible: Not(AppState('alarmReturned')),
                  ),
                  Text(
                    'Compliance is a lifestyle.',
                    style: Styles.bodySmall,
                    color: Colors.hex(0xFF795800),
                    textAlign: TextAlign.center,
                    visible: AppState('alarmReturned'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // The wipe pass' placeholder is no longer reachable. Guarded so the script
  // stays rerun-safe (and compilable against an empty project in tests).
  app.raw((project) {
    if (project.theme.loadingIndicatorStyle.diameter < 20) {
      project.theme.loadingIndicatorStyle = FFLoadingIndicator(
        type: FFLoadingIndicator_IndicatorType.CIRCULAR,
        diameter: 40,
      );
    }
  });

  app.raw((project) {
    final bootstrap = project.getWidgetClassByName('KyaBootstrap');
    if (bootstrap != null) {
      project.pageKeys.remove(bootstrap.node.key);
      project.widgetClasses.remove(bootstrap.node.key);
    }
  });
}
