import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: KyaColors.cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const KyaApp());
}

class KyaColors {
  static const yellow = Color(0xFFFFD93D);
  static const blue = Color(0xFF2F8CFF);
  static const red = Color(0xFFFF4655);
  static const green = Color(0xFF66CC78);
  static const cream = Color(0xFFFFFDF5);
  static const ink = Color(0xFF17191C);
  static const gray = Color(0xFF687280);
  static const navy = Color(0xFF162333);
}

class KyaApp extends StatelessWidget {
  const KyaApp({
    super.key,
    this.audioEnabled = true,
    this.cameraEnabled = true,
  });

  final bool audioEnabled;
  final bool cameraEnabled;

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final textColor = dark ? const Color(0xFFF8F4EA) : KyaColors.ink;
    final scheme = ColorScheme.fromSeed(
      seedColor: KyaColors.blue,
      brightness: brightness,
      surface: dark ? const Color(0xFF171B21) : KyaColors.cream,
      error: KyaColors.red,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Nunito',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 58,
          height: .98,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 34,
          height: 1.05,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 27,
          height: 1.12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          height: 1.42,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        labelLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: .15,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF242A32) : Colors.white,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF687280) : const Color(0xFFCBD1D8),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KyaColors.blue, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KyaColors.red, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KYA — Know Your Alarm',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: KyaFlow(audioEnabled: audioEnabled, cameraEnabled: cameraEnabled),
    );
  }
}

// Scan length is demo-paced: three 4s phases keep the KYC beat under the 2-minute run.
const int _kScanPhase = 4;
const int _kScanTotal = _kScanPhase * 3;

enum KyaStage {
  alarm,
  trap,
  intro,
  reason,
  captcha,
  officer,
  processing,
  identity,
  approved,
  snoozing,
  stopped,
}

class KyaFlow extends StatefulWidget {
  const KyaFlow({
    super.key,
    this.audioEnabled = true,
    this.cameraEnabled = true,
  });

  final bool audioEnabled;
  final bool cameraEnabled;

  @override
  State<KyaFlow> createState() => _KyaFlowState();
}

class _KyaFlowState extends State<KyaFlow> {
  KyaStage _stage = KyaStage.alarm;
  final _reasonController = TextEditingController();
  final _officerController = TextEditingController();
  final Set<int> _captchaSelection = {};
  AudioPlayer? _alarmPlayer;
  CameraController? _cameraController;
  Timer? _processingTimer;
  Timer? _identityTimer;
  Timer? _snoozeTimer;
  int _dodgeCount = 0;
  int _selectedReason = 0;
  int _captchaAttempt = 0;
  bool _captchaFailed = false;
  bool _officerRejected = false;
  bool _alarmReturned = false;
  String? _reasonError;
  double _processingProgress = 0;
  int _processingTick = 0;
  int _identityTick = 0;
  double _identityProgress = 0;
  bool _identityScanning = false;
  bool _identityComplete = false;
  bool _cameraLoading = false;
  String? _cameraError;
  int _secondsLeft = 30;

