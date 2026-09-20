# KYA™ — Know Your Alarm · 2-minute demo script

**Because waking up wasn't inconvenient enough.**

## 0:00–0:12 — Hook

Alarm screen, ringing.

"Everyone knows the snooze button. You're tired, you want five more minutes."

Tap **SNOOZE**. The button dodges.

"So we asked: what if snoozing required **bank-level identity verification**?"

"Meet KYA — Know Your Alarm."

## 0:12–0:25 — The trap

KYA verification screen.

**FORM KYA-001B · Status: Pending · Risk Level: Sleepy**

"To snooze, you file a *Snooze Termination Request*. Because sleeping is a high-risk activity."

Tap **Start Verification**.

## 0:25–0:40 — Step 1: Reason form

"First, why do you want to snooze?"

Select **I am tired.** → app demands: **Explain why. Minimum 50 characters.**

"I literally just told it."

Type, continue.

## 0:40–0:55 — Step 2: CAPTCHA

**Select everything you would rather be doing right now.**

Tap the bed and the pillow.

**VERIFICATION FAILED — Sleeping behavior detected.**

"So wanting to sleep is suspicious behavior. In an alarm app."

## 0:55–1:10 — Step 3: AI Snooze Officer

Alby, now in uniform: **"I'm Alby, your AI Snooze Compliance Officer."**

Type: "I'm really tired."

**REJECTED. Insufficient justification. Please provide supporting documentation.**

Appeal. Granted, grudgingly.

## 1:10–1:22 — Processing

"Reviewing your sleep history… Contacting your pillow… Consulting the International Sleep Authority… Evaluating vibes…"

Progress hits **97%**, then drops.

## 1:22–1:45 — Step 4: KYC — Identity Wake Check ⭐

Front camera opens. Badge: **MOCK KYC • DEMO MODE**.

"And this is the part we actually built: a real KYC liveness check. Same flow your bank makes you do — except the bank doesn't make you do it at 6am."

Tap **BEGIN FACE SCAN**. Live preview, blue frame, three prompts:

- **Face front.** Pretend you read the terms.
- **Turn left.** Avoid eye contact with responsibility.
- **Turn right.** Check for unfinished tasks.

Frame turns green: **Identity confirmed. Somehow.**

"Live preview only — nothing is recorded, uploaded, or stored."

*(Camera unavailable? The scan still runs; the demo never blocks.)*

## 1:45–2:00 — Punchline

Confetti. **KYA VERIFIED! Identity confirmed. Alarm silenced.**

Reveal: **AUTHORIZED SNOOZE PERIOD — 00:00:30.**

"Thirty. Seconds."

Countdown runs out: **Your authorized unconsciousness period has expired.** Alarm returns.

"KYA — Comply. Snooze. Repeat."

---

**Timing note:** the face scan is 12s (3 × 4s phases), set by `_kScanPhase` in `lib/main.dart`. Raise it for a longer demo; the script's 1:22–1:45 block assumes 12s.
