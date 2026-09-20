# KYA™ — Know Your Alarm

**Because waking up wasn't inconvenient enough.**

KYA is an alarm app that treats a snooze request like a regulated financial transaction. Tap SNOOZE and you don't get five more minutes — you get a *Snooze Termination Request*: a reason form, a CAPTCHA that flags sleeping as suspicious behavior, an AI Snooze Compliance Officer who rejects your appeal, fake processing, and a real front-camera KYC liveness check.

Then you're approved. For 30 seconds.

It runs from one Flutter codebase on web, iOS, and Android, with no backend, no account, and no network calls — clone it and the whole joke plays locally.

## Features

- **Eleven stages, one direction.** Alarm → hostile snooze → intro → reason form → CAPTCHA → AI officer → processing → identity scan → approval → countdown → the alarm comes back.
- **A snooze button that dodges.** Twice, inside safe bounds, before it yields.
- **A real liveness check.** Live front-camera preview with face-front / left / right prompts. Nothing is recorded, uploaded, or stored, and a denied or missing camera still completes the scan.
- **Deterministic by design.** The first CAPTCHA rejection and the officer's verdict are scripted, so demo timing lands the same way every run.
- **Always escapable.** Stop Alarm is reachable at every stage and never subject to the hostile mechanics.
- **Accessible.** Safe areas, system back, reduced motion, keyboard focus on web, 44–48px touch targets, scalable text.

## Requirements

- Flutter SDK with Dart `^3.13.4`
- A browser, iOS simulator/device, or Android emulator/device

## Installation

```bash
git clone https://github.com/geraldsberongoy/KYA.git
cd KYA
flutter pub get
```

## Usage

Run it in a browser — the fastest way to see the whole flow:

```bash
flutter run -d chrome
```

On a phone, where it's designed to be seen:

```bash
flutter devices
flutter run -d ios
flutter run -d android
```

Then: tap **SNOOZE**, chase the button, and comply. The camera stage asks for permission on first use — decline it and the scan still completes.

Want the narrated version? [`docs/kya-demo-script.md`](docs/kya-demo-script.md) is a timed two-minute walkthrough.

## Configuration

The app is a single file, [`lib/main.dart`](lib/main.dart). Stages are the `KyaStage` enum; each one is a builder method on `_KyaFlowState`.

| Knob | Where | Default |
| --- | --- | --- |
| Seconds per face-scan prompt (×3 prompts) | `_kScanPhase` | `4` |
| Authorized snooze duration | `_secondsLeft` | `30` |
| Alarm sound | `assets/audio/` | `modern-alarm-1.mp3` |
| Alby's poses | `assets/mascot/` | happy, suspicious, officer, celebrate |

Raising `_kScanPhase` lengthens the KYC beat; the demo script's 1:22–1:45 block assumes `4`.

## Development

```bash
flutter test
flutter analyze
flutter build web
```

`test/visual_test.dart` writes failure captures to `test/failures/`.

## Docs

- [`PRODUCT.md`](PRODUCT.md) — users, purpose, constraints, brand commitments
- [`docs/kya-flow.md`](docs/kya-flow.md) — direction contract and scope
- [`docs/kya-demo-script.md`](docs/kya-demo-script.md) — timed two-minute demo script

## Troubleshooting

- **Camera stage shows a placeholder.** Permission was denied, or the device has no front camera. Intentional — the scan runs anyway and the flow never blocks.
- **No alarm sound on web.** Browsers block autoplay until you interact with the page. Tap once and it starts.
- **Layout stretches on a wide window.** It shouldn't; wide layouts frame a portrait phone surface rather than expanding. If it stretches, that's a bug worth an issue.

## Contributing

Issues and PRs welcome. Run `flutter analyze` and `flutter test` before opening one.

Keep the jokes in the copy and the timing, not in the code.

## License

Not yet licensed. All rights reserved.

---

**KYA — Comply. Snooze. Repeat.**