  static const _reasons = [
    'I am tired',
    'I require additional sleep',
    'Alarm was premature',
    'I accidentally became conscious',
  ];
  static const _captchaItems = [
    ('Bed', Icons.bed_rounded),
    ('Coffee', Icons.coffee_rounded),
    ('Laptop', Icons.laptop_mac_rounded),
    ('Pillow', Icons.airline_seat_flat_rounded),
    ('Dumbbell', Icons.fitness_center_rounded),
    ('Airplane', Icons.flight_rounded),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.audioEnabled) {
      _alarmPlayer = AudioPlayer();
      unawaited(_startAlarm());
    }
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    _identityTimer?.cancel();
    _snoozeTimer?.cancel();
    final player = _alarmPlayer;
    if (player != null) unawaited(player.dispose());
    final camera = _cameraController;
    if (camera != null) unawaited(camera.dispose());
    _reasonController.dispose();
    _officerController.dispose();
    super.dispose();
  }

  void _go(KyaStage stage) {
    _processingTimer?.cancel();
    _identityTimer?.cancel();
    _snoozeTimer?.cancel();
    setState(() => _stage = stage);
    if (stage == KyaStage.processing) _startProcessing();
    if (stage == KyaStage.identity) unawaited(_initializeCamera());
    if (stage == KyaStage.snoozing) _startSnooze();
    if (stage == KyaStage.stopped) unawaited(_silenceAlarm());
    if (stage != KyaStage.identity) unawaited(_disposeCamera());
  }

  Future<void> _initializeCamera() async {
    if (!widget.cameraEnabled || _cameraLoading || _cameraController != null) {
      return;
    }
    setState(() {
      _cameraLoading = true;
      _cameraError = null;
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
      if (!mounted || _stage != KyaStage.identity) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraLoading = false;
        _cameraError = 'Camera unavailable — demo scan still works.';
      });
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) await controller.dispose();
  }

  Future<void> _startAlarm() async {
    try {
      final player = _alarmPlayer;
      if (player == null || player.state == PlayerState.playing) return;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('audio/modern-alarm-1.mp3'));
    } catch (_) {
      // Browsers may block autoplay; the next user interaction retries it.
    }
  }

  Future<void> _silenceAlarm() async {
    try {
      await _alarmPlayer?.stop();
    } catch (_) {
      // Audio is non-critical to the escape path.
    }
  }

  void _resetFlow() {
    _reasonController.clear();
    _officerController.clear();
    _captchaSelection.clear();
    setState(() {
      _dodgeCount = 0;
      _selectedReason = 0;
      _captchaAttempt = 0;
      _captchaFailed = false;
      _officerRejected = false;
      _reasonError = null;
      _processingProgress = 0;
      _processingTick = 0;
      _identityTick = 0;
      _identityProgress = 0;
      _identityScanning = false;
      _identityComplete = false;
      _cameraError = null;
      _secondsLeft = 30;
    });
  }

  void _startProcessing() {
    const values = [.16, .38, .68, .97, .94, .97, 1.0];
    _processingTick = 0;
    _processingProgress = 0;
    _processingTimer = Timer.periodic(const Duration(milliseconds: 850), (
      timer,
    ) {
      if (!mounted) return;
      if (_processingTick >= values.length) {
        timer.cancel();
        _go(KyaStage.identity);
        return;
      }
      setState(() => _processingProgress = values[_processingTick++]);
    });
  }

  void _startSnooze() {
    _secondsLeft = 30;
    _snoozeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        _returnAlarm();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _startIdentityScan() {
    if (_identityScanning) return;
    setState(() {
      _identityScanning = true;
      _identityComplete = false;
      _identityTick = 0;
      _identityProgress = 0;
    });
    _identityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _identityTick++;
      if (_identityTick >= _kScanTotal) {
        timer.cancel();
        setState(() {
          _identityProgress = 1;
          _identityComplete = true;
          _identityScanning = false;
        });
        unawaited(_silenceAlarm());
        _identityTimer = Timer(const Duration(milliseconds: 900), () {
          if (mounted) _go(KyaStage.approved);
        });
      } else {
        setState(() => _identityProgress = _identityTick / _kScanTotal);
      }
    });
  }

  void _returnAlarm() {
    _snoozeTimer?.cancel();
    _resetFlow();
    setState(() {
      _alarmReturned = true;
      _stage = KyaStage.alarm;
    });
    unawaited(_startAlarm());
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final wide = MediaQuery.sizeOf(context).width >= 620;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = _backgroundForStage(context);
    final showAppClock = MediaQuery.paddingOf(context).top == 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(systemNavigationBarColor: background),
      child: Scaffold(
        backgroundColor: KyaColors.navy,
        body: Center(
          child: Container(
            width: wide ? 430 : double.infinity,
            constraints: BoxConstraints(
              maxHeight: wide ? 880 : double.infinity,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: wide
                  ? BorderRadius.circular(36)
                  : BorderRadius.zero,
              border: wide ? Border.all(color: Colors.white24, width: 6) : null,
              boxShadow: wide
                  ? const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 40,
                        offset: Offset(0, 18),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              child: Column(
                children: [
                  _StatusBar(
                    stage: _stage,
                    showTime: showAppClock,
                    onStop: _stage == KyaStage.stopped
                        ? null
                        : () => _go(KyaStage.stopped),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 360),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(.06, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_stage),
                        child: _screenForStage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundForStage(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return switch (_stage) {
        KyaStage.alarm || KyaStage.trap => const Color(0xFF3A3108),
        KyaStage.approved => const Color(0xFF10351F),
        KyaStage.snoozing => const Color(0xFF0D1722),
        KyaStage.stopped => const Color(0xFF1E232A),
        _ => const Color(0xFF14181E),
      };
    }
    return switch (_stage) {
      KyaStage.alarm || KyaStage.trap => KyaColors.yellow,
      KyaStage.approved => const Color(0xFFE8FFE8),
      KyaStage.snoozing => KyaColors.navy,
      KyaStage.stopped => const Color(0xFFF0F2F4),
      _ => KyaColors.cream,
    };
  }

  Widget _screenForStage() => switch (_stage) {
    KyaStage.alarm => _alarmScreen(),
    KyaStage.trap => _trapScreen(),
    KyaStage.intro => _introScreen(),
    KyaStage.reason => _reasonScreen(),
    KyaStage.captcha => _captchaScreen(),
    KyaStage.officer => _officerScreen(),
    KyaStage.processing => _processingScreen(),
    KyaStage.identity => _identityScreen(),
    KyaStage.approved => _approvedScreen(),
    KyaStage.snoozing => _snoozingScreen(),
    KyaStage.stopped => _stoppedScreen(),
  };

  Widget _alarmScreen() => _Page(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
    children: [
      const Spacer(),
      _Mascot(
        asset: _alarmReturned
            ? 'assets/mascot/alby-suspicious.png'
            : 'assets/mascot/alby-happy.png',
        size: 225,
        semanticsLabel: _alarmReturned
            ? 'Alby watches suspiciously'
            : 'Alby waves cheerfully',
      ),
      const SizedBox(height: 8),
      Text(
        _alarmReturned ? 'Welcome back!' : 'Good morning!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 6),
      Text(
        _alarmReturned
            ? 'Your authorized unconsciousness period has expired.'
            : 'Rise and shine!\nA productive day awaits!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 20),
      Text(
        '6:00 AM',
        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 52),
      ),
      const Spacer(),
      _PrimaryButton(
        key: const Key('snoozeButton'),
        label: _alarmReturned ? 'REQUEST ANOTHER SNOOZE' : 'SNOOZE',
        detail: _alarmReturned ? null : '30 minutes',
        color: KyaColors.red,
        onPressed: () {
          unawaited(_startAlarm());
          _go(KyaStage.trap);
        },
      ),
      const SizedBox(height: 12),
      _SecondaryButton(
        label: 'Stop Alarm',
        onPressed: () => _go(KyaStage.stopped),
      ),
      const SizedBox(height: 14),
      Text(
        _alarmReturned
            ? 'Compliance is a lifestyle.'
            : 'Discipline today. A better you tomorrow!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : const Color(0xFF795800),
          fontSize: 12,
        ),
      ),
    ],
  );

  Widget _trapScreen() {
    const alignments = [
      Alignment(0, .65),
      Alignment(-.82, -.35),
      Alignment(.82, .15),
    ];
    return _Page(
      children: [
        const Spacer(),
        const _Mascot(
          asset: 'assets/mascot/alby-suspicious.png',
          size: 188,
          semanticsLabel: 'Alby blocks the snooze request',
        ),
        Text('Hold on!', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          "You can't snooze just yet.\nLet's complete a quick verification first!",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 215,
          child: Stack(
            children: [
              AnimatedAlign(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                alignment: alignments[_dodgeCount.clamp(0, 2)],
                child: SizedBox(
                  width: 190,
                  child: _PrimaryButton(
                    key: const Key('trapSnoozeButton'),
                    label: 'SNOOZE',
                    color: KyaColors.red,
                    onPressed: () {
                      if (_dodgeCount < 2) {
                        HapticFeedback.selectionClick();
                        setState(() => _dodgeCount++);
                      } else {
                        _go(KyaStage.intro);
                      }
                    },
                  ),
                ),
              ),
              if (_dodgeCount > 0)
                Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    _dodgeCount == 1 ? 'Almost! :)' : 'Fine. One more try.',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _introScreen() => _Page(
    children: [
      const Spacer(),
      Text(
        'KYA™',
        style: Theme.of(context).textTheme.displayLarge
            ?.copyWith(color: KyaColors.yellow),
      ),
      Text('Know Your Alarm', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 28),
      const _OfficialSeal(icon: Icons.badge_outlined),
      const SizedBox(height: 18),
      Text(
        'Snooze Termination\nRequest',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      Text(
        'To comply with the International Sleep Prevention Act, all users must complete Know Your Alarm verification.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const Spacer(),
      _PrimaryButton(
        key: const Key('startVerificationButton'),
        label: 'START VERIFICATION',
        color: KyaColors.blue,
        onPressed: () => _go(KyaStage.reason),
      ),
      const SizedBox(height: 18),
      const _CaseId(),
    ],
  );

  Widget _reasonScreen() => ListView(
    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
    children: [
      const _StepProgress(step: 1, label: 'Application'),
      const SizedBox(height: 26),
      Text(
        'Why are you snoozing?',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 14),
      Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD7DADF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: RadioGroup<int>(
          groupValue: _selectedReason,
          onChanged: (value) => setState(() => _selectedReason = value ?? 0),
          child: Column(
            children: List.generate(
              _reasons.length,
              (index) => RadioListTile<int>(
                key: Key('reason-$index'),
                value: index,
                activeColor: KyaColors.blue,
                title: Text(_reasons[index]),
                dense: true,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('Explain why.', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      TextField(
        key: const Key('reasonField'),
        controller: _reasonController,
        minLines: 3,
        maxLines: 4,
        maxLength: 140,
        onChanged: (_) => setState(() => _reasonError = null),
        decoration: InputDecoration(
          hintText: "I'm tired...",
          errorText: _reasonError,
          helperText: 'Minimum 50 characters of sleepy context.',
        ),
      ),
      const SizedBox(height: 16),
      _PrimaryButton(
        key: const Key('reasonNextButton'),
        label: 'NEXT',
        color: KyaColors.blue,
        onPressed: () {
          if (_reasonController.text.trim().length < 50) {
            setState(
              () => _reasonError =
                  'Your response lacks sufficient sleepy context.',
            );
          } else {
            _go(KyaStage.captcha);
          }
        },
      ),
    ],
  );

  Widget _captchaScreen() => ListView(
    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
    children: [
      const _StepProgress(step: 2, label: 'Wakefulness'),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Verify you're awake.",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select all objects you would rather be using right now.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const _Mascot(
            asset: 'assets/mascot/alby-suspicious.png',
            size: 92,
            semanticsLabel: 'Alby inspects the CAPTCHA',
          ),
        ],
      ),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.02,
        ),
        itemCount: _captchaItems.length,
        itemBuilder: (context, index) {
          final selected = _captchaSelection.contains(index);
          final item = _captchaItems[index];
          return Semantics(
            button: true,
            selected: selected,
            label: item.$1,
            child: InkWell(
              key: Key('captcha-$index'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() {
                selected
                    ? _captchaSelection.remove(index)
                    : _captchaSelection.add(index);
                _captchaFailed = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? KyaColors.blue : const Color(0xFFD5D8DC),
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.$2,
                            size: 34,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.$1,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Positioned(
                        right: 5,
                        top: 5,
                        child: Icon(
                          Icons.check_circle,
                          color: KyaColors.blue,
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      if (_captchaFailed) ...[
        const SizedBox(height: 14),
        const _Alert(
          title: 'Verification failed.',
          message: 'Sleeping behavior detected.',
          color: KyaColors.red,
        ),
      ],
      const SizedBox(height: 18),
      _PrimaryButton(
        key: const Key('captchaVerifyButton'),
        label: _captchaFailed ? 'TRY AGAIN' : 'VERIFY SELECTION',
        color: KyaColors.blue,
        onPressed: () {
          if (_captchaFailed) {
            setState(() {
              _captchaFailed = false;
              _captchaSelection.clear();
              _captchaAttempt = 1;
            });
          } else if (_captchaSelection.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Select at least one suspicious object.'),
              ),
            );
          } else if (_captchaAttempt == 0) {
            setState(() {
              _captchaFailed = true;
              _captchaAttempt = 1;
              _captchaSelection.clear();
            });
          } else {
            _go(KyaStage.officer);
          }
        },
      ),
    ],
  );

  Widget _officerScreen() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
    children: [
      const _StepProgress(step: 3, label: 'Officer review'),
      const SizedBox(height: 16),
      const _Mascot(
        asset: 'assets/mascot/alby-officer.png',
        size: 150,
        semanticsLabel: 'Alby wearing a compliance officer hat',
      ),
      Text(
        'AI Snooze Officer',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 14),
      const _ChatBubble(
        text: "Good morning. I'm Alby, your AI Snooze Officer. Please provide a valid reason for your snooze request.",
        fromOfficer: true,
      ),
      if (_officerRejected) ...[
        _ChatBubble(text: _officerController.text.trim(), fromOfficer: false),
        const _ChatBubble(
          text: 'REJECTED.\n\nInsufficient justification. Please provide supporting documentation such as a photo, doctor’s note, sleep study, or a 100-word essay.',
          fromOfficer: true,
          rejected: true,
        ),
        const SizedBox(height: 12),
        _PrimaryButton(
          key: const Key('appealButton'),
          label: 'SUBMIT APPEAL ANYWAY',
          color: KyaColors.blue,
          onPressed: () => _go(KyaStage.processing),
        ),
      ] else ...[
        const SizedBox(height: 12),
        TextField(
          key: const Key('officerField'),
          controller: _officerController,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "I'm just really tired...",
            labelText: 'Your testimony',
          ),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(
          key: const Key('sendTestimonyButton'),
          label: 'SUBMIT TESTIMONY',
          color: KyaColors.blue,
          onPressed: () {
            if (_officerController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('The officer requires testimony.'),
                ),
              );
            } else {
              setState(() => _officerRejected = true);
            }
          },
        ),
      ],
    ],
  );

  Widget _processingScreen() {
    final completed = (_processingTick / 2).floor().clamp(0, 3);
    const tasks = [
      'Reviewing your sleep history...',
      'Contacting your pillow...',
      'Consulting the International Sleep Authority...',
      'Evaluating vibes...',
      'Determining whether you are actually tired...',
      'Almost there...',
    ];
    return _Page(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 26),
      children: [
        const SizedBox(height: 14),
        Text(
          'Processing your request...',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 28),
        const _OfficialSeal(icon: Icons.description_outlined, square: true),
        const SizedBox(height: 28),
        for (var index = 0; index < tasks.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                if (index < completed)
                  const Icon(
                    Icons.check_circle,
                    color: KyaColors.green,
                    size: 24,
                  )
                else if (index == completed)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: KyaColors.blue,
                    ),
                  )
                else
                  const Icon(
                    Icons.radio_button_unchecked,
                    color: KyaColors.gray,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tasks[index],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: _processingProgress,
                  color: KyaColors.blue,
                  backgroundColor: const Color(0xFFDCE0E5),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(_processingProgress * 100).round()}%',
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _processingProgress >= .94
              ? 'This may take several mornings.'
              : 'This may take a few seconds.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: KyaColors.gray),
        ),
      ],
    );
  }

  Widget _identityScreen() {
    final phase = _identityTick < _kScanPhase
        ? 'FRONT'
        : _identityTick < _kScanPhase * 2
        ? 'LEFT'
        : 'RIGHT';
    final secondsRemaining = _kScanPhase - (_identityTick % _kScanPhase);
    final prompt = _identityComplete
        ? 'Identity confirmed. Somehow.'
        : !_identityScanning
        ? 'Center your face to begin'
        : switch (phase) {
            'FRONT' => 'Face front. Pretend you read the terms.',
            'LEFT' => 'Turn left. Avoid eye contact with responsibility.',
            _ => 'Turn right. Check for unfinished tasks.',
          };
    final colors = Theme.of(context).colorScheme;
    final camera = _cameraController;
    final cameraReady = camera?.value.isInitialized ?? false;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        const _StepProgress(step: 4, label: 'Identity check'),
        const SizedBox(height: 22),
        Text(
          'Identity Wake Check',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'One final scan before the alarm can be silenced.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        Semantics(
          label: 'Live camera face scanning frame',
          child: Container(
            height: 330,
            decoration: BoxDecoration(
              color: KyaColors.navy,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _identityComplete ? KyaColors.green : KyaColors.blue,
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
                    _identityComplete
                        ? Icons.verified_user_rounded
                        : Icons.face_rounded,
                    color: _identityComplete ? KyaColors.green : Colors.white70,
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
                if (_identityScanning)
                  Align(
                    alignment: Alignment(0, (_identityProgress * 2) - 1),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 58),
                      height: 3,
                      decoration: BoxDecoration(
                        color: KyaColors.blue,
                        boxShadow: const [
                          BoxShadow(
                            color: KyaColors.blue,
                            blurRadius: 14,
                            spreadRadius: 3,
                          ),
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
                if (_cameraLoading)
                  const CircularProgressIndicator(color: Colors.white),
                if (_cameraError != null)
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 16,
                    child: Text(
                      _cameraError!,
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
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            prompt,
            key: ValueKey(prompt),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: _identityComplete ? KyaColors.green : null),
          ),
        ),
        if (_identityScanning) ...[
          const SizedBox(height: 6),
          Text(
            '$phase • $secondsRemaining seconds',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 10),
        LinearProgressIndicator(
          minHeight: 9,
          value: _identityProgress,
          color: _identityComplete ? KyaColors.green : KyaColors.blue,
          backgroundColor: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 18),
        _PrimaryButton(
          key: const Key('startIdentityScanButton'),
          label: _identityScanning
              ? 'SCANNING...'
              : _identityComplete
              ? 'IDENTITY CONFIRMED'
              : _cameraLoading
              ? 'OPENING CAMERA...'
              : 'BEGIN FACE SCAN',
          color: _identityComplete ? KyaColors.green : KyaColors.blue,
          onPressed: _identityScanning || _identityComplete || _cameraLoading
              ? null
              : _startIdentityScan,
        ),
        const SizedBox(height: 12),
        Text(
          'Live preview only. Nothing is recorded, uploaded, or stored.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }

  Widget _approvedScreen() => _Page(
    children: [
      const Spacer(),
      const _Mascot(
        asset: 'assets/mascot/alby-celebrate.png',
        size: 230,
        semanticsLabel: 'Alby celebrates with confetti',
      ),
      Text('KYA Verified!', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 4),
      Text(
        'Identity confirmed. Alarm silenced.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 22),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KyaColors.green, width: 1.5),
        ),
        child: Column(
          children: [
            const Text(
              'AUTHORIZED SNOOZE PERIOD',
              style: TextStyle(fontFamily: 'RobotoMono', fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '00:00:30',
              style: Theme.of(context).textTheme.displayLarge
                  ?.copyWith(fontFamily: 'RobotoMono'),
            ),
            const Text(
              '(You wish.)',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      const Spacer(),
      _PrimaryButton(
        key: const Key('startSnoozeButton'),
        label: 'YAY...',
        color: KyaColors.blue,
        onPressed: () => _go(KyaStage.snoozing),
      ),
      const SizedBox(height: 18),
      Text(
        'Remember: productivity is a choice.\nSo is suffering.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: const Color(0xFF315A37)),
      ),
    ],
  );

  Widget _snoozingScreen() => _Page(
    children: [
      const Spacer(),
      const Icon(Icons.bedtime_rounded, color: KyaColors.yellow, size: 70),
      const SizedBox(height: 24),
      Text(
        'Authorized unconsciousness\nin progress',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge
            ?.copyWith(color: Colors.white),
      ),
      const SizedBox(height: 28),
      Text(
        '00:00:${_secondsLeft.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.displayLarge
            ?.copyWith(color: KyaColors.yellow, fontFamily: 'RobotoMono'),
      ),
      const SizedBox(height: 12),
      const Text(
        'Please sleep efficiently.',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Spacer(),
      _SecondaryButton(
        key: const Key('wakeNowButton'),
        label: 'WAKE ME NOW',
        onPressed: _returnAlarm,
        dark: true,
      ),
    ],
  );

  Widget _stoppedScreen() => _Page(
    children: [
      const Spacer(),
      const Icon(Icons.alarm_off_rounded, size: 78, color: KyaColors.gray),
      const SizedBox(height: 20),
      Text('Alarm stopped.', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 10),
      Text(
        'No forms. No appeals.\nSafety outranks the joke.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: KyaColors.gray),
      ),
      const Spacer(),
      _PrimaryButton(
        label: 'RESTART DEMO',
        color: KyaColors.ink,
        onPressed: () {
          _resetFlow();
          setState(() {
            _alarmReturned = false;
            _stage = KyaStage.alarm;
          });
          unawaited(_startAlarm());
        },
      ),
    ],
  );
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.stage,
    required this.showTime,
    required this.onStop,
  });
  final KyaStage stage;
  final bool showTime;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final bureaucratic =
        stage.index >= KyaStage.reason.index &&
        stage.index <= KyaStage.approved.index;
    final light = stage == KyaStage.snoozing;
    final foreground = light
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: showTime
                  ? Text(
                      '6:00',
                      style: TextStyle(
                        color: foreground,
                        fontFamily: bureaucratic ? 'RobotoMono' : 'Nunito',
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Center(
                child: bureaucratic
                    ? Text(
                        'CASE KYA-0018',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: light
                              ? Colors.white70
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFamily: 'RobotoMono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(
              width: 52,
              child: onStop == null
                  ? null
                  : Semantics(
                      button: true,
                      label: 'Stop alarm immediately',
                      child: IconButton(
                        tooltip: 'Stop alarm',
                        onPressed: onStop,
                        icon: Icon(Icons.close_rounded, color: foreground),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 24),
  });
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - padding.vertical).clamp(
            0,
            double.infinity,
          ),
        ),
        child: IntrinsicHeight(child: Column(children: children)),
      ),
    ),
  );
}

class _Mascot extends StatelessWidget {
  const _Mascot({
    required this.asset,
    required this.size,
    required this.semanticsLabel,
  });
  final String asset;
  final double size;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: semanticsLabel,
    child: Image.asset(asset, width: size, height: size, fit: BoxFit.contain),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.detail,
  });
  final String label;
  final String? detail;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: detail == null ? 58 : 66,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        shadowColor: Colors.black38,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    ),
  );
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.dark = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? Colors.white : colors.onSurface,
          backgroundColor: dark ? Colors.white10 : colors.surfaceContainerHigh,
          side: BorderSide(
            color: dark ? Colors.white38 : colors.outlineVariant,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.label});
  final int step;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Text(
            'STEP $step OF 4',
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              color: KyaColors.gray,
              fontSize: 11,
            ),
          ),
        ],
      ),
      const SizedBox(height: 9),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          minHeight: 8,
          value: step / 4,
          color: KyaColors.blue,
          backgroundColor: const Color(0xFFDCE0E5),
        ),
      ),
    ],
  );
}

class _CaseId extends StatelessWidget {
  const _CaseId();
  @override
  Widget build(BuildContext context) => const Text(
    'FORM KYA-001B  •  CASE ID: KYA-0018  •  RISK: SLEEPY',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 10,
      color: KyaColors.gray,
      height: 1.5,
    ),
  );
}

class _OfficialSeal extends StatelessWidget {
  const _OfficialSeal({required this.icon, this.square = false});
  final IconData icon;
  final bool square;

  @override
  Widget build(BuildContext context) => Container(
    width: 82,
    height: 82,
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4C8),
      borderRadius: BorderRadius.circular(square ? 12 : 24),
      border: Border.all(color: KyaColors.gray, width: 2),
    ),
    child: Icon(icon, size: 43, color: KyaColors.navy),
  );
}

class _Alert extends StatelessWidget {
  const _Alert({
    required this.title,
    required this.message,
    required this.color,
  });
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Row(
      children: [
        Icon(Icons.cancel, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              Text(
                message,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.fromOfficer,
    this.rejected = false,
  });
  final String text;
  final bool fromOfficer;
  final bool rejected;

  @override
  Widget build(BuildContext context) => Align(
    alignment: fromOfficer ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 335),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: fromOfficer
            ? (rejected
                  ? const Color(0xFFFFE6E8)
                  : Theme.of(context).colorScheme.surfaceContainerHigh)
            : KyaColors.blue,
        borderRadius: BorderRadius.circular(12),
        border: rejected ? Border.all(color: KyaColors.red) : null,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: fromOfficer
              ? (rejected
                    ? KyaColors.ink
                    : Theme.of(context).colorScheme.onSurface)
              : Colors.white,
          fontWeight: rejected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ),
  );
}
